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

#import "MPConcurrentQueue.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPConcurrentQueue ()

@property (nonatomic, strong) NSMutableArray *storage;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation MPConcurrentQueue

FB_FINAL_CLASS(objc_getClass("MPConcurrentQueue"));

- (instancetype)init
{
  self = [super init];
  if (self) {
    _queue = dispatch_queue_create("com.facebook.ads.util.queue", DISPATCH_QUEUE_SERIAL);
    _storage = [NSMutableArray array];
  }
  return self;
}

- (void)pushObject:(id)object
{
  dispatch_async(self.queue, ^{
    [self.storage addObject:object];
  });
}

- (void)pop:(void (^)(id object))block
{
  dispatch_async(self.queue, ^{
    id object = self.storage.firstObject;
    [self.storage removeObject:object];
    if (block) {
      block(object);
    }
  });
}

- (void)peek:(void (^)(id object))block
{
  dispatch_async(self.queue, ^{
    id object = self.storage.firstObject;
    if (block) {
      block(object);
    }
  });
}

- (void)popAll:(void (^)(NSEnumerator<id> *enumerator))block
{
  dispatch_async(self.queue, ^{
    NSEnumerator *enumerator = [[self.storage copy] objectEnumerator];
    [self.storage removeAllObjects];
    if (block) {
      block(enumerator);
    }
  });
}

@end

NS_ASSUME_NONNULL_END
