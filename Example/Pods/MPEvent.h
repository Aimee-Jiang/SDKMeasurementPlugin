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

#import "MPUtility.h"

@class MPEventToken;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MPEventPriority) {
  MPEventPriorityImmediate,
  MPEventPriorityDeferred,
};

typedef NSString * MPEventType NS_STRING_ENUM;

static MPEventType const MPEventTypeImpression = @"impression";
static MPEventType const MPEventTypeImpressionMiss = @"impression_miss";
static MPEventType const MPEventTypeStoreClick = @"store";
static MPEventType const MPEventTypeLinkClick = @"open_link";
static MPEventType const MPEventTypeViewReport = @"native_view";
static MPEventType const MPEventTypeVideo = @"video";
static MPEventType const MPEventTypeClose = @"close";
static MPEventType const MPEventTypeBrowserSession = @"browser_session";
static MPEventType const MPEventTypeAdComplete = @"ad_complete";
static MPEventType const MPEventTypeDebug = @"debug";

@interface MPEvent : NSObject

@property (nonatomic, copy, readonly) NSUUID *eventId;
@property (nonatomic, copy, readonly) MPEventType type;
@property (nonatomic, copy, readonly) NSDate *time;
@property (nonatomic, assign, readonly) MPEventPriority priority;
@property (nonatomic, copy, readonly, nullable) NSDictionary<NSString *, id> *extraData;
@property (nonatomic, copy, readonly, nullable) NSUUID *tokenId;
@property (nonatomic, copy) NSUUID *sessionId;
@property (nonatomic, copy) NSDate *sessionStartTime;
@property (nonatomic, assign) NSUInteger attemptsCount;

//FB_INIT_AND_NEW_UNAVAILABLE_NULLABILITY

- (instancetype)initWithType:(MPEventType)type
                withPriority:(MPEventPriority)priority
                 withTokenId:(nullable NSUUID *)tokenId
               withSessionId:(NSUUID *)sessionId
        withSessionStartTime:(NSDate *)sessionStartTime
               withExtraData:(nullable NSDictionary<NSString *, id> *)extraData NS_DESIGNATED_INITIALIZER;

+ (nullable MPEvent *)deserializeFromSqlite:(sqlite3_stmt * __nullable)queryStatement;

- (nullable NSString *)jsonExtraData;

//- (void)logStatusMessage;

@end

NS_ASSUME_NONNULL_END

