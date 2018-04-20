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

#import "MPQualityManager.h"

#import "MPQualityTest.h"
#import "MPQualityViewabilityMeasurement.h"

@interface MPQualityManager ()

@property (nonatomic, strong) NSArray<MPQualityTest *> *tests;
@property (nonatomic, strong) MPQualityViewabilityMeasurement *viewabilityMeasurement;

@end

@implementation MPQualityManager

+ (nullable instancetype)managerWithTargetView:(nonnull UIView *)targetView
                                         rules:(nullable NSArray<MPQualityRule *> *)rules
{
  return [[self alloc] initWithTargetView:targetView rules:rules];
}

- (nullable instancetype)initWithTargetView:(nonnull UIView *)targetView
                                      rules:(nullable NSArray<MPQualityRule *> *)rules
{
  self = [super init];
  if (self) {
    _statistics = [MPQualityStatistics new];
    _targetView = targetView;
    __block NSMutableArray *tests = [NSMutableArray new];
    [rules enumerateObjectsUsingBlock:^(MPQualityRule * _Nonnull rule, NSUInteger idx, BOOL * _Nonnull stop) {
      MPQualityTest *test = [MPQualityTest testWithRule:rule];
      if (test) {
        [tests addObject:test];
      }
    }];
    self.tests = tests;
    self.viewabilityMeasurement = [MPQualityViewabilityMeasurement measurementWithTargetView:targetView];
  }
  return self;
}

- (void)setTargetView:(UIView *)targetView
{
  _targetView = targetView;
  self.viewabilityMeasurement.targetView = targetView;
}

- (nullable instancetype)init
{
  return [self initWithTargetView:[UIView new]
                            rules:nil];
}

- (void)resetStatistics
{
  [self.statistics reset];
}

- (void)registerProgress:(NSTimeInterval)progress
                  volume:(float)volume
{
  if (volume >= 0.0) {
    [self.statistics registerAudibilityProgress:progress volume:volume];
  }
  
  float viewableRatio = self.viewabilityMeasurement.viewableRatio;
  
  // register statistics
  [self.statistics registerViewabilityProgress:progress viewableRatio:viewableRatio];
  
  // register tests
  [self.tests enumerateObjectsUsingBlock:^(MPQualityTest * _Nonnull test, NSUInteger idx, BOOL * _Nonnull stop) {
    [test registerProgress:progress viewableRatio:viewableRatio];
  }];
}

@end

