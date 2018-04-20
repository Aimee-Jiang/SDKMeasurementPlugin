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
#import <UIKit/UIKit.h>

#import "MPDefines+Internal.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Manages a single configuration file on disc and loads/stores all preferences into it.
 The API is very close to NSUserDefaults, but with explicit save/load.
 
 This class is fully threadsafe and is safe to use across multiple threads.
 */
FB_SUBCLASSING_RESTRICTED
@interface MPConfigManager : NSObject

- (instancetype)initWithAsyncLoad:(BOOL)async NS_DESIGNATED_INITIALIZER;

+ (MPConfigManager*)sharedManager;

- (instancetype)loadConfigurationFromStorage;
- (instancetype)loadConfigurationFromJSONString:(nullable NSString *)string;
- (instancetype)loadConfigurationFromDictionary:(NSDictionary *)dictionary;
//- (instancetype)loadConfigurationFromPropertyList:(NSData *)data;
- (instancetype)saveConfiguration;
- (instancetype)saveConfiguration:(BOOL)async;
- (instancetype)deleteConfiguration;

// Enables use of [MPConfigManager sharedManager][@"key"] syntax
- (nullable id)objectForKeyedSubscript:(id)key;
- (void)setObject:(nullable id)obj forKeyedSubscript:(id <NSCopying>)key;

#pragma mark Config Values

@property (nonatomic, assign, readonly) NSTimeInterval adClickabilityThresholdInterval;
@property (nonatomic, assign, readonly, getter=isFNFEnabled) BOOL fnfEnabled;
@property (nonatomic, assign, readonly, getter=isFNFCloseDecompressionImmediatelyEnabled) BOOL fnfCloseDecompressionImmediatelyEnabled;
@property (nonatomic, assign, readonly, getter=isFNFOffThreadRenderingEnabled) BOOL fnfOffThreadRenderingEnabled;
@property (nonatomic, assign, readonly, getter=isFNFShouldUseTypedInternalEnabled) BOOL fnfShouldUseTypedInternalsEnabled;
@property (nonatomic, assign, readonly, getter=isFNFShouldSyncBeforeRunloopStopEnabled) BOOL fnfShouldSyncBeforeRunloopStopEnabled;
@property (nonatomic, assign, readonly, getter=isMetalImageRendererEnabled) BOOL metalImageRendererEnabled;
@property (nonatomic, assign, readonly) NSTimeInterval unifiedLoggingImmediateDelay;
@property (nonatomic, assign, readonly) NSInteger unifiedLoggingEventLimit;
@property (nonatomic, assign, readonly) CGFloat adTapMargin;
@property (nonatomic, assign, readonly) NSTimeInterval minimumElapsedTimeAfterImpression;
@property (nonatomic, assign, readonly, getter=isAdClickabilityRestrictedUntilImpression) BOOL adClickabilityRestrictedUntilImpression;
@property (nonatomic, assign, readonly, getter=isVisibleAreaCheckEnabled) BOOL visibleAreaCheckEnabled;
@property (nonatomic, assign, readonly) NSInteger visibleAreaPercentage;
@property (nonatomic, assign, readonly) NSInteger adTapMarginPercentage; //valid range 0 - 50
@property (nonatomic, copy, readonly) NSString *rvAutoRotate;
@property (nonatomic, assign, readonly, getter=isInAppAppStoreDisabled) BOOL inAppAppStoreDisabled;
@property (nonatomic, assign, readonly) BOOL useCachedImageContextForSoftwareRenderer;
@property (nonatomic, assign, readonly) BOOL useCachedImageContextForMetalRenderer;
@property (nonatomic, assign, readonly) BOOL useCachedImageContextForOpenGLRenderer;
@property (nonatomic, assign, readonly, getter=isRVPlayPauseButtonEnabled) BOOL rvPlayPauseButtonEnabled;
@property (nonatomic, assign, readonly, getter=isRVMetadataEnabled) BOOL rvMetadataEnabled;
@property (nonatomic, assign, readonly, getter=isImpressionMissTrackingEnabled) BOOL impressionMissTrackingEnabled;
@property (nonatomic, assign, readonly, getter=isDeviceIDBasedRoutingEnabled) BOOL deviceIDBasedRoutingEnabled;
@property (nonatomic, assign, readonly, getter=isDebugOverlayEnabled) BOOL debugOverlayEnabled;
@property (nonatomic, assign, readonly) BOOL useStoreURL;
@property (nonatomic, assign, readonly) BOOL shouldPurgeEventsAndTokensOn413Response;
@property (nonatomic, assign, readonly) BOOL cookieInjectionEnabled;
@property (nonatomic, assign, readonly, getter=isDebugLoggingEnabled) BOOL debugLoggingEnabled;
@property (nonatomic, assign, readonly, getter=isWatchAndInstallEnabled) BOOL watchAndInstallEnabled;

@end

NS_ASSUME_NONNULL_END

