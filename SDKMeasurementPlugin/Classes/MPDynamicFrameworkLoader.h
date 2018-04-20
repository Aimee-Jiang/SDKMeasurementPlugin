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

#include <zlib.h>

#import <AudioToolbox/AudioToolbox.h>
#import <CoreMedia/CoreMedia.h>
#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#if __has_include(<MetalKit/MetalKit.h>) && !TARGET_IPHONE_SIMULATOR
#import <Metal/Metal.h>
#endif
#import <QuartzCore/QuartzCore.h>
#import <VideoToolbox/VideoToolbox.h>
#import <UIKit/UIKit.h>
#import "SystemConfiguration/SystemConfiguration.h"

#import "MPDefines+Internal.h"

FB_EXTERN_C_BEGIN

/*
 MPDynamicFrameworkLoader
 
 This class provides a way to load constants and methods from Apple Frameworks in a dynamic
 fashion.  It allows the SDK to be just dragged into a project without having to specify additional
 frameworks to link against.  It is an internal class and not to be used by 3rd party developers.
 
 As new types are needed, they should be added and strongly typed.
 */

#pragma mark - QuartzCore Classes

Class mpsdk_dfl_CATransactionClass(void);
//Class mpsdk_dfl_CAGradientLayerClass(void);
//Class mpsdk_dfl_CAShapeLayerClass(void);
//Class mpsdk_dfl_CADisplayLinkClass(void);
//Class mpsdk_dfl_CAEAGLLayerClass(void);
//Class mpsdk_dfl_CAKeyframeAnimationClass(void);

#pragma mark - QuartzCore APIs

CFTimeInterval mpsdk_dfl_CACurrentMediaTime (void);

void mpsdk_dfl_CAShapeLayer_setPath(id layer, CGPathRef path);

#pragma mark - AudioToolbox APIs

OSStatus mpsdk_dfl_AudioSessionInitialize(CFRunLoopRef inRunLoop, CFStringRef inRunLoopMode, AudioSessionInterruptionListener inInterruptionListener, void *inClientData);
OSStatus mpsdk_dfl_AudioSessionGetProperty(AudioSessionPropertyID inID, UInt32 *ioDataSize, void *outData);
OSStatus mpsdk_dfl_AudioQueueEnqueueBufferWithParameters(AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, UInt32 inNumPacketDescs, const AudioStreamPacketDescription *inPacketDescs, UInt32 inTrimFramesAtStart, UInt32 inTrimFramesAtEnd, UInt32 inNumParamValues, const AudioQueueParameterEvent *inParamValues, const AudioTimeStamp *inStartTime, AudioTimeStamp *outActualStartTime);
OSStatus mpsdk_dfl_AudioQueueStart(AudioQueueRef inAQ, const AudioTimeStamp *inStartTime);
OSStatus mpsdk_dfl_AudioQueueReset(AudioQueueRef inAQ);
OSStatus mpsdk_dfl_AudioQueueFlush(AudioQueueRef inAQ);
OSStatus mpsdk_dfl_AudioQueueStop(AudioQueueRef inAQ, Boolean inImmediate);
OSStatus mpsdk_dfl_AudioQueuePause(AudioQueueRef inAQ);
OSStatus mpsdk_dfl_AudioQueueDispose(AudioQueueRef inAQ, Boolean inImmediate);
OSStatus mpsdk_dfl_AudioQueueNewOutput(const AudioStreamBasicDescription *inFormat, AudioQueueOutputCallback inCallbackProc, void *inUserData, CFRunLoopRef inCallbackRunLoop, CFStringRef inCallbackRunLoopMode, UInt32 inFlags, AudioQueueRef *outAQ);
OSStatus mpsdk_dfl_AudioQueueFreeBuffer(AudioQueueRef inAQ, AudioQueueBufferRef inBuffer);
OSStatus mpsdk_dfl_AudioQueueAllocateBufferWithPacketDescriptions(AudioQueueRef inAQ, UInt32 inBufferByteSize, UInt32 inNumberPacketDescriptions, AudioQueueBufferRef *outBuffer);
OSStatus mpsdk_dfl_AudioQueueGetProperty(AudioQueueRef inAQ, AudioQueuePropertyID inID, void *outData, UInt32 *ioDataSize);
OSStatus mpsdk_dfl_AudioQueueSetParameter(AudioQueueRef inAQ, AudioQueueParameterID inParamID, AudioQueueParameterValue inValue);
OSStatus mpsdk_dfl_AudioQueueAddPropertyListener(AudioQueueRef inAQ, AudioQueuePropertyID inID, AudioQueuePropertyListenerProc inProc, void *inUserData);
OSStatus mpsdk_dfl_AudioQueueRemovePropertyListener(AudioQueueRef inAQ, AudioQueuePropertyID inID, AudioQueuePropertyListenerProc inProc, void *inUserData);
OSStatus mpsdk_dfl_AudioQueueGetCurrentTime(AudioQueueRef inAQ, AudioQueueTimelineRef inTimeline, AudioTimeStamp *outTimeStamp, Boolean *outTimelineDiscontinuity);
OSStatus mpsdk_dfl_AudioQueueSetProperty (AudioQueueRef inAQ, AudioQueuePropertyID inID, const void * inData, UInt32 inDataSize);
OSStatus mpsdk_dfl_AudioQueueCreateTimeline (AudioQueueRef inAQ, AudioQueueTimelineRef * outTimeline);
OSStatus mpsdk_dfl_AudioQueueDisposeTimeline (AudioQueueRef inAQ, AudioQueueTimelineRef inTimeline);

