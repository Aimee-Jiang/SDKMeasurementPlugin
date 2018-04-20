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

#import <UIKit/UIKit.h>

#import "MPDefines+Internal.h"

NS_ASSUME_NONNULL_BEGIN

FB_SUBCLASSING_RESTRICTED
@interface MPScreen : NSObject

/*
 * The scale of the main screen.
 *
 * Safe to call from any thread.
 */
+ (CGFloat)scale;

/*
 * The native scale of the main screen.
 *
 * - Returns: the scale factor between the actual
 * number of physical screen pixels and the screen
 * points
 *
 * Note: For iPhone 6+ this returns ~2.6 whereas
 * +[MPScreen scale] returns 3
 *
 * Safe to call from any thread.
 */
+ (CGFloat)nativeScale;

/*
 * The overall screen size in fixed orientation.
 *
 * Safe to call from any thread.
 */
+ (CGSize)size;

/*
 * The size of the physical screen, measured in pixels.
 *
 * Safe to call from any thread.
 */
+ (CGSize)nativeSize;

+ (CGRect)bounds;

/*
 * Screen bounds in current orientation including the status bar.
 *
 * Only safe to call from main thread.
 */
+ (CGRect)boundsInOrientation;

/*
 * Screen size in current orientation including the status bar.
 *
 * Only safe to call from main thread.
 */
+ (CGSize)sizeInOrientation;

/*
 * Interface orientation from status bar
 *
 * Only safe to call from main thread.
 */
+ (UIInterfaceOrientation)orientation;

/*
 * Recompute the cached state inside MPScreen.
 *
 * This function exists because [UIScreen mainScreen] can change at runtime.
 * For example, on iOS 8, when an iPhone-only app is run on an iPad: During the
 * early stages of initialization, the size starts at 768x1024 (the native size
 * of the iPad).  It's not until later that the UIScreen size changes to 320x480.
 *
 * Only safe to be called on the main thread.
 */
+ (void)recomputeCachedState;

+ (BOOL)isPortrait;

+ (BOOL)isLandscape;

@end

NS_ASSUME_NONNULL_END

