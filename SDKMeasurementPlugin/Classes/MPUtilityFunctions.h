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

#import <objc/runtime.h>

#import <UIKit/UIKit.h>

#ifndef FBAudienceNetwork_MPUtilityFunctions_h
#define FBAudienceNetwork_MPUtilityFunctions_h

#import "MPDefines+Internal.h"

NS_ASSUME_NONNULL_BEGIN

FB_EXTERN_C_BEGIN

// Types for IMP function calls
typedef void (*FB_IMP_NO_PARAMS)(id, SEL);
typedef id __nullable (*FB_IMP_NO_PARAMS_RET_ID)(id, SEL);
typedef BOOL (*FB_IMP_BOOL)(id, SEL, BOOL);

// Types for fb_generate_dynamic_subclass
typedef struct fbIvarPair {
  char *name;
  const char *encoding;
} fbIvarPair;
typedef struct fbSelBlockPair {
  SEL aSEL;
  id (^__unsafe_unretained aBlock)(id, ...);
} fbSelBlockPair;

// Helpers for fb_generate_dynamic_subclass
#define FB_SEL_NIL_PAIR ((struct fbSelBlockPair) { 0, 0 })
#define FB_SEL_PAIR_LIST (struct fbSelBlockPair [])
#define FB_IVAR_NIL_PAIR ((struct fbIvarPair) { 0, 0 })
#define FB_IVAR_PAIR_LIST (struct fbIvarPair [])
#define FB_IMP_BLOCK_CAST (id (^)(id, ...))


extern NSString * __nullable FBCreateNSString(const char * __nullable string);

// Convert NSString to heap allocated C string
FB_WARN_RESULT extern char * __nullable FBCString(NSString * __nullable string);

FB_PURE extern BOOL FBIsKindOfClass(id<NSObject>obj, NSArray<Class> *classes);

FB_PURE extern BOOL FBIsMemberOfClass(id<NSObject>obj, NSArray<Class> *classes);

/* Device identification functions */

FB_PURE extern BOOL FBIsTablet(void);

/* Helper functions for cleaner programmatic view creation */
FB_CONST extern CGFloat FBDouble(CGFloat value);

FB_CONST extern CGFloat FBTriple(CGFloat value);

FB_CONST extern CGFloat FBQuadruple(CGFloat value);

FB_CONST extern CGFloat FBHalve(CGFloat value);

FB_CONST extern CGFloat FBOneThird(CGFloat value);

FB_CONST extern CGFloat FBTwoThirds(CGFloat value);

FB_CONST extern CGFloat FBOneFourth(CGFloat value);

FB_CONST extern CGFloat FBOneFifth(CGFloat value);

FB_CONST extern CGFloat FBTwoFifths(CGFloat value);

FB_CONST extern CGFloat FBThreeFifths(CGFloat value);

FB_CONST extern CGFloat FBFourFifths(CGFloat value);

FB_CONST extern CGFloat FBNineTenths(CGFloat value);

FB_CONST FB_OVERLOADABLE extern CGRect FBHalveCGRect(CGRect input, BOOL width, BOOL height);

FB_CONST FB_OVERLOADABLE extern CGRect FBHalveCGRect(CGRect input);

FB_CONST FB_OVERLOADABLE extern CGRect FBOneThirdCGRect(CGRect input, BOOL width, BOOL height);

FB_CONST FB_OVERLOADABLE extern CGRect FBOneThirdCGRect(CGRect input);

FB_CONST FB_OVERLOADABLE extern CGRect FBTwoThirdsCGRect(CGRect input, BOOL width, BOOL height);

FB_CONST FB_OVERLOADABLE extern CGRect FBTwoThirdsCGRect(CGRect input);

FB_CONST FB_OVERLOADABLE extern CGRect FBOneFourthCGRect(CGRect input, BOOL width, BOOL height);

FB_CONST FB_OVERLOADABLE extern CGRect FBOneFourthCGRect(CGRect input);

FB_CONST FB_OVERLOADABLE extern BOOL fb_is_nan(CGFloat input);

FB_CONST FB_OVERLOADABLE extern BOOL fb_is_nan(CGPoint input);

FB_CONST FB_OVERLOADABLE extern BOOL fb_is_nan(CGSize input);

FB_CONST FB_OVERLOADABLE extern BOOL fb_is_nan(CGRect input);

