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

#import "MPBackgroundStateManager.h"

#import <mutex>

#import "MPDynamicFrameworkLoader.h"
#import "MPLogger.h"
#import "MPNotificationCenter.h"

typedef NS_ENUM(NSUInteger, MPApplicationState) {
  MPApplicationStateEnteredForeground,
  MPApplicationStateActive,
  MPApplicationStateEnteredBackground,
  MPApplicationStateInactive,
};

@interface MPBackgroundStateManager ()

@property (atomic, assign) MPApplicationState extensionState;

@end

@implementation MPBackgroundStateManager


static BOOL isRunningInExtension(void)
{
  return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"NSExtension"] != nil;
}

- (instancetype)init
{
  self = [super init];
  if (self) {
    // At the time this class is being initialized, extension must be active
    self.extensionState = MPApplicationStateActive;
    MPNotificationCenter *notificationCenter = [MPNotificationCenter notificationCenterForObject:self];
    weakify(self);
    BOOL isExtension = isRunningInExtension();
    MPLogDebug(@"MPBackgroundStateManager detected extension? %d", isExtension);
    if (!isExtension) {
      MPLogDebug(@"MPBackgroundStateManager registering normal active/inactive notifications...", isExtension);
      [notificationCenter addNotificationWithName:UIApplicationWillEnterForegroundNotification block:^(NSNotification *notification) {
        strongify(self);
        if (self) {
          self.extensionState = MPApplicationStateEnteredForeground;
        }
      }];
      [notificationCenter addNotificationWithName:UIApplicationDidBecomeActiveNotification block:^(NSNotification *notification) {
        strongify(self);
        if (self) {
          self.extensionState = MPApplicationStateActive;
        }
      }];
      [notificationCenter addNotificationWithName:UIApplicationDidEnterBackgroundNotification block:^(NSNotification *notification) {
        strongify(self);
        if (self) {
          self.extensionState = MPApplicationStateEnteredBackground;
        }
      }];
      [notificationCenter addNotificationWithName:UIApplicationWillResignActiveNotification block:^(NSNotification *notification) {
        strongify(self);
        if (self) {
          self.extensionState = MPApplicationStateInactive;
        }
      }];
    } else {
    }
  }
  return self;
}

- (void)dealloc
{
  [MPNotificationCenter removeAllObserversForObject:self];
}

#pragma mark - FBBackgroundStateManaging

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-property-ivar"
- (BOOL)isApplicationBecomingActive
{
  return self.extensionState == MPApplicationStateEnteredForeground;
}
#pragma clang diagnostic pop

- (BOOL)isApplicationActive
{
  return self.extensionState == MPApplicationStateActive;
}

- (BOOL)isApplicationInactive
{
  return self.extensionState == MPApplicationStateInactive;
}

- (BOOL)isApplicationBackgrounded
{
  return self.extensionState == MPApplicationStateEnteredBackground;
}

- (UIApplicationState)applicationState
{
  switch (self.extensionState) {
    case MPApplicationStateActive: {
      return UIApplicationStateActive;
    }
    case MPApplicationStateInactive: {
      return UIApplicationStateInactive;
    }
    case MPApplicationStateEnteredForeground: {
      return UIApplicationStateInactive;
    }
    case MPApplicationStateEnteredBackground: {
      return UIApplicationStateBackground;
    }
  }
}

@end

