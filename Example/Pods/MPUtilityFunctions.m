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

#import "MPUtilityFunctions.h"

#import <objc/message.h>
#include <sys/sysctl.h>

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "MPDefines.h"
#import "MPDevice.h"
#import "MPScreen.h"
#import "MPUtility.h"

NS_ASSUME_NONNULL_BEGIN

/* C Utility Functions */

// Converts C style string to NSString
NSString * __nullable FBCreateNSString(const char * __nullable string)
{
  if (!string) {
    return NULL;
  } else {
    const char *unwrappedString = (const char *)string;
    return @(unwrappedString);
    
  }
}

// Convert NSString to heap allocated C string
FB_WARN_RESULT char * __nullable FBCString(NSString * __nullable string)
{
  if (!string) {
    return NULL;
  }
  const char *stackString = string.UTF8String;
  size_t length = (size_t)[string lengthOfBytesUsingEncoding:NSUTF8StringEncoding] + 1;
  if ((stackString == NULL) || length <= 0) {
    return NULL;
  }
  size_t dataSize = sizeof(char) * length;
  char *heapAlloc = (char *)malloc(dataSize);
  memcpy(heapAlloc, stackString, dataSize);
  return heapAlloc;
}

FB_PURE BOOL FBIsKindOfClass(id<NSObject>obj, NSArray<Class> *classes)
{
  for (Class cls in classes) {
    if ([obj isKindOfClass:cls]) {
      return YES;
    }
  }
  return NO;
}

FB_PURE BOOL FBIsMemberOfClass(id<NSObject>obj, NSArray<Class> *classes)
{
  for (Class cls in classes) {
    if ([obj isMemberOfClass:cls]) {
      return YES;
    }
  }
  return NO;
}

/* Device identification functions */

FB_PURE BOOL FBIsTablet(void)
{
  return ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad);
}

/* Helper functions for cleaner programmatic view creation */
FB_CONST CGFloat FBDouble(CGFloat value) {
  return (value * (CGFloat)2.0);
}

FB_CONST CGFloat FBTriple(CGFloat value) {
  return (value * (CGFloat)3.0);
}

FB_CONST CGFloat FBQuadruple(CGFloat value) {
  return (value * (CGFloat)4.0);
}

FB_CONST CGFloat FBHalve(CGFloat value) {
  return (value / (CGFloat)2.0);
}

FB_CONST CGFloat FBOneThird(CGFloat value) {
  return (value / (CGFloat)3.0);
}

FB_CONST CGFloat FBTwoThirds(CGFloat value) {
  return (FBOneThird(value) * (CGFloat)2.0);
}

FB_CONST CGFloat FBOneFourth(CGFloat value) {
  return (value / (CGFloat)4.0);
}

FB_CONST CGFloat FBOneFifth(CGFloat value) {
  return ((value / (CGFloat)5.0));
}

FB_CONST CGFloat FBTwoFifths(CGFloat value) {
  return ((value / (CGFloat)5.0) * (CGFloat)2.0);
}

FB_CONST CGFloat FBThreeFifths(CGFloat value) {
  return ((value / (CGFloat)5.0) * (CGFloat)3.0);
}

FB_CONST CGFloat FBFourFifths(CGFloat value) {
  return ((value / (CGFloat)5.0) * (CGFloat)4.0);
}

FB_CONST CGFloat FBNineTenths(CGFloat value) {
  return ((value / (CGFloat)10.0) * (CGFloat)9.0);
}

FB_CONST FB_OVERLOADABLE CGRect FBHalveCGRect(CGRect input, BOOL width, BOOL height) {
  CGRect output = input;
  if (width) {
    output.size.width /= 2.0;
  }
  if (height) {
    output.size.height /= 2.0;
  }
  return output;
}

FB_CONST FB_OVERLOADABLE CGRect FBHalveCGRect(CGRect input) {
  return FBHalveCGRect(input, YES, NO);
}

FB_CONST FB_OVERLOADABLE CGRect FBOneThirdCGRect(CGRect input, BOOL width, BOOL height) {
  CGRect output = input;
  if (width) {
    output.size.width /= 3.0;
  }
  if (height) {
    output.size.height /= 3.0;
  }
  return output;
}

