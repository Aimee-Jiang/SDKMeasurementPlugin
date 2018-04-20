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

#import "MPDefines+Internal.h"

NS_ASSUME_NONNULL_BEGIN

/*
 MPPerformanceMetrics provides raw access to make performance-related datasources.
 Note that many of these require syscalls that can be relatively expensive (milliseconds).
 Be wary of this if you want to call these from performance sensitive contexts.
 */

typedef struct MPDeviceBatteryInfo {
  UIDeviceBatteryState state;
  CGFloat level;
} MPDeviceBatteryInfo;

typedef struct {
  uint64_t bytesSent;
  uint64_t bytesReceived;
} FBNetworkUsage;

typedef struct {
  uint64_t freeDiskBytes;
  uint64_t totalDiskBytes;
} FBFreeAndTotalDiskBytes;

FB_SUBCLASSING_RESTRICTED
@interface MPPerformanceMetrics : NSObject

/* Number of hardware cores */
+ (uint)coreCount;

/* Returns the battery state and level after enabling monitory, if necessary */
+ (MPDeviceBatteryInfo)batteryInfo;

/* Amount of free physical memory in bytes */
+ (uint64_t)freeMemoryBytes;

/* Amount of total physical memory in bytes */
+ (uint64_t)totalMemoryBytes;

/* Return amount of free disk space, in bytes */
+ (uint64_t)freeDiskBytes;

@end

NS_ASSUME_NONNULL_END

