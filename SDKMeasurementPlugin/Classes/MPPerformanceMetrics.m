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

#import "MPPerformanceMetrics.h"

#import <ifaddrs.h>
#import <mach/mach.h>
#import <net/if.h>
#import <sys/sysctl.h>

NS_ASSUME_NONNULL_BEGIN

// Local redef to break deps
#define ARRAY_COUNT(x) sizeof(x) / sizeof(x[0])

#define task_basic_info_zero (struct task_basic_info){0, 0, 0, {0, 0}, {0, 0}, 0}

#pragma mark - Helper Functions

static uint FBReadSysCtlUInt(int ctl, int type)
{
  int mib[2] = {ctl, type};
  uint value;
  size_t size = sizeof value;
  if (0 != sysctl(mib, ARRAY_COUNT(mib), &value, &size, NULL, 0)) {
    return 0;
  }
  return value;
}

static uint64_t FBReadSysCtlUInt64(int ctl, int type)
{
  int mib[2] = {ctl, type};
  uint64_t value;
  size_t size = sizeof value;
  if (0 != sysctl(mib, ARRAY_COUNT(mib), &value, &size, NULL, 0)) {
    return 0;
  }
  return value;
}

#pragma mark - MPPerformanceMetrics

@implementation MPPerformanceMetrics

FB_FINAL_CLASS(objc_getClass("MPPerformanceMetrics"));

+ (uint)coreCount
{
  return FBReadSysCtlUInt(CTL_HW, HW_AVAILCPU);
}

+ (MPDeviceBatteryInfo)batteryInfo
{
  MPDeviceBatteryInfo info;
  
  if (![NSThread isMainThread]) {
    info.state = UIDeviceBatteryStateUnknown;
    info.level = -1;
    return info;
  }
  
  UIDevice *device = [UIDevice currentDevice];
  BOOL monitoring = device.batteryMonitoringEnabled;
  
  device.batteryMonitoringEnabled = YES;
  info.state = device.batteryState;
  info.level = device.batteryLevel;
  device.batteryMonitoringEnabled = monitoring;
  
  return info;
}

+ (uint64_t)freeMemoryBytes
{
  uint pageSize = FBReadSysCtlUInt(CTL_HW, HW_PAGESIZE);
  if (0 == pageSize) {
    return 0;
  }
  
  mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
  vm_statistics_data_t vmstat;
  if (KERN_SUCCESS != host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmstat, &count)) {
    return 0;
  }
  
  return vmstat.free_count * pageSize;
}

+ (uint64_t)totalMemoryBytes
{
  return FBReadSysCtlUInt64(CTL_HW, HW_MEMSIZE);
}

+ (uint64_t)residentMemoryBytes
{
  kern_return_t rval = 0;
  mach_port_t task = mach_task_self();
  
  struct task_basic_info info = task_basic_info_zero;
  mach_msg_type_number_t tcnt = TASK_BASIC_INFO_COUNT;
  task_flavor_t flavor = TASK_BASIC_INFO;
  
  task_info_t tptr = (task_info_t) &info;
  
  if (tcnt > sizeof(info))
    return 0;
  
  rval = task_info(task, flavor, tptr, &tcnt);
  if (rval != KERN_SUCCESS) {
    return 0;
  }
  
  return info.resident_size;
}

+ (uint64_t)virtualMemoryBytes
{
  kern_return_t rval = 0;
  mach_port_t task = mach_task_self();
  
  struct task_basic_info info = task_basic_info_zero;
  mach_msg_type_number_t tcnt = TASK_BASIC_INFO_COUNT;
  task_flavor_t flavor = TASK_BASIC_INFO;
  
  task_info_t tptr = (task_info_t) &info;
  if (tcnt > sizeof(info))
    return 0;
  
  rval = task_info(task, flavor, tptr, &tcnt);
  if (rval != KERN_SUCCESS) {
    return 0;
  }
  
  return info.virtual_size;
}

+ (uint64_t)freeDiskBytes
{
  return [MPPerformanceMetrics freeAndTotalDiskBytes].freeDiskBytes;
}

+ (FBFreeAndTotalDiskBytes)freeAndTotalDiskBytes
{
  FBFreeAndTotalDiskBytes ret = {0, 0};
  
  NSArray<NSString *> *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSDictionary<NSString *, id> *dictionary = [[NSFileManager defaultManager] attributesOfFileSystemForPath:MPUnwrap(paths.lastObject) error:nil];
  
  if (dictionary) {
    NSNumber *freeFileSystemSizeInBytes = dictionary[NSFileSystemFreeSize];
    ret.freeDiskBytes = freeFileSystemSizeInBytes.unsignedLongLongValue;
    
    ret.totalDiskBytes = [dictionary[NSFileSystemSize] unsignedLongLongValue];
  }
  
  return ret;
}

@end

NS_ASSUME_NONNULL_END

