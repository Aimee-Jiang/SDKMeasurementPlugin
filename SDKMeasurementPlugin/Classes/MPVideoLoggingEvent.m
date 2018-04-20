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

#import "MPVideoLoggingEvent.h"

NS_ASSUME_NONNULL_BEGIN

typedef NSString * MPVideoLoggingParameter NS_STRING_ENUM;

static MPVideoLoggingParameter const ACTION = @"action";
static MPVideoLoggingParameter const AUDIBLE_TIME_MS = @"atime_ms";
static MPVideoLoggingParameter const AUTOPLAY = @"autoplay";
static MPVideoLoggingParameter const MAX_CONTINUOUS_AUDIBLE_TIME_MS = @"mcat_ms";
static MPVideoLoggingParameter const MAX_CONTINUOUS_VIEWABLE_TIME_MS = @"mcvt_ms";
static MPVideoLoggingParameter const PLAYER_HEIGHT = @"ph";
static MPVideoLoggingParameter const PLAYER_OFFSET_LEFT = @"pl";
static MPVideoLoggingParameter const PLAYER_OFFSET_TOP = @"pt";
static MPVideoLoggingParameter const PLAYER_WIDTH = @"pw";
static MPVideoLoggingParameter const PREVIOUS_TIME = @"ptime";
static MPVideoLoggingParameter const TIME = @"time";
static MPVideoLoggingParameter const VIEWABILITY_AVG = @"vwa";
static MPVideoLoggingParameter const VIEWABILITY_MAX = @"vwmax";
static MPVideoLoggingParameter const VIEWABILITY_MIN = @"vwm";
static MPVideoLoggingParameter const VIEWABLE_TIME_MS = @"vtime_ms";
static MPVideoLoggingParameter const VIEWPORT_HEIGHT = @"vph";
static MPVideoLoggingParameter const VIEWPORT_WIDTH = @"vpw";
static MPVideoLoggingParameter const VOLUME_AVG = @"vla";
static MPVideoLoggingParameter const VOLUME_MAX = @"vlmax";
static MPVideoLoggingParameter const VOLUME_MIN = @"vlm";
static MPVideoLoggingParameter const VIEWABLE_DETECTION = @"vw_d";

static NSString * const FB_VIEWABLE_DETECTION = @"sdk-mp-ios";

static void addAction(NSMutableDictionary *parameters, MPVideoAction action)
{
  if (action != MPVideoActionNone) {
    parameters[ACTION] = [NSString stringWithFormat:@"%ld", (long)action];
  }
}

static void addAudibilityStatistics(NSMutableDictionary *parameters, MPQualityMetric *audibilityStatistics)
{
  parameters[VOLUME_AVG] = [NSString stringWithFormat:@"%f", audibilityStatistics.avg];
  parameters[VOLUME_MIN] = [NSString stringWithFormat:@"%f", audibilityStatistics.min];
  parameters[VOLUME_MAX] = [NSString stringWithFormat:@"%f", audibilityStatistics.max];
  parameters[AUDIBLE_TIME_MS] = [NSString stringWithFormat:@"%lu", (unsigned long)(audibilityStatistics.eligibleSeconds * 1000)];
  parameters[MAX_CONTINUOUS_AUDIBLE_TIME_MS] = [NSString stringWithFormat:@"%lu", (unsigned long)(audibilityStatistics.maxContinuousEligibleSeconds * 1000)];
}

static void addViewableDetection(NSMutableDictionary *parameters)
{
  parameters[VIEWABLE_DETECTION] = FB_VIEWABLE_DETECTION;
}

static void addAutoplay(NSMutableDictionary *parameters, BOOL autoplay)
{
  parameters[AUTOPLAY] = autoplay ? @"1" : @"0";
}

static void addCurrentTime(NSMutableDictionary *parameters, NSTimeInterval currentTime)
{
  parameters[TIME] = [NSString stringWithFormat:@"%f", currentTime];
}

static void addPreviousTime(NSMutableDictionary *parameters, NSTimeInterval previousTime)
{
  parameters[PREVIOUS_TIME] = [NSString stringWithFormat:@"%f", previousTime];
}

