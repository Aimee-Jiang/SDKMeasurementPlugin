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

#import "FBMPObserver.h"
#import "MPVideoLogger.h"
#import "MPVideoLoggingEvent.h"
#import "MPDynamicFrameworkLoader.h"

static NSString * const kToken = @"brightcove";
//static NSString * const kToken = @"_nc_client_token=";
//static NSString * const kToken = @"redirector";

@interface FBMPObserver ()
@property (nonatomic) AVPlayer* player; //observable objects
@property (nonatomic) AVPlayerItem* playerItem; //observable objects
@property (nonatomic, strong) UIControl *skipButton; //TBD
@property (nonatomic) StateType state;
@property (nonatomic, strong) MPVideoLogger *mpLogger;
@property (nonatomic, strong) id progressTimeObserver;
@property (nonatomic) BOOL seeking;
@property (nonatomic) BOOL continued;
@end


@implementation FBMPObserver
static FBMPObserver* _instance = nil;

+ (instancetype)shareInstance
{
  static dispatch_once_t onceToken ;
  dispatch_once(&onceToken, ^{
    _instance = [[self alloc] init] ;
  }) ;
  
  return _instance ;
}

- (void)registerObjects:(NSDictionary *)dict {
  self.player = [dict objectForKey:@"player"];
  self.mpLogger = (MPVideoLogger *)[[MPVideoLogger alloc] initWithTargetView:[dict objectForKey:@"playerView"]
                                                           targetVolumeBlock:[self getTargetVolumeBlock]
                                                                    autoplay:true];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(jumpNotification:) name:AVPlayerItemTimeJumpedNotification object:nil];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(itemDidFinishPlaying:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];

  [self.player addObserver:self forKeyPath:@"rate" options:0 context:nil];
  [self.skipButton addObserver:self forKeyPath:@"highlighted" options:0 context:nil];
}

- (void)addProgressTimeObserverIfNot
{
  if (!self.progressTimeObserver) {
    [self.player addObserver:self forKeyPath:@"rate" options:0 context:nil];
    weakify(self);
    self.progressTimeObserver = [self addPeriodicTimeObserverForInterval:mpsdk_dfl_CMTimeMakeWithSeconds((NSTimeInterval)0.2, 1000)
                                                                   queue:dispatch_get_main_queue()
                                                              usingBlock:^(CMTime time) {
                                                                strongify(self);
                                                                [self.mpLogger registerProgressForPlayerItem:self.playerItem state:self.state];
                                                              }];
  }
}


- (id)addPeriodicTimeObserverForInterval:(CMTime)interval
                                   queue:(nullable dispatch_queue_t)queue
                              usingBlock:(void (^)(CMTime time))block
{
  return [self.player addPeriodicTimeObserverForInterval:interval
                                                   queue:queue
                                              usingBlock:block];
}

-(void)itemDidFinishPlaying:(NSNotification *) notification {
  AVPlayerItem *playerItem = notification.object;
  AVAsset *currentPlayerAsset = playerItem.asset;
  if (![currentPlayerAsset isKindOfClass:AVURLAsset.class] || [(AVURLAsset *)currentPlayerAsset URL] == nil) return;
  
  NSURL *url = [(AVURLAsset *)currentPlayerAsset URL];
  if ([self extractClientTokenFrom:url.absoluteString] == nil) {
    return;
  }
  if (self.state != kStateTypeComplete) {
    [self.mpLogger registerComplete:[self.playerItem currentTime]];
    NSLog(@"MP Complete playing at time: %f", mpsdk_dfl_CMTimeGetSeconds([self.playerItem currentTime]));
    self.state = kStateTypeComplete;
  }
}

-(void)jumpNotification:(NSNotification *)notification
{
  //   Will be called when AVPlayer seek to a new point
  if(![notification.object isKindOfClass:AVPlayerItem.class]) {
    return;
  }
  
  AVPlayerItem *playerItem = notification.object;
  AVAsset *currentPlayerAsset = playerItem.asset;
  if (![currentPlayerAsset isKindOfClass:AVURLAsset.class] || [(AVURLAsset *)currentPlayerAsset URL] == nil) return;
  
  NSURL *url = [(AVURLAsset *)currentPlayerAsset URL];
  if ([self extractClientTokenFrom:url.absoluteString] == nil) {
    return;
  }
  
  self.playerItem = playerItem;
  self.player = [playerItem valueForKey:@"player"];
  
  [self.mpLogger updateInlineClientToken:[self extractClientTokenFrom:url.absoluteString]];
  [self addProgressTimeObserverIfNot];
  [self.mpLogger updateTargetVolumeBlock:[self getTargetVolumeBlock]];
  
  NSTimeInterval currentTime = mpsdk_dfl_CMTimeGetSeconds([self.playerItem currentTime]);
  if (currentTime == 0.0) {
    if (self.state != kStateTypeResume) {
      if (self.state == kStateTypeComplete) {
        self.continued = YES;
      }
      [self.mpLogger registerResume:[self.playerItem currentTime]];
      NSLog(@"MP(notification) Resume to play at time: %f", mpsdk_dfl_CMTimeGetSeconds([self.playerItem currentTime]));
      self.state = kStateTypeResume;
    }
  } else if (self.state == kStateTypeJump){
    self.state = kStateTypeDoubleJump;
  } else {
    self.state = kStateTypeJump;
  }
}

