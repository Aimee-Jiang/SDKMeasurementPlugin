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

#import "MPNotificationCenter.h"

#import <objc/runtime.h>

NS_ASSUME_NONNULL_BEGIN

@interface MPNotificationCenter ()

@property (nonatomic, strong) NSMutableArray *notifications;
@property (nonatomic, weak) id object;

@end

@implementation MPNotificationCenter

FB_FINAL_CLASS(objc_getClass("MPNotificationCenter"));

- (instancetype)init
{
  self = [super init];
  if (self) {
    _notifications = [NSMutableArray array];
  }
  return self;
}

- (NSNotificationCenter *)notificationCenter
{
  return [NSNotificationCenter defaultCenter];
}

- (void)addNotificationWithName:(nullable NSString *)name block:(void (^)(NSNotification *notification))block
{
  [self addNotificationWithName:name object:nil block:block];
}

- (void)addNotificationWithName:(nullable NSString *)name object:(nullable id)object block:(void (^)(NSNotification *notification))block
{
  [self addNotificationWithName:name object:object queue:[NSOperationQueue mainQueue] block:block];
}

- (void)addNotificationWithName:(nullable NSString *)name object:(nullable id)object queue:(NSOperationQueue *)queue block:(void (^)(NSNotification *notification))block
{
  NSParameterAssert(name);
  NSParameterAssert(block);
  
  id observer = [self.notificationCenter addObserverForName:name object:object queue:queue usingBlock:block];
  [self.notifications addObject:observer];
}

- (void)removeAllObservers
{
  for (id observer in self.notifications) {
    [self.notificationCenter removeObserver:observer];
  }
  [self.class setNotificationCenter:nil forObject:self.object];
}

+ (instancetype)notificationCenterForObject:(id)object
{
  return [self notificationCenterForObject:object update:YES];
}

+ (instancetype)notificationCenterForObject:(id)object update:(BOOL)shouldUpdate
{
  if (!object) {
    return nil;
  }
  MPNotificationCenter *notification = objc_getAssociatedObject(object, @selector(notificationCenterForObject:));
  if (shouldUpdate && !notification) {
    notification = [MPNotificationCenter new];
    [self setNotificationCenter:notification forObject:object];
  }
  return notification;
}

+ (void)setNotificationCenter:(nullable MPNotificationCenter *)notification forObject:(nullable id)object
{
  if (!object) {
    return;
  }
  objc_setAssociatedObject(MPUnwrap(object), @selector(notificationCenterForObject:), notification, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
  notification.object = object;
}

+ (void)removeAllObserversForObject:(nullable id)object
{
  if (object) {
    MPNotificationCenter *notification = [self notificationCenterForObject:MPUnwrap(object) update:NO];
    [notification removeAllObservers];
  }
}

- (void)dealloc
{
  [self removeAllObservers];
  [_notifications removeAllObjects];
}

@end

NS_ASSUME_NONNULL_END