#pragma mark - VideoToolbox APIs

typedef OSStatus (*VTDecompressionSessionCreate_type)(CFAllocatorRef, CMVideoFormatDescriptionRef, CFDictionaryRef, CFDictionaryRef, const VTDecompressionOutputCallbackRecord *, CM_RETURNS_RETAINED_PARAMETER VTDecompressionSessionRef *);

VTDecompressionSessionCreate_type mpsdk_dfl_VTDecompressionSessionCreateFunc(void);

OSStatus mpsdk_dfl_VTDecompressionSessionCreate(CFAllocatorRef allocator, CMVideoFormatDescriptionRef videoFormatDescription, CFDictionaryRef videoDecoderSpecification, CFDictionaryRef destinationImageBufferAttributes, const VTDecompressionOutputCallbackRecord * outputCallback, CM_RETURNS_RETAINED_PARAMETER VTDecompressionSessionRef * decompressionSessionOut) __OSX_AVAILABLE_STARTING(__MAC_10_8,__IPHONE_8_0);
OSStatus mpsdk_dfl_VTDecompressionSessionDecodeFrame(VTDecompressionSessionRef session, CMSampleBufferRef sampleBuffer, VTDecodeFrameFlags decodeFlags, void *sourceFrameRefCon, VTDecodeInfoFlags *infoFlagsOut) __OSX_AVAILABLE_STARTING(__MAC_10_8,__IPHONE_8_0);
void mpsdk_dfl_VTDecompressionSessionInvalidate(VTDecompressionSessionRef session) __OSX_AVAILABLE_STARTING(__MAC_10_8,__IPHONE_8_0);
OSStatus mpsdk_dfl_VTDecompressionSessionWaitForAsynchronousFrames(VTDecompressionSessionRef session) __OSX_AVAILABLE_STARTING(__MAC_10_8,__IPHONE_8_0);
Boolean mpsdk_dfl_VTDecompressionSessionCanAcceptFormatDescription(VTDecompressionSessionRef session, CMFormatDescriptionRef newFormatDesc);

#pragma mark - CoreVideo Classes

#pragma mark - CoreVideo APIs