FB_CONST FB_OVERLOADABLE CGRect FBOneThirdCGRect(CGRect input) {
  return FBOneThirdCGRect(input, YES, NO);
}
FB_CONST FB_OVERLOADABLE CGRect FBTwoThirdsCGRect(CGRect input, BOOL width, BOOL height) {
  CGRect output = input;
  if (width) {
    output.size.width *= (2.0 / 3.0);
    
  }
  if (height) {
    output.size.height *= (2.0 / 3.0);
  }
  return output;
}

FB_CONST FB_OVERLOADABLE CGRect FBTwoThirdsCGRect(CGRect input) {
  return FBHalveCGRect(input, YES, NO);
}

FB_CONST FB_OVERLOADABLE CGRect FBOneFourthCGRect(CGRect input, BOOL width, BOOL height) {
  CGRect output = input;
  if (width) {
    output.size.width /= 4.0;
  }
  if (height) {
    output.size.height /= 4.0;
  }
  return output;
}

FB_CONST FB_OVERLOADABLE CGRect FBOneFourthCGRect(CGRect input) {
  return FBOneFourthCGRect(input, YES, NO);
}

FB_CONST FB_OVERLOADABLE BOOL fb_is_nan(CGFloat input) {
  return (BOOL)(isnan(input));
}

FB_CONST FB_OVERLOADABLE BOOL fb_is_nan(CGPoint input) {
  return (fb_is_nan(input.x) || fb_is_nan(input.y));
}

FB_CONST FB_OVERLOADABLE BOOL fb_is_nan(CGSize input) {
  return (fb_is_nan(input.width) || fb_is_nan(input.height));
}

FB_CONST FB_OVERLOADABLE BOOL fb_is_nan(CGRect input) {
  return (fb_is_nan(input.origin) || fb_is_nan(input.size));
}

FB_CONST FB_OVERLOADABLE BOOL fb_is_valid(CGFloat input) {
  return (BOOL)!(isnan(input) || isinf(input));
}

FB_CONST FB_OVERLOADABLE BOOL fb_is_valid(CGPoint input) {
  return (fb_is_valid(input.x) || fb_is_valid(input.y));
}

FB_CONST FB_OVERLOADABLE BOOL fb_is_valid(CGSize input) {
  return (fb_is_valid(input.width) || fb_is_valid(input.height));
}

FB_CONST FB_OVERLOADABLE BOOL fb_is_valid(CGRect input) {
  return (fb_is_valid(input.origin) || fb_is_valid(input.size));
}

FB_CONST FB_OVERLOADABLE CGRect FB_LIMIT_BOUNDS(CGRect input, CGFloat limit) {
  CGRect bounds = input;
  if (bounds.size.width > limit) {
    CGFloat extraSpace = bounds.size.width - limit;
    bounds.origin.x += FBHalve(extraSpace);
    bounds.size.width = limit;
  }
  return bounds;
}

FB_CONST FB_OVERLOADABLE CGRect FB_LIMIT_BOUNDS(CGRect input) {
  return FB_LIMIT_BOUNDS(input, 360);
}

FB_CONST FB_OVERLOADABLE CGFloat FB_LIMIT_BOUNDS_OFFSET(CGRect input, CGFloat limit) {
  CGRect bounds = input;
  CGFloat extraSpace = 0;
  if (bounds.size.width > limit) {
    extraSpace = FBHalve(extraSpace);
  }
  return isnan(extraSpace) ? extraSpace : 0;
}

FB_CONST FB_OVERLOADABLE CGFloat FB_LIMIT_BOUNDS_OFFSET(CGRect input) {
  return FB_LIMIT_BOUNDS_OFFSET(input, 360);
}

FB_CONST CGRect FB_CLIP_ON_HEIGHT(CGRect input, NSNumber *heightLimit, NSNumber *shouldClip) {
  if (!heightLimit || !shouldClip.boolValue) {
    return input;
  }
  CGFloat limit = (CGFloat)heightLimit.doubleValue;
  CGFloat currentHeight = input.size.height;
  if (currentHeight <= 0.0) {
    return input;
  }
  input.size.height = MAX(currentHeight, limit);
  return input;
}

