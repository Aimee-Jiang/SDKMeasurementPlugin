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

#import "MPURLSession.h"

#import "MPConcurrentQueue.h"
#import "MPConfigManager.h"
#import "MPTimer.h"
#import "MPUtility.h"
#import "MPUtilityFunctions.h"

NS_ASSUME_NONNULL_BEGIN

static NSTimeInterval kMPURLSessionTimeoutDelivery = 10.0;

@interface MPURLSession () <NSURLSessionDelegate, NSURLSessionDataDelegate>

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) MPConcurrentQueue<dispatch_block_t> *queue;
@property (nonatomic, strong, nullable) MPTimer *userAgentTimer;

@end

@implementation MPURLSession

- (instancetype)init
{
  self = [super init];
  if (self) {
    _queue = [MPConcurrentQueue new];
  }
  return self;
}

+ (instancetype)sharedSession
{
  return FB_INITIALIZE_WITH_BLOCK_AND_RETURN_STATIC(^MPURLSession *{
    MPURLSession *adSession = [self new];
    [self updateSession:adSession];
    return adSession;
  });
}

+ (NSURLSessionConfiguration *)defaultConfiguration
{
  NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
  configuration.timeoutIntervalForRequest = kMPURLSessionTimeoutDelivery;
  configuration.requestCachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
  NSMutableDictionary<NSString *, NSString *> *extraHeaders = configuration.HTTPAdditionalHeaders ? [[NSMutableDictionary alloc] initWithDictionary:MPUnwrap(configuration.HTTPAdditionalHeaders)] : [[NSMutableDictionary alloc] init];
  if ([MPConfigManager sharedManager].isDeviceIDBasedRoutingEnabled) {
    extraHeaders[@"X-FB-Pool-Routing-Token"] = [MPUtility getAdvertisingIdentifier];
  }
  configuration.HTTPAdditionalHeaders = extraHeaders;
  return configuration;
}

+ (void)updateSession:(MPURLSession *)adSession
{
  // Keep querying for the user agent, it might not be available when we want it
  // Until we get the user agent, queue up network requests
  NSURLSessionConfiguration *configuration = [self defaultConfiguration];
  
  adSession.userAgentTimer = [MPTimer scheduledTimerWithTimeInterval:(NSTimeInterval)0.1
                                                               repeats:YES
                                                                 queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)
                                                                 block:^(MPTimer *timer) {
                                                                   [MPUtility currentUserAgentWithBlock:^(NSString * __nullable userAgent) {
                                                                     NSMutableDictionary<NSString *, NSString *> *extraHeaders = configuration.HTTPAdditionalHeaders ? [[NSMutableDictionary alloc] initWithDictionary:MPUnwrap(configuration.HTTPAdditionalHeaders)] : [[NSMutableDictionary alloc] init];
                                                                     if ([MPConfigManager sharedManager].isDeviceIDBasedRoutingEnabled) {
                                                                       extraHeaders[@"X-FB-Pool-Routing-Token"] = [MPUtility getAdvertisingIdentifier];
                                                                     }
                                                                     if (userAgent && userAgent.length > 0) {
                                                                       extraHeaders[@"User-Agent"] = MPUnwrap(userAgent);
                                                                       configuration.HTTPAdditionalHeaders = extraHeaders;
                                                                       adSession.session = [NSURLSession sessionWithConfiguration:configuration delegate:adSession delegateQueue:nil];
                                                                       [adSession emptyQueue];
                                                                       [timer invalidate];
                                                                       adSession.userAgentTimer = nil;
                                                                     } else {
                                                                       configuration.HTTPAdditionalHeaders = extraHeaders;
                                                                     }
                                                                   }];
                                                                 }];
}

- (BOOL)valid
{
  return self.session != nil;
}

- (void)enqueueOrExecuteRequest:(dispatch_block_t)block
{
  if (!block) {
    return;
  }
  if (self.valid) {
    [self emptyQueue];
    block();
  } else {
    [self.class updateSession:self];
    [self.queue pushObject:block];
  }
}

- (void)emptyQueue
{
  if (self.valid) {
    MPConcurrentQueue *queue = self.queue;
    [queue popAll:^(NSEnumerator *enumerator) {
      for (dispatch_block_t block in enumerator) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
      }
    }];
  } else {
    [self.class updateSession:self];
  }
}

