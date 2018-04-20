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
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPQualityViewabilityMeasurement : NSObject

@property (nonatomic, strong) UIView *targetView;

+ (nullable instancetype)measurementWithTargetView:(UIView *)targetView;

- (nullable instancetype)initWithTargetView:(UIView *)targetView NS_DESIGNATED_INITIALIZER;

/**
 * Derives the ratio of viewable area to total area of self.targetView.
 * <p/>
 * - Returns: The viewable ratio as a CGFloat.
 */
- (float)viewableRatio;

@end

@interface UIColor (MPQualityViewabilityMeasurement)

/**
 Returns the color's alpha value.
 - Returns: The color's apha value as a CGFloat.
 */
- (CGFloat)alpha;

@end

@interface UIWindow (MPQualityViewabilityMeasurement)

/**
 @abstract Returns a z-ordered array of UIWindow objects that belong to the same UIScreen as the UIWindow.
 @return An NSArray of one or more UIWindow objects.
 */
- (NSArray<UIWindow *> *)siblingWindows;

@end

@interface UIView (MPQualityViewabilityMeasurement)

/**
 Returns the view's bounds rect relative to the UIScreen on which it resides.
 Useful to relate views to the same coordinate space.
 - Returns: The UIView's bounds rect relative to its UIScreen, as a CGRect.
 */
- (CGRect)screenRect;

/**
 Returns the view's bounds rect relative to the UIScreen on which it resides, with all clipping applied.
 
 Useful in finding the potentially visible portion of a view.
 - Returns: The UIView's clipped bounds rect relative to its UIScreen, as a CGRect.
 */
- (CGRect)clippedScreenRect;

/**
 Returns the combined alpha value after applying all superview alpha settings.
 
 Used to determine the alpha of the view when rendered to the screen.
 - Returns: The displayed alpha as a CGFloat value.
 */
- (CGFloat)displayedAlpha;

/**
 Check if the view is the UIWindow instance attached to the shared UIApplication delegate.
 
 Indicates whether this is the top view in the hierarchy.
 - Returns: The application window check as a BOOL.
 */
- (BOOL)isWindow;

/**
 Flag representing whether the view is visible.
 
 Considers all factors that influence visibility.
 - Returns: The visible state as a BOOL.
 */
- (BOOL)visible;

/**
 Flag representing whether the view blocks underlying views.
 
 Checks the opaque state and the backgroundColor alpha.
 - Returns: The blocking state as a BOOL.
 */
- (BOOL)blocking;

@end

NS_ASSUME_NONNULL_END