FB_CONST CGRect FB_CGRectCeil(CGRect input) {
  CGRect output = CGRectZero;
  output.origin.x = ceil(input.origin.x);
  output.origin.y = ceil(input.origin.y);
  output.size.width = ceil(input.size.width);
  output.size.height = ceil(input.size.height);
  return output;
}

FB_CONST CGSize FBCGSizeIntegral(CGSize input) {
  CGSize output = CGSizeZero;
  output.width = floor(input.width);
  output.height = floor(input.height);
  return output;
}

FB_CONST CGRect FB_CGRectAlign(CGRect input, CGRect alignFrame, BOOL width, BOOL height) {
  CGRect output = input;
  if (width) {
    output.origin.x = alignFrame.origin.x;
    output.size.width = alignFrame.size.width;
  }
  if (height) {
    output.origin.y = alignFrame.origin.y;
    output.size.height = alignFrame.size.height;
  }
  return output;
}

FB_CONST CGRect FB_CGRectReduce(CGRect input, CGFloat dx, CGFloat dy) {
  CGRect output = input;
  output.size.width -= dx;
  output.size.height -= dy;
  return output;
}

FB_PURE CGFloat FBRoundPixelValueForScale(CGFloat f, CGFloat scale)
{
  // Round to the nearest device pixel (.5 on retina)
  return round(f * scale) / scale;
}

//FB_PURE CGFloat FBRoundPixelValue(CGFloat f)
//{
//    return FBRoundPixelValueForScale(f, [MPScreen scale]);
//}

FB_PURE CGPoint FB_CGPointMult(CGPoint point, CGFloat multiplier)
{
  point.x *= multiplier;
  point.y *= multiplier;
  return point;
}

FB_PURE CGSize FB_CGSizeMult(CGSize size, CGFloat multiplier)
{
  size.width *= multiplier;
  size.height *= multiplier;
  return size;
}

FB_PURE CGRect FB_CGRectMult(CGRect rect, CGFloat multiplier)
{
  return (CGRect){FB_CGPointMult(rect.origin, multiplier), FB_CGSizeMult(rect.size, multiplier)};
}

FB_PURE BOOL FB_CGFloatFuzzyEquals(CGFloat firstValue, CGFloat secondValue, CGFloat epsilon)
{
  CGFloat absA = fabs(firstValue);
  CGFloat absB = fabs(secondValue);
  CGFloat diff = fabs(firstValue - secondValue);
  
  if (firstValue == secondValue) { // shortcut, handles infinities
    return true;
  } else if (firstValue == 0 || secondValue == 0 || diff < CGFLOAT_MIN) {
    return diff < (epsilon * CGFLOAT_MIN);
  } else {
    return diff / (absA + absB) < epsilon;
  }
}

void fb_dispatch_async_repeated_internal(dispatch_time_t startTime, NSTimeInterval interval, dispatch_queue_t queue, NSUInteger count, void(^block)(NSUInteger count, BOOL *shouldStop))
{
  __block BOOL shouldStop = NO;
  dispatch_time_t nextTime = dispatch_time(startTime, (int64_t)(interval * NSEC_PER_SEC));
  NSUInteger nextCount = ++count;
  dispatch_after(nextTime, queue, ^{
    block(count, &shouldStop);
    if (!shouldStop) {
      fb_dispatch_async_repeated_internal(nextTime, interval, queue, nextCount, block);
    }
  });
}

void fb_dispatch_async_repeated(NSTimeInterval interval, dispatch_queue_t queue, void(^block)(NSUInteger count, BOOL *shouldStop))
{
  dispatch_time_t startTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC));
  fb_dispatch_async_repeated_internal(startTime, interval, queue, 0, block);
}

FB_NONNULL1 void fb_add_ivar_to_class(Class aClass, fbIvarPair ivar)
{
  NSCAssert((ivar.name != NULL), @"Name must be nonnull.");
  NSCAssert((ivar.encoding != NULL), @"Encoding must be nonnull.");
  
  // NOTE: Must be called AFTER objc_allocateClassPair, but before objc_registerClassPair!
  NSUInteger size = 0, alignment = 0;
  NSGetSizeAndAlignment(ivar.encoding, &size, &alignment);
  class_addIvar(aClass, ivar.name, size, (uint8_t)alignment, ivar.encoding);
}