CVReturn mpsdk_dfl_CVOpenGLESTextureCacheCreate(CFAllocatorRef allocator, CFDictionaryRef cacheAttributes, CVEAGLContext eaglContext, CFDictionaryRef textureAttributes, CVOpenGLESTextureCacheRef *cacheOut);
void mpsdk_dfl_CVOpenGLESTextureCacheFlush(CVOpenGLESTextureCacheRef textureCache, CVOptionFlags options);
CVReturn mpsdk_dfl_CVOpenGLESTextureCacheCreateTextureFromImage(CFAllocatorRef allocator, CVOpenGLESTextureCacheRef textureCache, CVImageBufferRef sourceImage, CFDictionaryRef textureAttributes, GLenum target, GLint internalFormat, GLsizei width, GLsizei height, GLenum format, GLenum type, size_t planeIndex, CVOpenGLESTextureRef *textureOut);
uint32_t mpsdk_dfl_CVOpenGLESTextureGetTarget(CVOpenGLESTextureRef image);
uint32_t mpsdk_dfl_CVOpenGLESTextureGetName(CVOpenGLESTextureRef image);
CFTypeRef mpsdk_dfl_CVBufferGetAttachment(CVBufferRef buffer, CFStringRef key, CVAttachmentMode *attachmentMode) CF_RETURNS_NOT_RETAINED;
size_t mpsdk_dfl_CVPixelBufferGetWidth(CVPixelBufferRef pixelBuffer);
size_t mpsdk_dfl_CVPixelBufferGetHeight(CVPixelBufferRef pixelBuffer);
NSString *mpsdk_dfl_kCVPixelBufferOpenGLCompatibilityKey(void);
NSString *mpsdk_dfl_kCVPixelBufferOpenGLESCompatibilityKey(void);
NSString *mpsdk_dfl_kCVPixelBufferOpenGLESTextureCacheCompatibilityKey(void);
NSString *mpsdk_dfl_kCVPixelBufferWidthKey(void);
NSString *mpsdk_dfl_kCVPixelBufferHeightKey(void);
//NSString *mpsdk_dfl_kCVImageBufferYCbCrMatrix_ITU_R_601_4(void);
//NSString *mpsdk_dfl_kCVImageBufferYCbCrMatrixKey(void);
NSString *mpsdk_dfl_kCVPixelBufferPixelFormatTypeKey(void);
NSString *mpsdk_dfl_kCVPixelBufferIOSurfacePropertiesKey(void);

CF_IMPLICIT_BRIDGING_ENABLED

//CFStringRef mpsdk_dfl_kCVImageBufferYCbCrMatrix_ITU_R_601_4CFStringRef(void);
//CFStringRef mpsdk_dfl_kCVImageBufferYCbCrMatrixKeyCFStringRef(void);

CF_IMPLICIT_BRIDGING_DISABLED

CVReturn mpsdk_dfl_CVPixelBufferLockBaseAddress ( CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags lockFlags );
void mpsdk_dfl_CVPixelBufferRelease ( CV_RELEASES_ARGUMENT CVPixelBufferRef texture );
CVPixelBufferRef mpsdk_dfl_CVPixelBufferRetain ( CVPixelBufferRef texture );

#if !TARGET_OS_SIMULATOR
IOSurfaceRef mpsdk_dfl_kCVPixelBufferGetIOSurface ( CVPixelBufferRef pixelBuffer );
#endif

CVReturn mpsdk_dfl_CVPixelBufferUnlockBaseAddress ( CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags unlockFlags );

#pragma mark - AdSupport Classes

//Class mpsdk_dfl_ASIdentifierManagerClass(void);

#pragma mark - SafariServices Classes

Class mpsdk_dfl_SFSafariViewControllerClass(void);

#pragma mark - StoreKit classes

//Class mpsdk_dfl_SKStoreProductViewControllerClass(void);
//Class mpsdk_dfl_custom_SKStoreProductViewControllerClass(void);
NSString *mpsdk_dfl_SKStoreProductParameterITunesItemIdentifier(void);

#pragma mark - CoreTelephony Classes

Class mpsdk_dfl_CTTelephonyNetworkInfoClass(void);

