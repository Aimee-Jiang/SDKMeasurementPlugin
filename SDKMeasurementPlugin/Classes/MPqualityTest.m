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

#import "MPQualityTest.h"

@interface MPQualityTest ()

@property (nonatomic, strong, nonnull) MPQualityStatistics *passingStatistics;
@property (nonatomic, strong, nonnull) MPQualityStatistics *testStatistics;
@property (nonatomic, strong, nonnull, readonly) MPQualityRule *rule;
@property (nonatomic, assign) BOOL ended;
@property (nonatomic, assign) BOOL passed;
@property (nonatomic, assign) BOOL complete;

@end

@implementation MPQualityTest

+ (nullable instancetype)testWithRule:(MPQualityRule *)rule
{
  return [[self alloc] initWithRule:rule];
}

- (nullable instancetype)initWithRule:(MPQualityRule *)rule
{
  self = [super init];
  if (self) {
    _rule = rule;
    self.testStatistics = (id)[[MPQualityStatistics alloc] initWithViewableThreshold:rule.viewableRatio];
    self.passingStatistics = (id)[[MPQualityStatistics alloc] initWithViewableThreshold:rule.viewableRatio];
  }
  return self;
}

- (void)registerEnd
{
  if (!self.ended) {
    [self onEnd];
  }
}

- (void)registerProgress:(NSTimeInterval)progress
           viewableRatio:(float)viewableRatio
{
  if (self.ended) {
    return;
  }
  
  [self.testStatistics registerViewabilityProgress:progress viewableRatio:viewableRatio];
  [self.passingStatistics registerViewabilityProgress:progress viewableRatio:viewableRatio];
  
  NSTimeInterval viewableSeconds = self.passingStatistics.viewabilityStatistics.eligibleSeconds;
  
  // validate continuity
  if (self.rule.isContinuous && viewableRatio < self.rule.viewableRatio) {
    // reset viewable statistics
    self.passingStatistics = (id)[[MPQualityStatistics alloc] initWithViewableThreshold:self.rule.viewableRatio];
  }
  
  // validate duration
  if (viewableSeconds >= self.rule.viewableSeconds) {
    [self onPassed];
  }
}

- (void)onPassed
{
  self.passed = true;
  [self onComplete];
}

- (void)onComplete
{
  self.complete = true;
  [self onEnd];
}

- (void)onEnd
{
  self.ended = true;
  
  // if the test passed, results contain statistics for
  // the viewable duration, otherwise results contain statistics
  // for the entire test duration
  MPQualityStatistics *endStatistics = self.passed ? self.passingStatistics : self.testStatistics;
  
  self.rule.endCallback(self.complete, self.passed, endStatistics);
}

@end

