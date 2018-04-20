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

#import <sqlite3.h>

#import <Foundation/Foundation.h>

#import "MPDefines+Internal.h"

NS_ASSUME_NONNULL_BEGIN

typedef void (^MPDatabaseVoidCallback)(void);
typedef void (^MPDatabaseResultCallback)(NSError *error);
typedef void (^MPDatabaseIntCallback)(int a);
typedef void (^MPDatabaseCallback)(sqlite3 *db);
typedef void (^MPDatabaseVersionChangedCallback)(sqlite3 *db, int previousVersion, int currentVersion);
typedef void (^MPDatabaseStatementCallback)(sqlite3_stmt * __nullable pStmt);
typedef __nullable id (^MPDatabaseDeserializeCallback)(sqlite3_stmt * __nullable pStmt);
typedef void (^MPDatabaseArrayCallback)(NSMutableArray *array);

extern NSString *const MPDatabaseManagerErrorDomain;
extern NSString *const MPDatabaseManagerCriticalErrorDomain;

@interface MPDatabaseManager : NSObject

@property (nonatomic, copy, nullable) NSURL *storagePath;
@property (nonatomic, strong, readonly) dispatch_queue_t databaseQueue;

+ (instancetype)sharedManager;

- (void)initializeDatabaseWithCompletionCallback:(nullable MPDatabaseCallback)callback
                           withDowngradeCallback:(nullable MPDatabaseVersionChangedCallback)downgradeCallback
                             withUpgradeCallback:(nullable MPDatabaseVersionChangedCallback)upgradeCallback;
- (void)getDatabase:(MPDatabaseCallback)callback;

- (void)createTableSyncWithDatabase:(sqlite3 *)db withStatement:(char const *)createTableString withCallback:(nullable FB_NOESCAPE MPDatabaseResultCallback)callback;
- (void)dropTableSyncWithDatabase:(sqlite3 *)db withTableName:(NSString *)tableName withCallback:(nullable FB_NOESCAPE MPDatabaseResultCallback)callback;

- (void)queryWithStatementSync:(nullable char const *)queryStatementString withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPDatabaseStatementCallback)callback;

- (void)deserializeWithStatementSync:(nullable char const *)queryStatementString withDatabase:(sqlite3 *)db withDeserializeCallback:(nullable FB_NOESCAPE MPDatabaseDeserializeCallback)deserializeCallback withCallback:(nullable FB_NOESCAPE MPDatabaseArrayCallback)callback;

- (void)insertWithStatementSync:(nullable char const *)insertStatementString withDatabase:(sqlite3 *)db withStatementCallback:(nullable FB_NOESCAPE MPDatabaseStatementCallback)statementCallback withCompletionCallback:(FB_NOESCAPE MPDatabaseResultCallback)callback;

- (void)deleteWithStatementSync:(nullable char const *)deleteStatementString withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPDatabaseResultCallback)callback;

// test purpose only
- (int)currentDatabaseVersion;

@end

NS_ASSUME_NONNULL_END


