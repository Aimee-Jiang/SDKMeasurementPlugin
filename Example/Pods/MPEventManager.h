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

#import <Foundation/Foundation.h>

#import "MPDefines+Internal.h"
#import "MPEvent.h"
#import "MPEventToken.h"

NS_ASSUME_NONNULL_BEGIN

@class MPDatabaseManager;

typedef void (^MPEventVoidCallback)(void);
typedef void (^MPEventTokenIdCallback)(NSUUID * __nullable tokenId);

@interface MPEventManager : NSObject

@property (nonatomic, strong, readonly) NSUUID *sessionId;
@property (nonatomic, assign, readonly) NSTimeInterval sessionTime;

+ (instancetype)sharedManager;
- (instancetype)initWithDatabaseManager:(MPDatabaseManager *)databaseManager NS_DESIGNATED_INITIALIZER;

// Token for request (once all events for a token are logged, tokens will not persist)
- (void)tokenIdForToken:(nullable NSString *)token withCallback:(nullable MPEventTokenIdCallback)callback;

// Log custom event
- (void)logEventOfType:(MPEventType)type withPriority:(MPEventPriority)priority withToken:(nullable NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logEventOfType:(MPEventType)type withPriority:(MPEventPriority)priority withToken:(nullable NSString *)token withExtraData:(nullable NSDictionary *)extraData withCallback:(nullable MPEventVoidCallback)callback;

// Helper methods
- (void)logImpressionForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logImpressionMissForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logStoreClickForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logLinkClickForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logSnapshotForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logVideoEventForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logCloseEventForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logBrowserSessionEventForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logAdCompleteEventForToken:(NSString *)token withExtraData:(nullable NSDictionary *)extraData;
- (void)logDebugEventWithExtraData:(nullable NSDictionary<NSString *, id> *)extraData;

// test purpose only
+ (char const *)tokenTableString;
+ (char const *)eventTableString;
//- (void)updateAttemptCountForEvent:(MPEvent *)event withDatabase:(sqlite3 *)db withCallback:(nullable FB_NOESCAPE MPEventVoidCallback)callback;

@end

NS_ASSUME_NONNULL_END

