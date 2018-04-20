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

#import <Foundation/Foundation.h>

#if __has_include(<FBDefines/FBMacros.h>)
#import <FBDefines/FBMacros.h>
#else
@interface NSObject (FakeDesignatedInitializer)

- (nullable instancetype)init_SHUT_UP_CLANG;

@end
#endif

#if __has_include("MPDefines.h")
#import "MPDefines.h"
#endif

#ifndef FBAudienceNetwork_MPDefinesInternal_h
#define FBAudienceNetwork_MPDefinesInternal_h

// Method/function attributes
#define FB_NORETURN __attribute__((__noreturn__))
#define FB_NOTHROW __attribute__((__nothrow__))
#define FB_NONNULL1 __attribute__((__nonnull__(1)))
#define FB_NONNULL2 __attribute__((__nonnull__(2)))
#define FB_NONNULL3 __attribute__((__nonnull__(3)))
#define FB_NONNULL4 __attribute__((__nonnull__(4)))
#define FB_NONNULL5 __attribute__((__nonnull__(5)))
#define FB_NONNULL6 __attribute__((__nonnull__(6)))
#define FB_NONNULL7 __attribute__((__nonnull__(7)))
#define FB_NONNULL_ALL __attribute__((__nonnull__))
#define FB_SENTINEL __attribute__((__sentinel__))
#define FB_PURE __attribute__((__pure__))
#define FB_CONST __attribute__((__const__))
#define FB_WARN_RESULT __attribute__((__warn_unused_result__))
#define FB_MALLOC __attribute__((__malloc__))
#define FB_ALWAYS_INLINE __attribute__((__always_inline__))
#define FB_INLINE static inline
#define FB_NO_INLINE __attribute__((noinline))
#define FB_UNAVAILABLE __attribute__((__unavailable__))
#define FB_FAMILY_NONE __attribute__((objc_method_family(none)))
#define FB_OVERLOADABLE __attribute__((overloadable))
#define FB_WEAK __attribute__((weak))
#define FB_CONSTRUCTOR static __attribute__((constructor))

/**
 Creates and returns a privately-named static variable. The first time
 this macro is called, and only the first time, it initializes said
 static variable with the passed-in value Commonly used for implementing
 "sharedInstance" factory methods. E.g.:
 
 +(instancetype)sharedInstance {
 return FB_INITIALIZE_AND_RETURN_STATIC([self new]);
 }
 */
#ifndef FB_INITIALIZE_AND_RETURN_STATIC
#define FB_INITIALIZE_AND_RETURN_STATIC(...) ({ \
static __typeof__(__VA_ARGS__) static_storage__; \
void (^initialization_block__)(void) = ^{ static_storage__ = (__VA_ARGS__); }; \
static dispatch_once_t once_token__; \
dispatch_once(&once_token__, initialization_block__); \
static_storage__; \
})
#endif

/**
 Creates and returns a privately-named static variable. The first time
 this macro is called, and only the first time, it initializes said
 static variable with the result of calling the passed-in block Commonly
 used for implementing "sharedInstance" factory methods. This version is
 preferred over FB_INITIALIZE_AND_RETURN_STATIC when the initialization
 requires more than a single one-line expression. E.g.:
 
 +(instancetype)sharedInstance {
 return FB_INITIALIZE_WITH_BLOCK_AND_RETURN_STATIC(^{
 id calculation = ...;
 return [[self alloc] initWithResultOfCalculation: calculation];
 });
 }
 */

#ifndef FB_INITIALIZE_WITH_BLOCK_AND_RETURN_STATIC
#define FB_INITIALIZE_WITH_BLOCK_AND_RETURN_STATIC(...) ({ \
static __typeof__((__VA_ARGS__)()) static_storage__; \
void (^initialization_block__)(void) = ^{ static_storage__ = (__VA_ARGS__)(); }; \
static dispatch_once_t once_token__; \
dispatch_once(&once_token__, initialization_block__); \
static_storage__; \
})
#endif

/**
 If available, uses a Clang attribute `noescape` to allow annotation of blocks whose execution will not extend the
 lifetime of objects it references- for example, a method that accepts a block with noescape that executes and returns
 from the blocks before the method itself returns. Collection enumeration is one example of a block whose execution
 does not extend the lifetime of objects it references.
 
 If the attribute `noescape` is unavailable on this system, does nothing.
 */
#if defined(__has_attribute) && __has_attribute(noescape)
#define FB_NOESCAPE __attribute__((noescape))
#else
#define FB_NOESCAPE
#endif // defined(__has_attribute) && __has_attribute(noescape)

