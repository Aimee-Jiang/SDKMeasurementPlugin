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

#import "MPSettings.h"

#import "MPDefines+Internal.h"

NS_ASSUME_NONNULL_BEGIN

#define MPLogNotification(s,...) __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS [MPLogger logAtLevel:MPLogLevelNotification file:__FILE__ lineNumber:__LINE__ format:(s), ##__VA_ARGS__] __FB_PRAGMA_POP_NO_FORMAT_WARNINGS
#define MPLogError(s,...) __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS [MPLogger logAtLevel:MPLogLevelError file:__FILE__ lineNumber:__LINE__ format:(s), ##__VA_ARGS__] __FB_PRAGMA_POP_NO_FORMAT_WARNINGS
#define MPLogWarning(s,...) __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS [MPLogger logAtLevel:MPLogLevelWarning file:__FILE__ lineNumber:__LINE__ format:(s), ##__VA_ARGS__] __FB_PRAGMA_POP_NO_FORMAT_WARNINGS
#define MPLog(s,...) __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS [MPLogger logAtLevel:MPLogLevelLog file:__FILE__ lineNumber:__LINE__ format:(s), ##__VA_ARGS__] __FB_PRAGMA_POP_NO_FORMAT_WARNINGS
#define MPLogDebug(s,...) __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS [MPLogger logAtLevel:MPLogLevelDebug file:__FILE__ lineNumber:__LINE__ format:(s), ##__VA_ARGS__] __FB_PRAGMA_POP_NO_FORMAT_WARNINGS
#define MPLogVerbose(s,...) __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS [MPLogger logAtLevel:MPLogLevelVerbose file:__FILE__ lineNumber:__LINE__ format:(s), ##__VA_ARGS__] __FB_PRAGMA_POP_NO_FORMAT_WARNINGS

// Logs only for Debug builds
#ifdef DEBUG
#define MPLogDebugOnly(s,...) __FB_PRAGMA_PUSH_NO_FORMAT_WARNINGS [MPLogger logAtLevel:MPLogLevelNotification file:__FILE__ lineNumber:__LINE__ format:(s), ##__VA_ARGS__] __FB_PRAGMA_POP_NO_FORMAT_WARNINGS
#else
#define MPLogDebugOnly(s,...)
#endif

@interface MPLogger : NSObject

+ (void)logAtLevel:(int)level
              file:(const char *)file
        lineNumber:(int)lineNumber
            format:(NSString *)format, ... NS_FORMAT_FUNCTION(4,5);

@end

NS_ASSUME_NONNULL_END

