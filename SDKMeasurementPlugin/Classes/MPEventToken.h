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

#import <sqlite3.h>

#import <Foundation/Foundation.h>

#import "MPUtility.h"

NS_ASSUME_NONNULL_BEGIN

FB_SUBCLASSING_RESTRICTED
@interface MPEventToken : NSObject

@property (nonatomic, copy, readonly) NSUUID *tokenId;
@property (nonatomic, copy, readonly) NSString *token;

FB_INIT_AND_NEW_UNAVAILABLE_NULLABILITY

- (instancetype)initWithToken:(NSString *)token NS_DESIGNATED_INITIALIZER;

+ (nullable MPEventToken *)deserializeFromSqlite:(sqlite3_stmt * __nullable)queryStatement;

@end

NS_ASSUME_NONNULL_END