#ifndef FB_BLOCK_CALL_SAFE
#define FB_BLOCK_CALL_SAFE(BLOCK, ...) ((BLOCK) ? (BLOCK)(__VA_ARGS__) : (void)0)
#endif

#ifndef FB_NOT_DESIGNATED_INITIALIZER
#define FB_NOT_DESIGNATED_INITIALIZER() \
do { \
NSAssert2(NO, @"%@ is not the designated initializer for instances of %@.", NSStringFromSelector(_cmd), NSStringFromClass([self class])); \
return [self init_SHUT_UP_CLANG]; \
} while (0)
#endif // FB_NOT_DESIGNATED_INITIALIZER

#ifndef FB_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE
#define FB_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE \
__attribute__((unavailable("Must use designated initializer")))
#endif // FB_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE

#ifndef FB_DEPRECATED
#define FB_DEPRECATED \
__attribute__((deprecated))
#endif

#ifndef FB_INIT_AND_NEW_UNAVAILABLE
#define FB_INIT_AND_NEW_UNAVAILABLE \
- (instancetype)init FB_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE; \
+ (instancetype)new FB_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
#endif // FB_INIT_AND_NEW_UNAVAILABLE

#ifndef FB_INIT_AND_NEW_UNAVAILABLE_NULLABILITY
#define FB_INIT_AND_NEW_UNAVAILABLE_NULLABILITY \
- (nonnull instancetype)init FB_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE; \
+ (nonnull instancetype)new FB_NOT_DESIGNATED_INITIALIZER_ATTRIBUTE;
#endif // FB_INIT_AND_NEW_UNAVAILABLE_NULLABILITY

#ifndef FB_FINAL_CLASS_INITIALIZE_IMP
#define FB_FINAL_CLASS_INITIALIZE_IMP(__finalClass) \
do { \
if (![NSStringFromClass(self) hasPrefix:@"NSKVONotifying"] && self != (__finalClass)) { \
NSString *reason = [NSString stringWithFormat:@"%@ is a final class and cannot be subclassed. %@", NSStringFromClass((__finalClass)), NSStringFromClass(self)]; \
@throw [NSException exceptionWithName:@"FBFinalClassViolationException" reason:reason userInfo:nil]; \
} \
} while(0)
#endif // FB_FINAL_CLASS_INITIALIZE_IMP

#ifndef FB_FINAL_CLASS
#define FB_FINAL_CLASS(__finalClass) \
+ (void)initialize { \
Class __nullable __finalClassNullable = (__finalClass); \
if (__finalClassNullable) { \
Class __nonnull __finalClassNonNull = (Class __nonnull)__finalClassNullable; \
FB_FINAL_CLASS_INITIALIZE_IMP((__finalClassNonNull)); \
\
} \
}
#endif // FB_FINAL_CLASS

#ifndef __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS
#define __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wformat-extra-args\"") \
_Pragma("clang diagnostic ignored \"-Wcstring-format-directive\"")
#endif

#ifndef __FB_PRAGMA_POP_NO_FORMAT_WARNINGS
#define __FB_PRAGMA_POP_NO_FORMAT_WARNINGS _Pragma("clang diagnostic pop")
#endif

#ifndef FB_STATEMENT_EXPR_BEGIN
#define FB_STATEMENT_EXPR_BEGIN ({
#endif

#ifndef FB_STATEMENT_EXPR_END
#define FB_STATEMENT_EXPR_END });
#endif

// Nullability Unwrapping

#if __has_feature(objc_generics)

@interface MPNullableWrap<__covariant ObjectType>

- (nonnull ObjectType)asNonNull;

@end

