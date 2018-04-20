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

#import "MPConfigManager.h"

#import "MPUtility.h"

NS_ASSUME_NONNULL_BEGIN

static NSString * const fb_default_configuration_name = @"fb_an_config.plist";

typedef NSString * MPConfigurationKey NS_STRING_ENUM;

static MPConfigurationKey const fb_config_ad_clickability_threshold_ms = @"ad_clickability_threshold_ms";
static MPConfigurationKey const fb_config_fnf_enabled = @"ios_fnf_enabled";
static MPConfigurationKey const fb_config_fnf_close_decompression_immediately = @"ios_fnf_close_decompression_immediately";
static MPConfigurationKey const fb_config_fnf_off_thread_rendering_enabled = @"ios_fnf_off_thread_rendering_enabled";
static MPConfigurationKey const fb_config_fnf_should_sync_before_runloop_stop = @"ios_fnf_should_sync_before_runloop_stop";
static MPConfigurationKey const fb_config_fnf_should_use_typed_internals = @"ios_fnf_should_use_typed_internals";
static MPConfigurationKey const fb_config_metal_image_renderer_enabled = @"ios_metal_image_renderer_enabled";
static MPConfigurationKey const fb_config_unified_logging_immediate_delay_ms = @"unified_logging_immediate_delay_ms";
static MPConfigurationKey const fb_config_unified_logging_event_limit = @"unified_logging_event_limit";
static MPConfigurationKey const fb_config_ad_viewability_tick_duration = @"ad_viewability_tick_duration";
static MPConfigurationKey const fb_config_ad_viewability_tap_margin = @"ad_viewability_tap_margin";
static MPConfigurationKey const fb_config_minimum_elapsed_time_after_impression = @"minimum_elapsed_time_after_impression";
static MPConfigurationKey const fb_config_visible_area_check_enabled = @"visible_area_check_enabled";
static MPConfigurationKey const fb_config_visible_area_percentage = @"visible_area_percentage";
static MPConfigurationKey const fb_config_video_and_endcard_autorotate = @"video_and_endcard_autorotate";
static MPConfigurationKey const fb_config_in_app_app_store_disabled = @"disable_in_app_app_store";
static MPConfigurationKey const fb_config_use_cached_image_context_for_software_renderer
= @"use_cached_image_context_for_software_renderer";
static MPConfigurationKey const fb_config_use_cached_image_context_for_metal_renderer
= @"use_cached_image_context_for_metal_renderer";
static MPConfigurationKey const fb_config_use_cached_image_context_for_opengl_renderer
= @"use_cached_image_context_for_opengl_renderer";
static MPConfigurationKey const fb_config_rv_play_pause_button_enabled = @"show_play_pause_rewarded_video";
static MPConfigurationKey const fb_config_rv_metadata_enabled = @"show_metadata_rewarded_video";
static MPConfigurationKey const fb_config_impression_miss_tracking_enabled = @"impression_miss_tracking";
static MPConfigurationKey const fb_config_debug_overlay_enabled = @"adnw_enable_debug_overlay";
static MPConfigurationKey const fb_config_device_id_based_routing_enabled = @"device_id_based_routing";
static MPConfigurationKey const fb_config_use_store_url = @"adnw_ios_use_store_url";
static MPConfigurationKey const fb_config_purge_on_413_response = @"adnw_purge_on_413_response";
static MPConfigurationKey const fb_config_cookie_injection_enabled = @"adnw_native_cookie_injection";
static MPConfigurationKey const fb_config_debug_logging = @"adnw_debug_logging";
static MPConfigurationKey const fb_config_watch_and_install_enabled = @"adnw_ios_watch_and_install";

static NSURL *MPConfigManagerDefaultConfigurationFileURL()
{
  NSArray<NSURL *> *cacheDirectories = [[NSFileManager defaultManager] URLsForDirectory:NSCachesDirectory inDomains:NSUserDomainMask];
  return MPUnwrap([cacheDirectories.firstObject URLByAppendingPathComponent:fb_default_configuration_name]);
}

@interface MPConfigManager ()

@property (nonatomic, strong, readonly) NSURL *configurationFileURL;

/*!
 Using an atomic property, instead of a lock, for the sake of performance.
 The general usage pattern of this class is to load/save the entire configuration object, instead of setting explicit keys,
 thus resetting the full dictionary to a new one is faster to perform via atomic property in a contested use case.
 */
@property (atomic, copy, nullable) NSDictionary *configuration;

@end

@implementation MPConfigManager

FB_FINAL_CLASS(objc_getClass("MPConfigManager"));

