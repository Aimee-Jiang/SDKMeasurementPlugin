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

NS_ASSUME_NONNULL_BEGIN

static NSString * const FB_AN_LOG_LEVEL = @"fb_an_log_lv";
static NSString * const FB_AN_URL_PREFIX = @"fb_an_url_prefix";
static NSString * const FB_AN_TEST_DEVICES = @"fb_an_test_devices";

@interface MPSettings (Internal)

+ (BOOL)isChildDirected;
+ (NSString *)getMediationService;
+ (NSURL *)getBaseURL;
+ (NSURL *)getBaseEventURL;
+ (NSURL *)getBaseBiddingURL;
+ (NSURL *)getBaseURLWithDefault:(NSString *)defaultURL withFormat:(NSString *)formatString;
+ (NSURL *)getDeliveryEndpoint;
+ (NSURL *)getWebviewBaseURL;
+ (NSString *)sessionID;

/**
 Whether this library was built with assertions turned on or off
 */
@property (atomic, assign, readonly, class) BOOL assertionsEnabled;


@end

NS_ASSUME_NONNULL_END

