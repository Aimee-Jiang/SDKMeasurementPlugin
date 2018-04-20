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

#import "MPDevice.h"

#import <dirent.h>
#import <libkern/OSAtomic.h>
#import <sys/sysctl.h>

#import "MPDynamicFrameworkLoader.h"
#import "MPMonotonicTime.h"
#import "MPPerformanceMetrics.h"

NS_ASSUME_NONNULL_BEGIN

#define FB_DEVICE_BATTERY_INFO_CACHE_TTL 180.0f
#define FB_FREE_MEMORY_CACHE_TTL 60.0f
#define FB_TOTAL_MEMORY_CACHE_TTL 180.0f
#define FB_FREE_DISK_CACHE_TTL 180.0f

#define ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])

#pragma mark - Helper Functions

static void cleanInfoString(NSMutableString *str)
{
  for (NSString *replaceChar in @[@" ", @"/", @"\0"]) {
    [str replaceOccurrencesOfString:replaceChar
                         withString:@""
                            options:(NSStringCompareOptions)0
                              range:NSMakeRange(0, str.length)];
  }
}

static NSMutableString *readSysCtlString(int ctl, int type, size_t size)
{
  int mib[2] = {ctl, type};
  
  // If no size is passed in, set 'oldp' parameter to NULL to get the size of the data
  // returned so we can allocate appropriate amount of space.
  if (size == 0 && sysctl(mib, ARRAY_COUNT(mib), NULL, &size, NULL, 0) != 0) {
    return nil;
  }
  
  char *value = (char *)malloc(size);
  int result = sysctl(mib, ARRAY_COUNT(mib), value, &size, NULL, 0);
  
  // ENOMEM will be returned when the rqeuested value is longer than the size
  // provided. This means the size originally passed in is smaller than we expected,
  // but we should probably ignore this failure.
  if (result != 0 && result != ENOMEM) {
    free(value);
    return nil;
  }
  
  return (id)[[NSMutableString alloc] initWithBytesNoCopy:value
                                                   length:size
                                                 encoding:NSASCIIStringEncoding
                                             freeWhenDone:YES];
}

#pragma mark - FBDevice

// cached values
static NSString * __nullable _machine;
static NSString * __nullable _machineName;
static NSString * __nullable _architecture;
static NSString * __nullable _model;
static NSString * __nullable _systemName;
static NSString * __nullable _systemVersion;
static uint _coreCount;
static NSUInteger _adjustedFillRate;
static NSUInteger _deviceModel;
static MPDeviceBatteryInfo _deviceBatteryInfo;
static NSInteger _isSlowerDevice;
static NSInteger _isPad;
static uint64_t _freeMemoryBytes;
static uint64_t _totalMemoryBytes;
static uint64_t _freeDiskBytes;
static NSInteger _supportsPhone;

@implementation MPDevice

+ (NSRecursiveLock *)sharedLock
{
  return FB_INITIALIZE_AND_RETURN_STATIC([NSRecursiveLock new]);
}

+ (void)initialize
{
  FB_FINAL_CLASS_INITIALIZE_IMP(([MPDevice class]));
  if (self == [MPDevice class]) {
    [self resetCache];
  }
}

+ (void)initializeAndCacheValues
{
  FBAssertNotMainThread();
  [self isPad];
  [self systemVersion];
}

+ (void)resetCache
{
  [[self sharedLock] lock];
  _machine = nil;
  _machineName = nil;
  _architecture = nil;
  _model = nil;
  _systemName = nil;
  _systemVersion = nil;
  _adjustedFillRate = NSUIntegerMax;
  _deviceModel = NSUIntegerMax;
  _deviceBatteryInfo.state = UIDeviceBatteryStateUnknown;
  _deviceBatteryInfo.level = -1;
  _coreCount = UINT_MAX;
  _freeMemoryBytes = 0;
  _totalMemoryBytes = 0;
  _freeDiskBytes = 0;
  _isSlowerDevice = -1;
  _isPad = -1;
  _supportsPhone = -1;
  [[self sharedLock] unlock];
}

+ (NSString *)machine
{
  [[self sharedLock] lock];
  if (nil == _machine) {
    NSMutableString *hwMachine = readSysCtlString(CTL_HW, HW_MACHINE, 32);
    cleanInfoString(hwMachine);
    _machine = [hwMachine copy];
  }
  NSString *machine = MPUnwrap(_machine);
  [[self sharedLock] unlock];
  return machine;
}

