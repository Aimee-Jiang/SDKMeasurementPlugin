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

#import "MPQualityViewabilityMeasurement.h"

#import "MPBackgroundStateManaging.h"

NS_ASSUME_NONNULL_BEGIN

@implementation MPQualityViewabilityMeasurement

+ (nullable instancetype)measurementWithTargetView:(UIView *)targetView
{
  return [[self alloc] initWithTargetView:targetView];
}

- (nullable instancetype)initWithTargetView:(UIView *)targetView
{
  self = [super init];
  if (self) {
    _targetView = targetView;
  }
  return self;
}

- (nullable instancetype)init
{
  return [self initWithTargetView:[UIView new]];
}

- (float)viewableRatio
{
  // viewableRatio is 0.0 if the app is backgrounded
  UIApplicationState state = [[MPBackgroundStateManagerFactory backgroundStateManager] applicationState];
  if (state == UIApplicationStateBackground || state == UIApplicationStateInactive)
  {
    return 0.0f;
  }
  
  if (!self.targetView.visible || 0.9 - self.targetView.displayedAlpha > 0.0001) {
    return 0.0f;
  }
  
  CGRect targetRect = [self.targetView clippedScreenRect];
  
  // Recursively get all the descendant rectangles of current target, the target parent
  // to the top most container.
  NSMutableArray<NSValue *> *relatedRects = [self overlappingRectsInView:self.targetView
                                                              targetRect:targetRect];
  // calculate the size without the target view.
  CGFloat areaSize = [self unionAreaOfRects:relatedRects];
  
  // add the target rectangle
  [relatedRects addObject:[NSValue valueWithCGRect:targetRect]];
  
  // calculate area difference
  CGFloat newAreaSize = [self unionAreaOfRects:relatedRects];
  CGFloat targetViewableArea = newAreaSize - areaSize;
  
  // return viewable area
  CGFloat targetArea = self.targetView.frame.size.width * self.targetView.frame.size.height;
  return (float)(targetViewableArea / targetArea);
}

/**
 * Recursively find the CGRect values from views owned by the given UIView,
 * which overlap the target CGRect.
 * <p/>
 * @param view The target UIView.
 * @param targetRect The target CGRect value.
 * @return The set of overlapping CGRect values as NSValue objects.
 */

- (NSMutableArray<NSValue *> *)overlappingRectsInView:(UIView *)view
                                           targetRect:(CGRect)targetRect
{
  NSMutableArray<NSValue *> *relatedRects = [NSMutableArray new];
  
  UIView *superview = view.superview;
  if (superview || view.isWindow) {
    
    // get array of sibling views, including the view being considered
    NSArray<UIView *> *siblings;
    NSUInteger viewIndex;
    if (view.isWindow) {
      UIWindow *window = (UIWindow *)view;
      siblings = window.siblingWindows;
      viewIndex = [siblings indexOfObject:window];
    } else {
      siblings = superview.subviews;
      viewIndex = [siblings indexOfObject:view];
    }
    
    // include rects of intersecting sibling views, which are at a
    // higher index in the sibling array than the view being considered
    for (NSUInteger i = viewIndex + 1; i < siblings.count; i++) {
      [relatedRects addObjectsFromArray:[self intersectingRectsInView:[siblings objectAtIndex:i]
                                                           targetRect:targetRect]];
    }
    
    // recursively consider superviews
    if (superview) {
      [relatedRects addObjectsFromArray:[self overlappingRectsInView:superview
                                                          targetRect:targetRect]];
    }
  }
  return relatedRects;
}

/**
 * Recursively find the CGRect values from views owned by the given UIView,
 * which intersect the target CGRect.
 * <p/>
 * @param view The target UIViews
 * @param targetRect The target CGRect value.
 * @return The set of intersecting CGRect values as NSValue objects.
 */

- (NSArray<NSValue *> *)intersectingRectsInView:(UIView *)view
                                     targetRect:(CGRect)targetRect
{
  __block NSMutableArray *visibleRects = [NSMutableArray new];
  
  // Only consider visible views
  if (!view.visible) {
    return visibleRects;
  }
  
  // If the view is blocking and intersects the target CGRect, add its CGRect
  CGRect clippedWindowFrame = [view clippedScreenRect];
  if (view.blocking && CGRectIntersectsRect(clippedWindowFrame, targetRect)) {
    [visibleRects addObject:[NSValue valueWithCGRect:clippedWindowFrame]];
  }
  
  // If the view isn't blocking or doesn't clip its bounds,
  // recursively consider its subviews
  if (!view.clipsToBounds || !view.blocking) {
    [view.subviews enumerateObjectsUsingBlock:^(__kindof UIView *subview, NSUInteger idx, BOOL *stop) {
      [visibleRects addObjectsFromArray:[self intersectingRectsInView:subview targetRect:targetRect]];
    }];
  }
  
  return visibleRects;
}

/**
 * Discretization algorithm used to calculate the total size of rectangles, the overlapped
 * one will only be calculated once.
 * <p/>
 * The main idea is:
 * 1. discretizing all the rectangles by x and y axis
 * 2. mark the areas the rectangle covers
 * 3. calculate all the areas which are marked as covered
 * <p/>
 * This is the easiest algorithm I implemented from scratch, the only concern is the time
 * complexity which is a bit high: O(n^3), need to do performance test.
 *
 * @param rects The set of CGRect values as NSValue objects, from which to derive a union area.
 * @return The union area as a CGFloat value.
 */