FB_NONNULL1 FB_NONNULL2 __nullable Class fb_generate_dynamic_subclass(char *name, Class superclass, Protocol **protocols, fbIvarPair * __nullable ivars, fbSelBlockPair * __nullable imps)
{
  NSCAssert(name != NULL, @"Name must be nonnull.");
  
  // Classes loaded at runtime are lazily resolved
  [superclass class];
  
  // Allocate class
  Class newClass = objc_allocateClassPair(superclass, name, 0);
  if (!newClass) {
    return nil;
  }
  
  // Add protocols to class
  while (protocols && *protocols != NULL) {
    class_addProtocol(newClass, *protocols);
    protocols++;
  }
  
  // Add ivars to class
  while (ivars && ivars->name) {
    fb_add_ivar_to_class(newClass, *ivars);
    ivars++;
  }
  
  // Add methods to class
  while (imps && imps->aSEL) {
    class_addMethod(newClass, imps->aSEL, imp_implementationWithBlock(imps->aBlock), "@@:*");
    imps++;
  }
  
  // Register class with runtime
  objc_registerClassPair(newClass);
  
  return newClass;
}

void fb_dispatch_once_on_main_thread(dispatch_once_t *predicate,
                                     dispatch_block_t block) {
  if ([NSThread isMainThread]) {
    dispatch_once(predicate, block);
  } else {
    if (DISPATCH_EXPECT(*predicate == 0L, NO)) {
      dispatch_sync(dispatch_get_main_queue(), ^{
        dispatch_once(predicate, block);
      });
    }
  }
}

int fb_rot13(int character) {
  if(('a' <= character) && (character <= 'z')){
    return (((character - 'a') + 13) % 26) + 'a';
  } else if (('A' <= character) && (character <= 'Z')) {
    return (((character - 'A') + 13) % 26) + 'A';
  } else {
    return character;
  }
}

char *fb_rot13_string(const char *string) {
  size_t length = strlen(string);
  char *retString = (char *)malloc(length * sizeof(char) + 1);
  for (size_t i = 0; i < length; i++) {
    retString[i] = (char)fb_rot13(string[i]);
  }
  retString[length] = '\0';
  return retString;
}

NSString * __nullable fb_rot13_nsstring(NSString * __nullable string) {
  if ([string canBeConvertedToEncoding:NSASCIIStringEncoding]) {
    const char * __nullable cString = [string cStringUsingEncoding:NSASCIIStringEncoding];
    if (cString) {
      const char *unwrappedCString = (const char *)cString;
      char *decodedString = fb_rot13_string(unwrappedCString);
      size_t length = strlen(decodedString);
      return [[NSString alloc] initWithBytesNoCopy:decodedString
                                            length:length
                                          encoding:NSASCIIStringEncoding
                                      freeWhenDone:YES];
    }
  }
  return nil;
}