#pragma mark - CoreTelephony API

#pragma mark - CoreImage Classes

Class mpsdk_dfl_CIContextClass(void);
Class mpsdk_dfl_CIFilterClass(void);
//Class mpsdk_dfl_CIImageClass(void);

#pragma mark - CoreImage API

NSString *mpsdk_dfl_kCIInputImageKey (void);
NSString *mpsdk_dfl_kCIContextWorkingColorSpace (void);
//id mpsdk_dfl_CIImage_imageWithCGImage (CGImageRef image);

#pragma mark - CoreMedia Classes

#pragma mark - CoreMedia API

CMTime mpsdk_dfl_kCMTimeZero (void);
CMTime mpsdk_dfl_kCMTimeIndefinite (void);
CMTime mpsdk_dfl_kCMTimeInvalid (void);
CMTime mpsdk_dfl_kCMTimeNegativeInfinity (void);
CMTime mpsdk_dfl_kCMTimePositiveInfinity (void);
int32_t mpsdk_dfl_CMTimeCompare (CMTime time1, CMTime time2);
CMTime mpsdk_dfl_CMTimeMaximum (CMTime time1, CMTime time2);
CMTime mpsdk_dfl_CMTimeSubtract (CMTime time1, CMTime time2);
Float64 mpsdk_dfl_CMTimeGetSeconds (CMTime time1);
CMTime mpsdk_dfl_CMTimeMake (int64_t value, int32_t timescale);
CMTime mpsdk_dfl_CMTimeMakeWithSeconds (Float64 seconds, int32_t preferredTimeScale);

