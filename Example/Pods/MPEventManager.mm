// Copyright 2004-present Facebook. All Rights Reserved.
//
// You are hereby granted a non-exclusive, worldwide, royalty-free license to use,
// copy, modify, and distribute this software in source code or binary form for use
// in connection with the web services and APIs provided by Facebook.
//
// As with any software that integrates with the Facebook platform, your use of
// this software is subject to the Facebook Developer Principles and Policies
// [http://developers.facebook.com/policy/]. This copyright notice shall be
// included in all copies or substantial portions of the software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "MPEventManager.h"

#import <sqlite3.h>

#import "MPConcurrentArray.h"
#import "MPConfigManager.h"
#import "MPDatabaseManager.h"
#import "MPDebugLogging.h"
#import "MPDefines+Internal.h"
#import "MPDynamicFrameworkLoader.h"
#import "MPSettings+Internal.h"
#import "MPTimer.h"
#import "MPURLSession.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MPEventStatusCode) {
  MPEventStatusCodeSuccess = 1,
  MPEventStatusCodeSystemError = 1000,
  MPEventStatusCodeUnretriableError = 2000,
};

typedef void (^MPEventIntCallback)(int a);
typedef void (^MPEventDatabaseCallback)(sqlite3 *db);
typedef void (^MPEventObjectCallback)(MPEvent *event);
typedef void (^MPEventArrayEventCallback)(NSMutableArray<MPEvent *> *events);
typedef void (^MPEventArrayTokenCallback)(NSMutableArray<MPEventToken *> *tokens);
typedef void (^MPEventStatementCallback)(sqlite3_stmt *pStmt);

static const NSTimeInterval FB_EVENT_RETRY_TIME = 5.0;
static const NSTimeInterval FB_EVENT_MUST_DISPATCH_TIME = 5 * 60;

@interface MPEventManager ()

@property (nonatomic, strong, readwrite) NSUUID *sessionId;
@property (nonatomic, strong) NSDate *sessionStartTime;
@property (nonatomic, strong) MPDatabaseManager *databaseManager;
@property (nonatomic, strong) MPTimer *dispatchTimer;
@property (nonatomic, strong) dispatch_queue_t dispatchTimerQueue;
@property (nonatomic, strong) MPConcurrentArray<NSString *> *eventsInTransit;
@property (nonatomic, assign) NSUInteger sendAttempts;

@end

@implementation MPEventManager

+ (instancetype)sharedManager
{
  return FB_INITIALIZE_AND_RETURN_STATIC([MPEventManager new]);
}

- (instancetype)init
{
  return [self initWithDatabaseManager:[MPDatabaseManager sharedManager]];
}

- (instancetype)initWithDatabaseManager:(MPDatabaseManager *)databaseManager
{
  self = [super init];
  if (self) {
    _sessionId = [NSUUID UUID];
    _sessionStartTime = [NSDate date];
    _databaseManager = databaseManager;
    _eventsInTransit = [MPConcurrentArray array];
    _dispatchTimerQueue = dispatch_queue_create("com.facebook.ads.serialTimerQueue", nullptr);
    [self setupDatabaseWithCallback:nil];
    [self resetDispatchTimerWithTimeInterval:FB_EVENT_MUST_DISPATCH_TIME];
    [self dispatchEventsImmediately];
  }
  return self;
}

- (void)resetDispatchTimerWithTimeInterval:(NSTimeInterval)timeInterval {
  weakify(self);
  dispatch_async(self.dispatchTimerQueue, ^{
    strongify(self);
    [self.dispatchTimer invalidate];
    weakify(self);
    self.dispatchTimer = [MPTimer scheduledTimerWithTimeInterval:timeInterval repeats:NO queue:self.dispatchTimerQueue block:^(MPTimer *timer) {
      strongify(self);
      [self dispatchEventsImmediately];
      [self resetDispatchTimerWithTimeInterval:FB_EVENT_MUST_DISPATCH_TIME];
    }];
  });
}