- (MPURLSessionTaskContainer *)requestWithURLRequest:(NSURLRequest *)urlRequest
                                       responseHandler:(MPURLConnectionHandler)responseHandler
{
  MPURLSessionTaskContainer *container = [MPURLSessionTaskContainer new];
  [self enqueueOrExecuteRequest:^{
    
    NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:urlRequest
                                                     completionHandler:^(NSData *data,
                                                                         NSURLResponse *response,
                                                                         NSError *error) {
                                                       NSTimeInterval duration = fabs((container.requestStart).timeIntervalSinceNow);
                                                       if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
                                                         if (error != nil && ![self isEmptyURL:urlRequest.URL]) {
                                                           MPLogError(@"HTTP error, status=%ld, error=%@, bytes=%lu, encoding=%@, url=%@",
                                                                        (long)[(NSHTTPURLResponse *)response statusCode],
                                                                        error,
                                                                        (unsigned long)data.length,
                                                                        response.textEncodingName,
                                                                        urlRequest.URL);
                                                         } else {
                                                           MPLogDebug(@"HTTP complete, status=%lu, bytes=%ld, encoding=%@, duration=%f, url=%@",
                                                                        (unsigned long)[(NSHTTPURLResponse *)response statusCode],
                                                                        (long)data.length,
                                                                        response.textEncodingName,
                                                                        (double)duration,
                                                                        urlRequest.URL);
                                                         }
                                                       }
                                                       
                                                       if (responseHandler) {
                                                         responseHandler(container, response, data, error, duration);
                                                       }
                                                     }];
    [dataTask resume];
    container.task = dataTask;
    
  }];
  return container;
}

- (MPURLSessionTaskContainer *)requestWithURL:(NSURL *)url
                                     HTTPMethod:(NSString *)HTTPMethod
                                queryParameters:(NSDictionary *)queryParameters
                                responseHandler:(MPURLConnectionHandler)responseHandler
{
  NSURLRequest *urlRequest = [self urlRequestWithURL:url
                                          HTTPMethod:HTTPMethod
                                     queryParameters:queryParameters];
  
  return [self requestWithURLRequest:urlRequest
                     responseHandler:responseHandler];
}

- (BOOL)isEmptyURL:(nullable NSURL *)url
{
  if (!url) {
    return YES;
  }
  NSString *absoluteString = url.absoluteString;
  return ([absoluteString isEqualToString:@""] || [absoluteString isEqualToString:@"#"]);
}

- (NSURLRequest *)urlRequestWithURL:(NSURL *)url
                         HTTPMethod:(NSString *)HTTPMethod
                    queryParameters:(NSDictionary *)queryParameters
{
  NSMutableURLRequest *urlRequest = [NSMutableURLRequest new];
  
  NSString *queryString = [MPUtility createQueryStringFromParameters:[queryParameters copy]];
  
  // Default HTTPMethod method
  if (HTTPMethod == nil) {
    HTTPMethod = @"GET";
  }
  
  // POST implementation
  if ([HTTPMethod isEqualToString:@"POST"]) {
    
    // Create POST
    urlRequest.URL = url;
    
    [urlRequest setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    urlRequest.HTTPBody = [queryString dataUsingEncoding:NSUTF8StringEncoding];
    
    // GET implementation
  } else if ([HTTPMethod isEqualToString:@"GET"]) {
    
    NSURL *getUrl = url;
    
    if (queryString.length > 0) {
      
      NSMutableString *urlString = [[NSMutableString alloc] initWithString:@""];
      
      [urlString appendString:MPUnwrap(url.absoluteString)];
      
      // Add GET string to URL
      if ([urlString rangeOfString:@"?"].location == NSNotFound) {
        [urlString appendString:@"?"];
      } else {
        [urlString appendString:@"&"];
      }
      
      [urlString appendString:queryString];
      
      getUrl = [NSURL URLWithString:[NSString stringWithString:urlString]];
    }
    
    urlRequest.URL = getUrl;
  }
  
  urlRequest.HTTPMethod = HTTPMethod;
  
  return urlRequest;
}

- (BOOL)isSandboxHost:(NSString *)host
{
  return (host.length && ([host hasSuffix:@".sb.facebook.com"] ||
                          ([host rangeOfString:@"prn"].location != NSNotFound && [host hasSuffix:@".facebook.com"])));
}

#pragma mark NSURLSessionDelegate

- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
 completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler
{
  // Bypass SSL validation for devservers
  if (self.isSSLValidationDisabled && [self isSandboxHost:challenge.protectionSpace.host]) {
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:serverTrust]);
  } else {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
  }
}

@end

@implementation MPURLSessionTaskContainer

- (instancetype)init
{
  self = [super init];
  if (self) {
    _requestStart = [NSDate date];
  }
  return self;
}

- (NSURLSessionTaskState)state
{
  return self.task.state;
}

- (void)cancel
{
  [self.task cancel];
}

@end

NS_ASSUME_NONNULL_END

