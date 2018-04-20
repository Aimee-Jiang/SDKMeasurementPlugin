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
#import <StoreKit/StoreKit.h>

#import "MPDefines+Internal.h"
#import "MPLogger.h"

@class MPVideoURLWrapper;

NS_ASSUME_NONNULL_BEGIN

typedef unsigned long long FBDiskSize;

typedef NS_ENUM(NSInteger, MPTemplateID) {
  MPTemplateIDBannerLegacy = 4,
  MPTemplateIDBanner50 = 5,
  MPTemplateIDBanner90 = 6,
  MPTemplateIDBanner250 = 7,
  MPTemplateIDInterstitialHorizontal = 101,
  MPTemplateIDInterstitialVertical = 102,
  MPTemplateIDInterstitialTablet = 103,
  MPTemplateIDNative = 200,
  MPTemplateIDNative250 = 201,
  MPTemplateIDInstream = 300,
  MPTemplateIDRewardedVideo = 400,
};

typedef NS_ENUM(NSInteger, FBServerOrientation) {
  FBServerOrientationAny                = 0,
  FBServerOrientationPortrait           = 1,
  FBServerOrientationLandscape          = 2,
};

FB_SUBCLASSING_RESTRICTED
@interface MPUtility : NSObject

//+ (void)initializeAudienceNetwork;

@end

@interface MPUtility (MPDataModelUtility)

+ (UIInterfaceOrientation)interfaceOrientationFromServerOrientation:(FBServerOrientation)serverOrientation;
+ (BOOL)interfaceOrientationMaskSupportsPortrait:(UIInterfaceOrientationMask)interfaceOrientationMask;
+ (BOOL)interfaceOrientationMaskSupportsLandscape:(UIInterfaceOrientationMask)interfaceOrientationMask;
+ (FBServerOrientation)serverOrientationFromInterfaceOrientationMask:(UIInterfaceOrientationMask)interfaceOrientationMask;
+ (UIInterfaceOrientationMask)supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window;

@end

@interface MPUtility (MPDeviceInfoUtility)

//+ (BOOL)isAdvertisingTrackingEnabled;
+ (NSString *)getAdvertisingIdentifier;

//+ (BOOL)isArbitraryLoadAllowed;

//+ (NSString *)testHashForSelf;
//+ (NSString *)testHashForAdvertiserID:(NSString *)advertiserID;

+ (CGFloat)deviceVolume;

@end

@interface MPUtility (MPQueryUtility)

+ (NSDictionary<NSString *, NSString *> *)parseQueryString:(NSURL *)url;
+ (NSDictionary<NSString *, NSString *> *)parseQuery:(NSString *)query;

+ (NSString *)createQueryParameterFromKey:(id)key object:(id)obj;
+ (NSString *)createQueryStringFromParameters:(NSDictionary *)parameters;

+ (NSString *)currentLocale;
+ (void)currentUserAgentWithBlock:(void (^)(NSString * __nullable userAgent))userAgentBlock;

+ (nullable id)getObjectFromJSONString:(nullable NSString *)jsonString;
+ (nullable id)getObjectFromJSONData:(nullable NSData *)jsonData;
+ (nullable NSString *)getJSONStringFromObject:(nullable id)obj;
+ (nullable id)getObjectFromPropertyList:(nullable NSData *)data;
//+ (nullable NSData *)getPropertyListFromObject:(nullable id)obj;

+ (nullable id)attemptRecoveryOfObject:(id<NSObject>)object ofClass:(Class)aClass;

+ (BOOL)isStringEmpty:(nullable NSString *)string;

@end

@interface MPUtility (MPLoggingUtility)

//+ (void)displayDebugMessage:(NSString *)format, ... NS_FORMAT_FUNCTION(1,2);

//+ (void)logTracker:(NSURL *)trackerURL
//     withExtraData:(nullable NSDictionary *)extraData;

@end

@interface MPUtility (MPErrorUtility)

+ (void)startObservingBackgroundNotifications:(id)observer
                         usingBackgroundBlock:(void (^)(NSNotification *notification))backgroundBlock
                         usingForegroundBlock:(void (^)(NSNotification *notification))foregroundBlock;
+ (void)stopObservingBackgroundNotifications:(id)observer;

//+ (void)throwExceptionWithName:(NSString *)name
//                        reason:(NSString *)reason;

//+ (void)throwExceptionWithName:(NSString *)name
//                        reason:(NSString *)reason
//                      userInfo:(nullable NSDictionary *)userInfo;

@end

@interface MPUtility (MPViewUtility)

+ (nullable UIView *)findAdOnScreen;
+ (void)markView:(UIView *)view;

+ (void)setApplicationStatusBarHidden:(BOOL)hidden;

+ (void)setTopViewControllerOverride:(nullable UIViewController *)viewController;
+ (nullable UIViewController *)topViewController;
+ (nullable UIViewController *)viewControllerFromView:(nullable UIView *)view;

+ (void)traverseView:(UIView *)view withBlock:(nullable void (^)(UIView *view))block;

//+ (void)loadRemoteImageWithURL:(NSURL *)url withBlock:(nullable void (^)(UIImage * image))block;
//+ (void)loadRemoteImageWithURL:(NSURL *)url withBlock:(nullable void (^)(UIImage * image))block retry:(BOOL)retry;
//+ (void)loadRemoteImagesWithURLs:(NSArray<NSURL *> *)urls withBlock:(nullable void (^)(NSDictionary<NSURL *, UIImage *> *images))block retry:(BOOL)retry;
//
//+ (void)loadRemoteVideoWithURL:(NSURL *)url withBlock:(nullable void (^)(MPVideoURLWrapper *wrapper))block;