#define MPUnwrap(V) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
({ \
__strong id nullableObj = V; \
NSCAssert(nullableObj, @"Expected '%@' not to be nil.", @#V); \
MPNullableWrap<__typeof(nullableObj)> *typeUnwrapper; \
(__typeof(typeUnwrapper.asNonNull))nullableObj; \
}) \
_Pragma("clang diagnostic pop")

#else

#define MPUnwrap(V) \
({ \
id nullableObj = V; \
NSCAssert(nullableObj, @"Expected '%@' not to be nil.", @#V); \
nullableObj; \
})

#endif

// Type helpers

// The type of a literal string when stored in a struct.
// ARC doesn't like objects in structs. This will work ok
// however it is only intended for literal strings (hence
// the name).
#if __has_feature(objc_arc)
typedef __unsafe_unretained NSString* FBLiteralString;
#else
typedef NSString* FBLiteralString;
#endif
#if __has_feature(objc_arc)
typedef __unsafe_unretained NSString* const FBConstLiteralString;
#else
typedef NSString* const FBConstLiteralString;
#endif

#define NIL_IF_NSNULL(obj) ((obj == [NSNull null]) ? nil : obj)

#define NSNULL_IF_NIL(obj) ((obj == nil) ? (id)[NSNull null] : (id)obj)

// Execution environment
#define FB_IS_IPAD() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define FB_IS_IPHONE() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define FB_IS_RETINA() ([MPScreen scale] >= 2.0)

#define FB_SCREEN_WIDTH ([MPScreen sizeInOrientation].width)
#define FB_SCREEN_HEIGHT ([MPScreen sizeInOrientation].height)
#define FB_SCREEN_MAX_LENGTH (MAX(FB_SCREEN_WIDTH, FB_SCREEN_HEIGHT))
#define FB_SCREEN_MIN_LENGTH (MIN(FB_SCREEN_WIDTH, FB_SCREEN_HEIGHT))

#define FB_IS_IPHONE_4_OR_LESS() ([MPDevice deviceModel] <= MPDeviceModeliPhone4S)
#define FB_IS_IPHONE_5_OR_LESS() ([MPDevice deviceModel] <= MPDeviceModeliPhone5S)
#define FB_IS_IPHONE_6() ([MPDevice deviceModel] == MPDeviceModeliPhone6)
#define FB_IS_IPHONE_6P() ([MPDevice deviceModel] == MPDeviceModeliPhone6Plus)

#define FB_IS_SIMULATOR() ([MPDevice deviceModel] == MPDeviceModeliOSSimulator)

// Weak/strong helpers
#define weakify(arg) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__typeof__(arg) __weak mn_weak_##arg = arg \
_Pragma("clang diagnostic pop")

#define strongify(arg) \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Wshadow\"") \
__typeof__(arg) arg = mn_weak_##arg \
_Pragma("clang diagnostic pop")

// Math helpers
#define FB_CLAMP(x, low, high) \
({ \
__typeof__(x) __x = (x); \
__typeof__(low) __low = (low);\
__typeof__(high) __high = (high);\
__x > __high ? __high : (__x < __low ? __low : __x);\
})

#define FB_DISPATCH_QUEUE_PRIORITY_HIGH dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)
#define FB_DISPATCH_QUEUE_PRIORITY_DEFAULT dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#define FB_DISPATCH_QUEUE_PRIORITY_LOW dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0)
#define FB_DISPATCH_QUEUE_PRIORITY_BACKGROUND dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)

// View helpers
#define FBUpdateViewIfNeeded(variableName) \
BOOL needsUpdate = (variableName != _##variableName); \
_##variableName = variableName; \
[self updateView:needsUpdate];

// Debug helpers
#define FB_NOT_IMPLEMENTED() @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:[NSString stringWithFormat:@"[%@ %@:] not implemented.", NSStringFromClass(self.class), NSStringFromSelector(_cmd)] userInfo:nil];

#ifdef DEBUG
#define FB_LOG_METHOD() \
__FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS \
MPLogDebug(@"%s", __PRETTY_FUNCTION__); \
__FB_PRAGMA_POP_NO_FORMAT_WARNINGS
#else
#define FB_LOG_METHOD()
#endif

// Test helpers

#define FBXCTestAppID() @"256699801203835"
#define FBXCTestPlacementID() @"256699801203835_326140227593125"

#define FBXCTestExpectationInit(expectationName, description) \
XCTestExpectation *expectationName = [self expectationWithDescription:description]; \

#define FBXCTestExpectationInitAndAssign(expectationName, description) \
({ \
XCTestExpectation *expectationName = [self expectationWithDescription:description]; \
self.expectationName = expectationName; \
})

#define FBXCTestExpectationWaitForExpectations(timeout) \
({ \
[self waitForExpectationsWithTimeout:(NSTimeInterval)timeout handler:^(NSError *error) { \
if(error) { \
XCTFail(@"Expectation failed with error: %@", error); \
} \
}]; \
})

#define FBXCTestExpectationFulfill(expectationName) \
[expectationName fulfill];

#define FBXCTestExpectationFailed(errorName) \
XCTFail(@"Expectation failed with error: %@", errorName);

#define XCTAssertIsKindOfClass(object, class, ...); \
({XCTAssertTrue([object isKindOfClass:class], __VA_ARGS__);})

// Test Assertions

#if __has_include(<XCTest/XCTest.h>)

#define FBXCTAssertMainThread() XCTAssertTrue([NSThread isMainThread], @"This method must be called on the main thread")
#define FBXCTAssertNotMainThread() XCTAssertTrue(![NSThread isMainThread], @"This method must be called off the main thread")

#endif

// Assertions

//
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wreserved-id-macro"

#define __GET_MACRO(_1, _2, _3, _4, _5, _6, NAME, ...) NAME

#define __FBAssert1(condition) FBAssertWithSignal((condition), nil, nil)
#define __FBAssert2(condition, description) FBAssertWithSignal((condition), nil, (description))
#define __FBAssert3(condition, description, fmt1) FBAssertWithSignal((condition), nil, (description), (fmt1))
#define __FBAssert4(condition, description, fmt1, fmt2) FBAssertWithSignal((condition), nil, (description), (fmt1), (fmt2))
#define __FBAssert5(condition, description, fmt1, fmt2, fmt3) FBAssertWithSignal((condition), nil, (description), (fmt1), (fmt2), (fmt3))
#define __FBAssert6(condition, description, fmt1, fmt2, fmt3, fmt4) FBAssertWithSignal((condition), nil, (description), (fmt1), (fmt2), (fmt3), (fmt4))

#define __FBCAssert1(condition) FBCAssertWithSignal((condition), nil, nil)
#define __FBCAssert2(condition, description) FBCAssertWithSignal((condition), nil, (description))
#define __FBCAssert3(condition, description, fmt1) FBCAssertWithSignal((condition), nil, (description), (fmt1))
#define __FBCAssert4(condition, description, fmt1, fmt2) FBCAssertWithSignal((condition), nil, (description), (fmt1), (fmt2))
#define __FBCAssert5(condition, description, fmt1, fmt2, fmt3) FBCAssertWithSignal((condition), nil, (description), (fmt1), (fmt2), (fmt3))
#define __FBCAssert6(condition, description, fmt1, fmt2, fmt3, fmt4) FBCAssertWithSignal((condition), nil, (description), (fmt1), (fmt2), (fmt3), (fmt4))

#pragma clang diagnostic pop

#define FBAssert(...) __GET_MACRO(__VA_ARGS__, __FBAssert6, __FBAssert5, __FBAssert4, __FBAssert3, __FBAssert2, __FBAssert1)(__VA_ARGS__)
#define FBCAssert(...) __GET_MACRO(__VA_ARGS__, __FBCAssert6, __FBCAssert5, __FBCAssert4, __FBCAssert3, __FBCAssert2, __FBCAssert1)(__VA_ARGS__)

#define FBAssertWithSignal(condition, tag, description, ...) NSAssert(condition, description, ##__VA_ARGS__)
#define FBCAssertWithSignal(condition, tag, description, ...) NSCAssert(condition, description, ##__VA_ARGS__)
#define FBFatalWithSignal(condition, tag, description, ...) NSAssert(condition, description, ##__VA_ARGS__)
#define FBCFatalWithSignal(condition, tag, description, ...) NSCAssert(condition, description, ##__VA_ARGS__)

#define FBAssertMainThread() FBAssertWithSignal([NSThread isMainThread], nil, @"This method must be called on the main thread")
#define FBCAssertMainThread() FBCAssertWithSignal([NSThread isMainThread], nil, @"This function must be called on the main thread")

#define FBAssertNotMainThread() FBAssertWithSignal(![NSThread isMainThread], nil, @"This method must be called off the main thread")
#define FBCAssertNotMainThread() FBCAssertWithSignal(![NSThread isMainThread], nil, @"This function must be called off the main thread")

#define FBReportMustFix(frmt, ...)                       FBAssert(false, frmt, ##__VA_ARGS__)
#define FBReportMustFixIf(condition, frmt, ...)          FBAssert(!(condition), frmt, ##__VA_ARGS__)
#define FBReportMustFixIfTrue(condition, frmt, ...)      FBAssert(!(condition), frmt, ##__VA_ARGS__)
#define FBReportMustFixIfNotNil(condition, frmt, ...)    FBAssert(!(condition), frmt, ##__VA_ARGS__)
#define FBReportMustFixIfNot(condition, frmt, ...)       FBAssert((condition), frmt, ##__VA_ARGS__)
#define FBReportMustFixIfNil(condition, frmt, ...)       FBAssert((condition), frmt, ##__VA_ARGS__)
#define FBReportMustFixIfFalse(condition, frmt, ...)     FBAssert((condition), frmt, ##__VA_ARGS__)
#define FBReportMustFixIfMainThread()                    FBAssert(![NSThread isMainThread], @"This method must be called off the main thread")
#define FBReportMustFixIfNotMainThread()                 FBAssert([NSThread isMainThread], @"This method must be called on the main thread")
#define FBReportMustFixIfNotOnMarkedQueue(queue)         FBAssert(FB_IS_ON_MARKED_QUEUE(queue), @"This method must be called on a particular queue")
#define FBReportWarning(frmt, ...)                       FBAssert(false, frmt, ##__VA_ARGS__)
#define FBReportWarningIf(condition, frmt, ...)          FBAssert(!(condition), frmt, ##__VA_ARGS__)
#define FBReportWarningIfNot(condition, frmt, ...)       FBAssert((condition), frmt, ##__VA_ARGS__)

#define FBCReportMustFix(frmt, ...)                       FBCAssert(false, frmt, ##__VA_ARGS__)
#define FBCReportMustFixIf(condition, frmt, ...)          FBCAssert(!(condition), frmt, ##__VA_ARGS__)
#define FBCReportMustFixIfTrue(condition, frmt, ...)      FBCAssert(!(condition), frmt, ##__VA_ARGS__)
#define FBCReportMustFixIfNotNil(condition, frmt, ...)    FBCAssert(!(condition), frmt, ##__VA_ARGS__)
#define FBCReportMustFixIfNot(condition, frmt, ...)       FBCAssert((condition), frmt, ##__VA_ARGS__)
#define FBCReportMustFixIfNil(condition, frmt, ...)       FBCAssert((condition), frmt, ##__VA_ARGS__)
#define FBCReportMustFixIfFalse(condition, frmt, ...)     FBCAssert((condition), frmt, ##__VA_ARGS__)
#define FBCReportMustFixIfMainThread()                    FBCAssert(![NSThread isMainThread], @"This method must be called off the main thread")
#define FBCReportMustFixIfNotMainThread()                 FBCAssert([NSThread isMainThread], @"This method must be called on the main thread")
#define FBCReportMustFixIfNotOnMarkedQueue(queue)         FBCAssert(FB_IS_ON_MARKED_QUEUE(queue), @"This method must be called on a particular queue")
#define FBCReportWarning(frmt, ...)                       FBCAssert(false, frmt, ##__VA_ARGS__)
#define FBCReportWarningIf(condition, frmt, ...)          FBCAssert(!(condition), frmt, ##__VA_ARGS__)
#define FBCReportWarningIfNot(condition, frmt, ...)       FBCAssert((condition), frmt, ##__VA_ARGS__)

#if !defined(NS_BLOCK_ASSERTIONS)
#define FBAssertDictionaryTypes(dictionary, keyType, valueType) ({ \
fb_ad_verify_dictionary_types_recursive(dictionary, keyType, valueType); \
})
#else
#define FBAssertDictionaryTypes(dictionary, keyType, valueType) ({ })
#endif

#define MPViewParentController(__view) ({ \
UIResponder *__responder = __view; \
while ([__responder isKindOfClass:[UIView class]]) \
__responder = [__responder nextResponder]; \
(UIViewController *)__responder; \
})


