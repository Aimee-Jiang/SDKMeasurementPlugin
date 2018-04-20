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

@interface MPQualityMetric : NSObject

@property (nonatomic, assign, readonly) float avg;
@property (nonatomic, assign, readonly) NSTimeInterval continuousEligibleSeconds;
@property (nonatomic, assign, readonly) float current;
@property (nonatomic, assign, readonly) NSTimeInterval eligibleSeconds;
@property (nonatomic, assign, readonly) float eligibleThreshold;
@property (nonatomic, assign, readonly) float max;
@property (nonatomic, assign, readonly) NSTimeInterval maxContinuousEligibleSeconds;
@property (nonatomic, assign, readonly) NSInteger measurementCount;
@property (nonatomic, assign, readonly) NSTimeInterval measurementSeconds;
@property (nonatomic, assign, readonly) float min;

+ (nullable instancetype)metricWithEligibleThreshold:(float)eligibleThreshold;

- (nullable instancetype)initWithEligibleThreshold:(float)eligibleThreshold NS_DESIGNATED_INITIALIZER;

- (void)registerProgress:(NSTimeInterval)progress
                   value:(float)value;

- (void)reset;

@end

