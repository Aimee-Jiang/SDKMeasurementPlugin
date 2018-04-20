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
#import <UIKit/UIKit.h>

#import "MPDefines+Internal.h"
#import "MPQualityMetric.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, MPVideoAction) {
  MPVideoActionNone = -1,
  MPVideoActionPlay = 0,
  MPVideoActionSkip = 1,
  MPVideoActionTime = 2,
  MPVideoActionMRC = 3,
  MPVideoActionPause = 4,
  MPVideoActionResume = 5,
  MPVideoActionViewableImpression = 10,
  MPVideoActionIABImpression = 16,
};

FB_SUBCLASSING_RESTRICTED
@interface MPVideoLoggingEvent : NSObject

@property (nonatomic, copy, readonly) NSDictionary *loggingParams;

+ (nullable instancetype)loggingEventWithAction:(MPVideoAction)action
                                     targetView:(UIView *)targetView
                                       autoplay:(BOOL)autoplay
                                    currentTime:(NSTimeInterval)currentTime;

+ (nullable instancetype)loggingEventWithAction:(MPVideoAction)action
                                     targetView:(UIView *)targetView
                                       autoplay:(BOOL)autoplay
                                    currentTime:(NSTimeInterval)currentTime
                          viewabilityStatistics:(MPQualityMetric *)viewabilityStatistics
                           audibilityStatistics:(MPQualityMetric *)audibilityStatistics;

+ (nullable instancetype)loggingEventWithAction:(MPVideoAction)action
                                     targetView:(UIView *)targetView
                                       autoplay:(BOOL)autoplay
                                    currentTime:(NSTimeInterval)currentTime
                                   previousTime:(NSTimeInterval)previousTime
                          viewabilityStatistics:(MPQualityMetric *)viewabilityStatistics
                           audibilityStatistics:(MPQualityMetric *)audibilityStatistics;

@end

NS_ASSUME_NONNULL_END