+ (void)animateWithFadeIn:(NSArray<UIView *> *)views completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithFadeIn:(NSArray<UIView *> *)views customAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithFadeOut:(NSArray<UIView *> *)views completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithFadeOut:(NSArray<UIView *> *)views customAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithStandardAnimations:(void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithStandardAnimations:(void (^)(void))animations duration:(NSTimeInterval)duration completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateEnabled:(BOOL)animationEnabled withStandardAnimations:(void (^)(void))animations duration:(NSTimeInterval)duration completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateEnabled:(BOOL)animationEnabled withTransactionBlock:(void (^)(void))transactionBlock duration:(NSTimeInterval)duration completion:(nullable void (^)(void))completion;

+ (void)animateWithFadeIn:(NSArray<UIView *> *)views duration:(NSTimeInterval)duration completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithFadeIn:(NSArray<UIView *> *)views duration:(NSTimeInterval)duration customAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithFadeOut:(NSArray<UIView *> *)views duration:(NSTimeInterval)duration completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithFadeOut:(NSArray<UIView *> *)views duration:(NSTimeInterval)duration customAnimations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion;
+ (void)animateWithFade:(BOOL)fade duration:(NSTimeInterval)duration views:(NSArray<UIView *> *)views animations:(nullable void (^)(void))animations completion:(nullable void (^)(BOOL finished))completion;

+ (NSHashTable<UIView *> *)allInteractableTargets:(UIView *)view;
//+ (NSHashTable<UIView *> *)allInteractableTargets:(UIView *)view excluding:(nullable NSHashTable *)exclusions;

+ (UIImage *)snapshotOfView:(UIView *)view withBlock:(nullable void (^)(UIView *view))block;

//+ (CIImage *)addGaussianBlurToImage:(UIImage *)image usingContext:(CIContext *)context;
//+ (void)addGaussianBlurToImages:(NSDictionary<NSURL *, UIImage *> *)images usingContext:(CIContext *)context withBlock:(void (^)(NSDictionary<NSURL *, UIImage *> *blurredImages))block;

+ (CGSize)sizeThatFits:(CGSize)size
     isFlexibileAdSize:(BOOL)isFlexibleAdSize
          actualAdSize:(CGSize)actualAdSize;


//+ (UIImage *)imageWithColor:(UIColor *)color;

+ (BOOL)isMPScheme:(NSURL *)requestURL;

@end

@interface NSArray (MPUtility)

- (id)objectAtIndexOrNil:(NSUInteger)index;

@end


@interface NSDictionary (MPUtility)

- (nullable id)objectForKeyOrNil:(id)key;
- (id)objectForKey:(id)key orDefault:(id)object;
- (nullable NSString *)stringForKeyOrNil:(id)key;
- (NSString *)stringForKey:(id)key orDefault:(NSString *)string;
- (nullable NSNumber *)numberForKeyOrNil:(id)key;
- (NSNumber *)numberForKey:(id)key orDefault:(NSNumber *)number;
- (NSInteger)integerForKey:(id)key orDefault:(NSInteger)integer;
- (NSUInteger)unsignedIntegerForKey:(id)key orDefault:(NSUInteger)unsignedInteger;
- (double)doubleForKey:(id)key orDefault:(double)dub;
- (CGFloat)CGFloatForKey:(id)key orDefault:(CGFloat)cgFloat;
- (BOOL)boolForKey:(id)key orDefault:(BOOL)yesOrNo;
- (nullable NSDictionary<NSString *, NSObject *> *)dictionaryForKeyOrNil:(id)key;
//- (NSDictionary<NSString *, NSObject *> *)dictionaryForKey:(id)key orDefault:(NSDictionary<NSString *, NSObject *> *)dictionary;
- (nullable NSArray *)arrayForKeyOrNil:(id)key;
//- (NSArray<NSObject *> *)arrayForKey:(id)key orDefault:(NSArray<NSObject *>  *)array;
//- (nullable id)objectForKeyOrNil:(id)key ofClass:(nullable Class)aClass;

@end

@interface NSNumberFormatter (MPUtility)

+ (instancetype)defaultFormatter;
- (nullable NSNumber *)safeNumberFromString:(nullable NSString *)string;

@end

@interface NSURLRequest (FBCURL)

@property (nonatomic, readonly, copy) NSString *fb_CURLCommand;

@end

@interface UIColor (MPUtility)

+ (nullable UIColor *)colorWithInteger:(NSUInteger)integer;

@end

@interface UIView (MPTapCheck)

- (BOOL)fb_isTap:(CGPoint)tapPosition inBoundsByMarginPercentage:(NSInteger)marginPercentage;

@end

@interface NSThread (MPUtility)

- (NSNumber *)fb_threadIdentifier;

@end

@interface NSString (MPUtility)

@property (nonatomic, readonly, copy) NSString *fb_URLEncodedString;
//- (BOOL)fb_containsString:(NSString *)string;

@end

@interface NSFileManager (MPUtility)

- (BOOL)fb_getSizeOfDirectory:(FBDiskSize *)size atURL:(NSURL *)directoryURL error:(NSError * __autoreleasing *)error;

@end

NS_ASSUME_NONNULL_END