OSStatus mpsdk_dfl_CMVideoFormatDescriptionCreateFromH264ParameterSets(CFAllocatorRef allocator, size_t parameterSetCount, const uint8_t * const * parameterSetPointers, const size_t * parameterSetSizes, int NALUnitHeaderLength, CM_RETURNS_RETAINED_PARAMETER CMFormatDescriptionRef * formatDescriptionOut );
OSStatus mpsdk_dfl_CMSampleBufferCreate (CFAllocatorRef allocator, CMBlockBufferRef dataBuffer, Boolean dataReady, CMSampleBufferMakeDataReadyCallback makeDataReadyCallback, void * makeDataReadyRefcon, CMFormatDescriptionRef formatDescription,CMItemCount numSamples, CMItemCount numSampleTimingEntries, const CMSampleTimingInfo * sampleTimingArray,CMItemCount numSampleSizeEntries, const size_t * sampleSizeArray, CM_RETURNS_RETAINED_PARAMETER CMSampleBufferRef * sBufOut);
OSStatus mpsdk_dfl_CMTimebaseSetTimerDispatchSourceNextFireTime (CMTimebaseRef timebase, dispatch_source_t timerSource, CMTime fireTime, uint32_t flags);
OSStatus mpsdk_dfl_CMTimebaseSetRate (CMTimebaseRef timebase, Float64 rate);
OSStatus mpsdk_dfl_CMTimebaseSetTime (CMTimebaseRef timebase, CMTime time);
Boolean mpsdk_dfl_CMBlockBufferIsRangeContiguous (CMBlockBufferRef theBuffer, size_t offset, size_t length);
CVImageBufferRef mpsdk_dfl_CMSampleBufferGetImageBuffer (CMSampleBufferRef sbuf);
OSStatus mpsdk_dfl_CMBlockBufferCreateEmpty (CFAllocatorRef structureAllocator, uint32_t subBlockCapacity, CMBlockBufferFlags flags, CM_RETURNS_RETAINED_PARAMETER CMBlockBufferRef * newBBufOut);
OSStatus mpsdk_dfl_CMBlockBufferCopyDataBytes (CMBlockBufferRef theSourceBuffer, size_t offsetToData, size_t dataLength, void* destination);
CMTime mpsdk_dfl_CMSampleBufferGetDuration (CMSampleBufferRef sbuf);
OSStatus mpsdk_dfl_CMAudioClockCreate (CFAllocatorRef allocator, CM_RETURNS_RETAINED_PARAMETER CMClockRef * clockOut);
CMTime mpsdk_dfl_CMTimeAdd (CMTime addend1, CMTime addend2);
Boolean mpsdk_dfl_CMTimeRangeContainsTime (CMTimeRange range, CMTime time);
CMTime mpsdk_dfl_CMSampleBufferGetOutputPresentationTimeStamp (CMSampleBufferRef sbuf);
CMTime mpsdk_dfl_CMTimebaseGetTime (CMTimebaseRef timebase);
OSStatus mpsdk_dfl_CMSampleBufferGetAudioStreamPacketDescriptionsPtr (CMSampleBufferRef sbuf, const AudioStreamPacketDescription   ** packetDescriptionsPtrOut, size_t * packetDescriptionsSizeOut);
OSStatus mpsdk_dfl_CMSampleBufferGetSampleTimingInfoArray (CMSampleBufferRef sbuf, CMItemCount timingArrayEntries, CMSampleTimingInfo * timingArrayOut, CMItemCount * timingArrayEntriesNeededOut);
OSStatus mpsdk_dfl_CMTimebaseCreateWithMasterClock (CFAllocatorRef allocator, CMClockRef masterClock, CM_RETURNS_RETAINED_PARAMETER CMTimebaseRef * timebaseOut );
CMFormatDescriptionRef mpsdk_dfl_CMSampleBufferGetFormatDescription (CMSampleBufferRef sbuf);
size_t mpsdk_dfl_CMBlockBufferGetDataLength (CMBlockBufferRef theBuffer);
CFArrayRef mpsdk_dfl_CMSampleBufferGetSampleAttachmentsArray (CMSampleBufferRef sbuf, Boolean createIfNecessary);
CMTimeRange mpsdk_dfl_CMTimeRangeMake (CMTime start, CMTime duration);
OSStatus mpsdk_dfl_CMSampleBufferGetSampleTimingInfo (CMSampleBufferRef sbuf, CMItemIndex sampleIndex, CMSampleTimingInfo * timingInfoOut);
OSStatus mpsdk_dfl_CMSampleBufferInvalidate (CMSampleBufferRef sbuf);
CMVideoDimensions mpsdk_dfl_CMVideoFormatDescriptionGetDimensions (CMVideoFormatDescriptionRef videoDesc);
OSStatus mpsdk_dfl_CMBlockBufferGetDataPointer (CMBlockBufferRef theBuffer, size_t offset, size_t * lengthAtOffset, size_t * totalLength, char ** dataPointer);
OSStatus mpsdk_dfl_CMTimebaseAddTimerDispatchSource (CMTimebaseRef timebase, dispatch_source_t timerSource);
CMClockRef mpsdk_dfl_CMClockGetHostTimeClock (void);
CMBlockBufferRef mpsdk_dfl_CMSampleBufferGetDataBuffer (CMSampleBufferRef sbuf);
OSStatus mpsdk_dfl_CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer (CMSampleBufferRef sbuf, size_t * bufferListSizeNeededOut, AudioBufferList * bufferListOut, size_t bufferListSize, CFAllocatorRef bbufStructAllocator, CFAllocatorRef bbufMemoryAllocator, uint32_t flags, CM_RETURNS_RETAINED_PARAMETER CMBlockBufferRef * blockBufferOut);
CMTime mpsdk_dfl_CMSampleBufferGetPresentationTimeStamp (CMSampleBufferRef sbuf);
OSStatus mpsdk_dfl_CMTimebaseRemoveTimerDispatchSource (CMTimebaseRef timebase, dispatch_source_t timerSource);
OSStatus mpsdk_dfl_CMSampleBufferCreateCopyWithNewTiming (CFAllocatorRef allocator, CMSampleBufferRef originalSBuf, CMItemCount numSampleTimingEntries, const CMSampleTimingInfo * sampleTimingArray, CM_RETURNS_RETAINED_PARAMETER CMSampleBufferRef * sBufCopyOut);
AudioStreamBasicDescription *mpsdk_dfl_CMAudioFormatDescriptionGetStreamBasicDescription (CMAudioFormatDescriptionRef desc);
CGSize mpsdk_dfl_CMVideoFormatDescriptionGetPresentationDimensions (CMVideoFormatDescriptionRef videoDesc, Boolean usePixelAspectRatio, Boolean useCleanAperture);
OSStatus mpsdk_dfl_CMBlockBufferAppendMemoryBlock (CMBlockBufferRef theBuffer, void * memoryBlock, size_t blockLength, CFAllocatorRef blockAllocator, const CMBlockBufferCustomBlockSource * customBlockSource, size_t offsetToData, size_t dataLength, CMBlockBufferFlags flags);
//NSString *mpsdk_dfl_kCMSampleAttachmentKey_DisplayImmediately (void);
//NSString *mpsdk_dfl_kCMSampleAttachmentKey_NotSync (void);
//NSString *mpsdk_dfl_kCMSampleAttachmentKey_IsDependedOnByOthers (void);
//NSString *mpsdk_dfl_kCMSampleAttachmentKey_DoNotDisplay (void);
//CFStringRef mpsdk_dfl_kCMSampleAttachmentKey_DisplayImmediatelyStringRef(void);
//CFStringRef mpsdk_dfl_kCMSampleAttachmentKey_NotSyncStringRef(void);
//CFStringRef mpsdk_dfl_kCMSampleAttachmentKey_IsDependedOnByOthersStringRef(void);
//CFStringRef mpsdk_dfl_kCMSampleAttachmentKey_DoNotDisplayStringRef(void);