#pragma mark - Init

- (instancetype)init
{
  return [self initWithAsyncLoad:NO];
}

- (instancetype)initWithAsyncLoad:(BOOL)async
{
  self = [super init];
  if (self) {
    _configuration = @{};
    _configurationFileURL = MPConfigManagerDefaultConfigurationFileURL();
    [self loadConfigurationFromStorage:async];
  }
  return self;
}

+ (MPConfigManager*)sharedManager
{
  return [self sharedManagerWithAsyncLoad:NO];
}

+ (MPConfigManager*)sharedManagerWithAsyncLoad:(BOOL)async
{
  return FB_INITIALIZE_AND_RETURN_STATIC([[MPConfigManager alloc] initWithAsyncLoad:async]);
}

#pragma mark - Load

- (instancetype)loadConfigurationFromStorage:(BOOL)async
{
  dispatch_block_t block = ^{
    NSError *error = nil;
    NSData *localStorage = [NSData dataWithContentsOfURL:self.configurationFileURL
                                                 options:NSDataReadingMappedIfSafe
                                                   error:&error];
    if (!localStorage) {
      MPLogDebug(@"Failed to load local configuration: %@", error);
      return;
    }
    
    //        [self loadConfigurationFromPropertyList:localStorage];
  };
  
  if (async) {
    dispatch_async(FB_DISPATCH_QUEUE_PRIORITY_DEFAULT, block);
  } else {
    block();
  }
  
  return self;
}

- (instancetype)loadConfigurationFromStorage
{
  return [self loadConfigurationFromStorage:NO];
}

- (instancetype)loadConfigurationFromJSONString:(nullable NSString *)string
{
  NSDictionary *dictionary = [MPUtility getObjectFromJSONString:string];
  if (dictionary) {
    self.configuration = dictionary;
  }
  return self;
}

- (instancetype)loadConfigurationFromDictionary:(NSDictionary *)dictionary
{
  self.configuration = [dictionary mutableCopy];
  return self;
}

#pragma mark - Delete

- (instancetype)deleteConfiguration
{
  self.configuration = [NSMutableDictionary new];
  [[NSFileManager defaultManager] removeItemAtURL:self.configurationFileURL error:nil];
  return self;
}

#pragma mark - Subscripts

- (nullable id)objectForKeyedSubscript:(id)key
{
  return [self.configuration objectForKeyedSubscript:key];
}

- (void)setObject:(nullable id)obj forKeyedSubscript:(id <NSCopying>)key
{
  NSMutableDictionary *dictionary = [self.configuration mutableCopy] ?: [NSMutableDictionary new];
  dictionary[key] = obj;
  
  self.configuration = dictionary;
}

#pragma mark Config Values

- (BOOL)boolForKey:(NSString *)key defaultReturnValue:(BOOL)defaultReturnValue
{
  NSDictionary<NSString *, id> *config = self.configuration;
  return config ? [config boolForKey:key orDefault:defaultReturnValue] : defaultReturnValue;
}

- (NSInteger)integerForKey:(NSString *)key defaultReturnValue:(NSInteger)defaultReturnValue
{
  NSDictionary<NSString *, id> *config = self.configuration;
  return config ? [config integerForKey:key orDefault:defaultReturnValue] : defaultReturnValue;
}

- (NSTimeInterval)timeIntervalforKey:(NSString *)key defaultReturnValue:(NSTimeInterval)defaultReturnValue
{
  NSDictionary<NSString *, id> *config = self.configuration;
  return (NSTimeInterval)((config ? [config doubleForKey:key orDefault:defaultReturnValue] : defaultReturnValue) / 1000.0);
}

- (NSString *)stringForKey:(NSString *)key defaultReturnValue:(NSString *)defaultReturnValue
{
  NSDictionary<NSString *, id> *config = self.configuration;
  return config ? [config stringForKey:key orDefault:defaultReturnValue] : defaultReturnValue;
}

- (NSTimeInterval)adClickabilityThresholdInterval
{
  return [self timeIntervalforKey:fb_config_ad_clickability_threshold_ms defaultReturnValue:0];
}

- (BOOL)isFNFEnabled
{
  return [self boolForKey:fb_config_fnf_enabled defaultReturnValue:YES];
}

- (BOOL)isFNFCloseDecompressionImmediatelyEnabled
{
  return [self boolForKey:fb_config_fnf_close_decompression_immediately defaultReturnValue:YES];
}

- (BOOL)isFNFShouldUseTypedInternalEnabled
{
  return [self boolForKey:fb_config_fnf_should_use_typed_internals defaultReturnValue:YES];
}