- (MPVideoLoggerTargetVolumeBlock) getTargetVolumeBlock {
  weakify(self);
  MPVideoLoggerTargetVolumeBlock targetVolumeBlock = ^float{
    strongify(self);
    return self.player.volume;
  };
  return targetVolumeBlock;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  // skip button
  if ([object isKindOfClass:UIControl.class]) {
    if ([keyPath isEqualToString:@"highlighted"]) {
      NSLog(@"MP Skip");
      [self.mpLogger registerSkip:[self.playerItem currentTime]];
    }
    return;
  }
  
  AVPlayer *player = object;
  AVAsset *currentPlayerAsset = [player currentItem].asset;
  if (![currentPlayerAsset isKindOfClass:AVURLAsset.class] || [(AVURLAsset *)currentPlayerAsset URL] == nil) return;
  
  NSURL *url = [(AVURLAsset *)currentPlayerAsset URL];
  if ([self extractClientTokenFrom:url.absoluteString] == nil) {
    return;
  }

  if (!self.playerItem) {
    self.playerItem = [self.player currentItem];
  }
  NSTimeInterval currentTime = mpsdk_dfl_CMTimeGetSeconds([self.playerItem currentTime]);
  [self addProgressTimeObserverIfNot];
//  NSLog(@"MP(observer) called at: %f", currentTime);
  if ([keyPath isEqualToString:@"rate"]) {
    if (currentTime <= 0.000000 || [self.player rate]) {
      if (self.state == kStateTypePause) {
        self.state = kStateTypeResume;
        [self.mpLogger registerResume:[self.playerItem currentTime]];
        NSLog(@"MP(observer) Resume to play at: %f", currentTime);
      }
      [NSTimer scheduledTimerWithTimeInterval:0.9
                                       target:self
                                     selector:@selector(checkSeekEnd:)
                                     userInfo:@{@"scheduledTime": @(currentTime)}
                                      repeats:NO];
    } else if (self.state != kStateTypeComplete) {
      if (self.state != kStateTypePause && self.state != kStateTypeSeekStart) {
        [NSTimer scheduledTimerWithTimeInterval:0.9
                                         target:self
                                       selector:@selector(checkSeekStart:)
                                       userInfo:@{@"scheduledTime": @(currentTime)}
                                        repeats:NO];
      }
    }
    return;
  }
  
  if ([keyPath isEqualToString:@"muted"]) {
    if (self.player.isMuted) {
      NSLog(@"audio is muted");
      self.state = kStateTypeMute;
    }
    else {
      NSLog(@"audio is unmuted");
      self.state = kStateTypeUnmute;
    }
  } else if ([keyPath isEqualToString:@"volume"]){
    NSLog(@"the volume is changed to %f", self.player.volume);
    self.state = kStateTypeChangeVolume;
  }
}

- (void)checkSeekStart:(NSTimer *)timer {
  if(self.state == kStateTypeSeekStart || self.state == kStateTypeComplete) return;
  NSTimeInterval scheduledTime = [[[timer userInfo] objectForKey:@"scheduledTime"] doubleValue];
  if (self.state == kStateTypeDoubleJump || self.seeking) {
    NSTimeInterval scheduledTime = [[[timer userInfo] objectForKey:@"scheduledTime"] doubleValue];
    NSLog(@"MP seek start at time: %f", scheduledTime);
    self.state = kStateTypeSeekStart;
    self.seeking = !self.seeking;
    [self.mpLogger registerSeekStart:mpsdk_dfl_CMTimeMakeWithSeconds(scheduledTime, 1000)];
  } else if ((self.state == kStateTypeSeekEnd || self.state == kStateTypeResume) && !self.continued) {
    NSLog(@"MP pause at time: %f",scheduledTime);
    self.state = kStateTypePause;
    [self.mpLogger registerPause: mpsdk_dfl_CMTimeMakeWithSeconds(scheduledTime, 1000)];
  }
  self.continued = NO;
}

- (void)checkSeekEnd:(NSTimer *)timer {
  if (self.state == kStateTypeDoubleJump || self.state == kStateTypeSeekStart) {
    NSTimeInterval scheduledTime = [[[timer userInfo] objectForKey:@"scheduledTime"] doubleValue];
    NSLog(@"MP seek end at time: %f", scheduledTime);
    self.state = kStateTypeSeekEnd;
    self.seeking = !self.seeking;
    [self.mpLogger registerSeekEnd:mpsdk_dfl_CMTimeMakeWithSeconds(scheduledTime, 1000)];
  }
}

- (BOOL)containsToken:(NSString *)url {
  return [url rangeOfString:kToken].length != 0;
}

- (NSString *)extractClientTokenFrom: (NSString *)url {
  if ([self containsToken:url]) {
    return [url substringFromIndex: [url rangeOfString:kToken].location + kToken.length];
  }
  return nil;
}

- (void)dealloc {
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

