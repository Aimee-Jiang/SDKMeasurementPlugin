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

#import <Availability.h>
#import <AvailabilityInternal.h>

#import <CoreFoundation/CFBase.h>
#import <Foundation/Foundation.h>

#ifndef kCFCoreFoundationVersionNumber_iOS_7_1
#define kCFCoreFoundationVersionNumber_iOS_7_1 847.24
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_0
#define kCFCoreFoundationVersionNumber_iOS_8_0 1140.10
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_1
#define kCFCoreFoundationVersionNumber_iOS_8_1 1141.14
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_2
#define kCFCoreFoundationVersionNumber_iOS_8_2 1142.16
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_8_3
#define kCFCoreFoundationVersionNumber_iOS_8_3 1144.17
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_0
#define kCFCoreFoundationVersionNumber_iOS_9_0 1240.1
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_1
#define kCFCoreFoundationVersionNumber_iOS_9_1 1241.11
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_2
#define kCFCoreFoundationVersionNumber_iOS_9_2 1242.13
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_9_3
#define kCFCoreFoundationVersionNumber_iOS_9_3 1280.3
#endif

#ifndef kCFCoreFoundationVersionNumber_iOS_11_0
#define kCFCoreFoundationVersionNumber_iOS_11_0 1429.15 // based on the first seed of iOS 11
#endif

#ifndef __IPHONE_7_0
#define __IPHONE_7_0 70000
#endif

#ifndef __IPHONE_8_0
#define __IPHONE_8_0 80000
#endif

#ifndef __IPHONE_8_1
#define __IPHONE_8_1 80100
#endif

#ifndef __IPHONE_8_2
#define __IPHONE_8_2 80200
#endif

#ifndef __IPHONE_9_0
#define __IPHONE_9_0 90000
#endif

#ifndef __IPHONE_9_1
#define __IPHONE_9_1 90100
#endif

#ifndef __IPHONE_11_0
#define __IPHONE_11_0 110000
#endif

#define FB_AT_LEAST_IOS7_1 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_7_1)
#define FB_AT_LEAST_IOS8 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_0)
#define FB_AT_LEAST_IOS8_1 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_1)
#define FB_AT_LEAST_IOS8_2 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_2)
#define FB_AT_LEAST_IOS8_3 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_8_3)
#define FB_AT_LEAST_IOS9 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_0)
#define FB_AT_LEAST_IOS9_1 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_1)
#define FB_AT_LEAST_IOS9_2 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_2)
#define FB_AT_LEAST_IOS9_3 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_9_3)
#define FB_AT_LEAST_IOS11 (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_11_0)

#ifndef FB_IOS11_SDK_OR_LATER
#define FB_IOS11_SDK_OR_LATER (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_11_0)
#endif

#ifndef FB_IOS10_SDK_OR_LATER
#define FB_IOS10_SDK_OR_LATER (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_10_0)
#endif

#ifndef FB_IOS9_SDK_OR_LATER
#define FB_IOS9_SDK_OR_LATER (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_0)
#endif

#ifndef FB_IOS9_1_SDK_OR_LATER
#define FB_IOS9_1_SDK_OR_LATER (__IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_1)
#endif

// On watchOS2, TARGET_OS_IPHONE is 1, and Apple introduced TARGET_OS_IOS and TARGET_OS_WATCH to distinguish between iOS and watchOS.
// Before we adopt iOS9 SDK, adding a FB_TARGET_OS_IOS to determine if the target is iOS.
#if FB_IOS9_SDK_OR_LATER
#define FB_TARGET_OS_IOS TARGET_OS_IOS
#else
#define FB_TARGET_OS_IOS TARGET_OS_IPHONE
#endif

#define FB_PHOTOS_USE_IOS8_PHOTO_KIT FB_AT_LEAST_IOS8

#if defined(__LP64__) && __LP64__
#define FB_64 1
#else
#define FB_64 0
#endif