+ (NSString *)machineName
{
  return [self machine];
}

+ (NSString *)architecture
{
  return [self machine];
}

+ (NSString *)model
{
  [[self sharedLock] lock];
  if (nil == _model) {
    NSMutableString *hwModel = readSysCtlString(CTL_HW, HW_MODEL, 0);
    cleanInfoString(hwModel);
    _model = [hwModel copy];
  }
  NSString *model = MPUnwrap(_model);
  [[self sharedLock] unlock];
  return model;
}

static MPDeviceModel device_model(NSString *machine)
{
  NSInteger subModel = 999;
  NSArray *nameAndSubmodel = [machine componentsSeparatedByString:@","];
  
  if (nameAndSubmodel.count > 1) {
    subModel = [nameAndSubmodel[1] integerValue];
  }
  
  if ([machine hasPrefix:@"iPhone2"]) return MPDeviceModeliPhone3GS;
  if ([machine hasPrefix:@"iPhone3"]) return MPDeviceModeliPhone4;
  if ([machine hasPrefix:@"iPhone4"]) return MPDeviceModeliPhone4S;
  if ([machine hasPrefix:@"iPhone5"]) return MPDeviceModeliPhone5;
  if ([machine hasPrefix:@"iPhone6"]) return MPDeviceModeliPhone5S;
  if ([machine hasPrefix:@"iPhone7"]) return subModel > 1 ? MPDeviceModeliPhone6 : MPDeviceModeliPhone6Plus;
  if ([machine hasPrefix:@"iPhone10"]) {
    if (subModel == 3 || subModel == 6) return MPDeviceModeliPhoneX;
  }
  
  if ([machine hasPrefix:@"iPod3"]) return MPDeviceModeliPod3G;
  if ([machine hasPrefix:@"iPod4"]) return MPDeviceModeliPod4G;
  if ([machine hasPrefix:@"iPod5"]) return MPDeviceModeliPod5G;
  
  if ([machine hasPrefix:@"iPad1"]) return MPDeviceModeliPad1;
  
  // If we don't recognize the submodel then we assume it is the latest model
  if ([machine hasPrefix:@"iPad2"]) return subModel > 4 ? MPDeviceModeliPadMini1 : MPDeviceModeliPad2;
  if ([machine hasPrefix:@"iPad3"]) return subModel > 3 ? MPDeviceModeliPad4 : MPDeviceModeliPad3;
  if ([machine hasPrefix:@"iPad4"]) return subModel > 3 ? MPDeviceModeliPadMini2 : MPDeviceModeliPadA7;
  if ([machine hasPrefix:@"iPad5"]) return MPDeviceModeliPadAir2;
  if ([machine hasPrefix:@"x86"]) return MPDeviceModeliOSSimulator;
  
  return MPDeviceModelUnknown;
}

+ (MPDeviceModel)deviceModel
{
  [[self sharedLock] lock];
  if (NSUIntegerMax == _deviceModel) {
    _deviceModel = device_model([self machine]);
  }
  MPDeviceModel deviceModel = (MPDeviceModel)_deviceModel;
  [[self sharedLock] unlock];
  return deviceModel;
}

+ (NSString *)systemName
{
  [[self sharedLock] lock];
  if (nil == _systemName) {
    FBAssertMainThread();
    _systemName = [UIDevice currentDevice].systemName;
  }
  NSString *systemName = MPUnwrap(_systemName);
  [[self sharedLock] unlock];
  return systemName;
}

/**
 Congratulations! You have discovered a very terrible hack. The Very Bad Things contained herein are, unfortunately,
 necessary to support iPhone-only applications that use +isPad from any initialization context that happens before UIKit
 sets the proper value, i.e. from within +initialize, +load, or a constructor-attributed static method.
 
 Problem:  When called from +initialize, [[UIDevice currentDevice] userInterfaceIdiom] returns a naive answer that
 doesn't account for the application's device support.
 Solution: Read the info plist for the UIDeviceFamily key. Xcode automatically inserts this into the plist based on the
 project's setting, so it's expected to be there in an app compiled by Xcode. If the iPad is supported, the
 naive answer is also the correct one. Otherwise, if the application does not declare iPad support, isPad
 should always return NO.
 
 Problem:  The UIDeviceFamily key can be either an array or a string, but the documentation incorrectly claims it can be
 either an array or a *number*. On the other hand, when it is an array, the members are indeed numbers.
 Solution: Be very cautious and check against both NSString and NSNumber.
 
 Problem:  There is no UIDeviceFamily key in the info dictionary. This can happen when, for example, you are running a
 test, rather than an application, or very old versions of iOS, or if your build process somehow skips adding
 the key like Xcode is expected to.
 Solution: Assume the iPad is not supported by default. If no case checking the key hits, then we don't want the app to
 run as an iPad app.
 */
