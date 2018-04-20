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

#import "MPQualityRule.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MPQualityRule

+ (nullable instancetype)mrcRuleWithEndCallback:(nullable MPQualityRuleEndCallback)endCallback
{
  return [self ruleWithViewableRatio:0.5f
                     viewableSeconds:2.0
                          continuous:YES
                         endCallback:endCallback];
}

+ (nullable instancetype)viewableImpressionRuleWithEndCallback:(nullable MPQualityRuleEndCallback)endCallback
{
  return [self ruleWithViewableRatio:0.0000001f
                     viewableSeconds:0.001
                          continuous:NO
                         endCallback:endCallback];
}

+ (nullable instancetype)ruleWithViewableRatio:(float)viewableRatio
                               viewableSeconds:(NSTimeInterval)viewableSeconds
                                    continuous:(BOOL)continuous
                                   endCallback:(nullable MPQualityRuleEndCallback)endCallback
{
  return [[self alloc] initWithViewableRatio:viewableRatio
                             viewableSeconds:viewableSeconds
                                  continuous:continuous
                                 endCallback:endCallback];
}

- (nullable instancetype)initWithViewableRatio:(float)viewableRatio
                               viewableSeconds:(NSTimeInterval)viewableSeconds
                                    continuous:(BOOL)continuous
                                   endCallback:(nullable MPQualityRuleEndCallback)endCallback
{
  self = [super init];
  if (self) {
    _continuous = continuous;
    _endCallback = endCallback;
    _viewableRatio = viewableRatio;
    _viewableSeconds = viewableSeconds;
  }
  return self;
}

- (instancetype)init
{
  return [self initWithViewableRatio:0.0f
                     viewableSeconds:0.0
                          continuous:NO
                         endCallback:nil];
}

@end

NS_ASSUME_NONNULL_END

