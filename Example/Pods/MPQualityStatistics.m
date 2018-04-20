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

#import "MPQualityStatistics.h"

#import "MPUtility.h"

static float const DEFAULT_VIEWABLE_THRESHOLD = 0.5f;
static float const DEFAULT_AUDIBLE_THRESHOLD = 0.05f;

@implementation MPQualityStatistics

+ (nullable instancetype)statisticsWithViewableThreshold:(float)viewableThreshold
                                        audibleThreshold:(float)audibleThreshold
{
  return [[self alloc] initWithViewableThreshold:viewableThreshold
                                audibleThreshold:audibleThreshold];
}

+ (nullable instancetype)statisticsWithViewableThreshold:(float)viewableThreshold
{
  return [self statisticsWithViewableThreshold:viewableThreshold
                              audibleThreshold:DEFAULT_AUDIBLE_THRESHOLD];
}

- (nullable instancetype)initWithViewableThreshold:(float)viewableThreshold
                                  audibleThreshold:(float)audibleThreshold
{
  self = [super init];
  if (self) {
    _viewabilityStatistics = MPUnwrap([MPQualityMetric metricWithEligibleThreshold:viewableThreshold]);
    _audibilityStatistics = MPUnwrap([MPQualityMetric metricWithEligibleThreshold:audibleThreshold]);
  }
  return self;
}

- (nullable instancetype)initWithViewableThreshold:(float)viewableThreshold
{
  return [self initWithViewableThreshold:viewableThreshold
                        audibleThreshold:DEFAULT_AUDIBLE_THRESHOLD];
}

- (nullable instancetype)init
{
  return [self initWithViewableThreshold:DEFAULT_VIEWABLE_THRESHOLD
                        audibleThreshold:DEFAULT_AUDIBLE_THRESHOLD];
}

- (void)registerAudibilityProgress:(NSTimeInterval)progress
                            volume:(float)volume
{
  [self.audibilityStatistics registerProgress:progress
                                        value:volume];
}

- (void)registerViewabilityProgress:(NSTimeInterval)progress
                      viewableRatio:(float)viewableRatio
{
  [self.viewabilityStatistics registerProgress:progress
                                         value:viewableRatio];
}

- (void)reset
{
  [self.audibilityStatistics reset];
  [self.viewabilityStatistics reset];
}

@end
