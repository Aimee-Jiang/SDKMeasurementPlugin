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
#import "MPDefines+Internal.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, MPDebugEventType) {
  MPDebugEventTypeGeneric = 0,
  MPDebugEventTypeDatabase,
  MPDebugEventTypeParsing,
};

typedef NS_ENUM(NSUInteger, MPDatabaseDebugEventCode) {
  MPDatabaseDebugEventCodeUnknown = 0,
  MPDatabaseDebugEventCodeCannotDeserializeEvent,
  MPDatabaseDebugEventCodeCannotDeserializeToken,
  MPDatabaseDebugEventCodeCannotInsertEvent,
  MPDatabaseDebugEventCodeCannotInsertToken,
  MPDatabaseDebugEventCodeCannotDeleteEvent,
  MPDatabaseDebugEventCodeCannotDeleteToken,
  MPDatabaseDebugEventCodeCannotOpenDatabase,
  MPDatabaseDebugEventCodeCannotMigrateV1toV2,
};

typedef NS_ENUM(NSUInteger, MPParsingDebugEventCode) {
  MPParsingDebugEventCodeUnknown = 0,
};

@interface NSMutableDictionary<KeyType, ObjectType> (MPDebugLogging)

- (void)adnw_setNonNilObject:(nullable ObjectType)anObject forKey:(KeyType<NSCopying>)aKey;
- (void)adnw_setNullStringIfNilObject:(nullable ObjectType)anObject forKey:(KeyType<NSCopying>)aKey;
- (void)adnw_setNullStringIfNullCharPointer:(nullable const char *)aCharPointer forKey:(KeyType<NSCopying>)aKey;

@end

FB_SUBCLASSING_RESTRICTED
@interface MPDebugLogging : NSObject

+ (void)logDebugEventWithType:(MPDebugEventType)type info:(nullable NSDictionary<NSString *, id> *)info;
+ (void)logGenericDebugEventWithMessage:(nonnull NSString *)message;
+ (void)logDatabaseDebugEventWithCode:(MPDatabaseDebugEventCode)code errorDescription:(nullable NSString *)errorDescription;
+ (void)logDatabaseDebugEventWithCode:(MPDatabaseDebugEventCode)code info:(nullable NSDictionary<NSString *, id> *)info;
+ (void)logParsingDebugEventWithCode:(MPParsingDebugEventCode)code info:(nullable NSDictionary<NSString *, id> *)info;

@end

NS_ASSUME_NONNULL_END