#define FB_CMTIME_COMPARE_INLINE(time1, comparator, time2) ((Boolean)(mpsdk_dfl_CMTimeCompare(time1, time2) comparator 0))

#pragma mark - AVFoundation Classes

//Class mpsdk_dfl_AVMutableAudioMix(void);
//Class mpsdk_dfl_AVMutableAudioMixInputParameters(void);
//Class mpsdk_dfl_AVPlayer(void);
//Class mpsdk_dfl_AVPlayerItem(void);
//Class mpsdk_dfl_AVPlayerLayer(void);
//Class mpsdk_dfl_AVURLAsset(void);
//Class mpsdk_dfl_AVAudioSession(void);
//Class mpsdk_dfl_AVAssetReader(void);
//Class mpsdk_dfl_AVAssetReaderTrackOutput(void);

#pragma mark - AVFoundation API

NSString *mpsdk_dfl_AVLayerVideoGravityResizeAspect (void);
NSString *mpsdk_dfl_AVLayerVideoGravityResizeAspectFill (void);
NSString *mpsdk_dfl_AVPlayerItemDidPlayToEndTimeNotification (void);
NSString *mpsdk_dfl_AVMediaTypeVideo(void);
NSString *mpsdk_dfl_AVMediaTypeAudio (void);
NSString *mpsdk_dfl_AVPlayerItemFailedToPlayToEndTimeNotification (void);
NSString *mpsdk_dfl_AVPlayerItemPlaybackStalledNotification (void);
NSString *mpsdk_dfl_AVPlayerItemNewErrorLogEntryNotification (void);

#pragma mark - CoreMotion Classes

Class mpsdk_dfl_CMMotionManager(void);

#pragma mark - GLKit Classes

Class mpsdk_dfl_GLKViewClass(void);
Class mpsdk_dfl_EAGLContextClass(void);

#pragma mark - GLKit API