+ (BOOL)isPad
{
  [[self sharedLock] lock];
  if (_isPad < 0) {
    // The non-cached implementation is only safe to call on the main thread. To be able to call
    // this method on a background thread, the value must be precalcaculated and cached by first
    // calling +initializeAndCacheValues on the main thread (ie, during app startup).
    FBAssertNotMainThread();
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
      // DO NOT CHANGE THIS TO objectForInfoDictionaryKey:. That will setup the CF device language cache
      // **before** we are able to modify it as we want. Set a breakpoint in CFPreferencesCopyAppValue
      // and change this method and you can see the backtrace of CF loading the current locale too early.
      // (This only matters because of the hacks in Cajmere to be English-only; see FBForceEnglish.m.)
      NSObject *deviceFamily = [NSBundle mainBundle].infoDictionary[@"UIDeviceFamily"];
      
      BOOL padIsSupported = NO;
      if ([deviceFamily isKindOfClass:[NSArray class]]) {
        if ([(NSArray *)deviceFamily containsObject:@2]) {
          // Expected: value is a number when inside an array
          padIsSupported = YES;
        } else if ([(NSArray *)deviceFamily containsObject:@"2"]) {
          // Guard against unexpected case: value is a string when inside an array
          padIsSupported = YES;
        }
      } else if ([deviceFamily isKindOfClass:[NSString class]]) {
        // Expected: value is a string when it's the only supported device family
        padIsSupported = [(NSString *)deviceFamily isEqualToString:@"2"];
      } else if ([deviceFamily isKindOfClass:[NSNumber class]]) {
        // Guard against unexpected case: value is a number when it's the only supported device family
        padIsSupported = [(NSNumber *)deviceFamily isEqualToNumber:@2];
      }
      _isPad = padIsSupported;
    } else {
      _isPad = NO;
    }
  }
  BOOL isPad = _isPad;
  [[self sharedLock] unlock];
  return 0 != isPad;
}

+ (uint)coreCount
{
  [[self sharedLock] lock];
  if (UINT_MAX == _coreCount) {
    _coreCount = [MPPerformanceMetrics coreCount];
  }
  uint coreCount = _coreCount;
  [[self sharedLock] unlock];
  return coreCount;
}

+ (uint64_t)freeDiskSpace
{
  return [MPPerformanceMetrics freeDiskBytes];
}

static FBDeviceAdjustedFillRate fill_rate(MPDeviceModel model)
{
  switch (model) {
      //iPhone 4/3GS, iPad 3, iPod touch 4
    case MPDeviceModeliPhone3GS:
    case MPDeviceModeliPhone4:
    case MPDeviceModeliPad1:
    case MPDeviceModeliPad3:
    case MPDeviceModeliPod3G:
    case MPDeviceModeliPod4G:
      return FBDeviceAdjustedFillRateAbysmal;
      
    case MPDeviceModeliPhone4S:
    case MPDeviceModeliPod5G:
    case MPDeviceModeliPad2:
    case MPDeviceModeliPadMini1:
      return FBDeviceAdjustedFillRateLow;
      
    case MPDeviceModeliPhone5:
    case MPDeviceModeliPad4:
    case MPDeviceModeliOSSimulator:
      return FBDeviceAdjustedFillRateMedium;
      
    case MPDeviceModeliPhone5S:
    case MPDeviceModeliPhone6:
    case MPDeviceModeliPhone6Plus:
    case MPDeviceModeliPadA7:
    case MPDeviceModeliPadAir2:
    case MPDeviceModeliPadMini2:
    case MPDeviceModeliPhoneX:
      return FBDeviceAdjustedFillRateHigh;
      
    case MPDeviceModelUnknown:
      return FBDeviceAdjustedFillRateUnknown;
  }
  
  return FBDeviceAdjustedFillRateUnknown;
}

