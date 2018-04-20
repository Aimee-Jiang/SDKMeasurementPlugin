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

#import "MPEvent.h"

#import "MPDebugLogging.h"
#import "MPDynamicFrameworkLoader.h"
#import "MPUtilityFunctions.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPEvent ()

@property (nonatomic, copy, readwrite) NSUUID *eventId;
@property (nonatomic, copy, readwrite) MPEventType type;
@property (nonatomic, copy, readwrite) NSDate *time;
@property (nonatomic, copy, readwrite) NSDate *expiration;
@property (nonatomic, assign, readwrite) MPEventPriority priority;
@property (nonatomic, copy, readwrite, nullable) NSDictionary<NSString *, id> *extraData;
@property (nonatomic, copy, readwrite, nullable) NSUUID *tokenId;

@end

@implementation MPEvent

- (instancetype)initWithType:(MPEventType)type
                withPriority:(MPEventPriority)priority
                 withTokenId:(nullable NSUUID *)tokenId
               withSessionId:(NSUUID *)sessionId
        withSessionStartTime:(NSDate *)sessionStartTime
               withExtraData:(nullable NSDictionary<NSString *, id> *)extraData
{
  self = [super init];
  if (self) {
    _type = type;
    _eventId = [NSUUID UUID];
    _time = [NSDate date];
    _priority = priority;
    _extraData = extraData;
    _tokenId = tokenId;
    _sessionId = sessionId;
    _sessionStartTime = sessionStartTime;
    _attemptsCount = 1;
    if (extraData) {
      FBAssertDictionaryTypes(MPUnwrap(extraData), [NSString class], [NSString class]);
    }
  }
  return self;
}

+ (nullable MPEvent *)deserializeFromSqlite:(sqlite3_stmt * __nullable)queryStatement
{
  const char *eventId = (const char *)mpsdk_dfl_sqlite3_column_text(queryStatement, 0);
  const char *tokenId = (const char *)mpsdk_dfl_sqlite3_column_text(queryStatement, 1);
  sqlite3_int64 priority = mpsdk_dfl_sqlite3_column_int64(queryStatement, 2);
  const char *type = (const char *)mpsdk_dfl_sqlite3_column_text(queryStatement, 3);
  double time = mpsdk_dfl_sqlite3_column_double(queryStatement, 4);
  const char *sessionId = (const char *)mpsdk_dfl_sqlite3_column_text(queryStatement, 5);
  double sessionStartTime = mpsdk_dfl_sqlite3_column_double(queryStatement, 6);
  const char *jsonExtraData = (const char *)mpsdk_dfl_sqlite3_column_text(queryStatement, 7);
  sqlite3_int64 attemptsCount = mpsdk_dfl_sqlite3_column_int64(queryStatement, 8);
  
  id extraData = nil;
  if (jsonExtraData) {
    extraData = [MPUtility getObjectFromJSONString:@(jsonExtraData)];
  }
  
  if (!eventId || !type || !sessionId) {
    NSMutableDictionary<NSString *, NSString *> *info = [NSMutableDictionary new];
    [info adnw_setNullStringIfNullCharPointer:eventId forKey:@"eventId"];
    [info adnw_setNullStringIfNullCharPointer:type forKey:@"type"];
    [info adnw_setNullStringIfNullCharPointer:sessionId forKey:@"sessionId"];
    [info adnw_setNullStringIfNullCharPointer:tokenId forKey:@"tokenId"];
    
    [MPDebugLogging logDatabaseDebugEventWithCode:MPDatabaseDebugEventCodeCannotDeserializeEvent info:info];
    return nil;
  }
  
  NSUUID * __nullable tokenUUID = nil;
  if (tokenId) {
    tokenUUID = [[NSUUID alloc] initWithUUIDString:@(tokenId)];
  }
  NSUUID *sessionUUID = [[NSUUID alloc] initWithUUIDString:@(sessionId)];
  NSUUID *eventUUID = [[NSUUID alloc] initWithUUIDString:@(eventId)];
  
  MPEvent *event = [[MPEvent alloc] initWithType:@(type)
                                        withPriority:(MPEventPriority)priority
                                         withTokenId:tokenUUID
                                       withSessionId:sessionUUID ?: [NSUUID UUID]
                                withSessionStartTime:[NSDate dateWithTimeIntervalSince1970:sessionStartTime]
                                       withExtraData:extraData];
  event.eventId = eventUUID ?: [NSUUID UUID];
  event.time = [NSDate dateWithTimeIntervalSince1970:time];
  event.attemptsCount = attemptsCount;
  
  return event;
}

- (nullable NSString *)jsonExtraData
{
  return [MPUtility getJSONStringFromObject:self.extraData];
}

//- (void)logStatusMessage
//{
//    NSString *type = self.type ? [self.type capitalizedString] : @"Event";
//    [MPUtility displayDebugMessage:@"%@ is logged", type];
//}

- (NSString *)description
{
  return [NSString stringWithFormat:@"<%@: %p; type = %@; eventId = %@; tokenId = %@; time = %@; sessionId = %@>", [self class], self, self.type, self.eventId, self.tokenId, self.time, self.sessionId];
}

@end

NS_ASSUME_NONNULL_END