- (void)migrateDatabaseV1ToV2:(sqlite3 *)db
{
  [self.databaseManager insertWithStatementSync:"ALTER TABLE events ADD attempt BIGINT DEFAULT 1"
                                   withDatabase:db
                          withStatementCallback:nil
                         withCompletionCallback:^(NSError *error) {
                           if ([error.domain isEqualToString:MPDatabaseManagerCriticalErrorDomain]) {
                             [MPDebugLogging logDatabaseDebugEventWithCode:MPDatabaseDebugEventCodeCannotMigrateV1toV2 errorDescription:error.localizedDescription];
                           }
                         }];
}

- (void)setupDatabaseWithCallback:(nullable MPEventDatabaseCallback)callback
{
  MPDatabaseVersionChangedCallback downgradeCallback = ^(sqlite3 *db, int previousVersion, int currentVersion) {
    // SDK schema changed, wipe everything (Saved database is newer than running interface)
    [self.databaseManager dropTableSyncWithDatabase:db withTableName:@"tokens" withCallback:nil];
    [self.databaseManager dropTableSyncWithDatabase:db withTableName:@"events" withCallback:nil];
  };
  
  MPDatabaseVersionChangedCallback upgradeCallback = ^(sqlite3 *db, int previousVersion, int currentVersion) {
    if (previousVersion <= 1 && currentVersion >=2) {
      [self migrateDatabaseV1ToV2:db];
    }
    else {
      // Migration seems to be unimplemeted, wipe everything
      [self.databaseManager dropTableSyncWithDatabase:db withTableName:@"tokens" withCallback:nil];
      [self.databaseManager dropTableSyncWithDatabase:db withTableName:@"events" withCallback:nil];
    }
  };
  
  [self.databaseManager initializeDatabaseWithCompletionCallback:^(sqlite3 *db) {
    try {
      [self.databaseManager createTableSyncWithDatabase:db withStatement:[[self class] tokenTableString] withCallback:nil];
      [self.databaseManager createTableSyncWithDatabase:db withStatement:[[self class] eventTableString] withCallback:nil];
      [self removeAllOrphanedTokensSyncWithDatabase:db withCallback:nil];
      [self removeAllOrphanedEventsSyncWithDatabase:db withCallback:nil];
      MPLogDebug(@"Finished event database initialization!");
      if (callback) {
        callback(db);
      };
    } catch (...) {
      
    }
  } withDowngradeCallback:downgradeCallback withUpgradeCallback:upgradeCallback];
  
}

- (void)tokenIdForToken:(nullable NSString *)token withCallback:(nullable MPEventTokenIdCallback)callback
{
  [self.databaseManager getDatabase:^(sqlite3 *db) {
    [self queryTokensSyncWithStatement:(const char *)[[NSString stringWithFormat:@"SELECT * FROM tokens WHERE token = \"%@\"", token] UTF8String]
                          withDatabase:db
                          withCallback:^(NSArray<MPEventToken *> *tokens) {
                            NSUUID *tokenId = tokens.firstObject.tokenId;
                            if (!tokenId && token) {
                              MPEventToken *tokenObj = [[MPEventToken alloc] initWithToken:MPUnwrap(token)];
                              tokenId = tokenObj.tokenId;
                              [self.databaseManager insertWithStatementSync:"INSERT INTO tokens (tokenId, token) VALUES (?, ?);"
                                                               withDatabase:db
                                                      withStatementCallback:^(sqlite3_stmt *pStmt) {
                                                        mpsdk_dfl_sqlite3_bind_text(pStmt, 1, tokenObj.tokenId.UUIDString.UTF8String, -1, nil);
                                                        mpsdk_dfl_sqlite3_bind_text(pStmt, 2, tokenObj.token.UTF8String, -1, nil);
                                                      } withCompletionCallback:^(NSError *error) {
                                                        if ([error.domain isEqualToString:MPDatabaseManagerCriticalErrorDomain]) {
                                                          [MPDebugLogging logDatabaseDebugEventWithCode:MPDatabaseDebugEventCodeCannotInsertToken errorDescription:error.localizedDescription];
                                                        }
                                                        if (nil != callback) {
                                                          callback(tokenId);
                                                        }
                                                      }];
                            } else {
                              if (nil != callback) {
                                callback(tokenId);
                              }
                            }
                          }];
  }];
}