void mpsdk_dfl_glClearColor(float red, float blue, float green, float alpha);
void mpsdk_dfl_glClear(uint32_t flags);
void mpsdk_dfl_glEnable (uint32_t cap);
void mpsdk_dfl_glDisable (uint32_t cap);
void mpsdk_dfl_glBlendFunc (uint32_t sfactor, uint32_t dfactor);
void mpsdk_dfl_glGenRenderbuffers (int32_t n, uint32_t *renderbuffers);
void mpsdk_dfl_glBindRenderbuffer (uint32_t target, uint32_t renderbuffer);
void mpsdk_dfl_glDeleteRenderbuffers (int32_t n, const uint32_t *renderbuffers);
void mpsdk_dfl_glGetRenderbufferParameteriv (uint32_t target, uint32_t pname, int32_t *params);
void mpsdk_dfl_glGenFramebuffers (int32_t n, uint32_t *framebuffers);
void mpsdk_dfl_glBindFramebuffer (uint32_t target, uint32_t framebuffer);
uint32_t mpsdk_dfl_glCheckFramebufferStatus (uint32_t target);
void mpsdk_dfl_glDeleteFramebuffers (int32_t n, const uint32_t *framebuffers);
void mpsdk_dfl_glFramebufferRenderbuffer (uint32_t target, uint32_t attachment, uint32_t renderbuffertarget, uint32_t renderbuffer);
void mpsdk_dfl_glFinish (void);
uint32_t mpsdk_dfl_glCreateProgram (void);
void mpsdk_dfl_glGetProgramiv (uint32_t program, uint32_t pname, int32_t *params);
void mpsdk_dfl_glUseProgram (uint32_t program);
void mpsdk_dfl_glValidateProgram (uint32_t program);
void mpsdk_dfl_glDeleteProgram (uint32_t program);
void mpsdk_dfl_glLinkProgram (uint32_t program);
void mpsdk_dfl_glGetProgramInfoLog (uint32_t program, int32_t bufSize, int32_t *length, char *infoLog);
uint32_t mpsdk_dfl_glCreateShader (uint32_t type);
void mpsdk_dfl_glShaderSource (uint32_t shader, int32_t count, const char* const *string, const int32_t *length);
void mpsdk_dfl_glCompileShader (uint32_t shader);
void mpsdk_dfl_glDeleteShader (uint32_t shader);
void mpsdk_dfl_glAttachShader (uint32_t program, uint32_t shader);
void mpsdk_dfl_glDetachShader (uint32_t program, uint32_t shader);
void mpsdk_dfl_glGetShaderInfoLog (uint32_t shader, int32_t bufSize, int32_t *length, char *infoLog);
void mpsdk_dfl_glGetShaderiv (uint32_t shader, uint32_t pname, int32_t *params);
int32_t mpsdk_dfl_glGetUniformLocation (uint32_t program, const char *name);
void mpsdk_dfl_glBindAttribLocation (uint32_t program, uint32_t index, const char *name);
void mpsdk_dfl_glUniform1i (int32_t location, int32_t v0);
void mpsdk_dfl_glUniformMatrix3fv (int32_t location, int32_t count, uint8_t transpose, const float *value);
void mpsdk_dfl_glViewport (int32_t x, int32_t y, int32_t width, int32_t height);
void mpsdk_dfl_glVertexAttribPointer (uint32_t index, int32_t size, uint32_t type, uint8_t normalized, int32_t stride, const void *pointer);
void mpsdk_dfl_glEnableVertexAttribArray (uint32_t index);
void mpsdk_dfl_glDisableVertexAttribArray (uint32_t index);
void mpsdk_dfl_glBindTexture (uint32_t target, uint32_t texture);
void mpsdk_dfl_glActiveTexture (uint32_t texture);
void mpsdk_dfl_glTexParameterf (uint32_t target, uint32_t pname, float param);
void mpsdk_dfl_glTexParameteri (uint32_t target, uint32_t pname, int32_t param);
void mpsdk_dfl_glUniform1f (int32_t location, float v0);
void mpsdk_dfl_glDrawArrays (uint32_t mode, int32_t first, int32_t count);
void mpsdk_dfl_glFlush (void);
void mpsdk_dfl_glBindBuffer (uint32_t target, uint32_t buffer);
void mpsdk_dfl_glBufferData (uint32_t target, intptr_t size, const void* data, uint32_t usage);
void mpsdk_dfl_glGenBuffers (int32_t n, uint32_t* buffers);
void mpsdk_dfl_glBindVertexArrayOES (uint32_t array);
void mpsdk_dfl_glGenVertexArraysOES (int32_t n, uint32_t *arrays);
void mpsdk_dfl_glCullFace(uint32_t mode);


