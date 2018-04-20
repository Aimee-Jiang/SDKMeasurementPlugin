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

#import "MPScreen.h"

#import <CoreGraphics/CoreGraphics.h>

#import "MPAvailability.h"

#if TARGET_OS_WATCH
#import <WatchKit/WKInterfaceDevice.h>
#endif

#if FB_TARGET_OS_IOS
#import <UIKit/UIScreen.h>
#endif

#import "MPDevice.h"
#import "MPUtilityFunctions.h"

NS_ASSUME_NONNULL_BEGIN

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"

static CGSize _MPScreenSize(void)
{
#if FB_TARGET_OS_IOS
  return [UIScreen mainScreen].bounds.size;
#endif
  
#if TARGET_OS_WATCH
  return [WKInterfaceDevice currentDevice].screenBounds.size;
#endif
}

static CGSize _MPScreenNativeSize(void)
{
#if FB_TARGET_OS_IOS
  return [UIScreen mainScreen].nativeBounds.size;
#endif
  
#if TARGET_OS_WATCH
  return [WKInterfaceDevice currentDevice].screenBounds.size;
#endif
}

static CGFloat _MPScreenNativeScale(void)
{
#if FB_TARGET_OS_IOS
  return [UIScreen mainScreen].nativeScale;
#endif
  
#if TARGET_OS_WATCH
  return [[WKInterfaceDevice currentDevice] screenScale];
#endif
}

static CGFloat _MPScreenScale(void)
{
#if FB_TARGET_OS_IOS
  return [UIScreen mainScreen].scale;
#endif
  
#if TARGET_OS_WATCH
  return [[WKInterfaceDevice currentDevice] screenScale];
#endif
}

#pragma clang diagnostic pop

@implementation MPScreen

static CGFloat scale;
static CGFloat nativeScale;
static CGSize size;
static CGSize nativeSize;

+ (void)initialize
{
  FB_FINAL_CLASS_INITIALIZE_IMP([MPScreen class]);
  // The non-cached implementation is only safe to call on the main thread, so call this up front
  // and cache it so that the cached value can be obtained from any thread.
  if (self == [MPScreen class]) {
    [self recomputeCachedState];
  }
}

+ (void)recomputeCachedState
{
  scale = _MPScreenScale();
  if (FB_AT_LEAST_IOS8) {
    nativeScale = _MPScreenNativeScale();
  } else {
    nativeScale = scale;
  }
  
  size = _MPScreenSize();
  if (FB_AT_LEAST_IOS8) {
    nativeSize = _MPScreenNativeSize();
  } else {
    nativeSize = CGSizeMake(size.width * scale, size.height * scale);
  }
}

+ (CGFloat)scale
{
  return scale;
}

+ (CGFloat)nativeScale
{
  return nativeScale;
}

+ (CGSize)size
{
  return size;
}

+ (CGSize)nativeSize
{
  return nativeSize;
}

+ (BOOL)isPortrait
{
  UIInterfaceOrientation orientation = [MPScreen orientation];
  return UIInterfaceOrientationIsPortrait(orientation);
}

+ (BOOL)isLandscape
{
  UIInterfaceOrientation orientation = [MPScreen orientation];
  return UIInterfaceOrientationIsLandscape(orientation);
}

+ (CGRect)bounds
{
  CGSize currentSize = [self size];
  return CGRectMake(0, 0, currentSize.width, currentSize.height);
}

+ (UIInterfaceOrientation)orientation
{
  FBAssertMainThread();
  return [UIApplication sharedApplication].statusBarOrientation;
}

+ (CGRect)boundsInOrientation
{
  FBAssertMainThread();
  CGSize sizeInOrientation = [self sizeInOrientation];
  return CGRectMake(0, 0, sizeInOrientation.width, sizeInOrientation.height);
}

+ (CGSize)sizeInOrientation
{
  FBAssertMainThread();
  CGSize screenSize = [UIScreen mainScreen].bounds.size;
  if ([MPDevice systemVersionIsGreaterThanOrEqualToiOS8]) {
    return screenSize;
  }
  
  UIInterfaceOrientation statusBarOrientation = [self orientation];
  
  if (UIInterfaceOrientationIsLandscape(statusBarOrientation)) {
    // Swap height and width
    CGFloat temp = screenSize.height;
    screenSize.height = screenSize.width;
    screenSize.width = temp;
  }
  
  return screenSize;
}

@end

NS_ASSUME_NONNULL_END