- (void)logEvent:(MPEvent *)event withCallback:(nullable MPEventVoidCallback)callback
{
  [self.databaseManager getDatabase:^(sqlite3 *db) {
    [self insertEvent:event withDatabase:db withCallback:^{
      if ([self shouldDispatchNow:event]) {
        MPLogDebug(@"Dispatching events now!");
        [self dispatchEvents];
      } else {
        MPLogDebug(@"Waiting to dispatch events...");
      }
      if (callback) {
        callback();
      }
    }];
  }];
}

- (void)logEventOfType:(MPEventType)type withPriority:(MPEventPriority)priority withToken:(nullable NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:type withPriority:priority withToken:token withExtraData:extraData withCallback:nil];
}

- (void)logEventOfType:(MPEventType)type withPriority:(MPEventPriority)priority withToken:(nullable NSString *)token withExtraData:(nullable NSDictionary *)extraData withCallback:(nullable MPEventVoidCallback)callback
{
  [self tokenIdForToken:token withCallback:^(NSUUID *tokenId) {
    [self logEvent:[[MPEvent alloc] initWithType:type
                                      withPriority:priority
                                       withTokenId:tokenId
                                     withSessionId:self.sessionId
                              withSessionStartTime:self.sessionStartTime
                                     withExtraData:extraData] withCallback:callback];
  }];
}

- (void)logImpressionForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeImpression withPriority:MPEventPriorityImmediate withToken:token withExtraData:extraData];
}

- (void)logImpressionMissForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeImpressionMiss withPriority:MPEventPriorityDeferred withToken:token withExtraData:extraData];
}

- (void)logStoreClickForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeStoreClick withPriority:MPEventPriorityImmediate withToken:token withExtraData:extraData];
}

- (void)logLinkClickForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeLinkClick withPriority:MPEventPriorityImmediate withToken:token withExtraData:extraData];
}

- (void)logSnapshotForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeViewReport withPriority:MPEventPriorityDeferred withToken:token withExtraData:extraData];
}

- (void)logVideoEventForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeVideo withPriority:MPEventPriorityImmediate withToken:token withExtraData:extraData];
//  NSLog(@"%@",extraData);
}

- (void)logCloseEventForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeClose withPriority:MPEventPriorityImmediate withToken:token withExtraData:extraData];
}

- (void)logBrowserSessionEventForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeBrowserSession withPriority:MPEventPriorityDeferred withToken:token withExtraData:extraData];
}

- (void)logAdCompleteEventForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData
{
  [self logEventOfType:MPEventTypeAdComplete withPriority:MPEventPriorityImmediate withToken:token withExtraData:extraData];
}

- (void)logDebugEventWithExtraData:(nullable NSDictionary<NSString *, id> *)extraData
{
  if ([[MPConfigManager sharedManager] isDebugLoggingEnabled]) {
    MPEvent *debugEvent = [[MPEvent alloc] initWithType:MPEventTypeDebug
                                               withPriority:MPEventPriorityDeferred
                                                withTokenId:nil
                                              withSessionId:self.sessionId
                                       withSessionStartTime:self.sessionStartTime
                                              withExtraData:extraData];
    [self logEvent:debugEvent withCallback:nil];
  }
}

- (BOOL)shouldDispatchNow:(MPEvent *)event
{
  return (event.priority == MPEventPriorityImmediate);
}

- (void)retryDispatch
{
  [self resetDispatchTimerWithTimeInterval:FB_EVENT_RETRY_TIME];
}

