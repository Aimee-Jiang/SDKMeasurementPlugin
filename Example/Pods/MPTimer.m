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

#import "MPTimer.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPTimer ()

@property (atomic, strong, readwrite, nullable) dispatch_source_t timer;
@property (nonatomic, copy, readwrite) dispatch_block_t block;
@property (nonatomic, copy, readwrite) fb_timer_block innerBlock;
@property (nonatomic, copy, readwrite) BOOL (^condition)(void);
@property (nonatomic, strong, readwrite, nullable) dispatch_queue_t queue;
@property (nonatomic, assign, readwrite) NSTimeInterval timeInterval;
@property (nonatomic, assign, readwrite) BOOL repeats;

@end

dispatch_source_t FBDispatchTimerMake(NSTimeInterval interval, dispatch_queue_t queue, dispatch_block_t block);

dispatch_source_t FBDispatchTimerMake(NSTimeInterval interval, dispatch_queue_t queue, dispatch_block_t block)
{
  dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
  if (timer)
  {
    dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(interval * NSEC_PER_SEC)), (uint64_t)(interval * NSEC_PER_SEC), (1ull * NSEC_PER_SEC) / 10);
    dispatch_source_set_event_handler(timer, block);
    dispatch_resume(timer);
  }
  return timer;
}

@implementation MPTimer

FB_FINAL_CLASS(objc_getClass("MPTimer"));

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo block:(fb_timer_block)block
{
  return [self scheduledTimerWithTimeInterval:ti repeats:yesOrNo queue:dispatch_get_main_queue() block:block];
}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeats:(BOOL)yesOrNo queue:(dispatch_queue_t)queue block:(fb_timer_block)block
{
  return [[self new] scheduledTimerWithTimeInterval:ti repeatsUntilCondition:^BOOL(MPTimer *timer){
    return !yesOrNo;
  } queue:queue block:block];}

+ (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeatsUntilCondition:(fb_timer_condition_block)condition queue:(dispatch_queue_t)queue block:(fb_timer_block)block
{
  return [[self new] scheduledTimerWithTimeInterval:ti repeatsUntilCondition:condition queue:queue block:block];
}

- (instancetype)scheduledTimerWithTimeInterval:(NSTimeInterval)ti repeatsUntilCondition:(fb_timer_condition_block)condition queue:(dispatch_queue_t)queue block:(fb_timer_block)block
{
  fb_timer_block passedBlock = [block copy];
  dispatch_block_t wrapperBlock = nil;
  weakify(passedBlock);
  weakify(self);
  wrapperBlock = ^{
    strongify(self);
    strongify(passedBlock);
    if ([self isValid] && passedBlock) {
      passedBlock(self);
    }
    if (condition && condition(self)) {
      [self invalidate];
    }
  };
  _innerBlock = passedBlock;
  
  if (!queue) {
    queue = dispatch_get_main_queue();
  }
  _queue = queue;
  
  self.timer = FBDispatchTimerMake(ti, queue, wrapperBlock);
  _block = wrapperBlock;
  _timeInterval = ti;
  
  return self;
}

- (void)invalidate
{
  dispatch_source_t timer = self.timer;
  if (timer) {
    dispatch_source_cancel(MPUnwrap(timer));
    self.timer = nil;
  }
  _userInfo = nil;
  _innerBlock = nil;
  _block = nil;
  _condition = nil;
  _queue = nil;
}

- (BOOL)isValid
{
  return (self.timer != nil);
}

- (void)dealloc
{
  [self invalidate];
}

- (void)fire
{
  if (self.valid && self.block) {
    dispatch_async(_queue ? MPUnwrap(_queue) : dispatch_get_main_queue(), ^{
      FB_BLOCK_CALL_SAFE(self.block);
    });
  }
}


@end

NS_ASSUME_NONNULL_END