static void addTargetView(NSMutableDictionary *parameters, UIView *targetView)
{
  parameters[PLAYER_OFFSET_TOP] = [NSString stringWithFormat:@"%f", targetView.frame.origin.y];
  parameters[PLAYER_OFFSET_LEFT] = [NSString stringWithFormat:@"%f", targetView.frame.origin.x];
  parameters[PLAYER_HEIGHT] = [NSString stringWithFormat:@"%f", targetView.frame.size.height];
  parameters[PLAYER_WIDTH] = [NSString stringWithFormat:@"%f", targetView.frame.size.width];
  parameters[VIEWPORT_HEIGHT] = [NSString stringWithFormat:@"%f", targetView.window.frame.size.height];
  parameters[VIEWPORT_WIDTH] = [NSString stringWithFormat:@"%f", targetView.window.frame.size.width];
}

static void addViewabilityStatistics(NSMutableDictionary *parameters, MPQualityMetric *viewabilityStatistics)
{
  parameters[VIEWABILITY_AVG] = [NSString stringWithFormat:@"%f", viewabilityStatistics.avg];
  parameters[VIEWABILITY_MIN] = [NSString stringWithFormat:@"%f", viewabilityStatistics.min];
  parameters[VIEWABILITY_MAX] = [NSString stringWithFormat:@"%f", viewabilityStatistics.max];
  parameters[VIEWABLE_TIME_MS] = [NSString stringWithFormat:@"%lu", (unsigned long)(viewabilityStatistics.eligibleSeconds * 1000)];
  parameters[MAX_CONTINUOUS_VIEWABLE_TIME_MS] = [NSString stringWithFormat:@"%lu", (unsigned long)(viewabilityStatistics.maxContinuousEligibleSeconds * 1000)];
}

@implementation MPVideoLoggingEvent

+ (nullable instancetype)loggingEventWithAction:(MPVideoAction)action
                                     targetView:(UIView *)targetView
                                       autoplay:(BOOL)autoplay
                                    currentTime:(NSTimeInterval)currentTime
{
  NSMutableDictionary *loggingParams = [NSMutableDictionary dictionary];
  addViewableDetection(loggingParams);
  addAction(loggingParams, action);
  addTargetView(loggingParams, targetView);
  addAutoplay(loggingParams, autoplay);
  addCurrentTime(loggingParams, currentTime);
  return [[MPVideoLoggingEvent alloc] initWithLoggingParams:loggingParams];
}

+ (nullable instancetype)loggingEventWithAction:(MPVideoAction)action
                                     targetView:(UIView *)targetView
                                       autoplay:(BOOL)autoplay
                                    currentTime:(NSTimeInterval)currentTime
                          viewabilityStatistics:(MPQualityMetric *)viewabilityStatistics
                           audibilityStatistics:(MPQualityMetric *)audibilityStatistics
{
  NSMutableDictionary *loggingParams = [NSMutableDictionary dictionary];
  addViewableDetection(loggingParams);
  addAction(loggingParams, action);
  addTargetView(loggingParams, targetView);
  addAutoplay(loggingParams, autoplay);
  addCurrentTime(loggingParams, currentTime);
  addViewabilityStatistics(loggingParams, viewabilityStatistics);
  addAudibilityStatistics(loggingParams, audibilityStatistics);
  return [[MPVideoLoggingEvent alloc] initWithLoggingParams:loggingParams];
}

+ (nullable instancetype)loggingEventWithAction:(MPVideoAction)action
                                     targetView:(UIView *)targetView
                                       autoplay:(BOOL)autoplay
                                    currentTime:(NSTimeInterval)currentTime
                                   previousTime:(NSTimeInterval)previousTime
                          viewabilityStatistics:(MPQualityMetric *)viewabilityStatistics
                           audibilityStatistics:(MPQualityMetric *)audibilityStatistics
{
  NSMutableDictionary *loggingParams = [NSMutableDictionary dictionary];
  addViewableDetection(loggingParams);
  addAction(loggingParams, action);
  addTargetView(loggingParams, targetView);
  addAutoplay(loggingParams, autoplay);
  addCurrentTime(loggingParams, currentTime);
  addPreviousTime(loggingParams, previousTime);
  addViewabilityStatistics(loggingParams, viewabilityStatistics);
  addAudibilityStatistics(loggingParams, audibilityStatistics);
  return [[MPVideoLoggingEvent alloc] initWithLoggingParams:loggingParams];
}

- (nullable instancetype)init
{
  return [self initWithLoggingParams:@{}];
}

- (nullable instancetype)initWithLoggingParams:(NSDictionary *)loggingParams
{
  self = [super init];
  if (self) {
    _loggingParams = loggingParams;
  }
  return self;
}

@end

NS_ASSUME_NONNULL_END

