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

#import "MPEventToken.h"

#import "MPDynamicFrameworkLoader.h"

NS_ASSUME_NONNULL_BEGIN

@interface MPEventToken ()

@property (nonatomic, copy, readwrite) NSUUID *tokenId;
@property (nonatomic, copy, readwrite) NSString *token;

@end

@implementation MPEventToken

FB_FINAL_CLASS(objc_getClass("MPEventToken"));

- (instancetype)initWithToken:(NSString *)token
{
  self = [super init];
  if (self) {
    _tokenId = [NSUUID UUID];
    _token = token;
  }
  return self;
}

+ (nullable MPEventToken *)deserializeFromSqlite:(sqlite3_stmt * __nullable)queryStatement
{
  const char *tokenId = (const char *)mpsdk_dfl_sqlite3_column_text(queryStatement, 0);
  const char *token = (const char *)mpsdk_dfl_sqlite3_column_text(queryStatement, 1);
  
  if (!tokenId || !token) {
    return nil;
  }
  
  MPEventToken *tokenObj = [[MPEventToken alloc] initWithToken:@(token)];
  NSUUID *tokenUUID = [[NSUUID alloc] initWithUUIDString:@(tokenId)];
  tokenObj.tokenId = tokenUUID ?: [NSUUID UUID];
  
  return tokenObj;
}

@end

NS_ASSUME_NONNULL_END