// Exceptions

/**
 Argument preconditions exist to simplify the process of validating parameters to a method. It makes the process of
 performing a check more concise. It's considered a best-practice to validate arguments for values that make your class
 or function impossible/not ideal to run with. For example:
 
 - (instancetype)initWithMessage:(NSString *)message
 {
 if (message == nil) {
 @throw [NSException exceptionWithName:NSInvalidArgumentException
 reason:@"message can't be nil"
 userInfo:nil];
 }
 }
 
 becomes...
 
 - (instancetype)initWithMessage:(NSString *)message
 {
 FBArgumentPreconditionCheckIf(message != nil, @"message can't be nil.");
 }
 
 - Parameter condition: A condition to check before throwing an exception;
 - Parameter message: The message to include as a reason in an NSInvalidArgumentException.
 */
#define FBArgumentPreconditionCheckIf(condition, message) do { if (!(condition)) { @throw [NSException exceptionWithName:NSInvalidArgumentException reason:(message) userInfo:nil]; } } while (0)

/**
 As above, but for inconsistency checks. For example:
 
 FBInternalConsistencyCheckIf([NSThread isMainThread], nil); // Will fail and throw if called off the main thread.
 FBInternalConsistencyCheckIf(methodReturnValue == 5, nil); // Will fail and throw methodReturnValue != 5.
 */
#define FBInternalConsistencyCheckIf(condition, message) do { if (!(condition)) { @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:(message) userInfo:nil]; } } while (0)

/**
 As above, but for range checks. For example:
 
 FBRangeCheckIf(x < [array count], nil);
 */
#define FBRangeCheckIf(condition, message) do { if (!(condition)) { @throw [NSException exceptionWithName:NSRangeException reason:(message) userInfo:nil]; } } while (0)

#endif

