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

#import "MPConcurrentArray.h"

#import <mutex>

#import "MPUtility.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPConcurrentArray ()
{
  std::recursive_mutex _storageLock;
}

@property (nonatomic, strong) NSMutableArray *storage;

@end

@implementation MPConcurrentArray

- (instancetype)init
{
  self = [super init];
  if (self) {
    _storage = [NSMutableArray array];
  }
  return self;
}

- (instancetype)initWithCapacity:(NSUInteger)numItems
{
  self = [super init];
  if (self) {
    _storage = [[NSMutableArray alloc] initWithCapacity:numItems];
  }
  return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)aDecoder
{
  self = [super init];
  if (self) {
    NSArray * __nullable storage = [[NSMutableArray alloc] initWithCoder:aDecoder];
    if (storage) {
      _storage = MPUnwrap(storage);
    } else {
      return nil;
    }
  }
  return self;
}

+ (instancetype)array
{
  return [self new];
}

+ (instancetype)arrayWithCapacity:(NSUInteger)numItems
{
  return [(MPConcurrentArray *)[self alloc] initWithCapacity:numItems];
}

- (NSUInteger)count
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  return self.storage.count;
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state
                                  objects:(id __nullable __unsafe_unretained [])buffer
                                    count:(NSUInteger)len
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  return [self.storage countByEnumeratingWithState:state
                                           objects:buffer
                                             count:len];
}

- (nullable id)objectAtIndex:(NSUInteger)index
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  return(self.storage)[index];
}

- (void)addObject:(id)anObject
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  [self.storage addObject:anObject];
}

- (void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  [self.storage insertObject:anObject atIndex:index];
}

- (void)removeLastObject
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  [self.storage removeLastObject];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  [self.storage removeObjectAtIndex:index];
}

- (void)removeObjectIdenticalTo:(id)anObject
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  [self.storage removeObjectIdenticalTo:anObject];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)anObject
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  (self.storage)[index] = anObject;
}

- (void)removeObject:(id)anObject
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  [self.storage removeObject:anObject];
}

- (void)removeAllObjects
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  [self.storage removeAllObjects];
}

- (nullable id)objectAtIndexedSubscript:(NSUInteger)idx
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  return [self.storage objectAtIndexedSubscript:idx];
}

- (void)setObject:(id)obj atIndexedSubscript:(NSUInteger)idx
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  [self.storage setObject:obj atIndexedSubscript:idx];
}

- (NSArray *)nonConcurrentCopy
{
  std::lock_guard<std::recursive_mutex> lock(_storageLock);
  return [self.storage copy];
}

@end

NS_ASSUME_NONNULL_END