- (void)dispatchEvents
{
  [self resetDispatchTimerWithTimeInterval:[[MPConfigManager sharedManager] unifiedLoggingImmediateDelay]];
}

- (void)dispatchEventsImmediately
{
  self.sendAttempts++;
  
  [self.databaseManager getDatabase:^(sqlite3 *db) {
    NSMutableString *eventQueryString = [NSMutableString stringWithFormat:@"SELECT * FROM events"];
    NSInteger eventLimit = [[MPConfigManager sharedManager] unifiedLoggingEventLimit];
    if (eventLimit > 0) {
      [eventQueryString appendFormat:@" LIMIT %ld", (long)eventLimit];
    }
    
    [self queryEventsSyncWithStatement:(const char *)eventQueryString.UTF8String withDatabase:db withCallback:^(NSMutableArray<MPEvent *> *events) {
      try {
        // Exclude events waiting on a response and update transit list
        NSArray *eventIdsInTransit = [self.eventsInTransit nonConcurrentCopy];
        NSMutableArray<MPEvent *> *eventsToRemove = [NSMutableArray arrayWithCapacity:eventIdsInTransit.count];
        NSMutableSet<NSString*> *newTransitEvents = [NSMutableSet set];
        for (MPEvent *event in events) {
          if ([eventIdsInTransit containsObject:event.eventId.UUIDString]) {
            [eventsToRemove addObject:event];
          } else {
            // Add event to transit list
            NSString *eventId = event.eventId.UUIDString;
            [newTransitEvents addObject:eventId];
            [self.eventsInTransit addObject:eventId];
          }
        }
        [events removeObjectsInArray:eventsToRemove];
        eventsToRemove = nil;
        
        // Exit early if no events are found
        if (events.count == 0) {
          if (eventIdsInTransit.count == 0) {
            self.sendAttempts = 0;
          }
          return;
        }
        
        // Get all event ids to query
        NSMutableSet *tokenIds = [NSMutableSet setWithCapacity:events.count];
        for (MPEvent *event in events) {
          if (event.tokenId) {
            [tokenIds addObject:MPUnwrap(event.tokenId)];
          }
        }
        
        // Construct token query string
        NSMutableString *tokenQueryString = [NSMutableString stringWithFormat:@"SELECT * FROM tokens WHERE "];
        for (NSUUID *tokenId in tokenIds) {
          [tokenQueryString appendFormat:@"tokenId = \"%@\" OR ", tokenId.UUIDString];
        }
        [tokenQueryString appendString:@"1"];
        
        [self queryTokensSyncWithStatement:(const char *)tokenQueryString.UTF8String withDatabase:db withCallback:^(NSArray<MPEventToken *> *tokens) {
          try {
            NSURL *eventURL = [MPSettings getBaseEventURL];
            MPLogDebug(@"Logging %lu event%s with %lu token%s to %@...", (unsigned long)events.count, events.count > 1 ? "s" : "", (unsigned long)tokens.count, tokens.count > 1 ? "s" : "", eventURL.absoluteString);
            // Construct request data
            NSMutableDictionary *tokenDict = [NSMutableDictionary dictionaryWithCapacity:tokens.count];
            NSMutableArray *eventArray = [NSMutableArray arrayWithCapacity:events.count];
            for (MPEvent *event in events) {
              NSMutableDictionary *mutableEventData = [@{@"id": event.eventId.UUIDString,
                                                         @"type": event.type,
                                                         @"time": @(event.time.timeIntervalSince1970).stringValue,
                                                         @"session_id": event.sessionId.UUIDString,
                                                         @"session_time": @(event.sessionStartTime.timeIntervalSince1970).stringValue,
                                                         @"data": event.extraData ? MPUnwrap(event.extraData) : @{},
                                                         @"attempt": [@(event.attemptsCount) stringValue]
                                                         } mutableCopy];
              NSUUID *tokenId = event.tokenId;
              if (tokenId) {
                mutableEventData[@"token_id"] = MPUnwrap(tokenId.UUIDString);
              }
              NSDictionary *eventData = [NSDictionary dictionaryWithDictionary:mutableEventData];
              [eventArray addObject:eventData];
              MPLogDebug(@"Logging event of type %@ with event ID %@ with token ID %@", event.type, event.eventId.UUIDString, event.tokenId.UUIDString);
              //                            [event logStatusMessage];
            }
            for (MPEventToken *token in tokens) {
              [tokenDict setObject:token.token forKey:token.tokenId.UUIDString];
              MPLogDebug(@"Logging token with token ID: %@", token.tokenId.UUIDString);
            }
            NSDictionary *extraData = @{@"payload":
                                          @{
                                            @"tokens": tokenDict,
                                            @"events": eventArray
                                            }
                                        };
            
            [self sendRequestInternal:eventURL withExtraData:extraData onRetry:^{
              [self.databaseManager getDatabase:^(sqlite3 *database) {
                for (MPEvent *event in events) {
                  event.attemptsCount++;
                  [self updateAttemptCountForEvent:event withDatabase:database withCallback:nil];
                }
              }];
              
              for (NSString *eventId in newTransitEvents) {
                [self.eventsInTransit removeObject:eventId];
              }
            }];
          } catch (...) {
          }
        }];
      } catch (...) {
      }
    }];
  }];
}