+ (FBDeviceAdjustedFillRate)adjustedFillRate
{
  [[self sharedLock] lock];
  if (NSUIntegerMax == _adjustedFillRate) {
    _adjustedFillRate = fill_rate([self deviceModel]);
  }
  FBDeviceAdjustedFillRate adjustedFillRate = (FBDeviceAdjustedFillRate)_adjustedFillRate;
  [[self sharedLock] unlock];
  return adjustedFillRate;
}

+ (MPDeviceBatteryInfo)deviceBatteryInfo
{
  [[self sharedLock] lock];
  static FBMonotonicTimeSeconds lastCachedTime = 0;
  
  FBMonotonicTimeSeconds currentTime = FBMonotonicTimeGetCurrentSeconds();
  
  if ( (currentTime - lastCachedTime) > FB_DEVICE_BATTERY_INFO_CACHE_TTL ) {
    
    // We cannot get valid battery info off the main thread.
    // We can cache the unknown battery state, but set the ttl to zero so it will refresh next opportunity.
    if (![NSThread isMainThread]) {
      lastCachedTime = 0;
    } else {
      lastCachedTime = currentTime;
    }
    _deviceBatteryInfo = [MPPerformanceMetrics batteryInfo];
  }
  MPDeviceBatteryInfo deviceBatteryInfo = _deviceBatteryInfo;
  [[self sharedLock] unlock];
  return deviceBatteryInfo;
}

+ (uint64_t)freeMemoryBytes
{
  [[self sharedLock] lock];
  static CFTimeInterval lastCachedTime = 0;
  
  CFTimeInterval currentTime = mpsdk_dfl_CACurrentMediaTime();
  
  if ( (currentTime - lastCachedTime) > FB_FREE_MEMORY_CACHE_TTL ) {
    if (![NSThread isMainThread]) {
      lastCachedTime = 0;
    } else {
      lastCachedTime = currentTime;
    }
    _freeMemoryBytes = [MPPerformanceMetrics freeMemoryBytes];
  }
  uint64_t freeMemoryBytes = _freeMemoryBytes;
  [[self sharedLock] unlock];
  return freeMemoryBytes;
}

+ (uint64_t)totalMemoryBytes
{
  [[self sharedLock] lock];
  static CFTimeInterval lastCachedTime = 0;
  
  CFTimeInterval currentTime = mpsdk_dfl_CACurrentMediaTime();
  
  if ( (currentTime - lastCachedTime) > FB_TOTAL_MEMORY_CACHE_TTL ) {
    if (![NSThread isMainThread]) {
      lastCachedTime = 0;
    } else {
      lastCachedTime = currentTime;
    }
    _totalMemoryBytes = [MPPerformanceMetrics totalMemoryBytes];
  }
  uint64_t totalMemoryBytes = _totalMemoryBytes;
  [[self sharedLock] unlock];
  return totalMemoryBytes;
}

+ (uint64_t)freeDiskBytes
{
  [[self sharedLock] lock];
  static CFTimeInterval lastCachedTime = 0;
  
  CFTimeInterval currentTime = mpsdk_dfl_CACurrentMediaTime();
  
  if ( (currentTime - lastCachedTime) > FB_FREE_DISK_CACHE_TTL ) {
    if (![NSThread isMainThread]) {
      lastCachedTime = 0;
    } else {
      lastCachedTime = currentTime;
    }
    _freeDiskBytes = [MPPerformanceMetrics freeDiskBytes];
  }
  uint64_t freeDiskBytes = _freeDiskBytes;
  [[self sharedLock] unlock];
  return freeDiskBytes;
}

/*
 * Returns YES if the device is on the slower end of the iOS spectrum (iPad 1, iPhone 3GS, iPhone 4, or iPod 3).
 */
+ (BOOL)isSlowerDevice
{
  [[self sharedLock] lock];
  if (_isSlowerDevice < 0) {
    MPDeviceModel deviceModel = [self deviceModel];
    _isSlowerDevice = deviceModel == MPDeviceModeliPad1
    || deviceModel == MPDeviceModeliPhone3GS
    || deviceModel == MPDeviceModeliPhone4
    || deviceModel == MPDeviceModeliPhone4S
    || deviceModel == MPDeviceModeliPod3G;
  }
  BOOL isSlowerDevice = _isSlowerDevice;
  [[self sharedLock] unlock];
  return 0 != isSlowerDevice;
}

