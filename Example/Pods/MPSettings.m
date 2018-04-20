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

#import "MPSettings.h"
#import "MPSettings+Internal.h"

#import "MPDynamicFrameworkLoader.h"
#import "MPLogger.h"
#import "MPUtility.h"

NS_ASSUME_NONNULL_BEGIN

// NS_BLOCK_ASSERTIONS works on being defined, not on the value being set
#if defined(NS_BLOCK_ASSERTIONS)
#define FB_AD_BLOCK_ASSERTIONS YES
#else
#define FB_AD_BLOCK_ASSERTIONS NO
#endif

NSString * const FBAudienceNetworkErrorDomain = @"com.facebook.ads.sdk";
NSString * const FBAudienceNetworkMediaViewErrorDomain = @"com.facebook.ads.sdk.mediaview";

static const NSTimeInterval SESSION_ID_BACKGROUND_RESET_INTERVAL = 5 * 60;

static NSString * const FB_BASE_GRAPH_URL_DEFAULT = @"https://graph.facebook.com";
static NSString * const FB_BASE_GRAPH_URL_FORMAT = @"https://graph.%@.facebook.com";
static NSString * const FB_AUDIENCE_NETWORK_ENDPOINT = @"network_ads_common/";

static NSString * const FB_BASE_URL_DEFAULT = @"https://www.facebook.com";
static NSString * const FB_BASE_URL_FORMAT = @"https://www.%@.facebook.com";
static NSString * const FB_AUDIENCE_NETWORK_EVENT_ENDPOINT = @"adnw_logging/";

static NSString * const FB_BASE_AN_URL_DEFAULT = @"https://an.facebook.com";
static NSString * const FB_BASE_AN_URL_FORMAT = @"https://an.%@.facebook.com";
static NSString * const FB_AUDIENCE_NETWORK_BIDDING_ENDPOINT = @"placementbid.ortb/";

static BOOL _backgroundVideoPlaybackAllowed = NO;
static BOOL _isChildDirected;
static NSString *_mediationService = @"";
static NSString * __nullable _urlPrefix;
static NSString *_sessionID;
static NSTimeInterval _sessionBackgroundTime;
static MPLogLevel _logLevel = MPLogLevelError;
static FBMediaViewRenderingMethod _mediaViewRenderingMethod = FBMediaViewRenderingMethodDefault;

//#define kFBTestModeOverride NO

@implementation MPSettings

FB_FINAL_CLASS(objc_getClass("MPSettings"));

static MPTestAdType _testAdType = MPTestAdType_Default;
static __weak id<MPLoggingDelegate> _loggingDelegate = nil;

@dynamic bidderToken;

+ (NSMutableSet *)testDevices
{
  static NSMutableSet *_testDevices;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSArray<NSString *> *devices = [[NSUserDefaults standardUserDefaults] stringArrayForKey:FB_AN_TEST_DEVICES];
    if (devices) {
      _testDevices = [[NSMutableSet alloc] initWithArray:devices];
    } else {
      _testDevices = [NSMutableSet new];
    }
  });
  return _testDevices;
}

+ (void)persistTestDevices {
  NSArray<NSString *> *devices = [[self testDevices] allObjects];
  [[NSUserDefaults standardUserDefaults] setObject:devices forKey:FB_AN_TEST_DEVICES];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (void)addTestDevice:(NSString *)deviceHash
{
  if (![[self testDevices] containsObject:deviceHash]) {
    [[self testDevices] addObject:deviceHash];
    [MPSettings persistTestDevices];
  }
}

+ (void)addTestDevices:(NSArray<NSString *> *)devicesHash
{
  if (![[NSSet setWithArray:devicesHash] isSubsetOfSet:[self testDevices]]) {
    [[self testDevices] addObjectsFromArray:devicesHash];
    [MPSettings persistTestDevices];
  }
}

+ (void)clearTestDevices
{
  if ([self testDevices].count == 0) {
    return;
  }
  
  [[self testDevices] removeAllObjects];
  [MPSettings persistTestDevices];
}

+ (void)clearTestDevice:(NSString *)deviceHash
{
  if (![[self testDevices] containsObject:deviceHash]) {
    return;
  }
  
  [[self testDevices] removeObject:deviceHash];
  [MPSettings persistTestDevices];
}

+ (void)setIsChildDirected:(BOOL)isChildDirected
{
  _isChildDirected = isChildDirected;
}

+ (BOOL)isChildDirected
{
  return _isChildDirected;
}

+ (BOOL)isBackgroundVideoPlaybackAllowed
{
  return _backgroundVideoPlaybackAllowed;
}

+ (void)setBackgroundVideoPlaybackAllowed:(BOOL)backgroundVideoPlaybackAllowed
{
  _backgroundVideoPlaybackAllowed = backgroundVideoPlaybackAllowed;
}

+ (void)setMediationService:(NSString *)service
{
  _mediationService = service;
}

+ (NSString *)getMediationService
{
  return _mediationService;
}

+ (nullable NSString *)urlPrefix
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _urlPrefix = [[NSUserDefaults standardUserDefaults] stringForKey:FB_AN_URL_PREFIX];
  });
  return _urlPrefix;
}