- (void)sendRequestInternal:(NSURL *)url
              withExtraData:(nullable NSDictionary *)extraData
                    onRetry:(void(^)(void)) onRetryBlock
{
  NSMutableDictionary *queryParameters = [NSMutableDictionary dictionary];
  if (extraData) {
    [queryParameters addEntriesFromDictionary:MPUnwrap(extraData)];
    
  }
  
  [[MPURLSession sharedSession] requestWithURL:url
                                      HTTPMethod:@"POST"
                                 queryParameters:queryParameters
                                 responseHandler:^(MPURLSessionTaskContainer *container,
                                                   NSURLResponse *response,
                                                   NSData *data,
                                                   NSError *error,
                                                   NSTimeInterval duration) {
                                   MPLogVerbose(@"Internal request: %@ %@ %@", response, data, error);
                                   NSHTTPURLResponse *httpResponse = nil;
                                   if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                     httpResponse = (NSHTTPURLResponse *)response;
                                   }
                                   if (error || !httpResponse || httpResponse.statusCode != 200) {
                                     // [T22801813] The request is too large, purge if purge is enabled in the configManager
                                     if (httpResponse.statusCode == 413 && [MPConfigManager sharedManager].shouldPurgeEventsAndTokensOn413Response) {
                                       [self.databaseManager getDatabase:^(sqlite3 *db) {
                                         [self.databaseManager deleteWithStatementSync:"DELETE FROM events" withDatabase:db withCallback:nil];
                                         [self.databaseManager deleteWithStatementSync:"DELETE FROM tokens" withDatabase:db withCallback:nil];
                                         [self.eventsInTransit removeAllObjects];
                                         self.sendAttempts = 0;
                                       }];
                                       return;
                                     }
                                     FB_BLOCK_CALL_SAFE(onRetryBlock);
                                     // Retry if network is online, otherwise wait for the next dispatch
                                     if (error.code != NSURLErrorNotConnectedToInternet) {
                                       [self retryDispatch];
                                     }
                                     return;
                                   }
                                   [self.databaseManager getDatabase:^(sqlite3 *db) {
                                     NSArray *jsonObj = [MPUtility getObjectFromJSONData:data];
                                     BOOL shouldRetry = NO;
                                     NSMutableArray<NSString *> *eventIdsToCleanup = [NSMutableArray arrayWithCapacity:jsonObj.count];
                                     for (NSDictionary *eventResult in jsonObj) {
                                       NSString *eventId = [eventResult stringForKeyOrNil:@"id"];
                                       NSString *eventStatus = [eventResult stringForKeyOrNil:@"code"];
                                       // Remove event from transit status
                                       [self.eventsInTransit removeObject:eventId];
                                       
                                       // Check if successful, if it's retriable, or just remove the event
                                       if ([self isEventSuccessful:eventStatus]) {
                                         // Success, remove old events
                                         MPLogDebug(@"Event with event ID %@ logged successfully.", eventId);
                                         if (eventId) {
                                           [eventIdsToCleanup addObject:eventId];
                                         }
                                       } else if ([self isEventRetriable:eventStatus]) {
                                         // Failure, retry
                                         MPLogDebug(@"Event with event ID %@ failed. Retrying...", eventId);
                                         shouldRetry = YES;
                                       } else {
                                         MPLogDebug(@"Event with event ID %@ failed.", eventId);
                                         if (eventId) {
                                           [eventIdsToCleanup addObject:eventId];
                                         }
                                       }
                                     }
                                     NSMutableString *queryString = [NSMutableString stringWithFormat:@"SELECT * FROM events WHERE "];
                                     BOOL next = NO;
                                     for (NSUUID *eventId in eventIdsToCleanup) {
                                       if (next) {
                                         [queryString appendString:@" OR "];
                                       }
                                       [queryString appendFormat:@"eventId = \"%@\"", eventId];
                                       next = YES;
                                     }
                                     [self queryEventsSyncWithStatement:(const char *)queryString.UTF8String withDatabase:db withCallback:^(NSMutableArray<MPEvent *> *eventsToBeCleanedUp) {
                                       for (MPEvent *eventToBeCleanedUp in eventsToBeCleanedUp) {
                                         MPLogDebug(@"Event %@ has been finalized and will be cleaned up.", eventToBeCleanedUp);
                                       }
                                       [self cleanupEventsSync:eventIdsToCleanup withDatabase:db];
                                     }];
                                     if (shouldRetry) {
                                       FB_BLOCK_CALL_SAFE(onRetryBlock);
                                       [self retryDispatch];
                                     } else {
                                       self.sendAttempts = 0;
                                     }
                                   }];
                                 }];
}

