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

extern NSString *const MPEndToEndTestingModeMarker;
extern NSString *const MPEndToEndTestingFeaturePrefix;

NS_ASSUME_NONNULL_BEGIN

/**
 Reflects end to end test configuration.
 It is highly discouraged, but can be used it alter application behaviour by blocking certain features.
 */
@interface MPEndToEnd : NSObject

/*! Returns whether application is under e2e test mode */
+ (BOOL)isRunningEndToEndTest;

/**
 Checks value of given feature set/requested by test
 
 @param key Name of the feature
 @return value of the feature
 */
+ (nullable NSString *)getArg:(NSString *)key;

/**
 Checks if given feature was set/requested by test.
 
 @param feature Name of the feature
 @return whether given feature was requested
 */
+ (BOOL)isEnabled:(NSString *)feature;

@end

NS_ASSUME_NONNULL_END

