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

NS_ASSUME_NONNULL_BEGIN

@interface MPTimer : NSObject

@property (nonatomic, readonly) NSTimeInterval timeInterval;
@property (nonatomic, readonly, getter=isValid) BOOL valid;
@property (nonatomic, readonly, nullable) dispatch_queue_t queue;
@property (nonatomic, copy, readwrite, nullable) NSDictionary *userInfo;

typedef void (^fb_timer_block)(MPTimer *timer);
typedef BOOL (^fb_timer_condition_block)(MPTimer *timer);

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo block:(fb_timer_block)block;
+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo queue:(dispatch_queue_t)queue block:(fb_timer_block)block;
+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeatsUntilCondition:(fb_timer_condition_block)condition queue:(dispatch_queue_t)queue block:(fb_timer_block)block;

- (void)invalidate;
- (void)fire;

@end

NS_ASSUME_NONNULL_END