- (BOOL)isEventSuccessful:(NSString *)eventStatus
{
  return (eventStatus.integerValue == MPEventStatusCodeSuccess);
}

- (BOOL)isEventRetriable:(NSString *)eventStatus
{
  // Is the event status code indicating any unretriable error (2000+)?
  NSInteger code = eventStatus.integerValue;
  return !(code >= 2000 && code < 3000);
}

- (void)cleanupEventsSync:(NSMutableArray<NSString *> *)eventIds withDatabase:(sqlite3 *)db
{
  FBAssertNotMainThread();
  if (eventIds.count) {
    NSMutableString *deleteQueryString = [NSMutableString stringWithFormat:@"DELETE FROM events WHERE "];
    BOOL next = NO;
    for (NSUUID *eventId in eventIds) {
      if (next) {
        [deleteQueryString appendString:@" OR "];
      }
      [deleteQueryString appendFormat:@"eventId = \"%@\"", eventId];
      next = YES;
    }
    [self.databaseManager deleteWithStatementSync:(const char *)deleteQueryString.UTF8String withDatabase:db withCallback:^(NSError *error) {
      // Cleanup unused tokens
      [self removeAllOrphanedTokensSyncWithDatabase:db withCallback:nil];
    }];
  }
}


#pragma mark Database Management

+ (char const *)tokenTableString
{
  char const *token = "CREATE TABLE tokens( \
  tokenId TEXT PRIMARY KEY NOT NULL, \
  token TEXT \
  );";
  return token;
}

+ (char const *)eventTableString
{
  char const *event = "CREATE TABLE events( \
  eventId TEXT PRIMARY KEY NOT NULL, \
  tokenId TEXT REFERENCES tokens ON UPDATE CASCADE ON DELETE RESTRICT, \
  priority BIGINT, \
  type TEXT, \
  time DOUBLE, \
  sessionId TEXT, \
  sessionStartTime DOUBLE, \
  data TEXT, \
  attempt BIGINT \
  );";
  return event;
}