- (CGFloat)unionAreaOfRects:(NSArray<NSValue *> *)rects
{
  const NSUInteger size = rects.count;
  const NSUInteger dim = size * 2;
  
  CGFloat x[dim];
  CGFloat y[dim];
  bool isCovered[dim][dim];
  memset(isCovered, 0, sizeof(bool) * dim * dim);
  
  NSUInteger xPos = 0;
  NSUInteger yPos = 0;
  for (NSUInteger i = 0; i < size; i++) {
    CGRect r = [rects[i] CGRectValue];
    // store left and bottom points
    x[xPos++] = r.origin.x;
    y[yPos++] = r.origin.y + r.size.height;
    
    // store right and top points
    x[xPos++] = r.origin.x + r.size.width;
    y[yPos++] = r.origin.y;
  }
  
  // sort on x and y axis
  qsort(x, dim, sizeof(CGFloat), compCGFloat);
  qsort(y, dim, sizeof(CGFloat), compCGFloat);
  
  for (NSUInteger i = 0; i < size; i++) {
    CGRect r = [rects[i] CGRectValue];
    NSInteger leftEdgeIndex = binarySearch(x, dim, r.origin.x);
    NSInteger rightEdgeIndex = binarySearch(x, dim, r.origin.x + r.size.width);
    NSInteger topEdgeIndex = binarySearch(y, dim, r.origin.y);
    NSInteger bottomEdgeIndex = binarySearch(y, dim, r.origin.y + r.size.height);
    
    for (NSInteger m = leftEdgeIndex + 1; m <= rightEdgeIndex; m++) {
      for (NSInteger n = topEdgeIndex + 1; n <= bottomEdgeIndex; n++) {
        isCovered[m][n] = true;
      }
    }
  }
  
  CGFloat area = 0.0;
  for (NSUInteger i = 0; i < dim; i++) {
    for (NSUInteger j = 0; j < dim; j++) {
      if (isCovered[i][j]) {
        CGFloat x0 = x[i - 1];
        CGFloat x1 = x[i];
        CGFloat y0 = y[j - 1];
        CGFloat y1 = y[j];
        CGFloat newArea = (x1 - x0) * (y1 - y0);
        area += newArea;
      }
    }
  }
  return area;
}

static int compCGFloat(const void *a, const void *b)
{
  if(*(CGFloat*)a < *(CGFloat*)b) return -1;
  return *(CGFloat*)a > *(CGFloat*)b;
}

/**
 * Binary search the index of the value in array.
 *
 * @param values Array of CGFloat values to search.
 * @param size Size of the array passed to the values argument.
 * @param target CGFloat value to search for.
 * @return index if found, -1 if not.
 */
static NSInteger binarySearch(const CGFloat * values, size_t size, const CGFloat target)
{
  NSInteger low = 0;
  NSInteger high = (NSInteger)size;
  while (low < high) {
    NSInteger mid = low + (high - low) / 2;
    if (values[mid] == target) {
      return mid;
    } else if (values[mid] > target) {
      high = mid;
    } else {
      low = mid + 1;
    }
  }
  return -1;
}

@end

@implementation UIColor (MPQualityViewabilityMeasurement)

- (CGFloat)alpha
{
  const CGFloat *components = CGColorGetComponents(self.CGColor);
  return components[CGColorGetNumberOfComponents(self.CGColor)-1];
}

@end

@implementation UIWindow (MPQualityViewabilityMeasurement)

- (NSArray<UIWindow *> *)siblingWindows
{
  NSMutableArray<UIWindow *> *siblingWindows = [NSMutableArray new];
  NSArray<UIWindow *> *windows = [UIApplication sharedApplication].windows;
  for (NSUInteger i = 0; i < windows.count; i++) {
    UIWindow *window = [windows objectAtIndex:i];
    if (window.screen == self.screen) {
      [siblingWindows addObject:window];
    }
  }
  
  return [NSArray arrayWithArray:siblingWindows];
}

@end

@implementation UIView (MPQualityViewabilityMeasurement)

- (CGRect)screenRect
{
  if (!self.isWindow && !self.window) {
    return CGRectZero;
  }
  if (self.isWindow) {
    UIWindow *window = (UIWindow *)self;
    return [self convertRect:self.bounds toCoordinateSpace:window.screen.coordinateSpace];
  }
  return [self convertRect:self.bounds toCoordinateSpace:(id <UICoordinateSpace>)self.window.screen.coordinateSpace];
}

- (CGRect)clippedScreenRect
{
  CGRect windowFrame = [self screenRect];
  UIView *view = self;
  while (view.superview) {
    if (view.superview.hidden || view.superview.alpha == 0.0) {
      return CGRectZero;
    }
    if (view.superview.clipsToBounds) {
      windowFrame = CGRectIntersection(windowFrame, [view.superview screenRect]);
    }
    view = view.superview;
  }
  if (view.isWindow) {
    UIWindow *window = (UIWindow *)view;
    return CGRectIntersection(windowFrame, window.screen.bounds);
  }
  return CGRectZero;
}

- (CGFloat)displayedAlpha
{
  CGFloat alpha = self.alpha;
  UIView *view = self;
  while (view.superview) {
    alpha = alpha * view.superview.alpha;
    view = view.superview;
  }
  return alpha;
}

- (BOOL)isWindow
{
  return [self isKindOfClass:[UIWindow class]];
}

- (BOOL)visible
{
  if (CGRectIsEmpty(self.frame)) {
    return NO;
  }
  
  if (self.hidden) {
    return NO;
  }
  
  if (self.alpha == 0.0) {
    return NO;
  }
  
  if (!self.isWindow) {
    if (!self.superview) {
      return NO;
    }
    
    if (!self.window) {
      return NO;
    }
  }
  
  return YES;
}

- (BOOL)blocking
{
  if (self.alpha == 0.0) {
    return NO;
  }
  if (!self.backgroundColor || self.backgroundColor.alpha == 0.0) {
    return NO;
  }
  return YES;
}

@end

NS_ASSUME_NONNULL_END

