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

#import "MPDatabaseManager.h"

#import "MPDebugLogging.h"
#import "MPDevice.h"
#import "MPDynamicFrameworkLoader.h"
#import "MPUtility.h"

NS_ASSUME_NONNULL_BEGIN

static const int FB_DATABASE_VERSION = 2;

NSString *const MPDatabaseManagerErrorDomain = @"MPDatabaseManagerErrorDomain";
NSString *const MPDatabaseManagerCriticalErrorDomain = @"MPDatabaseManagerCriticalErrorDomain";

@interface MPDatabaseManager ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong, readwrite) dispatch_queue_t databaseQueue;
@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, assign, getter=isInitialized) BOOL initialized;

@end

@implementation MPDatabaseManager

+ (instancetype)sharedManager
{
  return FB_INITIALIZE_AND_RETURN_STATIC([MPDatabaseManager new]);
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    _databaseQueue = dispatch_queue_create("com.facebook.ads.database", DISPATCH_QUEUE_SERIAL);
  }
  return self;
}

#pragma mark Database Management

- (void)openDatabaseWithCallback:(MPDatabaseCallback)callback
{
  [self openDatabaseWithCallback:callback withRetry:YES];
}

- (void)openDatabaseWithCallback:(MPDatabaseCallback)callback withRetry:(BOOL)retry
{
  @try {
    if (self.initialized && self.database) {
      if (nil != callback) {
        callback(self.database);
      }
    }
    sqlite3 *db = nil;
    NSURL *pathURL = [self storagePath];
    [[NSFileManager defaultManager] createDirectoryAtURL:MPUnwrap(pathURL.URLByDeletingLastPathComponent) withIntermediateDirectories:YES attributes:nil error:nil];
    char const *path = pathURL.absoluteString.UTF8String;
    if (mpsdk_dfl_sqlite3_open(path, &db) == SQLITE_OK) {
      MPLogDebug(@"Successfully opened connection to database at %s", path);
    } else {
      NSString *severeErrorMessage = @"This is a severe error that may impact the reliability of the Audience Network SDK.";
      MPLogError(@"Could not open database! %@ (%s)", retry ? @"Retrying..." : severeErrorMessage, mpsdk_dfl_sqlite3_errmsg(db));
      if (retry) {
        NSError *error = nil;
        MPLogError(@"Attempting to remove corrupt or invalid database...");
        BOOL removedOldDatabase = [[NSFileManager defaultManager] removeItemAtURL:pathURL error:&error];
        if (!removedOldDatabase) {
          MPLogError(@"Corrupt or invalid database could not be removed.");
        } else {
          MPLogError(@"Corrupt or invalid database removed successfully. Recreating...");
        }
        [self openDatabaseWithCallback:callback withRetry:NO];
      }
      else {
        [MPDebugLogging logDatabaseDebugEventWithCode:MPDatabaseDebugEventCodeCannotOpenDatabase errorDescription:[self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
      }
    }
    self.database = db;
    if (nil != callback) {
      callback(db);
    }
  } @catch (...) {
    
  }
}

- (void)getDatabase:(MPDatabaseCallback)callback
{
  dispatch_async(self.databaseQueue, ^{
    if (callback) {
      callback(self.database);
    }
  });
}

- (int)currentDatabaseVersion
{
  return FB_DATABASE_VERSION;
}

- (void)initializeDatabaseWithCompletionCallback:(nullable MPDatabaseCallback)callback
                           withDowngradeCallback:(nullable MPDatabaseVersionChangedCallback)downgradeCallback
                             withUpgradeCallback:(nullable MPDatabaseVersionChangedCallback)upgradeCallback
{
  dispatch_async(self.databaseQueue, ^{
    [self openDatabaseWithCallback:^(sqlite3 *db) {
      [self queryUserVersionSyncWithDatabase:db withCallback:^(int userVersion) {
        int currentVersion = [self currentDatabaseVersion];
        if (userVersion > currentVersion) {
          if (nil != downgradeCallback) {
            downgradeCallback(db, userVersion, currentVersion);
          }
        } else if (userVersion < currentVersion) {
          if (nil != upgradeCallback) {
            upgradeCallback(db, userVersion, currentVersion);
          }
        }
        [self setUserVersionSync:currentVersion withDatabase:db withCallback:nil];
        [self setForeignKeyEnforcementSyncWithDatabase:db withCallback:nil];
        MPLogDebug(@"Finished database initialization!");
        if (nil != callback) {
          callback(db);
        }
      }];
    }];
  });
}

- (void)createTableSyncWithDatabase:(sqlite3 *)db withStatement:(char const *)createTableString withCallback:(nullable FB_NOESCAPE MPDatabaseResultCallback)callback
{
  FBAssertNotMainThread();
  
  BOOL tableCreated = NO;
  NSString *errorDomain = nil;
  NSString *errorDescription = nil;
  
  sqlite3_stmt *createTableStatement = nil;
  if (mpsdk_dfl_sqlite3_prepare_v2(db, createTableString, -1, &createTableStatement, nil) == SQLITE_OK) {
    if (mpsdk_dfl_sqlite3_step(createTableStatement) == SQLITE_DONE) {
      tableCreated = YES;
      MPLogDebug(@"Table created.");
    } else {
      errorDomain = MPDatabaseManagerCriticalErrorDomain;
      errorDescription = [NSString stringWithFormat:@"Table could not be created. (%@)", [self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
      MPLogError(@"%@", errorDescription);
    }
  } else {
    errorDomain = MPDatabaseManagerErrorDomain;
    errorDescription = [NSString stringWithFormat:@"CREATE TABLE statement could not be prepared. (%@)", [self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
    MPLogWarning(@"%@", errorDescription);
  }
  
  dispatch_async(self.databaseQueue, ^{
    if (callback) {
      NSError *error = nil;
      if (!tableCreated) {
        error = [NSError errorWithDomain:errorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:errorDescription}];
      }
      callback(error);
    }
    mpsdk_dfl_sqlite3_finalize(createTableStatement);
  });
}

- (void)dropTableSyncWithDatabase:(sqlite3 *)db withTableName:(NSString *)tableName withCallback:(nullable FB_NOESCAPE MPDatabaseResultCallback)callback
{
  FBAssertNotMainThread();
  
  BOOL tableDropped = NO;
  NSString *errorDomain = nil;
  NSString *errorDescription = nil;
  
  sqlite3_stmt *dropTableStatement = nil;
  NSString *query = [NSString stringWithFormat:@"DROP TABLE %@", tableName];
  if (mpsdk_dfl_sqlite3_prepare_v2(db, query.UTF8String, -1, &dropTableStatement, nil) == SQLITE_OK) {
    if (mpsdk_dfl_sqlite3_step(dropTableStatement) == SQLITE_DONE) {
      tableDropped = YES;
      MPLogDebug(@"Table dropped.");
    } else {
      errorDomain = MPDatabaseManagerCriticalErrorDomain;
      errorDescription = [NSString stringWithFormat:@"Table could not be dropped. (%@)", [self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
      MPLogError(@"%@", errorDescription);
    }
  } else {
    errorDomain = MPDatabaseManagerErrorDomain;
    errorDescription = [NSString stringWithFormat:@"DROP TABLE statement could not be prepared. (%@)", [self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
    MPLogWarning(@"%@", errorDescription);
  }
  
  dispatch_async(self.databaseQueue, ^{
    if (callback) {
      NSError *error = nil;
      if (!tableDropped) {
        error = [NSError errorWithDomain:errorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:errorDescription}];
      }
      callback(error);
    }
    mpsdk_dfl_sqlite3_finalize(dropTableStatement);
  });
}

#pragma mark Database Querying

- (void)queryWithStatementSync:(nullable char const *)queryStatementString withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPDatabaseStatementCallback)callback
{
  FBAssertNotMainThread();
  
  if (!queryStatementString) {
    if (callback) {
      return callback(NULL);
    }
  }
  sqlite3_stmt *queryStatement = nil;
  if (mpsdk_dfl_sqlite3_prepare_v2(db, queryStatementString, -1, &queryStatement, nil) == SQLITE_OK) {
  } else {
    MPLogError(@"SELECT statement could not be prepared. (%s)", mpsdk_dfl_sqlite3_errmsg(db));
  }
  
  dispatch_async(self.databaseQueue, ^{
    if (callback) {
      callback(queryStatement);
    }
    mpsdk_dfl_sqlite3_finalize(queryStatement);
  });
}

- (void)deserializeWithStatementSync:(nullable char const *)queryStatementString withDatabase:(sqlite3 *)db withDeserializeCallback:(nullable FB_NOESCAPE MPDatabaseDeserializeCallback)deserializeCallback withCallback:(nullable FB_NOESCAPE MPDatabaseArrayCallback)callback
{
  FBAssertNotMainThread();
  
  [self queryWithStatementSync:queryStatementString withDatabase:db withCallback:^(sqlite3_stmt *pStmt) {
    NSMutableArray *deserializedObjects = [NSMutableArray array];
    if (pStmt) {
      while (mpsdk_dfl_sqlite3_step(pStmt) == SQLITE_ROW) {
        id obj = deserializeCallback(pStmt);
        if (obj) {
          [deserializedObjects addObject:obj];
        }
      }
    }
    if (nil != callback) {
      callback(deserializedObjects);
    }
  }];
}

#pragma mark Database Insertion

- (void)insertWithStatementSync:(nullable char const *)insertStatementString withDatabase:(sqlite3 *)db withStatementCallback:(nullable FB_NOESCAPE MPDatabaseStatementCallback)statementCallback withCompletionCallback:(FB_NOESCAPE MPDatabaseResultCallback)callback
{
  FBAssertNotMainThread();
  
  if (NULL == insertStatementString) {
    dispatch_async(self.databaseQueue, ^{
      if (nil != callback) {
        NSError *error = [NSError errorWithDomain:MPDatabaseManagerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"Empty insert statement string"}];
        callback(error);
      }
    });
    return;
  }
  
  BOOL success = NO;
  NSString *errorDescription = nil;
  
  sqlite3_stmt *insertStatement = nil;
  if (mpsdk_dfl_sqlite3_prepare_v2(db, insertStatementString, -1, &insertStatement, nil) == SQLITE_OK) {
    if (statementCallback) {
      statementCallback(insertStatement);
    }
    if (mpsdk_dfl_sqlite3_step(insertStatement) == SQLITE_DONE) {
      success = YES;
      MPLogDebug(@"Successfully inserted item.");
    } else {
      errorDescription = [NSString stringWithFormat:@"Could not insert item: (%@)", [self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
      MPLogError(@"Could not insert item: (%s) (%s)", insertStatementString, mpsdk_dfl_sqlite3_errmsg(db));
    }
  } else {
    errorDescription = [NSString stringWithFormat:@"INSERT statement could not be prepared: (%@)", [self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
    MPLogError(@"%@", errorDescription);
  }
  
  if (nil != callback) {
    NSError *error = nil;
    if (!success) {
      error = [NSError errorWithDomain:MPDatabaseManagerCriticalErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:errorDescription}];
    }
    callback(error);
  }
  
  mpsdk_dfl_sqlite3_finalize(insertStatement);
}

#pragma mark Database Deletion

- (void)deleteWithStatementSync:(nullable char const *)deleteStatementString withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPDatabaseResultCallback)callback
{
  FBAssertNotMainThread();
  
  if (NULL == deleteStatementString) {
    if (nil != callback) {
      NSError *error = [NSError errorWithDomain:MPDatabaseManagerErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"Empty delete statement string"}];
      callback(error);
    }
    return;
  }
  
  BOOL success = NO;
  NSString *errorDescription = nil;
  
  sqlite3_stmt *deleteStatement = nil;
  if (mpsdk_dfl_sqlite3_prepare_v2(db, deleteStatementString, -1, &deleteStatement, nil) == SQLITE_OK) {
    if (mpsdk_dfl_sqlite3_step(deleteStatement) == SQLITE_DONE) {
      success = YES;
      MPLogDebug(@"Successfully deleted item.");
    } else {
      errorDescription = [NSString stringWithFormat:@"Could not delete item: (%@)", [self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
      MPLogError(@"%@", errorDescription);
    }
  } else {
    errorDescription = [NSString stringWithFormat:@"DELETE statement could not be prepared (%@)", [self stringFromChars:mpsdk_dfl_sqlite3_errmsg(db)]];
    MPLogError(@"%@", errorDescription);
  }
  
  if (nil != callback) {
    NSError *error = nil;
    if (!success) {
      error = [NSError errorWithDomain:MPDatabaseManagerCriticalErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:errorDescription}];
    }
    callback(error);
  }
  dispatch_async(self.databaseQueue, ^{
    mpsdk_dfl_sqlite3_finalize(deleteStatement);
  });
}

#pragma mark Schema Management

- (void)setForeignKeyEnforcementSyncWithDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPDatabaseVoidCallback)callback
{
  FBAssertNotMainThread();
  
  sqlite3_stmt *foreignKeyStatement;
  if (mpsdk_dfl_sqlite3_prepare_v2(db, "PRAGMA foreign_keys = ON", -1, &foreignKeyStatement, NULL) == SQLITE_OK) {
    if (mpsdk_dfl_sqlite3_step(foreignKeyStatement) == SQLITE_DONE) {
      MPLogDebug(@"Successfully changed foreign_keys.");
    } else {
      MPLogError(@"Could not change foreign_keys. (%s)", mpsdk_dfl_sqlite3_errmsg(db));
    }
  } else {
    MPLogError(@"PRAGMA statement could not be prepared. (%s)", mpsdk_dfl_sqlite3_errmsg(db));
  }
  mpsdk_dfl_sqlite3_finalize(foreignKeyStatement);
  if (nil != callback) {
    callback();
  }
}

- (void)queryUserVersionSyncWithDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPDatabaseIntCallback)callback
{
  FBAssertNotMainThread();
  
  sqlite3_stmt *versionStatement;
  int databaseVersion = 0;
  
  if (mpsdk_dfl_sqlite3_prepare_v2(db, "PRAGMA user_version;", -1, &versionStatement, NULL) == SQLITE_OK) {
    while(mpsdk_dfl_sqlite3_step(versionStatement) == SQLITE_ROW) {
      databaseVersion = mpsdk_dfl_sqlite3_column_int(versionStatement, 0);
      MPLogDebug(@"Current database version: %d", databaseVersion);
    }
  } else {
    MPLogError(@"PRAGMA statement could not be prepared. (%s)", mpsdk_dfl_sqlite3_errmsg(db));
  }
  
  dispatch_async(self.databaseQueue, ^{
    if (callback) {
      callback(databaseVersion);
    }
    mpsdk_dfl_sqlite3_finalize(versionStatement);
  });
}

- (void)setUserVersionSync:(int)version withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPDatabaseVoidCallback)callback
{
  FBAssertNotMainThread();
  
  sqlite3_stmt *versionStatement;
  NSString *query = [NSString stringWithFormat:@"PRAGMA user_version = %d", version];
  if (mpsdk_dfl_sqlite3_prepare_v2(db, query.UTF8String, -1, &versionStatement, NULL) == SQLITE_OK) {
    if (mpsdk_dfl_sqlite3_step(versionStatement) == SQLITE_DONE) {
      MPLogDebug(@"Successfully changed user_version.");
    } else {
      MPLogError(@"Could not change user_version. (%s)", mpsdk_dfl_sqlite3_errmsg(db));
    }
  } else {
    MPLogError(@"PRAGMA statement could not be prepared. (%s)", mpsdk_dfl_sqlite3_errmsg(db));
  }
  mpsdk_dfl_sqlite3_finalize(versionStatement);
  if (nil != callback) {
    callback();
  }
}

#pragma mark Storage Locations

- (nullable NSURL *)storagePath
{
  if (_storagePath) {
    return _storagePath;
  } else {
    NSArray<NSURL *> *cacheDirectories = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
    return [[cacheDirectories.firstObject URLByAppendingPathComponent:@"audience_network/"] URLByAppendingPathComponent:@"database.sqlite"];
  }
}

- (nullable NSString *)stringFromChars:(const char *)chars
{
  return (NULL != chars) ? [NSString stringWithUTF8String:(const char * _Nonnull)chars] : nil;
}

- (void)dealloc
{
  if (_database) {
    mpsdk_dfl_sqlite3_close(_database);
  }
}

@end

NS_ASSUME_NONNULL_END