NSString *mpsdk_dfl_kEAGLDrawablePropertyRetainedBacking(void);
NSString *mpsdk_dfl_kEAGLDrawablePropertyColorFormat(void);
NSString *mpsdk_dfl_kEAGLColorFormatRGBA8(void);
NSString *mpsdk_dfl_kEAGLColorFormatRGB565(void);
NSString *mpsdk_dfl_kEAGLColorFormatSRGBA8(void);

#if __has_include(<MetalKit/MetalKit.h>) && !TARGET_IPHONE_SIMULATOR

#pragma mark - Metal Classes

#pragma mark - Metal API

id<MTLDevice> mpsdk_dfl_MTLCreateSystemDefaultDevice(void);

#pragma mark - MetalKit Classes

Class mpsdk_dfl_MTKViewClass(void);

#pragma mark - MetalKit API

#endif

#pragma mark - WebKit Classes

Class mpsdk_dfl_WKWebViewClass(void);
Class mpsdk_dfl_WKWebViewConfigurationClass(void);
Class mpsdk_dfl_WKProcessPoolClass(void);
void mpsdk_dfl_WKWebViewSetAllowsLinkPreview (id target, BOOL allowsLinkPreview);

#pragma mark - WebKit API

#pragma mark - SystemConfiguration Classes

#pragma mark - SystemConfiguration API

SCNetworkReachabilityRef mpsdk_dfl_SCNetworkReachabilityCreateWithAddress(CFAllocatorRef allocator, const struct sockaddr *address);
BOOL mpsdk_dfl_SCNetworkReachabilityGetFlags(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags);

#pragma mark - zlib API

uLong mpsdk_dfl_zlib_compressBound(uLong sourceLen);
int mpsdk_dfl_zlib_compress(Bytef *dest, uLongf *destLen, const Bytef *source, uLong sourceLen);

#pragma mark - sqlite3 API

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_open(const char *filename, sqlite3 **ppDb);
SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail);
SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_step(sqlite3_stmt* pStmt);
SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_finalize(sqlite3_stmt *pStmt);
SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_bind_text(sqlite3_stmt *pStmt, int idx, const char* str, int a, void(*b)(void*));
SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_bind_int64(sqlite3_stmt *pStmt, int idx, sqlite3_int64 value);
SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_bind_double(sqlite3_stmt *pStmt, int idx, double value);

SQLITE_API const unsigned char * SQLITE_STDCALL mpsdk_dfl_sqlite3_column_text(sqlite3_stmt*, int iCol);
SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_column_int(sqlite3_stmt *pStmt, int iCol);
SQLITE_API sqlite3_int64 SQLITE_STDCALL mpsdk_dfl_sqlite3_column_int64(sqlite3_stmt*, int iCol);
SQLITE_API double SQLITE_STDCALL mpsdk_dfl_sqlite3_column_double(sqlite3_stmt*, int iCol);

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_extended_errcode(sqlite3 *db);
SQLITE_API const char * SQLITE_STDCALL mpsdk_dfl_sqlite3_errmsg(sqlite3 *db);

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_close(sqlite3 *db);

#pragma mark - Foundation API

NSString *mpsdk_dfl_NSExtensionHostWillEnterForegroundNotification(void);
NSString *mpsdk_dfl_NSExtensionHostDidEnterBackgroundNotification(void);
NSString *mpsdk_dfl_NSExtensionHostWillResignActiveNotification(void);
NSString *mpsdk_dfl_NSExtensionHostDidBecomeActiveNotification(void);

FB_EXTERN_C_END