#pragma mark Database Insertion

- (void)insertEvent:(MPEvent *)event withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPEventVoidCallback)callback
{
  FBAssertNotMainThread();
  [self.databaseManager insertWithStatementSync:"INSERT INTO events (eventId, tokenId, priority, type, time, sessionId, sessionStartTime, data, attempt) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);"
                                   withDatabase:db
                          withStatementCallback:^(sqlite3_stmt *pStmt) {
                            mpsdk_dfl_sqlite3_bind_text(pStmt, 1, event.eventId.UUIDString.UTF8String, -1, nil);
                            mpsdk_dfl_sqlite3_bind_text(pStmt, 2, event.tokenId.UUIDString.UTF8String, -1, nil);
                            mpsdk_dfl_sqlite3_bind_int64(pStmt, 3, (sqlite3_int64)event.priority);
                            mpsdk_dfl_sqlite3_bind_text(pStmt, 4, event.type.UTF8String, -1, nil);
                            mpsdk_dfl_sqlite3_bind_double(pStmt, 5, (double)event.time.timeIntervalSince1970);
                            mpsdk_dfl_sqlite3_bind_text(pStmt, 6, event.sessionId.UUIDString.UTF8String, -1, nil);
                            mpsdk_dfl_sqlite3_bind_double(pStmt, 7, (double)event.sessionStartTime.timeIntervalSince1970);
                            mpsdk_dfl_sqlite3_bind_text(pStmt, 8, event.jsonExtraData.UTF8String, -1, nil);
                            mpsdk_dfl_sqlite3_bind_int64(pStmt, 9, (sqlite3_int64)event.attemptsCount);
                          } withCompletionCallback:^(NSError *error) {
                            if ([error.domain isEqualToString:MPDatabaseManagerCriticalErrorDomain]) {
                              [MPDebugLogging logDatabaseDebugEventWithCode:MPDatabaseDebugEventCodeCannotInsertEvent errorDescription:error.localizedDescription];
                            }
                            if (nil != callback) {
                              return callback();
                            }
                          }];
}

- (void)updateAttemptCountForEvent:(MPEvent *)event withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPEventVoidCallback)callback
{
  FBAssertNotMainThread();
  NSUInteger attempts = event.attemptsCount;
  NSString *eventId = event.eventId.UUIDString;
  NSString *statement = [NSString stringWithFormat:@"UPDATE events SET attempt = %lu WHERE eventId = '%@';", (unsigned long)attempts, eventId];
  
  [self.databaseManager insertWithStatementSync:(const char *)statement.UTF8String
                                   withDatabase:db
                          withStatementCallback:nil
                         withCompletionCallback:^(NSError *error) {
                           if (nil != callback) {
                             return callback();
                           }
                         }];
}

#pragma mark Database Deletion

- (void)removeAllOrphanedTokensWithDatabase:(sqlite3 *)db withCallback:(nullable MPEventVoidCallback)callback
{
  [self.databaseManager getDatabase:^(sqlite3 * __nullable unneeded) {
    [self removeAllOrphanedTokensSyncWithDatabase:db withCallback:callback];
  }];
}

- (void)removeAllOrphanedEventsWithDatabase:(sqlite3 *)db withCallback:(nullable MPEventVoidCallback)callback
{
  [self.databaseManager getDatabase:^(sqlite3 * __nullable unneeded) {
    [self removeAllOrphanedEventsSyncWithDatabase:db withCallback:callback];
  }];
}