+ (NSURL *)getDeliveryEndpoint
{
  return MPUnwrap([NSURL URLWithString:FB_AUDIENCE_NETWORK_ENDPOINT relativeToURL:[MPSettings getBaseURL]]);
}

+ (NSURL *)getWebviewBaseURL
{
  return [MPSettings getBaseURL];
}

+ (NSURL *)getBaseURLWithDefault:(NSString *)defaultURL withFormat:(NSString *)formatString
{
  if (![MPSettings urlPrefix]) {
    return MPUnwrap([NSURL URLWithString:defaultURL]);
  }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wformat-nonliteral"
  NSString *urlString = [NSString stringWithFormat:formatString, [MPSettings urlPrefix]];
  return MPUnwrap([NSURL URLWithString:urlString]);
#pragma clang diagnostic pop
}

+ (NSURL *)getBaseEventURL
{
  return MPUnwrap([NSURL URLWithString:FB_AUDIENCE_NETWORK_EVENT_ENDPOINT
                           relativeToURL:[MPSettings getBaseURLWithDefault:FB_BASE_URL_DEFAULT withFormat:FB_BASE_URL_FORMAT]]);
}

+ (NSURL *)getBaseBiddingURL
{
  return MPUnwrap([NSURL URLWithString:FB_AUDIENCE_NETWORK_BIDDING_ENDPOINT
                           relativeToURL:[MPSettings getBaseURLWithDefault:FB_BASE_AN_URL_DEFAULT withFormat:FB_BASE_AN_URL_FORMAT]]);
}

+ (NSURL *)getBaseURL
{
  return [self getBaseURLWithDefault:FB_BASE_GRAPH_URL_DEFAULT withFormat:FB_BASE_GRAPH_URL_FORMAT];
}

+ (MPLogLevel)getLogLevel
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    _logLevel = [[NSUserDefaults standardUserDefaults] integerForKey:FB_AN_LOG_LEVEL];
  });
  return _logLevel;
}

+ (void)setLogLevel:(MPLogLevel)level
{
  if (_logLevel != level) {
    _logLevel = level;
    [[NSUserDefaults standardUserDefaults] setInteger:_logLevel forKey:FB_AN_LOG_LEVEL];
    [[NSUserDefaults standardUserDefaults] synchronize];
  }
}

+ (NSString *)sessionID
{
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    [MPUtility startObservingBackgroundNotifications:[MPSettings class]
                                  usingBackgroundBlock:^(NSNotification *notification) {
                                    _sessionBackgroundTime = mpsdk_dfl_CACurrentMediaTime();
                                  }
                                  usingForegroundBlock:^(NSNotification *notification) {
                                    if ((mpsdk_dfl_CACurrentMediaTime() - _sessionBackgroundTime) > SESSION_ID_BACKGROUND_RESET_INTERVAL) {
                                      [self resetSessionID];
                                    }
                                  }];
    [self resetSessionID];
  });
  return _sessionID;
}

+ (void)resetSessionID
{
  _sessionID = [NSUUID UUID].UUIDString;
}

+ (FBMediaViewRenderingMethod)mediaViewRenderingMethod
{
  return _mediaViewRenderingMethod;
}

+ (void)setMediaViewRenderingMethod:(FBMediaViewRenderingMethod)mediaViewRenderingMethod
{
  _mediaViewRenderingMethod = mediaViewRenderingMethod;
}

+ (MPTestAdType)testAdType {
  return _testAdType;
}

+ (void)setTestAdType:(MPTestAdType)testAdType {
  _testAdType = testAdType;
}

+ (nullable id<MPLoggingDelegate>)loggingDelegate {
  return _loggingDelegate;
}

+ (void)setLoggingDelegate:(nullable id<MPLoggingDelegate>)loggingDelegate {
  _loggingDelegate = loggingDelegate;
}

+ (BOOL)assertionsEnabled
{
  @synchronized(self) {
    return !FB_AD_BLOCK_ASSERTIONS;
  }
}

@end

NS_ASSUME_NONNULL_END