FB_WARN_RESULT BOOL fb_is_jailbroken() {
  return FB_INITIALIZE_WITH_BLOCK_AND_RETURN_STATIC(^BOOL{
    BOOL isJailbroken = NO;
#if !(TARGET_IPHONE_SIMULATOR)
    NSFileManager *defaultManager = [NSFileManager defaultManager];
    NSMutableArray *paths = [NSMutableArray arrayWithCapacity:5];
    NSString *cydiaPath = fb_rot13_nsstring(@"/Nccyvpngvbaf/Plqvn.ncc"); // /Applications/Cydia.app
    if (cydiaPath) {
      [paths addObject:MPUnwrap(cydiaPath)];
    }
    NSString * __nullable mobileSubstratePath = fb_rot13_nsstring(@"/Yvoenel/ZbovyrFhofgengr/ZbovyrFhofgengr.qlyvo"); // @"/Library/MobileSubstrate/MobileSubstrate.dylib"
    if (mobileSubstratePath) {
      [paths addObject:MPUnwrap(mobileSubstratePath)];
    }
    NSString * __nullable bashPath = fb_rot13_nsstring(@"/ova/onfu"); // @"/bin/bash"
    if (bashPath) {
      [paths addObject:MPUnwrap(bashPath)];
    }
    NSString * __nullable sshdPath = fb_rot13_nsstring(@"/hfe/fova/ffuq"); // @"/usr/sbin/sshd"
    if (sshdPath) {
      [paths addObject:MPUnwrap(sshdPath)];
    }
    NSString * __nullable aptPath = fb_rot13_nsstring(@"/rgp/ncg"); // @"/etc/apt"
    if (cydiaPath) {
      [paths addObject:MPUnwrap(aptPath)];
    }
    
    for (NSString *path in paths) {
      if ([defaultManager fileExistsAtPath:path]) {
        isJailbroken = YES;
        return isJailbroken;
      }
    }
    
    NSError *error = nil;
    NSString *writableTest = @"Testing...";
    NSString *filePath = fb_rot13_nsstring(@"/cevingr/wnvyoernx.grfg"); // @"/private/jailbreak.test";
    [writableTest writeToFile:filePath
                   atomically:YES
                     encoding:NSASCIIStringEncoding
                        error:&error];
    if(!error) {
      isJailbroken = YES;
      return isJailbroken;
    } else {
      [defaultManager removeItemAtPath:filePath error:nil];
    }
#endif
    return isJailbroken;
  });
}

FB_WARN_RESULT BOOL fb_am_i_being_debugged(void)
{
  int ignored = 0;
  int mib[4] = {CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()};
  struct kinfo_proc info;
  info.kp_proc.p_flag = 0;
  
  size_t size = sizeof(info);
  
  ignored = sysctl(mib, sizeof(mib) / sizeof(*mib), &info, &size, NULL, 0);
  NSCAssert(ignored == 0, @"Sysctl failed due to unknown reasons.");
  
  return ((info.kp_proc.p_flag & P_TRACED) != 0);
}

BOOL fb_is_running_in_test_environment(void)
{
  return FB_INITIALIZE_AND_RETURN_STATIC((BOOL)(objc_getClass("SenTestCase") != nil || objc_getClass("XCTest") != nil || objc_getClass("SnapshotTestAppDelegate") != nil));
}

NSTimeInterval fb_time_interval_for_uievent(UIEvent * __nullable event)
{
  NSTimeInterval interval = [event timestamp] + ([[NSDate date] timeIntervalSince1970] - [[NSProcessInfo processInfo] systemUptime]);
  return interval;
}

NSString *fb_javascript_safe_create(NSString *javaScript)
{
  return [[NSString alloc] initWithFormat:@"(function(){try{%@}catch(e){return e.toString();}}());", javaScript];
}

void fb_ad_verify_array_types_recursive(NSArray *array, Class __nullable keyType, Class valueType)
{
  for (id<NSObject> value in array) {
    if ([value isKindOfClass:[NSDictionary class]]) {
      fb_ad_verify_dictionary_types_recursive((NSDictionary *)value, MPUnwrap(keyType), valueType);
    } else if ([value isKindOfClass:[NSArray class]]) {
      fb_ad_verify_array_types_recursive((NSArray *)value, keyType, valueType);
    } else {
      FBCAssert([value isKindOfClass:valueType], @"Type validation failed on value %@ with expected type %@ and actual type %@.", value, valueType, [value class]);
    }
  }
}

void fb_ad_verify_dictionary_types_recursive(NSDictionary *dictionary, Class keyType, Class valueType)
{
  for (id<NSObject> key in dictionary) {
    id<NSObject> value = dictionary[key];
    if ([value isKindOfClass:[NSDictionary class]]) {
      fb_ad_verify_dictionary_types_recursive((NSDictionary *)value, keyType, valueType);
    } else if ([value isKindOfClass:[NSArray class]]) {
      fb_ad_verify_array_types_recursive((NSArray *)value, keyType, valueType);
    } else {
      FBCAssert([key isKindOfClass:keyType], @"Type validation failed on key %@ with expected type %@ and actual type %@.", key, keyType, [key class]);
      FBCAssert([value isKindOfClass:valueType], @"Type validation failed on value %@ for key %@ with expected type %@ and actual type %@.", value, key, valueType, [value class]);
    }
  }
}

NS_ASSUME_NONNULL_END

