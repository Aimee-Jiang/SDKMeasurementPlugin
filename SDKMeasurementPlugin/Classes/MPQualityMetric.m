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

#import "MPQualityMetric.h"

@interface MPQualityMetric ()

@property (nonatomic, assign) float sum;

@end

@implementation MPQualityMetric

+ (nullable instancetype)metricWithEligibleThreshold:(float)eligibleThreshold
{
  return [[self alloc] initWithEligibleThreshold:eligibleThreshold];
}

- (nullable instancetype)initWithEligibleThreshold:(float)eligibleThreshold
{
  self = [super init];
  if (self) {
    _eligibleThreshold = eligibleThreshold;
    [self reset];
  }
  return self;
}

- (nullable instancetype)init
{
  return [self initWithEligibleThreshold:0.0];
}

- (void)registerProgress:(NSTimeInterval)progress
                   value:(float)value
{
  if (_measurementCount == 0) {
    _min = value;
    _max = value;
  } else {
    _min = fminf(_min, value);
    _max = fmaxf(_max, value);
  }
  
  _measurementCount++;
  _measurementSeconds += progress;
  
  _current = value;
  _sum += value * progress;
  _avg = (float)(_sum / _measurementSeconds);
  
  if (value >= _eligibleThreshold) {
    _eligibleSeconds += progress;
    _continuousEligibleSeconds += progress;
    _maxContinuousEligibleSeconds = fmax(_maxContinuousEligibleSeconds, _continuousEligibleSeconds);
  } else {
    _continuousEligibleSeconds = 0.0;
  }
}

- (void)reset
{
  _avg = 0.0;
  _current = 0.0;
  _eligibleSeconds = 0.0;
  _max = 0.0;
  _measurementCount = 0;
  _measurementSeconds = 0.0;
  _min = 0.0;
  _sum = 0.0;
}

@end

