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
// THE SOFTWARE IS PROVIDED "AS IS",MPDynamicFrameworkLoader WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
// FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
// COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
// IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
// CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#import "MPVideoLogger.h"

#import "MPDynamicFrameworkLoader.h"
#import "MPEventManager.h"
#import "MPQualityManager.h"
#import "MPQualityRule.h"
#import "MPQualityStatistics.h"
#import "MPVideoLoggingEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPVideoLogger ()

@property (nonatomic, strong, readonly) MPQualityManager *adQualityManager;
@property (nonatomic, assign) BOOL autoplay;
@property (nonatomic, assign) BOOL hasLoggedIABImpression;
@property (nonatomic, copy) NSString *inlineClientToken;
@property (nonatomic, assign) NSTimeInterval lastProgressBoundaryTime;
@property (nonatomic, assign) NSTimeInterval lastProgressCurrentTime;
@property (nonatomic, strong) MPVideoLoggerTargetVolumeBlock targetVolumeBlock;
@property (nonatomic, strong, nullable) MPVideoLoggerViewableImpressionBlock viewableImpressionBlock;
@property (nonatomic, assign) NSTimeInterval currentTimeSeconds;

@end

const static NSTimeInterval PROGRESS_BOUNDARY = 5.0;

@implementation MPVideoLogger

- (nullable instancetype)initWithTargetView:(UIView *)targetView
                          targetVolumeBlock:(MPVideoLoggerTargetVolumeBlock)targetVolumeBlock
                                   autoplay:(BOOL)autoplay
{
  return [self initWithTargetView:targetView
          viewableImpressionBlock:nil
                targetVolumeBlock:targetVolumeBlock
                         autoplay:autoplay];
}

- (nullable instancetype)initWithTargetView:(UIView *)targetView
                    viewableImpressionBlock:(nullable MPVideoLoggerViewableImpressionBlock)viewableImpressionBlock
                          targetVolumeBlock:(MPVideoLoggerTargetVolumeBlock)targetVolumeBlock
                                   autoplay:(BOOL)autoplay
{
  if (!targetView) {
    return nil;
  }
  self = [super init];
  if (self) {
    _autoplay = autoplay;
    _targetView = targetView;
    _targetVolumeBlock = targetVolumeBlock;
    _viewableImpressionBlock = viewableImpressionBlock;
    [self initializeWithTargetView:targetView];
  }
  return self;
}

- (void)updateInlineClientToken:(NSString *)token {
  self.inlineClientToken = [token stringByRemovingPercentEncoding];
}

- (void)updateTargetVolumeBlock:(MPVideoLoggerTargetVolumeBlock)block {
  self.targetVolumeBlock = block;
}

- (void)initializeWithTargetView:(UIView *)targetView
{
  _lastProgressBoundaryTime = 0.0;
  _lastProgressCurrentTime = 0.0;
  _currentTimeSeconds = 0.0;
  weakify(self);
  MPQualityRule *mrcRule = [MPQualityRule mrcRuleWithEndCallback:^(BOOL completed, BOOL passed, MPQualityStatistics *statistics) {
    strongify(self);
    [self onMRCRuleCallback:completed passed:passed statistics:statistics];
  }];
  MPQualityRule *viewableImpressionRule = [MPQualityRule viewableImpressionRuleWithEndCallback:^(BOOL completed, BOOL passed, MPQualityStatistics *statistics) {
    strongify(self);
    [self onViewableImpressionRuleCallback:completed passed:passed statistics:statistics];
  }];
  NSMutableArray *adQualityRules = [NSMutableArray new];
  if (mrcRule) {
    [adQualityRules addObject:mrcRule];
  }
  if (viewableImpressionRule) {
    [adQualityRules addObject:viewableImpressionRule];
  }
  MPQualityManager *adQualityManager = [MPQualityManager managerWithTargetView:targetView
                                                                             rules:adQualityRules];
  if (adQualityManager) {
    _adQualityManager = adQualityManager;
  }
}

- (void)setTargetView:(UIView *)targetView
{
  _targetView = targetView;
  self.adQualityManager.targetView = targetView;
}

- (void)registerComplete:(CMTime)currentTime
{
  [self registerProgress:currentTime forceLog:YES paused:NO];
  [self flush:currentTime];
}

- (void)registerPause:(CMTime)currentTime
{
  [self registerProgress:currentTime forceLog:YES paused:NO];
  [self logVideoEventForAction:MPVideoActionPause];
  [self flush:currentTime];
}

- (void)registerProgressForPlayerItem:(AVPlayerItem *)playerItem state:(StateType)state {
  if (state != kStateTypeNone && state != kStateTypeSeekStart && state != kStateTypeComplete) {
    [self registerProgress:[playerItem currentTime]];
  }
}

- (void)registerProgress:(CMTime)currentTime
{
  [self registerProgress:currentTime forceLog:NO paused:NO];
  
  // IAB impression
  if (!self.hasLoggedIABImpression) {
    self.hasLoggedIABImpression = YES;
    [self logVideoEventForAction:MPVideoActionIABImpression];
  }
}

