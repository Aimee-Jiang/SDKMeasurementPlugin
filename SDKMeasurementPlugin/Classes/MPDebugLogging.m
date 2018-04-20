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

#import "MPDebugLogging.h"

#import "MPDevice.h"
#import "MPEventManager.h"

#define FB_AD_SDK_VERSION @"4.28.0"

NS_ASSUME_NONNULL_BEGIN

@implementation NSMutableDictionary (MPDebugLogging)

- (void)adnw_setNonNilObject:(nullable id)anObject forKey:(id<NSCopying>)aKey
{
  if (nil != anObject) {
    [self setObject:(id _Nonnull)anObject forKey:aKey];
  }
}

- (void)adnw_setNullStringIfNilObject:(nullable id)anObject forKey:(id<NSCopying>)aKey
{
  if (nil != anObject) {
    [self setObject:(id _Nonnull)anObject forKey:aKey];
  }
  else {
    [self setObject:@"null" forKey:aKey];
  }
}

- (void)adnw_setNullStringIfNullCharPointer:(nullable const char *)aCharPointer forKey:(id<NSCopying>)aKey
{
  NSString *string = (NULL != aCharPointer) ? [NSString stringWithUTF8String:(const char * _Nonnull)aCharPointer] : nil;
  [self adnw_setNullStringIfNilObject:string forKey:aKey];
}

@end

@implementation MPDebugLogging

FB_FINAL_CLASS(objc_getClass("MPServerLogging"));

+ (nonnull NSString *)subtypeStringForDebugEventType:(MPDebugEventType)type
{
  NSString *result = nil;
  switch (type) {
    case MPDebugEventTypeGeneric:
      result = @"generic";
      break;
    case MPDebugEventTypeDatabase:
      result = @"database";
      break;
      
    case MPDebugEventTypeParsing:
      result = @"parsing";
      break;
      
    default:
      result = @"generic";
      break;
  }
  
  return result;
}

+ (void)logDebugEventWithType:(MPDebugEventType)type info:(nullable NSDictionary<NSString *, id> *)info
{
  NSMutableDictionary<NSString *, NSString *> *data = [[NSMutableDictionary alloc] initWithObjectsAndKeys:@"iOS", @"user_os", nil];
  [data setObject:[NSString stringWithFormat:@"%llu", [MPDevice freeDiskSpace]] forKey:@"available_disk_space"];
  [data setObject:FB_AD_SDK_VERSION forKey:@"sdk_version"];
  [data setObject:[self subtypeStringForDebugEventType:type] forKey:@"subtype"];
  [data adnw_setNonNilObject:[[NSBundle mainBundle] bundleIdentifier] forKey:@"bundle_package_name"];
  [data adnw_setNonNilObject:[MPDevice machine] forKey:@"device_marketing_name"];
  [data adnw_setNonNilObject:[MPDevice systemVersion] forKey:@"os_version"];
  
  NSString *JSONString = [MPUtility getJSONStringFromObject:info];
  [data adnw_setNonNilObject:JSONString forKey:@"info"];
  
  [[MPEventManager sharedManager] logDebugEventWithExtraData:data];
}

+ (void)logGenericDebugEventWithMessage:(nonnull NSString *)message
{
  [self logDebugEventWithType:MPDebugEventTypeGeneric info:@{@"message" : message}];
}

+ (void)logDatabaseDebugEventWithCode:(MPDatabaseDebugEventCode)code info:(nullable NSDictionary<NSString *, id> *)info
{
  NSMutableDictionary<NSString *, id> *mutableInfo = (nil != info) ? [info mutableCopy] : [[NSMutableDictionary alloc] init];
  mutableInfo[@"code"] = [NSString stringWithFormat:@"%lu", (unsigned long)code];
  [self logDebugEventWithType:MPDebugEventTypeDatabase info:mutableInfo];
}

+ (void)logDatabaseDebugEventWithCode:(MPDatabaseDebugEventCode)code errorDescription:(nullable NSString *)errorDescription
{
  NSMutableDictionary<NSString *, NSString *> *info = [NSMutableDictionary new];
  [info adnw_setNullStringIfNilObject:errorDescription forKey:@"description"];
  [MPDebugLogging logDatabaseDebugEventWithCode:code info:info];
}

+ (void)logParsingDebugEventWithCode:(MPParsingDebugEventCode)code info:(nullable NSDictionary<NSString *, id> *)info
{
  NSMutableDictionary<NSString *, id> *mutableInfo = (nil != info) ? [info mutableCopy] : [[NSMutableDictionary alloc] init];
  mutableInfo[@"code"] = [NSString stringWithFormat:@"%lu", (unsigned long)code];
  [self logDebugEventWithType:MPDebugEventTypeParsing info:mutableInfo];
}

@end

NS_ASSUME_NONNULL_END