- (void)removeAllOrphanedTokensSyncWithDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPEventVoidCallback)callback
{
  const char *query = "SELECT * FROM tokens WHERE NOT EXISTS (SELECT * FROM events WHERE tokens.tokenId = events.tokenId)";
  [self.databaseManager queryWithStatementSync:query withDatabase:db withCallback:^(sqlite3_stmt *pStmt) {
    NSMutableArray<NSString *> *tokenIds = [NSMutableArray array];
    NSMutableString *deleteQueryString = nil;
    if (pStmt) {
      while (mpsdk_dfl_sqlite3_step(pStmt) == SQLITE_ROW) {
        const char *tokenId = (const char *)mpsdk_dfl_sqlite3_column_text(pStmt, 0);
        if (tokenId) {
          NSString *tokenId_str = [NSString stringWithUTF8String:tokenId];
          [tokenIds addObject:tokenId_str];
        }
      }
      
      if (tokenIds.count > 0) {
        // Construct token query string
        deleteQueryString = [NSMutableString stringWithFormat:@"DELETE FROM tokens WHERE "];
        BOOL next = NO;
        for (NSUUID *tokenId in tokenIds) {
          if (next) {
            [deleteQueryString appendString:@" OR "];
          }
          [deleteQueryString appendFormat:@"tokenId = \"%@\"", tokenId];
          next = YES;
        }
        
      }
    }
    
    [self.databaseManager deleteWithStatementSync:(const char *)deleteQueryString.UTF8String withDatabase:db withCallback:^(NSError *error) {
      if (nil != callback) {
        callback();
      }
    }];
    
  }];
}

- (void)removeAllOrphanedEventsSyncWithDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPEventVoidCallback)callback
{
  const char *query = "SELECT * FROM events WHERE NOT EXISTS (SELECT * FROM tokens WHERE tokens.tokenId = events.tokenId)";
  [self.databaseManager queryWithStatementSync:query withDatabase:db withCallback:^(sqlite3_stmt *pStmt) {
    NSMutableArray<NSString *> *eventIds = [NSMutableArray array];
    NSMutableString *deleteQueryString = nil;
    if (pStmt) {
      while (mpsdk_dfl_sqlite3_step(pStmt) == SQLITE_ROW) {
        const char *eventId = (const char *)mpsdk_dfl_sqlite3_column_text(pStmt, 0);
        if (eventId) {
          NSString *eventId_str = [NSString stringWithUTF8String:eventId];
          [eventIds addObject:eventId_str];
        }
      }
      
      if (eventIds.count > 0) {
        // Construct event query string
        deleteQueryString = [NSMutableString stringWithFormat:@"DELETE FROM events WHERE "];
        BOOL next = NO;
        for (NSUUID *eventId in eventIds) {
          if (next) {
            [deleteQueryString appendString:@" OR "];
          }
          [deleteQueryString appendFormat:@"eventId = \"%@\"", eventId];
          next = YES;
        }
      }
    }
    
    [self.databaseManager deleteWithStatementSync:(const char *)deleteQueryString.UTF8String withDatabase:db withCallback:^(NSError *error) {
      if (nil != callback) {
        callback();
      }
    }];
    
  }];
}

#pragma mark Database Querying

- (void)queryEventsSyncWithStatement:(char const *)queryStatementString withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPEventArrayEventCallback)callback
{
  [self.databaseManager deserializeWithStatementSync:queryStatementString withDatabase:db withDeserializeCallback:^id __nullable(sqlite3_stmt * __nullable pStmt) {
    return [MPEvent deserializeFromSqlite:pStmt];
  } withCallback:^(NSMutableArray *array) {
    if (callback) {
      return callback(array);
    }
  }];
}

- (void)queryTokensSyncWithStatement:(char const *)queryStatementString withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPEventArrayTokenCallback)callback
{
  [self.databaseManager deserializeWithStatementSync:queryStatementString withDatabase:db withDeserializeCallback:^id __nullable(sqlite3_stmt * __nullable pStmt) {
    return [MPEventToken deserializeFromSqlite:pStmt];
  } withCallback:^(NSMutableArray *array) {
    if (callback) {
      return callback(array);
    }
  }];
}

#pragma mark Session Management

- (NSTimeInterval)sessionTime
{
  return [[NSDate date] timeIntervalSince1970] - [self.sessionStartTime timeIntervalSince1970];
}

@end

NS_ASSUME_NONNULL_END

