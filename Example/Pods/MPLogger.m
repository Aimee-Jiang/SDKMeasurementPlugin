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

#import "MPLogger.h"

#import "MPSettings+Internal.h"
#import "MPUtility.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const MPLogString = @"[FBAudienceNetworkLog/%@:%d thread:%ld%@] %@";


NSString *fb_ad_level_to_string(int level)
{
  // Note: leading space is purposeful
  switch (level) {
    case MPLogLevelNotification: return @"";
    case MPLogLevelError: return @" <error>";
    case MPLogLevelWarning: return @" <warn>";
    case MPLogLevelLog: return @" <log>";
    case MPLogLevelVerbose: return @" <verbose>";
    case MPLogLevelDebug: return @" <debug>";
    default: return @"";
  }
}

@implementation MPLogger

FB_FINAL_CLASS(objc_getClass("MPLogger"));

+ (void)logAtLevel:(int)level
              file:(const char *)file
        lineNumber:(int)lineNumber
            format:(NSString *)format, ... NS_FORMAT_FUNCTION(4,5)
{
  if ([MPSettings getLogLevel] >= level) {
    
    // Type to hold information about variable arguments.
    va_list ap;
    
    // Initialize a variable argument list.
    va_start (ap, format);
    
    NSString *fileName = (@(file)).lastPathComponent.stringByDeletingPathExtension;
    NSString *body = [[NSString alloc] initWithFormat:format arguments:ap];
    NSNumber *threadId = [[NSThread currentThread] fb_threadIdentifier];
    long threadIdAsLong = threadId.longValue;
    
    id<MPLoggingDelegate> loggingDelegate = [MPSettings loggingDelegate];
    if (loggingDelegate) {
      [loggingDelegate logAtLevel:level withFileName:fileName withLineNumber:lineNumber withThreadId:threadIdAsLong withBody:body];
    } else {
      NSLog(MPLogString, fileName, lineNumber, threadIdAsLong, fb_ad_level_to_string(level), body);
    }
  }
}

//+ (void)logInTestModeWithFile:(const char *)file
//                   lineNumber:(int)lineNumber
//                       format:(NSString *)format, ... NS_FORMAT_FUNCTION(3,4)
//{
//    if ([MPSettings isTestMode]) {
//        va_list ap;
//        va_start (ap, format);
//        NSMutableString *body = [[NSMutableString alloc] initWithFormat:format arguments:ap];
//
//        [body appendString:@" <testmode> "];
//
//        [self logAtLevel:MPLogLevelNotification file:file lineNumber:lineNumber format:@"%@", body];
//    }
//}

@end

NS_ASSUME_NONNULL_END