- (BOOL)isFNFShouldSyncBeforeRunloopStopEnabled
{
  return [self boolForKey:fb_config_fnf_should_sync_before_runloop_stop defaultReturnValue:YES];
}

- (BOOL)isFNFOffThreadRenderingEnabled
{
  return [self boolForKey:fb_config_fnf_off_thread_rendering_enabled defaultReturnValue:YES];
}

- (BOOL)isMetalImageRendererEnabled
{
  return [self boolForKey:fb_config_metal_image_renderer_enabled defaultReturnValue:YES];
}

- (NSTimeInterval)unifiedLoggingImmediateDelay
{
  return [self timeIntervalforKey:fb_config_unified_logging_immediate_delay_ms defaultReturnValue:500];
}

- (NSInteger)unifiedLoggingEventLimit
{
  return [self integerForKey:fb_config_unified_logging_event_limit defaultReturnValue:0];
}

- (NSInteger)adTapMarginPercentage
{
  return [self integerForKey:fb_config_ad_viewability_tap_margin defaultReturnValue:0];
}

- (NSTimeInterval)minimumElapsedTimeAfterImpression
{
  return [self timeIntervalforKey:fb_config_minimum_elapsed_time_after_impression defaultReturnValue:-1];
}

- (BOOL)isAdClickabilityRestrictedUntilImpression
{
  NSDictionary *config = self.configuration;
  BOOL defaultRet = NO;
  if (config) {
    NSTimeInterval interval = (NSTimeInterval)([config doubleForKey:fb_config_minimum_elapsed_time_after_impression orDefault:defaultRet] / 1000.0);
    if (interval < 0) {
      return NO;
    } else {
      return YES;
    }
  } else {
    return defaultRet;
  }
}

- (BOOL)isVisibleAreaCheckEnabled
{
  return [self boolForKey:fb_config_visible_area_check_enabled defaultReturnValue:NO];
}

- (NSInteger)visibleAreaPercentage
{
  return [self integerForKey:fb_config_visible_area_percentage defaultReturnValue:50];
}

- (NSString*)rvAutoRotate
{
  return [self stringForKey:fb_config_video_and_endcard_autorotate defaultReturnValue:@"autorotate_disabled"];
}

- (BOOL)isRVPlayPauseButtonEnabled
{
  return [self boolForKey:fb_config_rv_play_pause_button_enabled defaultReturnValue:NO];
}

- (BOOL)isDeviceIDBasedRoutingEnabled
{
  return [self boolForKey:fb_config_device_id_based_routing_enabled defaultReturnValue:NO];
}

- (BOOL)isRVMetadataEnabled
{
  return [self boolForKey:fb_config_rv_metadata_enabled defaultReturnValue:NO];
}

- (BOOL)isInAppAppStoreDisabled
{
  return [self boolForKey:fb_config_in_app_app_store_disabled defaultReturnValue:NO];
}

- (BOOL)useCachedImageContextForSoftwareRenderer
{
  return [self boolForKey:fb_config_use_cached_image_context_for_software_renderer defaultReturnValue:YES];
}

- (BOOL)useCachedImageContextForMetalRenderer
{
  return [self boolForKey:fb_config_use_cached_image_context_for_metal_renderer defaultReturnValue:YES];
}

- (BOOL)useCachedImageContextForOpenGLRenderer
{
  return [self boolForKey:fb_config_use_cached_image_context_for_opengl_renderer defaultReturnValue:YES];
}

- (BOOL)isImpressionMissTrackingEnabled
{
  return [self boolForKey:fb_config_impression_miss_tracking_enabled defaultReturnValue:YES];
}

- (BOOL)isDebugOverlayEnabled
{
  return [self boolForKey:fb_config_debug_overlay_enabled defaultReturnValue:NO];
}

- (BOOL)useStoreURL
{
  return [self boolForKey:fb_config_use_store_url defaultReturnValue:NO];
}

- (BOOL)shouldPurgeEventsAndTokensOn413Response
{
  return [self boolForKey:fb_config_purge_on_413_response defaultReturnValue:NO];
}

- (BOOL)cookieInjectionEnabled
{
  return [self boolForKey:fb_config_cookie_injection_enabled defaultReturnValue:NO];
}

- (BOOL)isDebugLoggingEnabled
{
  return [self boolForKey:fb_config_debug_logging defaultReturnValue:NO];
}

- (BOOL)isWatchAndInstallEnabled
{
  return [self boolForKey:fb_config_watch_and_install_enabled defaultReturnValue:YES];
}

@end

NS_ASSUME_NONNULL_END

