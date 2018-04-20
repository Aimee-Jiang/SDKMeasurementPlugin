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

#import "MPUtility.h"

#import <objc/runtime.h>

#import <AdSupport/ASIdentifierManager.h>
#import <WebKit/WebKit.h>

#import "MPBackgroundStateManager.h"
#import "MPBackgroundStateManaging.h"
#import "MPConfigManager.h"
#import "MPDevice.h"
#import "MPDynamicFrameworkLoader.h"
#import "MPEndToEnd.h"
#import "MPLogger.h"
#import "MPNotificationCenter.h"
#import "MPScreen.h"
#import "MPSettings+Internal.h"
#import "MPURLSession.h"
#import "MPUtilityFunctions.h"
#import "MPVideoURLWrapper.h"
NS_ASSUME_NONNULL_BEGIN


static NSString * const MPScheme = @"mp";
static const NSInteger MIN_BANNER_WIDTH = 320;

@implementation MPUtility

FB_FINAL_CLASS(objc_getClass("MPUtility"));

@end

@implementation MPUtility (MPDataModelUtility)

+ (UIInterfaceOrientation)interfaceOrientationFromServerOrientation:(FBServerOrientation)serverOrientation
{
  UIInterfaceOrientation interfaceOrientation = UIInterfaceOrientationUnknown;
  switch (serverOrientation) {
    case FBServerOrientationAny: {
      break;
    }
    case FBServerOrientationPortrait: {
      interfaceOrientation = UIInterfaceOrientationPortrait;
      break;
    }
    case FBServerOrientationLandscape: {
      interfaceOrientation = UIInterfaceOrientationLandscapeLeft;
      break;
    }
    default:
      break;
  }
  return interfaceOrientation;
}

+ (BOOL)interfaceOrientationMaskSupportsPortrait:(UIInterfaceOrientationMask)interfaceOrientationMask
{
  return (UIInterfaceOrientationMaskPortrait & interfaceOrientationMask) != 0 || (UIInterfaceOrientationMaskPortraitUpsideDown & interfaceOrientationMask) != 0;
}

+ (BOOL)interfaceOrientationMaskSupportsLandscape:(UIInterfaceOrientationMask)interfaceOrientationMask
{
  return (UIInterfaceOrientationMaskLandscape & interfaceOrientationMask) != 0;
}

+ (FBServerOrientation)serverOrientationFromInterfaceOrientationMask:(UIInterfaceOrientationMask)interfaceOrientationMask
{
  FBServerOrientation serverOrientation = FBServerOrientationAny;
  BOOL supportsPortrait = [self interfaceOrientationMaskSupportsPortrait:interfaceOrientationMask];
  BOOL supportsLandscape = [self interfaceOrientationMaskSupportsLandscape:interfaceOrientationMask];
  if (supportsPortrait && !supportsLandscape) {
    serverOrientation = FBServerOrientationPortrait;
  }
  if (supportsLandscape && !supportsPortrait) {
    serverOrientation = FBServerOrientationLandscape;
  }
  return serverOrientation;
}