FB_CONST FB_OVERLOADABLE extern BOOL fb_is_normal(CGFloat input);

FB_CONST FB_OVERLOADABLE extern BOOL fb_is_normal(CGPoint input);

FB_CONST FB_OVERLOADABLE extern BOOL fb_is_normal(CGSize input);

FB_CONST FB_OVERLOADABLE extern BOOL fb_is_normal(CGRect input);

FB_CONST FB_OVERLOADABLE BOOL fb_is_valid(CGFloat input);

FB_CONST FB_OVERLOADABLE BOOL fb_is_valid(CGPoint input);

FB_CONST FB_OVERLOADABLE BOOL fb_is_valid(CGSize input);

FB_CONST FB_OVERLOADABLE BOOL fb_is_valid(CGRect input);

FB_CONST FB_OVERLOADABLE extern CGRect FB_LIMIT_BOUNDS(CGRect input, CGFloat limit);

FB_CONST FB_OVERLOADABLE extern CGRect FB_LIMIT_BOUNDS(CGRect input);

FB_CONST FB_OVERLOADABLE extern CGFloat FB_LIMIT_BOUNDS_OFFSET(CGRect input, CGFloat limit);

FB_CONST FB_OVERLOADABLE extern CGFloat FB_LIMIT_BOUNDS_OFFSET(CGRect input);

FB_CONST extern CGRect FB_CLIP_ON_HEIGHT(CGRect input, NSNumber *heightLimit, NSNumber *shouldClip);

FB_CONST extern CGRect FB_CGRectCeil(CGRect input);

FB_CONST extern CGSize FBCGSizeIntegral(CGSize input);

FB_CONST extern CGRect FB_CGRectAlign(CGRect input, CGRect alignFrame, BOOL width, BOOL height);

FB_CONST extern CGRect FB_CGRectReduce(CGRect input, CGFloat dx, CGFloat dy);

FB_PURE extern CGFloat FBRoundPixelValueForScale(CGFloat f, CGFloat scale);

FB_PURE extern CGFloat FBRoundPixelValue(CGFloat f);

FB_PURE extern CGPoint FB_CGPointMult(CGPoint point, CGFloat multiplier);

FB_PURE extern CGSize FB_CGSizeMult(CGSize size, CGFloat multiplier);

FB_PURE extern CGRect FB_CGRectMult(CGRect rect, CGFloat multiplier);

FB_PURE extern BOOL FB_CGFloatFuzzyEquals(CGFloat firstValue, CGFloat secondValue, CGFloat epsilon);

extern void fb_dispatch_async_repeated_internal(dispatch_time_t startTime, NSTimeInterval interval, dispatch_queue_t queue, NSUInteger count, void(^block)(NSUInteger count, BOOL *shouldStop));

extern void fb_dispatch_async_repeated(NSTimeInterval interval, dispatch_queue_t queue, void(^block)(NSUInteger count, BOOL *shouldStop));

extern void fb_add_ivar_to_class(Class aClass, fbIvarPair ivar);

extern __nullable Class fb_generate_dynamic_subclass(char *name, Class superclass, Protocol * __nullable * __nullable protocols, fbIvarPair * __nullable ivars, fbSelBlockPair * __nullable imps);

extern void fb_dispatch_once_on_main_thread(dispatch_once_t *predicate,
                                            dispatch_block_t block);

extern int fb_rot13(int character);

extern char *fb_rot13_string(const char *string);

extern NSString * __nullable fb_rot13_nsstring(NSString * __nullable string);

FB_WARN_RESULT extern BOOL fb_is_jailbroken(void);

FB_WARN_RESULT extern BOOL fb_am_i_being_debugged(void);

FB_WARN_RESULT extern BOOL fb_is_running_in_test_environment(void);

extern NSTimeInterval fb_time_interval_for_uievent(UIEvent * __nullable event);

NSString *fb_javascript_safe_create(NSString *javaScript);

FB_WARN_RESULT extern BOOL fb_ad_is_iphone_x_compatibility_mode(void);

extern UIEdgeInsets fb_ad_safeAreaInsets(UIView *view);

extern void fb_ad_verify_array_types_recursive(NSArray *array, Class __nullable keyType, Class valueType);
extern void fb_ad_verify_dictionary_types_recursive(NSDictionary *dictionary, Class keyType, Class valueType);

FB_EXTERN_C_END

NS_ASSUME_NONNULL_END

#endif

