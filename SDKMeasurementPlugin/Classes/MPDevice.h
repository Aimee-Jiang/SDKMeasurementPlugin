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

#import "MPPerformanceMetrics.h"

NS_ASSUME_NONNULL_BEGIN

// A rough estimate of fill rate per screen area.
// If you're doing a lot of blending, this is the important quotient
typedef NS_ENUM(NSUInteger, FBDeviceAdjustedFillRate){
  FBDeviceAdjustedFillRateAbysmal,  // Lowest fill rate for display density. ~iPhone 4/3GS, iPad 3, iPad 1, iPod touch 4/3
  FBDeviceAdjustedFillRateLow,      // Low fill rate for display density     ~iPhone 4S, iPad 2, iPad mini, iPod touch 5
  FBDeviceAdjustedFillRateMedium,   // Fill rate well matched to display     ~iPhone 5, iPhone 5C, iPad 4.
  FBDeviceAdjustedFillRateHigh,     // Awesome gpu. Do cool effects.         ~iPhone 5S, iPad Air, iPad mini retina, iPhone 6, iPhone 6+
  FBDeviceAdjustedFillRateUnknown,  // Unknown device. Assume highest performance.
};

// Only list supported devices
typedef NS_ENUM(NSUInteger, MPDeviceModel){
  MPDeviceModeliPhone3GS = 3,
  MPDeviceModeliPhone4,
  MPDeviceModeliPhone4S,
  MPDeviceModeliPhone5,
  MPDeviceModeliPhone5S,
  MPDeviceModeliPhone6,
  MPDeviceModeliPhone6Plus,
  MPDeviceModeliPhoneX,
  
  MPDeviceModeliPod3G = 103,
  MPDeviceModeliPod4G,
  MPDeviceModeliPod5G,
  
  MPDeviceModeliPad1 = 201,
  MPDeviceModeliPad2,
  MPDeviceModeliPad3,
  MPDeviceModeliPad4,
  MPDeviceModeliPadA7,
  MPDeviceModeliPadAir2,
  
  MPDeviceModeliPadMini1,
  MPDeviceModeliPadMini2,
  
  MPDeviceModeliOSSimulator = 900,
  
  MPDeviceModelUnknown = 999,
};

FB_SUBCLASSING_RESTRICTED
@interface MPDevice : NSObject

/**
 * The non-cached implementations are isPad, and supportsPhone are only safe
 * to call on the main thread, so call these up front and cache them so that the cached
 * values can be obtained from any thread.
 */
+ (void)initializeAndCacheValues;

/* Something changed. Reset cached values. */
+ (void)resetCache;

/* Machine hardware */
+ (NSString *)machine;

/* Machine hardware name */
+ (NSString *)machineName;

/* Hardware architecture */
+ (NSString *)architecture;

/* Hardware model */
+ (NSString *)model;

/* Device model as enum. It is not recommended to branch on this; rather, use +coreCount or +adjustedFillRate */
+ (MPDeviceModel)deviceModel;

+ (NSString *)systemName;

+ (NSString *)systemVersion;

/* Device battery information. This is cached for performance. FBPerformanceMetrics batteryInfo has uncached values.*/
+ (MPDeviceBatteryInfo)deviceBatteryInfo;

/* Check if current device idiom is UIUserInterfaceIdiomPad */
+ (BOOL)isPad;

/* Number of hardware cores */
+ (uint)coreCount;

/**
 - Returns: The amount of unused disk space on the device.
 **/
+ (uint64_t)freeDiskSpace;

/* How much GPU power to expect per screen area */
+ (FBDeviceAdjustedFillRate)adjustedFillRate;

/* Amount of free physical memory in bytes */
+ (uint64_t)freeMemoryBytes;

/* Amount of total physical memory in bytes */
+ (uint64_t)totalMemoryBytes;

/* Return amount of free disk space, in bytes */
+ (uint64_t)freeDiskBytes;

// Don't use this. Instead gate on the CPU or GPU performance level you care about.
+ (BOOL)isSlowerDevice;

/* iPhone-only application running on an iPad in emulator mode */
+ (BOOL)isRunningOnPadInPhoneEmulator;

/**
 Compares the -[UIDevice systemVersion] to a string. e.g. [MPDevice systemVersionIsGreaterThanOrEqualTo:@"7.0.3"].
 If the system version is 7.0.2.1, an argument of @"7.0.3" will return YES.
 - Parameter version: The version number to compare. Passing nil will return NO.
 */
+ (BOOL)systemVersionIsGreaterThanOrEqualTo:(nullable NSString *)version;
+ (BOOL)systemVersionIsLessThan:(nullable NSString *)version;

/**
 Returns the OS build number (e.g. 14F1605)
 */
+ (NSString *)systemBuildNumber;

+ (BOOL)systemVersionIsGreaterThanOrEqualToiOS8;
+ (BOOL)systemVersionIsGreaterThanOrEqualToiOS9;
+ (BOOL)systemVersionIsGreaterThanOrEqualToiOS10;
+ (BOOL)systemVersionIsGreaterThanOrEqualToiOS11;

@end

NS_ASSUME_NONNULL_END