- (void)registerResume:(CMTime)currentTime
{
  NSTimeInterval currentTimeSeconds = mpsdk_dfl_CMTimeGetSeconds(currentTime);
  self.lastProgressBoundaryTime = currentTimeSeconds;
  self.lastProgressCurrentTime = currentTimeSeconds;
  [self logVideoEventForAction:MPVideoActionResume];
}

- (void)registerSeekEnd:(CMTime)seekEndTime
{
  self.seeking = NO;
  [self flush:seekEndTime];
}

- (void)registerSeekStart:(CMTime)seekStartTime
{
  [self registerProgress:seekStartTime forceLog:YES paused:NO];
  self.seeking = YES;
}

- (void)registerSkip:(CMTime)currentTime
{
  [self registerProgress:currentTime forceLog:YES paused:NO];
  [self logVideoEventForAction:MPVideoActionSkip];
}

- (void)registerStop:(CMTime)currentTime
{
  [self registerProgress:currentTime forceLog:YES paused:NO];
}

#pragma mark private methods

- (void)flush:(CMTime)time
{
  NSTimeInterval timeSeconds = mpsdk_dfl_CMTimeGetSeconds(time);
  [self.adQualityManager resetStatistics];
  self.lastProgressCurrentTime = timeSeconds;
  self.lastProgressBoundaryTime = timeSeconds;
}

- (void)logProgress
{
  [self logVideoTime];
}

- (void)logVideoEvent:(MPVideoLoggingEvent *)videoEvent
{
  [[MPEventManager sharedManager] logVideoEventForToken:self.inlineClientToken withExtraData:videoEvent.loggingParams];
}

- (void)logVideoEventForAction:(MPVideoAction)action
{
  MPVideoLoggingEvent *loggingEvent = [MPVideoLoggingEvent loggingEventWithAction:action
                                                                           targetView:self.targetView
                                                                             autoplay:self.autoplay
                                                                          currentTime:self.lastProgressCurrentTime
                                                                viewabilityStatistics:self.adQualityManager.statistics.viewabilityStatistics
                                                                 audibilityStatistics:self.adQualityManager.statistics.audibilityStatistics];
  if (loggingEvent) {
    [self logVideoEvent:loggingEvent];
  }
}

- (void)logVideoTime
{
  MPVideoLoggingEvent *loggingEvent = [MPVideoLoggingEvent loggingEventWithAction:MPVideoActionTime
                                                                           targetView:self.targetView
                                                                             autoplay:self.autoplay
                                                                          currentTime:self.lastProgressCurrentTime
                                                                         previousTime:self.lastProgressBoundaryTime
                                                                viewabilityStatistics:self.adQualityManager.statistics.viewabilityStatistics
                                                                 audibilityStatistics:self.adQualityManager.statistics.audibilityStatistics];
  if (loggingEvent) {
    [self logVideoEvent:loggingEvent];
  }
}

- (void)onMRCRuleCallback:(BOOL)completed
                   passed:(BOOL)passed
               statistics:(MPQualityStatistics *)statistics
{
  if (passed) {
    [self logVideoEventForAction:MPVideoActionMRC];
  }
}

- (void)onViewableImpressionRuleCallback:(BOOL)completed
                                  passed:(BOOL)passed
                              statistics:(MPQualityStatistics *)statistics
{
  if (passed) {
    FB_BLOCK_CALL_SAFE(self.viewableImpressionBlock);
    [self logVideoEventForAction:MPVideoActionViewableImpression];
  }
}

- (void)registerProgress:(CMTime)currentTime
                forceLog:(BOOL)forceLog
                  paused:(BOOL)paused
{
  if (self.seeking) {
    return;
  }
  
  NSTimeInterval currentTimeSeconds = mpsdk_dfl_CMTimeGetSeconds(currentTime);
//  NSLog(@"on progress: %f",currentTimeSeconds);
  NSTimeInterval currentProgress = currentTimeSeconds - self.lastProgressCurrentTime;
  NSTimeInterval progressSinceLastBoundary = currentTimeSeconds - self.lastProgressBoundaryTime;
  
  self.lastProgressCurrentTime = currentTimeSeconds;
  if (paused) {
    self.seeking = YES;
    return;
  }
  if (!forceLog && currentProgress <= 0.0) {
    return;
  }
  
  float deviceVolume = [[AVAudioSession sharedInstance] outputVolume];
  float effectiveVolume = deviceVolume * self.targetVolumeBlock();
  
  [self.adQualityManager registerProgress:currentProgress volume:effectiveVolume];
  
  if ((forceLog && progressSinceLastBoundary > 0.0) || progressSinceLastBoundary >= PROGRESS_BOUNDARY) {
    [self logProgress];
    self.lastProgressBoundaryTime = currentTimeSeconds;
    if (!forceLog) {
      [self flush:currentTime];
    }
  }
}

@end

NS_ASSUME_NONNULL_END

