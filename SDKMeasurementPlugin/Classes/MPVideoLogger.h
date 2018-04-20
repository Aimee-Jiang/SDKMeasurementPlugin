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

#import <AVFoundation/AVFoundation.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FBMPObserver.h"

#import "MPDefines+Internal.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, StateType) {
  kStateTypeNone,
  kStateTypePause,
  kStateTypeResume,
  kStateTypeSeekStart,
  kStateTypeSeekEnd,
  kStateTypeChangeVolume,
  kStateTypeMute,
  kStateTypeUnmute,
  kStateTypeComplete,
  kStateTypeJump,
  kStateTypeDoubleJump,
};

typedef void (^MPVideoLoggerViewableImpressionBlock)(void);
typedef float (^MPVideoLoggerTargetVolumeBlock)(void);

@interface MPVideoLogger : NSObject

@property (nonatomic, strong) UIView *targetView;
@property (nonatomic, assign) BOOL seeking;

FB_INIT_AND_NEW_UNAVAILABLE_NULLABILITY

- (nullable instancetype)initWithTargetView:(UIView *)targetView
                          targetVolumeBlock:(MPVideoLoggerTargetVolumeBlock)targetVolumeBlock
                                   autoplay:(BOOL)autoplay;

- (nullable instancetype)initWithTargetView:(UIView *)targetView
                    viewableImpressionBlock:(nullable MPVideoLoggerViewableImpressionBlock)viewableImpressionBlock
                          targetVolumeBlock:(MPVideoLoggerTargetVolumeBlock)targetVolumeBlock
                                   autoplay:(BOOL)autoplay NS_DESIGNATED_INITIALIZER;

- (void)updateInlineClientToken:(NSString *)token;

- (void)registerProgressForPlayerItem:(AVPlayerItem *)playerItem
                                state:(StateType)state;

- (void)updateTargetVolumeBlock:(MPVideoLoggerTargetVolumeBlock)block;

- (void)registerComplete:(CMTime)currentTime;

- (void)registerPause:(CMTime)currentTime;

- (void)registerProgress:(CMTime)currentTime;

- (void)registerResume:(CMTime)currentTime;

- (void)registerSeekEnd:(CMTime)seekEndTime;

- (void)registerSeekStart:(CMTime)seekStartTime;

- (void)registerSkip:(CMTime)currentTime;

- (void)registerStop:(CMTime)currentTime;

- (void)registerProgress:(CMTime)currentTime
                forceLog:(BOOL)forceLog
                  paused:(BOOL)paused;

@end

NS_ASSUME_NONNULL_END