+ (BOOL)isRunningOnPadInPhoneEmulator
{
  return [[UIDevice currentDevice].model hasPrefix:@"iPad"] && ![MPDevice isPad];
}

NS_INLINE NSIndexPath *_indexPathFromVersionStringComponents(NSArray *components, NSUInteger padding) {
  const NSUInteger count = components.count + padding;
  NSUInteger *indexes = (NSUInteger *)calloc(count, sizeof(NSUInteger));
  NSInteger i = 0;
  for (NSString *component in components) {
    // Static analysis wants us to make surely sure that indexes is properly allocated...
    if (indexes != nil) {
      indexes[i++] = (NSUInteger)MAX([component integerValue], 0); // -unsignedIntegerValue doesn't exist :(
    }
  }
  // An NSIndexPath of {7} != {7, 0}, but we want @"7" == @"7.0". So we pad the shorter with zeros.
  for (NSUInteger j = 0 ; j < padding ; ++j) {
    indexes[i++] = 0;
  }
  NSIndexPath *indexPath = [NSIndexPath indexPathWithIndexes:indexes length:count];
  free(indexes);
  return indexPath;
}

+ (NSString *)systemVersion
{
  [[self sharedLock] lock];
  if (_systemVersion == nil) {
    _systemVersion = [UIDevice currentDevice].systemVersion;
  }
  NSString *systemVersion = MPUnwrap(_systemVersion);
  [[self sharedLock] unlock];
  return systemVersion;
}

+ (NSString *)systemBuildNumber
{
  NSMutableString *osVersion = readSysCtlString(CTL_KERN, KERN_OSVERSION, 16);
  cleanInfoString(osVersion);
  return osVersion;
}

+ (BOOL)systemVersionIsGreaterThanOrEqualTo:(nullable NSString *)version
{
  if (version == nil) {
    return NO;
  }
  
  static NSCharacterSet *nonDecimalSet = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    nonDecimalSet = [NSCharacterSet decimalDigitCharacterSet].invertedSet;
  });
  
  NSArray *argumentComponents = [version componentsSeparatedByString:@"."];
  for (NSString *component in argumentComponents) {
    FBArgumentPreconditionCheckIf([component length] > 0, @"Invalid version number");
    FBArgumentPreconditionCheckIf([component rangeOfCharacterFromSet:nonDecimalSet].location == NSNotFound, @"Invalid version number.");
  }
  
  NSArray *systemComponents = [[self systemVersion] componentsSeparatedByString:@"."];
  NSUInteger systemPadding = (argumentComponents.count > systemComponents.count) ? argumentComponents.count - systemComponents.count : 0;
  NSUInteger argumentPadding = (systemComponents.count > argumentComponents.count) ? systemComponents.count - argumentComponents.count : 0;
  NSComparisonResult result = [_indexPathFromVersionStringComponents(systemComponents, systemPadding) compare:_indexPathFromVersionStringComponents(argumentComponents, argumentPadding)];
  return (result == NSOrderedDescending /* LHS > RHS */ ||
          result == NSOrderedSame);
}

+ (BOOL)systemVersionIsLessThan:(nullable NSString *)version
{
  return ![self systemVersionIsGreaterThanOrEqualTo:version];
}

+ (BOOL)systemVersionIsGreaterThanOrEqualToiOS8
{
  return FB_INITIALIZE_AND_RETURN_STATIC([self systemVersionIsGreaterThanOrEqualTo:@"8.0"]);
}

+ (BOOL)systemVersionIsGreaterThanOrEqualToiOS9
{
  return FB_INITIALIZE_AND_RETURN_STATIC([self systemVersionIsGreaterThanOrEqualTo:@"9.0"]);
}

+ (BOOL)systemVersionIsGreaterThanOrEqualToiOS10
{
  return FB_INITIALIZE_AND_RETURN_STATIC([self systemVersionIsGreaterThanOrEqualTo:@"10.0"]);
}

+ (BOOL)systemVersionIsGreaterThanOrEqualToiOS11
{
  return FB_INITIALIZE_AND_RETURN_STATIC([self systemVersionIsGreaterThanOrEqualTo:@"11.0"]);
}

@end

NS_ASSUME_NONNULL_END