+ (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window
{
  UIApplication *application = [UIApplication sharedApplication];
  id<UIApplicationDelegate>applicationDelegate = application.delegate;
  if ([applicationDelegate respondsToSelector:@selector(application:supportedInterfaceOrientationsForWindow:)]) {
    return [applicationDelegate application:application supportedInterfaceOrientationsForWindow:window];
  }
  return [[UIApplication sharedApplication] supportedInterfaceOrientationsForWindow:window];
}

@end

@implementation MPUtility (MPQueryUtility)

+ (NSDictionary<NSString *, NSString *> *)parseQueryString:(NSURL *)url
{
  if (!url) {
    return @{};
  }
  
  NSString *query = url.query;
  if (!query) {
    return @{};
  }
  return [self parseQuery:query];
}

+ (NSDictionary<NSString *, NSString *> *)parseQuery:(NSString *)query
{
  NSMutableArray *keys = [NSMutableArray new];
  NSMutableArray *values = [NSMutableArray new];
  
  NSArray<NSString *> *nameValuePairs = [query componentsSeparatedByString:@"&"];
  for(NSString *nameValuePair in nameValuePairs) {
    NSArray<NSString *> *keyAndValue = [nameValuePair componentsSeparatedByString:@"="];
    if (keyAndValue.count == 2) {
      // only accept wellformed name value pairs
      NSString *value = keyAndValue[1];
      value = [[value stringByReplacingOccurrencesOfString:@"+" withString:@" "]
               stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
      
      [keys addObject:keyAndValue[0]];
      [values addObject:value];
    }
  }
  
  return [NSDictionary dictionaryWithObjects:values
                                     forKeys:keys];
}

+ (NSString *)createQueryParameterFromKey:(id)key object:(id)obj
{
  return [NSString stringWithFormat:@"%@=%@",
          [key fb_URLEncodedString],
          [[MPUtility attemptRecoveryOfObject:obj ofClass:[NSString class]] fb_URLEncodedString]];
}

+ (NSString *)createQueryStringFromParameters:(NSDictionary *)parameters
{
  __block NSMutableString *paramsString = [NSMutableString stringWithString:@""];
  
  if (parameters != nil) {
    [parameters enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *parametersStop) {
      
      if ([obj isKindOfClass:[NSArray class]] || [obj isKindOfClass:[NSMutableArray class]]) {
        
        [(NSArray *)obj enumerateObjectsUsingBlock:^(id arrayObj, NSUInteger idx, BOOL *objStop) {
          
          if (paramsString.length > 0) {
            [paramsString appendString:@"&"];
          }
          
          [paramsString appendString:[self createQueryParameterFromKey:[NSString stringWithFormat:@"%@[]", key] object:arrayObj]];
        }];
        
      } else {
        
        if (paramsString.length > 0) {
          [paramsString appendString:@"&"];
        }
        
        [paramsString appendString:[self createQueryParameterFromKey:key object:obj]];
      }
    }];
  }
  
  // Create and return the final query string composed from the parameters string
  return [NSString stringWithString:paramsString];
}

+ (NSString *)currentLocale
{
  NSString *locale = [[NSLocale autoupdatingCurrentLocale] localeIdentifier];
  return  locale ?: @"en_US";
}

+ (void)currentUserAgentWithBlock:(void (^)(NSString * __nullable userAgent))userAgentBlock {
  static NSString *userAgent = nil;
  if (userAgent) {
    if (userAgentBlock) {
      userAgentBlock(userAgent);
    }
    return;
  }
  static dispatch_once_t onceToken = 0;
  fb_dispatch_once_on_main_thread(&onceToken, ^{
    static id webView = nil;
    NSString *userAgentJavascript = fb_javascript_safe_create(@"return navigator.userAgent");
    // Sarunas
    Class wkWebViewClass = [WKWebView class];
    if (wkWebViewClass) {
      webView = [wkWebViewClass new];
      [webView setHidden:YES];
      [webView evaluateJavaScript:userAgentJavascript completionHandler:^(id __nullable obj, NSError * __nullable error) {
        NSString *systemUserAgent = obj;
        if (![systemUserAgent isKindOfClass:[NSString class]]) {
          if (userAgentBlock) {
            userAgentBlock(nil);
          }
          return;
        }
        userAgent = [self generateUserAgentStringFromRawString:systemUserAgent];
        if (userAgentBlock) {
          userAgentBlock(userAgent);
        }
        webView = nil;
      }];
    } else {
      webView = [NSClassFromString(@"UIWebView") new];
      [webView setHidden:YES];
      NSString *systemUserAgent = [webView stringByEvaluatingJavaScriptFromString:userAgentJavascript];
      userAgent = [self generateUserAgentStringFromRawString:systemUserAgent];
      if (userAgentBlock) {
        userAgentBlock(userAgent);
      }
    }
  });
}

+ (nullable NSString *)generateUserAgentStringFromRawString:(NSString *)systemUserAgent
{
  if (!systemUserAgent) {
    return nil;
  }
  NSBundle *mainBundle = [NSBundle mainBundle];
  NSString *userAgent = [NSString stringWithFormat:@"%@ [FBAN/%@;FBDV/%@;FBMD/%@;FBSN/%@;FBSV/%@;FBLC/%@;FBVS/%@;FBAB/%@;FBAV/%@;FBBV/%@]",
                         systemUserAgent,
                         @"AudienceNetworkForiOS", // FBAN = Application Name
                         [self cleanUserAgentString:[MPDevice machine]], // FBDV = Device Name
                         [self cleanUserAgentString:[MPDevice model]], // FBMD = Model
                         [self cleanUserAgentString:[MPDevice systemName]], // FBSN = System Name
                         [self cleanUserAgentString:[MPDevice systemVersion]], // FBSV = System Version
                         [self cleanUserAgentString:[self currentLocale]], // FBLC = Locale
                         @"4.28.0",
                         mainBundle.bundleIdentifier, // FBAB = App Bundle ID
                         mainBundle.infoDictionary[@"CFBundleShortVersionString"], // FBAV = App Version
                         mainBundle.infoDictionary[@"CFBundleVersion"]]; // FBBV = App Build
  return userAgent;
}

+ (NSString *)cleanUserAgentString:(NSString *) str
{
  return [[str stringByReplacingOccurrencesOfString:@"/" withString:@"-"]
          stringByReplacingOccurrencesOfString:@";" withString:@"-"];
}

+ (nullable id)getObjectFromJSONString:(nullable NSString *)jsonString
{
  if (jsonString) {
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    return [self getObjectFromJSONData:data];
  }
  return nil;
}

+ (nullable id)getObjectFromJSONData:(nullable NSData *)jsonData
{
  if (jsonData) {
    @try {
      id obj = [NSJSONSerialization JSONObjectWithData:MPUnwrap(jsonData)
                                               options:(NSJSONReadingOptions)(NSJSONReadingMutableContainers |
                                                                              NSJSONReadingMutableLeaves |
                                                                              NSJSONReadingAllowFragments)
                                                 error:nil];
      return obj;
    }
    @catch (...) {
      MPLogDebug(@"Attempted to convert invalid JSON %@", [[NSString alloc] initWithData:MPUnwrap(jsonData)
                                                                                  encoding:NSUTF8StringEncoding]);
    }
  }
  return nil;
}

+ (nullable NSString *)getJSONStringFromObject:(nullable id)obj
{
  if (obj) {
    @try {
      NSData * __nullable jsonData = [NSJSONSerialization dataWithJSONObject:(id)obj ?: @""
                                                                     options:(NSJSONWritingOptions)kNilOptions
                                                                       error:nil];
      if (jsonData) {
        return [[NSString alloc] initWithData:(NSData *)jsonData encoding:NSUTF8StringEncoding];
      }
    }
    @catch (...) {
      MPLogDebug(@"Attempted to convert invalid object %@ to JSON", obj);
    }
  }
  return nil;
}

+ (nullable id)attemptRecoveryOfObject:(id<NSObject>)object ofClass:(Class)aClass
{
  if (!object) {
    return nil;
  } else if (aClass == [NSString class] && [object isKindOfClass:[NSNumber class]]) {
    NSNumber *number = (NSNumber *)object;
    NSString *string = number.stringValue;
    return string;
  } else if (aClass == [NSNumber class] && [object isKindOfClass:[NSString class]]) {
    NSString *string = (NSString *)object;
    NSNumber *number = [[NSNumberFormatter defaultFormatter] safeNumberFromString:string];
    return number;
  }  else if (aClass == [NSString class] && [object isKindOfClass:[NSString class]]) {
    return object;
  } else if (aClass == [NSNumber class] && [object isKindOfClass:[NSNumber class]]) {
    return object;
  } else if (aClass == [NSString class] && [object isKindOfClass:[NSDictionary class]]) {
    id obj = [MPUtility getJSONStringFromObject:object];
    return obj ?: @"";
  }
  return nil;
}

+ (BOOL)isStringEmpty:(nullable NSString *)string
{
  if (string && [string isKindOfClass:[NSString class]]) {
    return ([string length] <= 0);
  }
  return YES;
}

@end

@implementation MPUtility (MPLoggingUtility)

+ (void)sendRequestInternal:(NSURL *)url
              withExtraData:(nullable NSDictionary *)extraData
               withPostData:(nullable NSDictionary *)postData
{
  NSMutableDictionary *queryParameters = [NSMutableDictionary dictionary];
  if (extraData) {
    [queryParameters addEntriesFromDictionary:(NSDictionary *)extraData];
  }
  if (postData) {
    [queryParameters addEntriesFromDictionary:(NSDictionary *)postData];
  }
  BOOL isPOST = (postData && postData.count > 0);
  [[MPURLSession sharedSession] requestWithURL:url
                                      HTTPMethod:isPOST ? @"POST" : @"GET"
                                 queryParameters:queryParameters
                                 responseHandler:^(MPURLSessionTaskContainer *container,
                                                   NSURLResponse *response,
                                                   NSData *data,
                                                   NSError *error,
                                                   NSTimeInterval duration) {
                                   MPLogVerbose(@"Internal request: %@ %@ %@", response, data, error);
                                 }];
}

@end

@implementation MPUtility (MPErrorUtility)

+ (void)startObservingBackgroundNotifications:(id)observer
                         usingBackgroundBlock:(void (^)(NSNotification *notification))backgroundBlock
                         usingForegroundBlock:(void (^)(NSNotification *notification))foregroundBlock
{
  UIApplication *app = [UIApplication sharedApplication];
  MPNotificationCenter *notification = [MPNotificationCenter notificationCenterForObject:observer];
  [notification addNotificationWithName:UIApplicationDidEnterBackgroundNotification
                                 object:app
                                  block:backgroundBlock];
  [notification addNotificationWithName:UIApplicationDidBecomeActiveNotification
                                 object:app
                                  block:foregroundBlock];
}

+ (void)stopObservingBackgroundNotifications:(id)observer
{
  [MPNotificationCenter removeAllObserversForObject:observer];
}

@end

@implementation MPUtility (MPViewUtility)

+ (void)markView:(UIView *)view
{
  objc_setAssociatedObject(view, "fb_is_ad_view", @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (BOOL)isViewMarked:(UIView *)view
{
  NSNumber *number = objc_getAssociatedObject(view, "fb_is_ad_view");
  BOOL marked = NO;
  if ([number isKindOfClass:[NSNumber class]]) {
    marked = number.boolValue;
  }
  return marked;
}

+ (__kindof UIView *)findAdInViewController:(__kindof UIViewController *)viewController
{
  __block UIView *foundView = nil;
  [self traverseView:viewController.view withBlock:^(UIView *view) {
    if ([self isViewMarked:view]) {
      foundView = view;
    }
  }];
  return foundView;
  
}

+ (nullable __kindof UIView *)findAdOnScreen
{
  UIViewController *topViewController = [self topViewController];
  UIView *foundView = [self findAdInViewController:topViewController];
  if (!foundView) {
    NSArray<UIViewController *> *viewControllers = topViewController.childViewControllers;
    for (UIViewController *viewController in viewControllers) {
      foundView = [self findAdInViewController:viewController];
      if (foundView) {
        break;
      }
    }
  }
  return foundView;
}

+ (void)setApplicationStatusBarHidden:(BOOL)hidden
{
  // Hiding the status bar should use a fade effect.
  // Displaying the status bar should use no animation.
  UIStatusBarAnimation animation = hidden ?
  UIStatusBarAnimationFade : UIStatusBarAnimationNone;
  [[UIApplication sharedApplication] setStatusBarHidden:hidden withAnimation:animation];
}

static UIViewController * __nullable topViewControllerOverride;

+ (nullable UIViewController *)topViewControllerOverride
{
  return topViewControllerOverride;
}


+ (void)setTopViewControllerOverride:(nullable UIViewController *)viewController
{
  topViewControllerOverride = viewController;
}

+ (nullable UIViewController *)topViewController
{
  UIViewController *override = [self topViewControllerOverride];
  if (override) {
    return override;
  }
  return [self viewControllerFromView:nil];
}

+ (nullable UIViewController *)viewControllerFromView:(nullable UIView *)view
{
  if (view) {
    UIViewController *viewController = (UIViewController *)[self traverseResponderChainForViewController:view];
    if (!viewController) {
      viewController = [self topViewController];
    }
    return viewController;
  } else if ([self currentWindow].rootViewController) {
    UIViewController *topViewController = [self currentWindow].rootViewController;
    while (topViewController.presentedViewController) {
      topViewController = topViewController.presentedViewController;
    }
    return topViewController;
  } else {
    return [UIApplication sharedApplication].delegate.window.rootViewController;
  }
}

+ (nullable UIResponder *)traverseResponderChainForViewController:(nullable UIResponder *)responder
{
  if ([responder isKindOfClass:[UIViewController class]]) {
    return responder;
  } else if ([responder respondsToSelector:@selector(nextResponder)]) {
    return [self traverseResponderChainForViewController:[responder nextResponder]];
  } else {
    return nil;
  }
}

+ (nullable UIWindow *)currentWindow
{
  UIApplication *app = [UIApplication sharedApplication];
  UIWindow *window = app.keyWindow;
  if (window == nil || window.windowLevel != UIWindowLevelNormal) {
    for (window in app.windows) {
      if (window.windowLevel == UIWindowLevelNormal) {
        break;
      }
    }
  }
  return window;
}

+ (void)traverseView:(UIView *)view withBlock:(nullable void (^)(UIView *view))block
{
  if (!block) {
    return;
  }
  block(view);
  for (UIView *subview in view.subviews) {
    block(subview);
  }
}

+ (void)animateWithFadeIn:(NSArray<UIView *> *)views completion:(nullable void (^)(BOOL finished))completion
{
  [self animateWithFadeIn:views customAnimations:nil completion:completion];
}

+ (void)animateWithFadeIn:(NSArray<UIView *> *)views customAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion
{
  [self animateWithFade:NO views:views animations:animations completion:completion];
}

+ (void)animateWithFadeOut:(NSArray<UIView *> *)views completion:(nullable void (^)(BOOL finished))completion
{
  [self animateWithFadeOut:views customAnimations:nil completion:completion];
}

+ (void)animateWithFadeOut:(NSArray<UIView *> *)views customAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion
{
  [self animateWithFade:YES views:views animations:animations completion:completion];
}

+ (void)animateWithFade:(BOOL)fade views:(NSArray<UIView *> *)views animations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion
{
  for (UIView *view in views) {
    view.alpha = fade ? 1.0f : 0.0f;
  }
  [self animateWithStandardAnimations:^{
    for (UIView *view in views) {
      view.alpha = fade ? 0.0f : 1.0f;
    }
    if (animations) {
      animations();
    }
  } completion:completion];
}

+ (void)animateWithFadeIn:(NSArray<UIView *> *)views duration:(NSTimeInterval)duration completion:(nullable void (^)(BOOL finished))completion
{
  [self animateWithFadeIn:views duration:duration customAnimations:nil completion:completion];
}

+ (void)animateWithFadeIn:(NSArray<UIView *> *)views duration:(NSTimeInterval)duration customAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion
{
  [self animateWithFade:NO duration:duration views:views animations:animations completion:completion];
}

+ (void)animateWithFadeOut:(NSArray<UIView *> *)views duration:(NSTimeInterval)duration completion:(nullable void (^)(BOOL finished))completion
{
  [self animateWithFadeOut:views duration:duration customAnimations:nil completion:completion];
}

+ (void)animateWithFadeOut:(NSArray<UIView *> *)views duration:(NSTimeInterval)duration customAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion
{
  [self animateWithFade:YES duration:duration views:views animations:animations completion:completion];
}

+ (void)animateWithFade:(BOOL)fade duration:(NSTimeInterval)duration views:(NSArray<UIView *> *)views animations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion
{
  for (UIView *view in views) {
    view.alpha = fade ? 1.0f : 0.0f;
  }
  [self animateWithStandardAnimations:^{
    for (UIView *view in views) {
      view.alpha = fade ? 0.0f : 1.0f;
    }
    if (animations) {
      animations();
    }
  }
                             duration:duration
                           completion:completion];
}

+ (void)animateWithStandardAnimations:(void (^)(void))animations duration:(NSTimeInterval)duration completion:(nullable void (^)(BOOL finished))completion
{
  [self animateEnabled:YES withStandardAnimations:animations duration:duration completion:completion];
}

+ (void)animateEnabled:(BOOL)animationEnabled withStandardAnimations:(void (^)(void))animations duration:(NSTimeInterval)duration completion:(nullable void (^)(BOOL finished))completion
{
  if (animationEnabled) {
    const NSTimeInterval animationDelay = 0.0f;
    [UIView animateWithDuration:duration delay:animationDelay
                        options:(UIViewAnimationOptions)(UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowAnimatedContent)
                     animations:animations completion:completion];
  } else {
    if (animations) {
      animations();
    }
    if (completion) {
      completion(YES);
    }
  }
}

+ (void)animateEnabled:(BOOL)animationEnabled withTransactionBlock:(void (^)(void))transactionBlock duration:(NSTimeInterval)duration completion:(nullable void (^)(void))completion
{
  [CATransaction begin];
  [CATransaction setDisableActions:!animationEnabled];
  [CATransaction setAnimationDuration:duration];
  [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]];
  [CATransaction setCompletionBlock:completion];
  transactionBlock();
  [CATransaction commit];
  
}

+ (void)animateWithStandardAnimations:(void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion
{
  const NSTimeInterval animationDuration = 0.5f;
  [self animateWithStandardAnimations:animations duration:animationDuration completion:completion];
}

+ (BOOL)isMPScheme:(NSURL *)requestURL
{
  return [requestURL.scheme.lowercaseString isEqual:MPScheme];
  
}

@end

@implementation NSArray (MPUtility)

- (id)objectAtIndexOrNil:(NSUInteger)index
{
  return (index < self.count) ? self[index] : nil;
}

@end

@implementation NSDictionary (MPUtility)

- (nullable id)objectForKeyOrNil:(id)key
{
  return [self objectForKeyOrNil:key ofClass:nil];
}

- (id)objectForKey:(id)key orDefault:(id)object
{
  return [self objectForKey:key ofClass:nil orDefault:object];
}

- (id)objectForKey:(id)key ofClass:(nullable Class)aClass orDefault:(id)object
{
  id obj = [self objectForKeyOrNil:key ofClass:aClass];
  return obj ? MPUnwrap(obj) : object;
}

- (nullable NSString *)stringForKeyOrNil:(id)key
{
  return [self objectForKeyOrNil:key ofClass:[NSString class]];
}

- (NSString *)stringForKey:(id)key orDefault:(NSString *)string
{
  return [self objectForKey:key ofClass:[NSString class] orDefault:string];
}

- (nullable NSNumber *)numberForKeyOrNil:(id)key
{
  return [self objectForKeyOrNil:key ofClass:[NSNumber class]];
}

- (NSNumber *)numberForKey:(id)key orDefault:(NSNumber *)number
{
  return [self objectForKey:key ofClass:[NSNumber class] orDefault:number];
}

- (NSInteger)integerForKey:(id)key orDefault:(NSInteger)integer
{
  return [self numberForKey:key orDefault:@(integer)].integerValue;
}

- (NSUInteger)unsignedIntegerForKey:(id)key orDefault:(NSUInteger)unsignedInteger
{
  return [self numberForKey:key orDefault:@(unsignedInteger)].unsignedIntegerValue;
}

- (double)doubleForKey:(id)key orDefault:(double)dub
{
  return [self numberForKey:key orDefault:@(dub)].doubleValue;
}

- (CGFloat)CGFloatForKey:(id)key orDefault:(CGFloat)cgFloat
{
  return (CGFloat)[self numberForKey:key orDefault:@(cgFloat)].doubleValue;
}

- (BOOL)boolForKey:(id)key orDefault:(BOOL)yesOrNo
{
  id value = self[key];
  if ([value isKindOfClass:[NSString class]]) {
    return [value boolValue];
  }
  return [self numberForKey:key orDefault:@(yesOrNo)].boolValue;
}

- (nullable id)objectForKeyOrNil:(id)key ofClass:(nullable Class)aClass
{
  id object = self[key];
  
  if (object == nil || object == [NSNull null]) {
    return nil;
  }
  if (aClass) {
    if (![object isKindOfClass:aClass]) {
      //#ifdef DEBUG
      //            [MPUtility displayVerboseDebugMessage:@"Object %@ for key %@ did not match class. Expected: %@ Actual: %@.", object, key, aClass, [object class]];
      //#endif
      // In the case of simple NSString/NSNumber mismatches, try to fix
      id attemptedRecoveryObject = [self attemptRecoveryOfObject:object ofClass:aClass];
      if (attemptedRecoveryObject) {
        return attemptedRecoveryObject;
      }
      return nil;
    }
  }
  
  return object;
}

- (nullable id)attemptRecoveryOfObject:(id<NSObject>)object ofClass:(nullable Class)aClass
{
  if (!object) {
    return nil;
  } else if (aClass == [NSString class] && [object isKindOfClass:[NSNumber class]]) {
    NSNumber *number = (NSNumber *)object;
    NSString *string = number.stringValue;
    return string;
  } else if (aClass == [NSNumber class] && [object isKindOfClass:[NSString class]]) {
    NSString *string = (NSString *)object;
    NSNumber *number = [[NSNumberFormatter defaultFormatter] safeNumberFromString:string];
    return number;
  }
  return nil;
}

@end

@implementation NSNumberFormatter (MPUtility)

+ (instancetype)defaultFormatter
{
  return FB_INITIALIZE_AND_RETURN_STATIC([NSNumberFormatter new]);
}

- (nullable NSNumber *)safeNumberFromString:(nullable NSString *)string
{
  if (!string) {
    return nil;
  } else if ([string isKindOfClass:[NSString class]]) {
    return [self numberFromString:(NSString *)string];
  } else if ([string isKindOfClass:[NSNumber class]]) {
    return (NSNumber *)string;
  } else {
    return nil;
  }
}

@end

@implementation NSURLRequest (FBCURL)

- (NSString *)fb_CURLCommand
{
  NSMutableString *string = [NSMutableString stringWithString:@"curl -k -i "];
  
  // POST data
  if ([self.HTTPMethod isEqualToString:@"POST"]) {
    NSData *body = self.HTTPBody;
    if (body) {
      NSString *params = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
      [string appendFormat:@"-d \"%@\" ",params];
    }
  }
  
  // HTTP headers
  for (NSString *headerKey in (self.allHTTPHeaderFields).allKeys) {
    NSString *value = (self.allHTTPHeaderFields)[headerKey];
    [string appendFormat:@"-H \"%@\":\"%@\" ", headerKey, value];
  }
  
  [string appendString:[NSString stringWithFormat:@"\"%@\"",self.URL.absoluteString]];
  
  return string;
}

@end

@implementation UIColor (MPUtility)

+ (nullable UIColor *)colorWithInteger:(NSUInteger)integer
{
  return [UIColor colorWithRed:((float)((integer & 0xFF0000) >> 16))/255.0f
                         green:((float)((integer & 0xFF00) >> 8))/255.0f
                          blue:((float)(integer & 0xFF))/255.0f
                         alpha:((float)((integer & 0xFF000000) >> 24))/255.0f];
}

@end

@implementation UIView (MPTapCheck)

- (BOOL)fb_isTap:(CGPoint)tapPosition inBoundsByMarginPercentage:(NSInteger)marginPercentage {
  NSInteger validPercentage = MAX(MIN(marginPercentage, 50), 0);
  
  if (validPercentage == 0) {
    return TRUE;
  } else if (validPercentage == 50) {
    return FALSE;
  }
  
  CGFloat percentage = validPercentage / 100.0f;
  
  CGFloat marginWidth = self.bounds.size.width * percentage;
  CGFloat marginHeight = self.bounds.size.height * percentage;
  
  CGRect tapRect = CGRectMake(self.bounds.origin.x + marginWidth, self.bounds.origin.y + marginHeight,
                              self.bounds.size.width - 2 * marginWidth, self.bounds.size.height - 2 * marginHeight);
  
  return CGRectContainsPoint(tapRect, tapPosition);
}

@end

@implementation NSThread (MPUtility)

- (NSNumber *)fb_threadIdentifier
{
  NSNumber *threadId = objc_getAssociatedObject(self, @selector(fb_threadIdentifier));
  if (threadId != nil) {
    return threadId;
  }
  
  NSString *description = [self description];
  NSArray *keyValuePairs = [description componentsSeparatedByString:@","];
  for(NSString *keyValuePair in keyValuePairs) {
    NSArray *components = [keyValuePair componentsSeparatedByString:@"="];
    NSString *key = components[0];
    key = [key stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    //        if ([key fb_containsString:@"num"]) {
    //            threadId = [[NSNumberFormatter defaultFormatter] safeNumberFromString:components[1]];
    //            objc_setAssociatedObject(self, @selector(fb_threadIdentifier), threadId, OBJC_ASSOCIATION_COPY);
    //            return threadId;
    //        }
  }
  return @-1;
}

@end

@implementation NSString (MPUtility)

- (NSString *)fb_URLEncodedString
{
  NSMutableString *outputString = [NSMutableString string];
  const unsigned char *sourceString = (const unsigned char *)self.UTF8String;
  NSUInteger length = (NSUInteger)strlen((const char *)sourceString);
  for (NSUInteger i = 0; i < length; ++i) {
    const unsigned char currentChar = sourceString[i];
    if (currentChar == ' '){
      [outputString appendString:@"+"];
    } else if (currentChar == '.' || currentChar == '-' || currentChar == '_' || currentChar == '~' ||
               (currentChar >= 'a' && currentChar <= 'z') ||
               (currentChar >= 'A' && currentChar <= 'Z') ||
               (currentChar >= '0' && currentChar <= '9')) {
      [outputString appendFormat:@"%c", currentChar];
    } else {
      [outputString appendFormat:@"%%%02X", currentChar];
    }
  }
  return outputString;
}

@end

@implementation NSFileManager (MPUtility)

- (BOOL)fb_getSizeOfDirectory:(FBDiskSize *)size atURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error
{
  if (!size) {
    return NO;
  }
  if (!directoryURL) {
    return NO;
  }
  
  FBDiskSize accumulatedSize = 0;
  
  NSArray *properties = @[NSURLIsRegularFileKey,
                          NSURLFileAllocatedSizeKey,
                          NSURLTotalFileAllocatedSizeKey];
  
  __block BOOL errorDidOccur = NO;
  NSDirectoryEnumerator *enumerator = [[NSFileManager defaultManager] enumeratorAtURL:directoryURL
                                                           includingPropertiesForKeys:properties
                                                                              options:(NSDirectoryEnumerationOptions)0
                                                                         errorHandler:^(NSURL *url, NSError *enumeratorError) {
                                                                           if (error) {
                                                                             *error = enumeratorError;
                                                                           }
                                                                           MPLogWarning(@"Could not enumerate size of file at url: %@", url);
                                                                           errorDidOccur = YES;
                                                                           return NO;
                                                                         }];
  
  for (NSURL *fileURL in enumerator) {
    if (errorDidOccur) {
      return NO;
    }
    
    NSNumber *isRegularFile = nil;
    if (![fileURL getResourceValue:&isRegularFile forKey:NSURLIsRegularFileKey error:error]) {
      return NO;
    }
    if (isRegularFile.boolValue) {
      NSNumber *fileSize;
      if (![fileURL getResourceValue:&fileSize forKey:NSURLTotalFileAllocatedSizeKey error:error]) {
        return NO;
      }
      
      if (fileSize == nil) {
        if (![fileURL getResourceValue:&fileSize forKey:NSURLFileAllocatedSizeKey error:error]) {
          return NO;
        }
      }
      
      accumulatedSize += (FBDiskSize)fileSize.unsignedLongLongValue;
    }
  }
  
  if (errorDidOccur) {
    return NO;
  }
  
  *size = accumulatedSize;
  return YES;
}

@end

NS_ASSUME_NONNULL_END

