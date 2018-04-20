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

#import "MPDynamicFrameworkLoader.h"

#import <dlfcn.h>
#import <objc/runtime.h>

#import <StoreKit/StoreKit.h>

#import "MPLogger.h"
#import "MPUtilityFunctions.h"

static NSString *const g_frameworkPathTemplate = @"/System/Library/Frameworks/%@.framework/%@";

#pragma mark - Library and Symbol Loading

struct mpsdk_DFLLoadSymbolContext
{
  void *(*library)(void); // function to retrieve the library handle (it's a function instead of void * so it can be staticlly bound)
  const char *name;       // name of the symbol to retrieve
  void **address;         // [out] address of the symbol in the process address space
};

// Retrieves the handle for a library for framework. The paths for each are constructed
// differently so the loading function passed to dispatch_once() calls this.
static void *mpsdk_dfl_load_library_once(const char *path)
{
  void *handle = dlopen(path, RTLD_LAZY);
  if (handle) {
    MPLogVerbose(@"Dynamically loaded library at %s", path);
  } else {
    MPLogError(@"Failed to load library at %s", path);
  }
  return handle;
}

// Constructs the path for a system framework with the given name and returns the handle for dlsym
static void *mpsdk_dfl_load_framework_once(NSString *framework)
{
  NSString *path = [NSString stringWithFormat:g_frameworkPathTemplate, framework, framework];
  return mpsdk_dfl_load_library_once(path.fileSystemRepresentation);
}

// Implements the callback for dispatch_once() that loads the handle for specified framework name
#define _mpsdk_dfl_load_framework_once_impl_(FRAMEWORK) \
static void mpsdk_dfl_load_##FRAMEWORK##_once(void *context) { \
*(void **)context = mpsdk_dfl_load_framework_once(@#FRAMEWORK); \
}

// Implements the framework/library retrieval function for the given name.
// It calls the loading function once and caches the handle in a local static variable
#define _mpsdk_dfl_handle_get_impl_(LIBRARY) \
static void *mpsdk_dfl_handle_get_##LIBRARY(void) { \
static void *LIBRARY##_handle; \
static dispatch_once_t LIBRARY##_once; \
dispatch_once_f(&LIBRARY##_once, &LIBRARY##_handle, &mpsdk_dfl_load_##LIBRARY##_once); \
return LIBRARY##_handle;\
}

// Callback from dispatch_once() to load a specific symbol
static void mpsdk_dfl_load_symbol_once(void *context)
{
  struct mpsdk_DFLLoadSymbolContext *ctx = context;
  *ctx->address = dlsym(ctx->library(), ctx->name);
}

// The boilerplate code for loading a symbol from a given library once and caching it in a static local
#define _mpsdk_dfl_symbol_get(LIBRARY, PREFIX, SYMBOL, TYPE, VARIABLE_NAME) \
static TYPE VARIABLE_NAME; \
static dispatch_once_t SYMBOL##_once; \
static struct mpsdk_DFLLoadSymbolContext ctx = { .library = &mpsdk_dfl_handle_get_##LIBRARY, .name = PREFIX #SYMBOL, .address = (void **)&VARIABLE_NAME }; \
dispatch_once_f(&SYMBOL##_once, &ctx, &mpsdk_dfl_load_symbol_once)

#define _mpsdk_dfl_symbol_get_c(LIBRARY, SYMBOL) _mpsdk_dfl_symbol_get(LIBRARY, "OBJC_CLASS_$_", SYMBOL, Class, c) // convenience symbol retrieval macro for getting an Objective-C class symbol and storing it in the local static c
#define _mpsdk_dfl_symbol_get_f(LIBRARY, SYMBOL) _mpsdk_dfl_symbol_get(LIBRARY, "", SYMBOL, SYMBOL##_type, f)      // convenience symbol retrieval macro for getting a function pointer and storing it in the local static f
#define _mpsdk_dfl_symbol_get_k(LIBRARY, SYMBOL, TYPE) _mpsdk_dfl_symbol_get(LIBRARY, "", SYMBOL, TYPE, k)         // convenience symbol retrieval macro for getting a pointer to a named variable and storing it in the local static k

// convenience macro for verifying a pointer to a named variable was successfully loaded and returns the value
#define _mpsdk_dfl_return_k(FRAMEWORK, SYMBOL) \
NSCAssert(k != NULL, @"Failed to load constant %@ in the %@ framework", @#SYMBOL, @#FRAMEWORK); \
return *k

// convenience macro for getting a pointer to a named NSString, verifying it loaded correctly, and returning it
#define _mpsdk_dfl_get_and_return_NSString(LIBRARY, SYMBOL) \
_mpsdk_dfl_symbol_get_k(LIBRARY, SYMBOL, NSString **); \
NSCAssert([*k isKindOfClass:[NSString class]], @"Loaded symbol %@ is not of type NSString *", @#SYMBOL); \
_mpsdk_dfl_return_k(LIBRARY, SYMBOL)

#pragma mark - QuartzCore Classes

_mpsdk_dfl_load_framework_once_impl_(QuartzCore)
_mpsdk_dfl_handle_get_impl_(QuartzCore)

#define _mpsdk_dfl_QuartzCore_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(QuartzCore, SYMBOL);

#pragma mark - QuartzCore APIs

#define _mpsdk_dfl_QuartzCore_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(QuartzCore, SYMBOL)

typedef CFTimeInterval (*CACurrentMediaTime_type)(void);
typedef CATransform3D (*CATransform3DMakeScale_type)(CGFloat, CGFloat, CGFloat);
typedef CATransform3D (*CATransform3DMakeTranslation_type)(CGFloat, CGFloat, CGFloat);
typedef CATransform3D (*CATransform3DConcat_type)(CATransform3D, CATransform3D);

CFTimeInterval mpsdk_dfl_CACurrentMediaTime (void)
{
  _mpsdk_dfl_QuartzCore_get_f(CACurrentMediaTime);
  return f();
}

void mpsdk_dfl_CAShapeLayer_setPath(id layer, CGPathRef path)
{
  SEL selector = NSSelectorFromString(@"setPath:");
  IMP imp = [layer methodForSelector:selector];
  void (*func)(id, SEL, CGPathRef) = (void *)imp;
  return func(layer, selector, path);
}

#pragma mark - AudioToolbox APIs

_mpsdk_dfl_load_framework_once_impl_(AudioToolbox)
_mpsdk_dfl_handle_get_impl_(AudioToolbox)

#define _mpsdk_dfl_AudioToolbox_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(AudioToolbox, SYMBOL)

typedef OSStatus (*AudioSessionInitialize_type)(CFRunLoopRef, CFStringRef, AudioSessionInterruptionListener, void *);
typedef OSStatus (*AudioSessionGetProperty_type)(AudioSessionPropertyID, UInt32 *, void *);
typedef OSStatus (*AudioQueueEnqueueBufferWithParameters_type)(AudioQueueRef, AudioQueueBufferRef, UInt32, const AudioStreamPacketDescription *, UInt32, UInt32, UInt32, const AudioQueueParameterEvent *, const AudioTimeStamp *, AudioTimeStamp *);
typedef OSStatus (*AudioQueueStart_type)(AudioQueueRef, const AudioTimeStamp *);
typedef OSStatus (*AudioQueueReset_type)(AudioQueueRef);
typedef OSStatus (*AudioQueueFlush_type)(AudioQueueRef);
typedef OSStatus (*AudioQueueStop_type)(AudioQueueRef, Boolean);
typedef OSStatus (*AudioQueuePause_type)(AudioQueueRef);
typedef OSStatus (*AudioQueueDispose_type)(AudioQueueRef, Boolean inImmediate);
typedef OSStatus (*AudioQueueNewOutput_type)(const AudioStreamBasicDescription *, AudioQueueOutputCallback, void *, CFRunLoopRef, CFStringRef, UInt32, AudioQueueRef *);
typedef OSStatus (*AudioQueueFreeBuffer_type)(AudioQueueRef, AudioQueueBufferRef);
typedef OSStatus (*AudioQueueAllocateBufferWithPacketDescriptions_type)(AudioQueueRef, UInt32, UInt32, AudioQueueBufferRef *);
typedef OSStatus (*AudioQueueGetProperty_type)(AudioQueueRef, AudioQueuePropertyID, void *, UInt32 *);
typedef OSStatus (*AudioQueueSetParameter_type)(AudioQueueRef, AudioQueueParameterID, AudioQueueParameterValue);
typedef OSStatus (*AudioQueueAddPropertyListener_type)(AudioQueueRef, AudioQueuePropertyID, AudioQueuePropertyListenerProc, void *);
typedef OSStatus (*AudioQueueRemovePropertyListener_type)(AudioQueueRef, AudioQueuePropertyID, AudioQueuePropertyListenerProc, void *);
typedef OSStatus (*AudioQueueGetCurrentTime_type)(AudioQueueRef, AudioQueueTimelineRef, AudioTimeStamp *, Boolean *);
typedef OSStatus (*AudioQueueSetProperty_type)(AudioQueueRef, AudioQueuePropertyID, const void *, UInt32);
typedef OSStatus (*AudioQueueCreateTimeline_type)(AudioQueueRef, AudioQueueTimelineRef *);
typedef OSStatus (*AudioQueueDisposeTimeline_type)(AudioQueueRef, AudioQueueTimelineRef);

OSStatus mpsdk_dfl_AudioSessionInitialize(CFRunLoopRef inRunLoop, CFStringRef inRunLoopMode, AudioSessionInterruptionListener inInterruptionListener, void *inClientData)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioSessionInitialize);
  return f(inRunLoop, inRunLoopMode, inInterruptionListener, inClientData);
}

OSStatus mpsdk_dfl_AudioSessionGetProperty(AudioSessionPropertyID inID, UInt32 *ioDataSize, void *outData)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioSessionGetProperty);
  return f(inID, ioDataSize, outData);
}

OSStatus mpsdk_dfl_AudioQueueEnqueueBufferWithParameters(AudioQueueRef inAQ, AudioQueueBufferRef inBuffer, UInt32 inNumPacketDescs, const AudioStreamPacketDescription *inPacketDescs, UInt32 inTrimFramesAtStart, UInt32 inTrimFramesAtEnd, UInt32 inNumParamValues, const AudioQueueParameterEvent *inParamValues, const AudioTimeStamp *inStartTime, AudioTimeStamp *outActualStartTime)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueEnqueueBufferWithParameters);
  return f(inAQ, inBuffer, inNumPacketDescs, inPacketDescs, inTrimFramesAtStart, inTrimFramesAtEnd, inNumParamValues, inParamValues, inStartTime, outActualStartTime);
}

OSStatus mpsdk_dfl_AudioQueueStart(AudioQueueRef inAQ, const AudioTimeStamp *inStartTime)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueStart);
  return f(inAQ, inStartTime);
}

OSStatus mpsdk_dfl_AudioQueueReset(AudioQueueRef inAQ)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueReset);
  return f(inAQ);
}

OSStatus mpsdk_dfl_AudioQueueFlush(AudioQueueRef inAQ)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueFlush);
  return f(inAQ);
}

OSStatus mpsdk_dfl_AudioQueueStop(AudioQueueRef inAQ, Boolean inImmediate)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueStop);
  return f(inAQ, inImmediate);
}

OSStatus mpsdk_dfl_AudioQueuePause(AudioQueueRef inAQ)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueuePause);
  return f(inAQ);
}

OSStatus mpsdk_dfl_AudioQueueDispose(AudioQueueRef inAQ, Boolean inImmediate)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueDispose);
  return f(inAQ, inImmediate);
}

OSStatus mpsdk_dfl_AudioQueueNewOutput(const AudioStreamBasicDescription *inFormat, AudioQueueOutputCallback inCallbackProc, void *inUserData, CFRunLoopRef inCallbackRunLoop, CFStringRef inCallbackRunLoopMode, UInt32 inFlags, AudioQueueRef *outAQ)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueNewOutput);
  return f(inFormat, inCallbackProc, inUserData, inCallbackRunLoop, inCallbackRunLoopMode, inFlags, outAQ);
}

OSStatus mpsdk_dfl_AudioQueueFreeBuffer(AudioQueueRef inAQ, AudioQueueBufferRef inBuffer)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueFreeBuffer);
  return f(inAQ, inBuffer);
}

OSStatus mpsdk_dfl_AudioQueueAllocateBufferWithPacketDescriptions(AudioQueueRef inAQ, UInt32 inBufferByteSize, UInt32 inNumberPacketDescriptions, AudioQueueBufferRef *outBuffer)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueAllocateBufferWithPacketDescriptions);
  return f(inAQ, inBufferByteSize, inNumberPacketDescriptions, outBuffer);
}

OSStatus mpsdk_dfl_AudioQueueGetProperty(AudioQueueRef inAQ, AudioQueuePropertyID inID, void *outData, UInt32 *ioDataSize)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueGetProperty);
  return f(inAQ, inID, outData, ioDataSize);
}

OSStatus mpsdk_dfl_AudioQueueSetParameter(AudioQueueRef inAQ, AudioQueueParameterID inParamID, AudioQueueParameterValue inValue)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueSetParameter);
  return f(inAQ, inParamID, inValue);
}

OSStatus mpsdk_dfl_AudioQueueAddPropertyListener(AudioQueueRef inAQ, AudioQueuePropertyID inID, AudioQueuePropertyListenerProc inProc, void *inUserData)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueAddPropertyListener);
  return f(inAQ, inID, inProc, inUserData);
}

OSStatus mpsdk_dfl_AudioQueueRemovePropertyListener(AudioQueueRef inAQ, AudioQueuePropertyID inID, AudioQueuePropertyListenerProc inProc, void *inUserData)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueRemovePropertyListener);
  return f(inAQ, inID, inProc, inUserData);
}

OSStatus mpsdk_dfl_AudioQueueGetCurrentTime(AudioQueueRef inAQ, AudioQueueTimelineRef inTimeline, AudioTimeStamp *outTimeStamp, Boolean *outTimelineDiscontinuity)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueGetCurrentTime);
  return f(inAQ, inTimeline, outTimeStamp, outTimelineDiscontinuity);
}

OSStatus mpsdk_dfl_AudioQueueSetProperty (AudioQueueRef inAQ, AudioQueuePropertyID inID, const void * inData, UInt32 inDataSize)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueSetProperty);
  return f(inAQ, inID, inData, inDataSize);
}

OSStatus mpsdk_dfl_AudioQueueCreateTimeline (AudioQueueRef inAQ, AudioQueueTimelineRef * outTimeline)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueCreateTimeline);
  return f(inAQ, outTimeline);
}

OSStatus mpsdk_dfl_AudioQueueDisposeTimeline (AudioQueueRef inAQ, AudioQueueTimelineRef inTimeline)
{
  _mpsdk_dfl_AudioToolbox_get_f(AudioQueueDisposeTimeline);
  return f(inAQ, inTimeline);
}

#pragma mark - VideoToolbox APIs

_mpsdk_dfl_load_framework_once_impl_(VideoToolbox)
_mpsdk_dfl_handle_get_impl_(VideoToolbox)

#define _mpsdk_dfl_VideoToolbox_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(VideoToolbox, SYMBOL)

typedef OSStatus (*VTDecompressionSessionDecodeFrame_type)(VTDecompressionSessionRef, CMSampleBufferRef, VTDecodeFrameFlags, void *, VTDecodeInfoFlags *);
typedef void (*VTDecompressionSessionInvalidate_type)(VTDecompressionSessionRef);
typedef OSStatus (*VTDecompressionSessionWaitForAsynchronousFrames_type)(VTDecompressionSessionRef);
typedef Boolean (*VTDecompressionSessionCanAcceptFormatDescription_type)(VTDecompressionSessionRef, CMFormatDescriptionRef);

VTDecompressionSessionCreate_type mpsdk_dfl_VTDecompressionSessionCreateFunc(void)
{
  _mpsdk_dfl_VideoToolbox_get_f(VTDecompressionSessionCreate);
  return f;
}

OSStatus mpsdk_dfl_VTDecompressionSessionCreate(CFAllocatorRef allocator, CMVideoFormatDescriptionRef videoFormatDescription, CFDictionaryRef videoDecoderSpecification, CFDictionaryRef destinationImageBufferAttributes, const VTDecompressionOutputCallbackRecord * outputCallback, CM_RETURNS_RETAINED_PARAMETER VTDecompressionSessionRef * decompressionSessionOut)
{
  VTDecompressionSessionCreate_type f = mpsdk_dfl_VTDecompressionSessionCreateFunc();
  return f(allocator, videoFormatDescription, videoDecoderSpecification, destinationImageBufferAttributes, outputCallback, decompressionSessionOut);
}

OSStatus mpsdk_dfl_VTDecompressionSessionDecodeFrame(VTDecompressionSessionRef session, CMSampleBufferRef sampleBuffer, VTDecodeFrameFlags decodeFlags, void *sourceFrameRefCon, VTDecodeInfoFlags *infoFlagsOut)
{
  _mpsdk_dfl_VideoToolbox_get_f(VTDecompressionSessionDecodeFrame);
  return f(session, sampleBuffer, decodeFlags, sourceFrameRefCon, infoFlagsOut);
}

void mpsdk_dfl_VTDecompressionSessionInvalidate(VTDecompressionSessionRef session)
{
  _mpsdk_dfl_VideoToolbox_get_f(VTDecompressionSessionInvalidate);
  return f(session);
}

OSStatus mpsdk_dfl_VTDecompressionSessionWaitForAsynchronousFrames(VTDecompressionSessionRef session)
{
  _mpsdk_dfl_VideoToolbox_get_f(VTDecompressionSessionWaitForAsynchronousFrames);
  return f(session);
}

Boolean mpsdk_dfl_VTDecompressionSessionCanAcceptFormatDescription(VTDecompressionSessionRef session, CMFormatDescriptionRef newFormatDesc)
{
  _mpsdk_dfl_VideoToolbox_get_f(VTDecompressionSessionCanAcceptFormatDescription);
  return f(session, newFormatDesc);
}

#pragma mark - CoreVideo Classes

_mpsdk_dfl_load_framework_once_impl_(CoreVideo)
_mpsdk_dfl_handle_get_impl_(CoreVideo)

#pragma mark - CoreVideo APIs

#define _mpsdk_dfl_CoreVideo_get_and_return_NSString(SYMBOL) _mpsdk_dfl_get_and_return_NSString(CoreVideo, SYMBOL)

typedef CVReturn (*CVOpenGLESTextureCacheCreate_type)(CFAllocatorRef, CFDictionaryRef, CVEAGLContext, CFDictionaryRef, CVOpenGLESTextureCacheRef *);
typedef void (*CVOpenGLESTextureCacheFlush_type)(CVOpenGLESTextureCacheRef, CVOptionFlags);
typedef CVReturn (*CVOpenGLESTextureCacheCreateTextureFromImage_type)(CFAllocatorRef, CVOpenGLESTextureCacheRef, CVImageBufferRef, CFDictionaryRef, GLenum, GLint, GLsizei, GLsizei, GLenum, GLenum, size_t, CVOpenGLESTextureRef *);
typedef uint32_t (*CVOpenGLESTextureGetTarget_type)(CVOpenGLESTextureRef);
typedef uint32_t (*CVOpenGLESTextureGetName_type)(CVOpenGLESTextureRef);
typedef CFTypeRef (*CVBufferGetAttachment_type)(CVBufferRef, CFStringRef, CVAttachmentMode *);
typedef size_t (*CVPixelBufferGetWidth_type)(CVPixelBufferRef);
typedef size_t (*CVPixelBufferGetHeight_type)(CVPixelBufferRef);
typedef CVReturn (*CVPixelBufferLockBaseAddress_type)( CVPixelBufferRef, CVPixelBufferLockFlags);
typedef void (*CVPixelBufferRelease_type)( CV_RELEASES_ARGUMENT CVPixelBufferRef);
typedef CVPixelBufferRef (*CVPixelBufferRetain_type)( CVPixelBufferRef);
typedef CVReturn (*CVPixelBufferUnlockBaseAddress_type)( CVPixelBufferRef, CVPixelBufferLockFlags);

#if !TARGET_OS_SIMULATOR
typedef IOSurfaceRef (*CVPixelBufferGetIOSurface_type)( CVPixelBufferRef);
#endif

CVReturn mpsdk_dfl_CVOpenGLESTextureCacheCreate(CFAllocatorRef allocator, CFDictionaryRef cacheAttributes, CVEAGLContext eaglContext, CFDictionaryRef textureAttributes, CVOpenGLESTextureCacheRef *cacheOut)
{
  _mpsdk_dfl_VideoToolbox_get_f(CVOpenGLESTextureCacheCreate);
  return f(allocator, cacheAttributes, eaglContext, textureAttributes, cacheOut);
}

void mpsdk_dfl_CVOpenGLESTextureCacheFlush(CVOpenGLESTextureCacheRef textureCache, CVOptionFlags options)
{
  _mpsdk_dfl_VideoToolbox_get_f(CVOpenGLESTextureCacheFlush);
  return f(textureCache, options);
}

CVReturn mpsdk_dfl_CVOpenGLESTextureCacheCreateTextureFromImage(CFAllocatorRef allocator, CVOpenGLESTextureCacheRef textureCache, CVImageBufferRef sourceImage, CFDictionaryRef textureAttributes, GLenum target, GLint internalFormat, GLsizei width, GLsizei height, GLenum format, GLenum type, size_t planeIndex, CVOpenGLESTextureRef *textureOut)
{
  _mpsdk_dfl_VideoToolbox_get_f(CVOpenGLESTextureCacheCreateTextureFromImage);
  return f(allocator, textureCache, sourceImage, textureAttributes, target, internalFormat, width, height, format, type, planeIndex, textureOut);
}

uint32_t mpsdk_dfl_CVOpenGLESTextureGetTarget(CVOpenGLESTextureRef image)
{
  _mpsdk_dfl_VideoToolbox_get_f(CVOpenGLESTextureGetTarget);
  return f(image);
}

uint32_t mpsdk_dfl_CVOpenGLESTextureGetName(CVOpenGLESTextureRef image)
{
  _mpsdk_dfl_VideoToolbox_get_f(CVOpenGLESTextureGetName);
  return f(image);
}

CFTypeRef mpsdk_dfl_CVBufferGetAttachment(CVBufferRef buffer, CFStringRef key, CVAttachmentMode *attachmentMode)
{
  _mpsdk_dfl_VideoToolbox_get_f(CVBufferGetAttachment);
  return f(buffer, key, attachmentMode);
}

size_t mpsdk_dfl_CVPixelBufferGetWidth(CVPixelBufferRef pixelBuffer)
{
  _mpsdk_dfl_VideoToolbox_get_f(CVPixelBufferGetWidth);
  return f(pixelBuffer);
}

size_t mpsdk_dfl_CVPixelBufferGetHeight(CVPixelBufferRef pixelBuffer)
{
  _mpsdk_dfl_VideoToolbox_get_f(CVPixelBufferGetHeight);
  return f(pixelBuffer);
}

//NSString *mpsdk_dfl_kCVPixelBufferOpenGLCompatibilityKey(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVPixelBufferOpenGLCompatibilityKey);
//}
//
//NSString *mpsdk_dfl_kCVPixelBufferOpenGLESCompatibilityKey(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVPixelBufferOpenGLESCompatibilityKey);
//}

//NSString *mpsdk_dfl_kCVPixelBufferOpenGLESTextureCacheCompatibilityKey(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVPixelBufferOpenGLESTextureCacheCompatibilityKey);
//}
//
//NSString *mpsdk_dfl_kCVImageBufferYCbCrMatrix_ITU_R_601_4(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVImageBufferYCbCrMatrix_ITU_R_601_4);
//}
//
//NSString *mpsdk_dfl_kCVImageBufferYCbCrMatrixKey(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVImageBufferYCbCrMatrixKey);
//}
//
//NSString *mpsdk_dfl_kCVPixelBufferPixelFormatTypeKey(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVPixelBufferPixelFormatTypeKey);
//}
//
//NSString *mpsdk_dfl_kCVPixelBufferWidthKey(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVPixelBufferWidthKey);
//}
//
//NSString *mpsdk_dfl_kCVPixelBufferHeightKey(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVPixelBufferHeightKey);
//}

//NSString *mpsdk_dfl_kCVPixelBufferIOSurfacePropertiesKey(void)
//{
//    _mpsdk_dfl_CoreVideo_get_and_return_NSString(kCVPixelBufferIOSurfacePropertiesKey);
//}

//CFStringRef mpsdk_dfl_kCVImageBufferYCbCrMatrix_ITU_R_601_4CFStringRef(void)
//{
//    return (__bridge CFStringRef)mpsdk_dfl_kCVImageBufferYCbCrMatrix_ITU_R_601_4();
//}

//CFStringRef mpsdk_dfl_kCVImageBufferYCbCrMatrixKeyCFStringRef(void)
//{
//    return (__bridge CFStringRef)mpsdk_dfl_kCVImageBufferYCbCrMatrixKey();
//}

CVReturn mpsdk_dfl_CVPixelBufferLockBaseAddress ( CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags lockFlags )
{
  _mpsdk_dfl_VideoToolbox_get_f(CVPixelBufferLockBaseAddress);
  return f(pixelBuffer, lockFlags);
}

void mpsdk_dfl_CVPixelBufferRelease ( CV_RELEASES_ARGUMENT CVPixelBufferRef texture )
{
  _mpsdk_dfl_VideoToolbox_get_f(CVPixelBufferRelease);
  return f(texture);
}

CVPixelBufferRef mpsdk_dfl_CVPixelBufferRetain ( CVPixelBufferRef texture )
{
  _mpsdk_dfl_VideoToolbox_get_f(CVPixelBufferRetain);
  return f(texture);
}

#if !TARGET_OS_SIMULATOR
IOSurfaceRef mpsdk_dfl_kCVPixelBufferGetIOSurface ( CVPixelBufferRef pixelBuffer )
{
  _mpsdk_dfl_VideoToolbox_get_f(CVPixelBufferGetIOSurface);
  return f(pixelBuffer);
}
#endif

CVReturn mpsdk_dfl_CVPixelBufferUnlockBaseAddress ( CVPixelBufferRef pixelBuffer, CVPixelBufferLockFlags unlockFlags )
{
  _mpsdk_dfl_VideoToolbox_get_f(CVPixelBufferUnlockBaseAddress);
  return f(pixelBuffer, unlockFlags);
}

#pragma mark - Ad Support Classes

_mpsdk_dfl_load_framework_once_impl_(AdSupport)
_mpsdk_dfl_handle_get_impl_(AdSupport)

#define _mpsdk_dfl_AdSupport_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(AdSupport, SYMBOL);

//Class mpsdk_dfl_ASIdentifierManagerClass(void)
//{
//    _mpsdk_dfl_AdSupport_get_c(ASIdentifierManager);
//    return c;
//}

#pragma mark - Safari Services
_mpsdk_dfl_load_framework_once_impl_(SafariServices)
_mpsdk_dfl_handle_get_impl_(SafariServices)

#define _mpsdk_dfl_SafariServices_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(SafariServices, SYMBOL);

//Class mpsdk_dfl_SFSafariViewControllerClass(void)
//{
//    _mpsdk_dfl_SafariServices_get_c(SFSafariViewController);
//    return c;
//}

#pragma mark - StoreKit Classes

_mpsdk_dfl_load_framework_once_impl_(StoreKit)
_mpsdk_dfl_handle_get_impl_(StoreKit)

#define _mpsdk_dfl_StoreKit_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(StoreKit, SYMBOL);
#define _mpsdk_dfl_StoreKit_get_and_return_NSString(SYMBOL) _mpsdk_dfl_get_and_return_NSString(StoreKit, SYMBOL)

//Class mpsdk_dfl_SKStoreProductViewControllerClass(void)
//{
//    _mpsdk_dfl_StoreKit_get_c(SKStoreProductViewController);
//    return c;
//}
//
//NSString *mpsdk_dfl_SKStoreProductParameterITunesItemIdentifier(void)
//{
//    _mpsdk_dfl_StoreKit_get_and_return_NSString(SKStoreProductParameterITunesItemIdentifier);
//}

//Class mpsdk_dfl_custom_SKStoreProductViewControllerClass(void)
//{
//    return FB_INITIALIZE_WITH_BLOCK_AND_RETURN_STATIC(^Class {
//        return fb_generate_dynamic_subclass("MPStoreProductViewController",
//                                            mpsdk_dfl_SKStoreProductViewControllerClass(),
//                                            NULL,
//                                            NULL,
//                                            FB_SEL_PAIR_LIST {
//                                                {
//                                                    @selector(supportedInterfaceOrientations),
//                                                    FB_IMP_BLOCK_CAST ^UIInterfaceOrientationMask (void) {
//                                                        return UIInterfaceOrientationMaskAllButUpsideDown;
//                                                    }
//                                                },
//                                                FB_SEL_NIL_PAIR
//                                            });
//    });
//}

#pragma mark - CoreTelephony Classes

_mpsdk_dfl_load_framework_once_impl_(CoreTelephony)
_mpsdk_dfl_handle_get_impl_(CoreTelephony)

#define _mpsdk_dfl_CoreTelephonyLibrary_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(CoreTelephony, SYMBOL);

//Class mpsdk_dfl_CTTelephonyNetworkInfoClass(void)
//{
//    _mpsdk_dfl_CoreTelephonyLibrary_get_c(CTTelephonyNetworkInfo);
//    return c;
//}

#pragma mark - CoreTelephony API

#pragma mark - CoreImage Classes

#define _mpsdk_dfl_CoreImageLibrary_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(CoreImage, SYMBOL);

_mpsdk_dfl_load_framework_once_impl_(CoreImage)
_mpsdk_dfl_handle_get_impl_(CoreImage)
//
//Class mpsdk_dfl_CIContextClass(void)
//{
//    _mpsdk_dfl_CoreImageLibrary_get_c(CIContext);
//    return c;
//}
//
//Class mpsdk_dfl_CIFilterClass(void)
//{
//    _mpsdk_dfl_CoreImageLibrary_get_c(CIFilter);
//    return c;
//}
//
//Class mpsdk_dfl_CIImageClass(void)
//{
//    _mpsdk_dfl_CoreImageLibrary_get_c(CIImage);
//    return c;
//}


#pragma mark - CoreImage API

#define _mpsdk_dfl_CoreImage_get_and_return_NSString(SYMBOL) _mpsdk_dfl_get_and_return_NSString(CoreImage, SYMBOL)

//NSString *mpsdk_dfl_kCIInputImageKey (void)
//{
//    _mpsdk_dfl_CoreImage_get_and_return_NSString(kCIInputImageKey);
//}
//
//NSString *mpsdk_dfl_kCIContextWorkingColorSpace (void)
//{
//    _mpsdk_dfl_CoreImage_get_and_return_NSString(kCIContextWorkingColorSpace);
//}

//id mpsdk_dfl_CIImage_imageWithCGImage (CGImageRef image)
//{
//    SEL selector = nil;
//    IMP imp = nil;
//
//    selector = NSSelectorFromString(@"imageWithCGImage:");
//    imp = [mpsdk_dfl_CIImageClass() methodForSelector:selector];
//    id (*func)(id, SEL, CGImageRef) = (void *)imp;
//    return func ? func(mpsdk_dfl_CIImageClass(), selector, image) : nil;
//}

#pragma mark - CoreMedia Classes

_mpsdk_dfl_load_framework_once_impl_(CoreMedia)
_mpsdk_dfl_handle_get_impl_(CoreMedia)

#pragma mark - CoreMedia API

#define _mpsdk_dfl_CoreMedia_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(CoreMedia, SYMBOL)
#define _mpsdk_dfl_CoreMedia_get_and_return_NSString(SYMBOL) _mpsdk_dfl_get_and_return_NSString(CoreMedia, SYMBOL)
#define _mpsdk_dfl_CoreMedia_get_k(SYMBOL) _mpsdk_dfl_symbol_get_k(CoreMedia, SYMBOL, CMTime *)

#define _mpsdk_dfl_CoreMedia_get_and_return_k(SYMBOL) \
_mpsdk_dfl_CoreMedia_get_k(SYMBOL); \
_mpsdk_dfl_return_k(CoreMedia, SYMBOL)

typedef int32_t (*CMTimeCompare_type)(CMTime, CMTime);
typedef CMTime (*CMTimeMaximum_type)(CMTime, CMTime);
typedef CMTime (*CMTimeSubtract_type)(CMTime, CMTime);
typedef Float64 (*CMTimeGetSeconds_type)(CMTime);
typedef CMTime (*CMTimeMake_type)(int64_t, int32_t);
typedef CMTime (*CMTimeMakeWithSeconds_type)(Float64, int32_t);
typedef OSStatus (*CMVideoFormatDescriptionCreateFromH264ParameterSets_type)(CFAllocatorRef, size_t, const uint8_t * const *, const size_t *, int, CM_RETURNS_RETAINED_PARAMETER CMFormatDescriptionRef *);
typedef OSStatus (*CMSampleBufferCreate_type)(CFAllocatorRef, CMBlockBufferRef, Boolean, CMSampleBufferMakeDataReadyCallback, void *, CMFormatDescriptionRef, CMItemCount, CMItemCount, const CMSampleTimingInfo *,CMItemCount, const size_t *, CM_RETURNS_RETAINED_PARAMETER CMSampleBufferRef *);
typedef OSStatus (*CMTimebaseSetTimerDispatchSourceNextFireTime_type)(CMTimebaseRef, dispatch_source_t, CMTime, uint32_t);
typedef OSStatus (*CMTimebaseSetRate_type)(CMTimebaseRef, Float64);
typedef OSStatus (*CMTimebaseSetTime_type)(CMTimebaseRef, CMTime);
typedef Boolean (*CMBlockBufferIsRangeContiguous_type)(CMBlockBufferRef, size_t, size_t);
typedef CVImageBufferRef (*CMSampleBufferGetImageBuffer_type)(CMSampleBufferRef);
typedef OSStatus (*CMBlockBufferCreateEmpty_type)(CFAllocatorRef, uint32_t, CMBlockBufferFlags, CM_RETURNS_RETAINED_PARAMETER CMBlockBufferRef *);
typedef OSStatus (*CMBlockBufferCopyDataBytes_type)(CMBlockBufferRef, size_t, size_t, void*);
typedef CMTime (*CMSampleBufferGetDuration_type)(CMSampleBufferRef);
typedef OSStatus (*CMAudioClockCreate_type)(CFAllocatorRef, CM_RETURNS_RETAINED_PARAMETER CMClockRef *);
typedef CMTime (*CMTimeAdd_type)(CMTime, CMTime);
typedef Boolean (*CMTimeRangeContainsTime_type)(CMTimeRange, CMTime);
typedef CMTime (*CMSampleBufferGetOutputPresentationTimeStamp_type)(CMSampleBufferRef);
typedef CMTime (*CMTimebaseGetTime_type)(CMTimebaseRef);
typedef OSStatus (*CMSampleBufferGetAudioStreamPacketDescriptionsPtr_type)(CMSampleBufferRef, const AudioStreamPacketDescription  **, size_t *);
typedef OSStatus (*CMSampleBufferGetSampleTimingInfoArray_type)(CMSampleBufferRef, CMItemCount, CMSampleTimingInfo *, CMItemCount *);
typedef OSStatus (*CMTimebaseCreateWithMasterClock_type)(CFAllocatorRef, CMClockRef, CM_RETURNS_RETAINED_PARAMETER CMTimebaseRef *);
typedef CMFormatDescriptionRef (*CMSampleBufferGetFormatDescription_type)(CMSampleBufferRef);
typedef size_t (*CMBlockBufferGetDataLength_type)(CMBlockBufferRef);
typedef CFArrayRef (*CMSampleBufferGetSampleAttachmentsArray_type)(CMSampleBufferRef, Boolean);
typedef CMTimeRange (*CMTimeRangeMake_type)(CMTime, CMTime);
typedef OSStatus (*CMSampleBufferGetSampleTimingInfo_type)(CMSampleBufferRef, CMItemIndex, CMSampleTimingInfo *);
typedef OSStatus (*CMSampleBufferInvalidate_type)(CMSampleBufferRef);
typedef CMVideoDimensions (*CMVideoFormatDescriptionGetDimensions_type)(CMVideoFormatDescriptionRef);
typedef OSStatus (*CMBlockBufferGetDataPointer_type)(CMBlockBufferRef, size_t, size_t *, size_t *, char **);
typedef OSStatus (*CMTimebaseAddTimerDispatchSource_type)(CMTimebaseRef, dispatch_source_t);
typedef CMClockRef (*CMClockGetHostTimeClock_type)(void);
typedef CMBlockBufferRef (*CMSampleBufferGetDataBuffer_type)(CMSampleBufferRef);
typedef OSStatus (*CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer_type)(CMSampleBufferRef, size_t *, AudioBufferList *, size_t, CFAllocatorRef, CFAllocatorRef, uint32_t, CM_RETURNS_RETAINED_PARAMETER CMBlockBufferRef *);
typedef CMTime (*CMSampleBufferGetPresentationTimeStamp_type)(CMSampleBufferRef);
typedef OSStatus (*CMTimebaseRemoveTimerDispatchSource_type)(CMTimebaseRef, dispatch_source_t);
typedef OSStatus (*CMSampleBufferCreateCopyWithNewTiming_type)(CFAllocatorRef, CMSampleBufferRef, CMItemCount, const CMSampleTimingInfo *, CM_RETURNS_RETAINED_PARAMETER CMSampleBufferRef *);
typedef AudioStreamBasicDescription *(*CMAudioFormatDescriptionGetStreamBasicDescription_type)(CMAudioFormatDescriptionRef);
typedef CGSize (*CMVideoFormatDescriptionGetPresentationDimensions_type)(CMVideoFormatDescriptionRef, Boolean, Boolean);
typedef OSStatus (*CMBlockBufferAppendMemoryBlock_type)(CMBlockBufferRef, void *, size_t, CFAllocatorRef, const CMBlockBufferCustomBlockSource *, size_t, size_t, CMBlockBufferFlags);

CMTime mpsdk_dfl_kCMTimeZero (void)
{
  _mpsdk_dfl_CoreMedia_get_and_return_k(kCMTimeZero);
}

CMTime mpsdk_dfl_kCMTimeIndefinite (void)
{
  _mpsdk_dfl_CoreMedia_get_and_return_k(kCMTimeIndefinite);
}

CMTime mpsdk_dfl_kCMTimeInvalid (void)
{
  _mpsdk_dfl_CoreMedia_get_and_return_k(kCMTimeInvalid);
}

CMTime mpsdk_dfl_kCMTimeNegativeInfinity (void)
{
  _mpsdk_dfl_CoreMedia_get_and_return_k(kCMTimeNegativeInfinity);
}

CMTime mpsdk_dfl_kCMTimePositiveInfinity (void)
{
  _mpsdk_dfl_CoreMedia_get_and_return_k(kCMTimePositiveInfinity);
}

int32_t mpsdk_dfl_CMTimeCompare (CMTime time1, CMTime time2)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeCompare);
  return f(time1, time2);
}

CMTime mpsdk_dfl_CMTimeMaximum (CMTime time1, CMTime time2)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeMaximum);
  return f(time1, time2);
}

CMTime mpsdk_dfl_CMTimeSubtract (CMTime time1, CMTime time2)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeSubtract);
  return f(time1, time2);
}

Float64 mpsdk_dfl_CMTimeGetSeconds (CMTime time1)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeGetSeconds);
  return f(time1);
}

CMTime mpsdk_dfl_CMTimeMake (int64_t value, int32_t timescale)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeMake);
  return f(value, timescale);
}

CMTime mpsdk_dfl_CMTimeMakeWithSeconds (Float64 seconds, int32_t preferredTimeScale)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeMakeWithSeconds);
  return f(seconds, preferredTimeScale);
}

OSStatus mpsdk_dfl_CMVideoFormatDescriptionCreateFromH264ParameterSets(CFAllocatorRef allocator, size_t parameterSetCount, const uint8_t * const * parameterSetPointers, const size_t * parameterSetSizes, int NALUnitHeaderLength, CM_RETURNS_RETAINED_PARAMETER CMFormatDescriptionRef * formatDescriptionOut )
{
  _mpsdk_dfl_CoreMedia_get_f(CMVideoFormatDescriptionCreateFromH264ParameterSets);
  return f(allocator, parameterSetCount, parameterSetPointers, parameterSetSizes, NALUnitHeaderLength, formatDescriptionOut);
}

OSStatus mpsdk_dfl_CMSampleBufferCreate (CFAllocatorRef allocator, CMBlockBufferRef dataBuffer, Boolean dataReady, CMSampleBufferMakeDataReadyCallback makeDataReadyCallback, void * makeDataReadyRefcon, CMFormatDescriptionRef formatDescription,CMItemCount numSamples, CMItemCount numSampleTimingEntries, const CMSampleTimingInfo * sampleTimingArray,CMItemCount numSampleSizeEntries, const size_t * sampleSizeArray, CM_RETURNS_RETAINED_PARAMETER CMSampleBufferRef * sBufOut)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferCreate);
  return f(allocator, dataBuffer, dataReady, makeDataReadyCallback, makeDataReadyRefcon, formatDescription, numSamples, numSampleTimingEntries, sampleTimingArray, numSampleSizeEntries, sampleSizeArray, sBufOut);
}

OSStatus mpsdk_dfl_CMTimebaseSetTimerDispatchSourceNextFireTime (CMTimebaseRef timebase, dispatch_source_t timerSource, CMTime fireTime, uint32_t flags)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimebaseSetTimerDispatchSourceNextFireTime);
  return f(timebase, timerSource, fireTime, flags);
}

OSStatus mpsdk_dfl_CMTimebaseSetRate (CMTimebaseRef timebase, Float64 rate)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimebaseSetRate);
  return f(timebase, rate);
}

OSStatus mpsdk_dfl_CMTimebaseSetTime (CMTimebaseRef timebase, CMTime time)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimebaseSetTime);
  return f(timebase, time);
}

Boolean mpsdk_dfl_CMBlockBufferIsRangeContiguous (CMBlockBufferRef theBuffer, size_t offset, size_t length)
{
  _mpsdk_dfl_CoreMedia_get_f(CMBlockBufferIsRangeContiguous);
  return f(theBuffer, offset, length);
}

CVImageBufferRef mpsdk_dfl_CMSampleBufferGetImageBuffer (CMSampleBufferRef sbuf)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetImageBuffer);
  return f(sbuf);
}

OSStatus mpsdk_dfl_CMBlockBufferCreateEmpty (CFAllocatorRef structureAllocator, uint32_t subBlockCapacity, CMBlockBufferFlags flags, CM_RETURNS_RETAINED_PARAMETER CMBlockBufferRef * newBBufOut)
{
  _mpsdk_dfl_CoreMedia_get_f(CMBlockBufferCreateEmpty);
  return f(structureAllocator, subBlockCapacity, flags, newBBufOut);
}

OSStatus mpsdk_dfl_CMBlockBufferCopyDataBytes (CMBlockBufferRef theSourceBuffer, size_t offsetToData, size_t dataLength, void* destination)
{
  _mpsdk_dfl_CoreMedia_get_f(CMBlockBufferCopyDataBytes);
  return f(theSourceBuffer, offsetToData, dataLength, destination);
}

CMTime mpsdk_dfl_CMSampleBufferGetDuration (CMSampleBufferRef sbuf)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetDuration);
  return f(sbuf);
}

OSStatus mpsdk_dfl_CMAudioClockCreate (CFAllocatorRef allocator, CM_RETURNS_RETAINED_PARAMETER CMClockRef * clockOut)
{
  _mpsdk_dfl_CoreMedia_get_f(CMAudioClockCreate);
  return f(allocator, clockOut);
}

CMTime mpsdk_dfl_CMTimeAdd (CMTime addend1, CMTime addend2)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeAdd);
  return f(addend1, addend2);
}

Boolean mpsdk_dfl_CMTimeRangeContainsTime (CMTimeRange range, CMTime time)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeRangeContainsTime);
  return f(range, time);
}

CMTime mpsdk_dfl_CMSampleBufferGetOutputPresentationTimeStamp (CMSampleBufferRef sbuf)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetOutputPresentationTimeStamp);
  return f(sbuf);
}

CMTime mpsdk_dfl_CMTimebaseGetTime (CMTimebaseRef timebase)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimebaseGetTime);
  return f(timebase);
}

OSStatus mpsdk_dfl_CMSampleBufferGetAudioStreamPacketDescriptionsPtr (CMSampleBufferRef sbuf, const AudioStreamPacketDescription   ** packetDescriptionsPtrOut, size_t * packetDescriptionsSizeOut)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetAudioStreamPacketDescriptionsPtr);
  return f(sbuf, packetDescriptionsPtrOut, packetDescriptionsSizeOut);
}

OSStatus mpsdk_dfl_CMSampleBufferGetSampleTimingInfoArray (CMSampleBufferRef sbuf, CMItemCount timingArrayEntries, CMSampleTimingInfo * timingArrayOut, CMItemCount * timingArrayEntriesNeededOut)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetSampleTimingInfoArray);
  return f(sbuf, timingArrayEntries, timingArrayOut, timingArrayEntriesNeededOut);
}

OSStatus mpsdk_dfl_CMTimebaseCreateWithMasterClock (CFAllocatorRef allocator, CMClockRef masterClock, CM_RETURNS_RETAINED_PARAMETER CMTimebaseRef * timebaseOut )
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimebaseCreateWithMasterClock);
  return f(allocator, masterClock, timebaseOut);
}

CMFormatDescriptionRef mpsdk_dfl_CMSampleBufferGetFormatDescription (CMSampleBufferRef sbuf)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetFormatDescription);
  return f(sbuf);
}

size_t mpsdk_dfl_CMBlockBufferGetDataLength (CMBlockBufferRef theBuffer)
{
  _mpsdk_dfl_CoreMedia_get_f(CMBlockBufferGetDataLength);
  return f(theBuffer);
}

CFArrayRef mpsdk_dfl_CMSampleBufferGetSampleAttachmentsArray (CMSampleBufferRef sbuf, Boolean createIfNecessary)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetSampleAttachmentsArray);
  return f(sbuf, createIfNecessary);
}

CMTimeRange mpsdk_dfl_CMTimeRangeMake (CMTime start, CMTime duration)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimeRangeMake);
  return f(start, duration);
}

OSStatus mpsdk_dfl_CMSampleBufferGetSampleTimingInfo (CMSampleBufferRef sbuf, CMItemIndex sampleIndex, CMSampleTimingInfo * timingInfoOut)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetSampleTimingInfo);
  return f(sbuf, sampleIndex, timingInfoOut);
}

OSStatus mpsdk_dfl_CMSampleBufferInvalidate (CMSampleBufferRef sbuf)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferInvalidate);
  return f(sbuf);
}

CMVideoDimensions mpsdk_dfl_CMVideoFormatDescriptionGetDimensions (CMVideoFormatDescriptionRef videoDesc)
{
  _mpsdk_dfl_CoreMedia_get_f(CMVideoFormatDescriptionGetDimensions);
  return f(videoDesc);
}

OSStatus mpsdk_dfl_CMBlockBufferGetDataPointer (CMBlockBufferRef theBuffer, size_t offset, size_t * lengthAtOffset, size_t * totalLength, char ** dataPointer)
{
  _mpsdk_dfl_CoreMedia_get_f(CMBlockBufferGetDataPointer);
  return f(theBuffer, offset, lengthAtOffset, totalLength, dataPointer);
}

OSStatus mpsdk_dfl_CMTimebaseAddTimerDispatchSource (CMTimebaseRef timebase, dispatch_source_t timerSource)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimebaseAddTimerDispatchSource);
  return f(timebase, timerSource);
}

CMClockRef mpsdk_dfl_CMClockGetHostTimeClock (void)
{
  _mpsdk_dfl_CoreMedia_get_f(CMClockGetHostTimeClock);
  return f();
}

CMBlockBufferRef mpsdk_dfl_CMSampleBufferGetDataBuffer (CMSampleBufferRef sbuf)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetDataBuffer);
  return f(sbuf);
}

OSStatus mpsdk_dfl_CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer (CMSampleBufferRef sbuf, size_t * bufferListSizeNeededOut, AudioBufferList * bufferListOut, size_t bufferListSize, CFAllocatorRef bbufStructAllocator, CFAllocatorRef bbufMemoryAllocator, uint32_t flags, CM_RETURNS_RETAINED_PARAMETER CMBlockBufferRef * blockBufferOut)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer);
  return f(sbuf, bufferListSizeNeededOut, bufferListOut, bufferListSize, bbufStructAllocator, bbufMemoryAllocator, flags, blockBufferOut);
}

CMTime mpsdk_dfl_CMSampleBufferGetPresentationTimeStamp (CMSampleBufferRef sbuf)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferGetPresentationTimeStamp);
  return f(sbuf);
}

OSStatus mpsdk_dfl_CMTimebaseRemoveTimerDispatchSource (CMTimebaseRef timebase, dispatch_source_t timerSource)
{
  _mpsdk_dfl_CoreMedia_get_f(CMTimebaseRemoveTimerDispatchSource);
  return f(timebase, timerSource);
}

OSStatus mpsdk_dfl_CMSampleBufferCreateCopyWithNewTiming (CFAllocatorRef allocator, CMSampleBufferRef originalSBuf, CMItemCount numSampleTimingEntries, const CMSampleTimingInfo * sampleTimingArray, CM_RETURNS_RETAINED_PARAMETER CMSampleBufferRef * sBufCopyOut)
{
  _mpsdk_dfl_CoreMedia_get_f(CMSampleBufferCreateCopyWithNewTiming);
  return f(allocator, originalSBuf, numSampleTimingEntries, sampleTimingArray, sBufCopyOut);
}

AudioStreamBasicDescription *mpsdk_dfl_CMAudioFormatDescriptionGetStreamBasicDescription (CMAudioFormatDescriptionRef desc)
{
  _mpsdk_dfl_CoreMedia_get_f(CMAudioFormatDescriptionGetStreamBasicDescription);
  return f(desc);
}

CGSize mpsdk_dfl_CMVideoFormatDescriptionGetPresentationDimensions (CMVideoFormatDescriptionRef videoDesc, Boolean usePixelAspectRatio, Boolean useCleanAperture )
{
  _mpsdk_dfl_CoreMedia_get_f(CMVideoFormatDescriptionGetPresentationDimensions);
  return f(videoDesc, usePixelAspectRatio, useCleanAperture);
}

OSStatus mpsdk_dfl_CMBlockBufferAppendMemoryBlock (CMBlockBufferRef theBuffer, void * memoryBlock, size_t blockLength, CFAllocatorRef blockAllocator, const CMBlockBufferCustomBlockSource * customBlockSource, size_t offsetToData, size_t dataLength, CMBlockBufferFlags flags)
{
  _mpsdk_dfl_CoreMedia_get_f(CMBlockBufferAppendMemoryBlock);
  return f(theBuffer, memoryBlock, blockLength, blockAllocator, customBlockSource, offsetToData, dataLength, flags);
}

//NSString *mpsdk_dfl_kCMSampleAttachmentKey_DisplayImmediately (void)
//{
//    _mpsdk_dfl_CoreMedia_get_and_return_NSString(kCMSampleAttachmentKey_DisplayImmediately);
//}

//NSString *mpsdk_dfl_kCMSampleAttachmentKey_NotSync (void)
//{
//    _mpsdk_dfl_CoreMedia_get_and_return_NSString(kCMSampleAttachmentKey_NotSync);
//}
//
//NSString *mpsdk_dfl_kCMSampleAttachmentKey_IsDependedOnByOthers (void)
//{
//    _mpsdk_dfl_CoreMedia_get_and_return_NSString(kCMSampleAttachmentKey_IsDependedOnByOthers);
//}
//
//NSString *mpsdk_dfl_kCMSampleAttachmentKey_DoNotDisplay (void)
//{
//    _mpsdk_dfl_CoreMedia_get_and_return_NSString(kCMSampleAttachmentKey_DoNotDisplay);
//}

//CFStringRef mpsdk_dfl_kCMSampleAttachmentKey_DisplayImmediatelyStringRef(void)
//{
//    return (__bridge CFStringRef)mpsdk_dfl_kCMSampleAttachmentKey_DisplayImmediately();
//}

//CFStringRef mpsdk_dfl_kCMSampleAttachmentKey_NotSyncStringRef(void)
//{
//    return (__bridge CFStringRef)mpsdk_dfl_kCMSampleAttachmentKey_NotSync();
//}

//CFStringRef mpsdk_dfl_kCMSampleAttachmentKey_IsDependedOnByOthersStringRef(void)
//{
//    return (__bridge CFStringRef)mpsdk_dfl_kCMSampleAttachmentKey_IsDependedOnByOthers();
//}

//CFStringRef mpsdk_dfl_kCMSampleAttachmentKey_DoNotDisplayStringRef(void)
//{
//    return (__bridge CFStringRef)mpsdk_dfl_kCMSampleAttachmentKey_DoNotDisplay();
//}

#pragma mark - AVFoundation Classes

#define _mpsdk_dfl_AVFoundationLibrary_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(AVFoundation, SYMBOL);

_mpsdk_dfl_load_framework_once_impl_(AVFoundation)
_mpsdk_dfl_handle_get_impl_(AVFoundation)

//Class mpsdk_dfl_AVMutableAudioMix(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVMutableAudioMix);
//    return c;
//}
//
//Class mpsdk_dfl_AVMutableAudioMixInputParameters(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVMutableAudioMixInputParameters);
//    return c;
//}
//
//Class mpsdk_dfl_AVPlayer(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVPlayer);
//    return c;
//}
//
//Class mpsdk_dfl_AVPlayerItem(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVPlayerItem);
//    return c;
//}
//
//Class mpsdk_dfl_AVPlayerLayer(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVPlayerLayer);
//    return c;
//}

//Class mpsdk_dfl_AVURLAsset(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVURLAsset);
//    return c;
//}
//
//Class mpsdk_dfl_AVAudioSession(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVAudioSession);
//    return c;
//}
//
//Class mpsdk_dfl_AVAssetReader(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVAssetReader);
//    return c;
//}

//Class mpsdk_dfl_AVAssetReaderTrackOutput(void)
//{
//    _mpsdk_dfl_AVFoundationLibrary_get_c(AVAssetReaderTrackOutput);
//    return c;
//}

#pragma mark - AVFoundation API

#define _mpsdk_dfl_AVFoundation_get_and_return_NSString(SYMBOL) _mpsdk_dfl_get_and_return_NSString(AVFoundation, SYMBOL)

//NSString *mpsdk_dfl_AVLayerVideoGravityResizeAspect (void)
//{
//    _mpsdk_dfl_AVFoundation_get_and_return_NSString(AVLayerVideoGravityResizeAspect);
//}
//
//NSString *mpsdk_dfl_AVLayerVideoGravityResizeAspectFill (void)
//{
//    _mpsdk_dfl_AVFoundation_get_and_return_NSString(AVLayerVideoGravityResizeAspectFill);
//}
//
//NSString *mpsdk_dfl_AVMediaTypeVideo (void)
//{
//    _mpsdk_dfl_AVFoundation_get_and_return_NSString(AVMediaTypeVideo);
//}
//
//NSString *mpsdk_dfl_AVMediaTypeAudio (void)
//{
//    _mpsdk_dfl_AVFoundation_get_and_return_NSString(AVMediaTypeAudio);
//}
//
//NSString *mpsdk_dfl_AVPlayerItemDidPlayToEndTimeNotification (void)
//{
//    _mpsdk_dfl_AVFoundation_get_and_return_NSString(AVPlayerItemDidPlayToEndTimeNotification);
//}
//
//NSString *mpsdk_dfl_AVPlayerItemFailedToPlayToEndTimeNotification (void)
//{
//    _mpsdk_dfl_AVFoundation_get_and_return_NSString(AVPlayerItemFailedToPlayToEndTimeNotification);
//}
//
//NSString *mpsdk_dfl_AVPlayerItemPlaybackStalledNotification (void)
//{
//    _mpsdk_dfl_AVFoundation_get_and_return_NSString(AVPlayerItemPlaybackStalledNotification);
//}
//
//NSString *mpsdk_dfl_AVPlayerItemNewErrorLogEntryNotification (void)
//{
//    _mpsdk_dfl_AVFoundation_get_and_return_NSString(AVPlayerItemNewErrorLogEntryNotification);
//}

#pragma mark - CoreMotion Classes

#define _mpsdk_dfl_CoreMotionLibrary_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(CoreMotion, SYMBOL);

_mpsdk_dfl_load_framework_once_impl_(CoreMotion)
_mpsdk_dfl_handle_get_impl_(CoreMotion)

//Class mpsdk_dfl_CMMotionManager(void)
//{
//    _mpsdk_dfl_CoreMotionLibrary_get_c(CMMotionManager);
//    return c;
//}

#pragma mark - GLKit Classes

#define _mpsdk_dfl_GLKitLibrary_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(GLKit, SYMBOL);

_mpsdk_dfl_load_framework_once_impl_(GLKit)
_mpsdk_dfl_handle_get_impl_(GLKit)

//Class mpsdk_dfl_GLKViewClass(void)
//{
//    _mpsdk_dfl_GLKitLibrary_get_c(GLKView);
//    return c;
//}

//Class mpsdk_dfl_EAGLContextClass(void)
//{
//    _mpsdk_dfl_GLKitLibrary_get_c(EAGLContext);
//    return c;
//}

#pragma mark - GLKit API

#define _mpsdk_dfl_GLKit_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(GLKit, SYMBOL)
#define _mpsdk_dfl_GLKit_get_and_return_NSString(SYMBOL) _mpsdk_dfl_get_and_return_NSString(GLKit, SYMBOL)

typedef void (*glClearColor_type)(float, float, float, float);
typedef void (*glClear_type)(uint32_t);
typedef void (*glEnable_type)(uint32_t);
typedef void (*glDisable_type)(uint32_t);
typedef void (*glBlendFunc_type)(uint32_t, uint32_t);
typedef void (*glGenRenderbuffers_type)(int32_t, uint32_t *);
typedef void (*glBindRenderbuffer_type)(uint32_t, uint32_t);
typedef void (*glDeleteRenderbuffers_type)(int32_t, const uint32_t *);
typedef void (*glGetRenderbufferParameteriv_type)(uint32_t, uint32_t, int32_t *);
typedef void (*glGenFramebuffers_type)(int32_t, uint32_t *);
typedef void (*glBindFramebuffer_type)(uint32_t, uint32_t);
typedef uint32_t (*glCheckFramebufferStatus_type)(uint32_t);
typedef void (*glDeleteFramebuffers_type)(int32_t, const uint32_t *);
typedef void (*glFramebufferRenderbuffer_type)(uint32_t, uint32_t, uint32_t, uint32_t);
typedef void (*glFinish_type)(void);
typedef uint32_t (*glCreateProgram_type)(void);
typedef void (*glGetProgramiv_type)(uint32_t, uint32_t, int32_t *);
typedef void (*glUseProgram_type)(uint32_t);
typedef void (*glValidateProgram_type)(uint32_t);
typedef void (*glDeleteProgram_type)(uint32_t);
typedef void (*glLinkProgram_type)(uint32_t);
typedef void (*glGetProgramInfoLog_type)(uint32_t, int32_t, int32_t *, char *);
typedef uint32_t (*glCreateShader_type)(uint32_t);
typedef void (*glShaderSource_type)(uint32_t, int32_t, const char* const *, const int32_t *);
typedef void (*glCompileShader_type)(uint32_t);
typedef void (*glDeleteShader_type)(uint32_t);
typedef void (*glAttachShader_type)(uint32_t, uint32_t);
typedef void (*glDetachShader_type)(uint32_t, uint32_t);
typedef void (*glGetShaderInfoLog_type)(uint32_t, int32_t, int32_t *, char *);
typedef void (*glGetShaderiv_type)(uint32_t, uint32_t, int32_t *);
typedef int32_t (*glGetUniformLocation_type)(uint32_t, const char *);
typedef void (*glBindAttribLocation_type)(uint32_t, uint32_t, const char *);
typedef void (*glUniform1i_type)(int32_t, int32_t);
typedef void (*glUniformMatrix3fv_type)(int32_t, int32_t, uint8_t, const float *);
typedef void (*glViewport_type)(int32_t, int32_t, int32_t, int32_t);
typedef void (*glVertexAttribPointer_type)(uint32_t, int32_t, uint32_t, uint8_t, int32_t, const void *);
typedef void (*glEnableVertexAttribArray_type)(uint32_t);
typedef void (*glDisableVertexAttribArray_type)(uint32_t);
typedef void (*glBindTexture_type)(uint32_t, uint32_t);
typedef void (*glActiveTexture_type)(uint32_t);
typedef void (*glTexParameterf_type)(uint32_t, uint32_t, float);
typedef void (*glTexParameteri_type)(uint32_t, uint32_t, int32_t);
typedef void (*glUniform1f_type)(int32_t, float);
typedef void (*glDrawArrays_type)(uint32_t, int32_t, int32_t);
typedef void (*glFlush_type)(void);
typedef void (*glBindBuffer_type)(uint32_t, uint32_t);
typedef void (*glBufferData_type)(uint32_t, intptr_t, const void*, uint32_t);
typedef void (*glGenBuffers_type)(int32_t, uint32_t*);
typedef void (*glBindVertexArrayOES_type)(uint32_t);
typedef void (*glGenVertexArraysOES_type)(int32_t, uint32_t *);
typedef void (*glCullFace_type)(uint32_t);

void mpsdk_dfl_glClearColor(float red, float blue, float green, float alpha)
{
  _mpsdk_dfl_GLKit_get_f(glClearColor);
}

void mpsdk_dfl_glClear(uint32_t flags)
{
  _mpsdk_dfl_GLKit_get_f(glClear);
}

void mpsdk_dfl_glEnable (uint32_t cap)
{
  _mpsdk_dfl_GLKit_get_f(glEnable);
  return f(cap);
}

void mpsdk_dfl_glDisable (uint32_t cap)
{
  _mpsdk_dfl_GLKit_get_f(glDisable);
  return f(cap);
}

void mpsdk_dfl_glBlendFunc (uint32_t sfactor, uint32_t dfactor)
{
  _mpsdk_dfl_GLKit_get_f(glBlendFunc);
  return f(sfactor, dfactor);
}

void mpsdk_dfl_glGenRenderbuffers (int32_t n, uint32_t *renderbuffers)
{
  _mpsdk_dfl_GLKit_get_f(glGenRenderbuffers);
  return f(n, renderbuffers);
}

void mpsdk_dfl_glBindRenderbuffer (uint32_t target, uint32_t renderbuffer)
{
  _mpsdk_dfl_GLKit_get_f(glBindRenderbuffer);
  return f(target, renderbuffer);
}

void mpsdk_dfl_glDeleteRenderbuffers (int32_t n, const uint32_t *renderbuffers)
{
  _mpsdk_dfl_GLKit_get_f(glDeleteRenderbuffers);
  return f(n, renderbuffers);
}

void mpsdk_dfl_glGetRenderbufferParameteriv (uint32_t target, uint32_t pname, int32_t *params)
{
  _mpsdk_dfl_GLKit_get_f(glGetRenderbufferParameteriv);
  return f(target, pname, params);
}

void mpsdk_dfl_glGenFramebuffers (int32_t n, uint32_t *framebuffers)
{
  _mpsdk_dfl_GLKit_get_f(glGenFramebuffers);
  return f(n, framebuffers);
}

void mpsdk_dfl_glBindFramebuffer (uint32_t target, uint32_t framebuffer)
{
  _mpsdk_dfl_GLKit_get_f(glBindFramebuffer);
  return f(target, framebuffer);
}

uint32_t mpsdk_dfl_glCheckFramebufferStatus (uint32_t target)
{
  _mpsdk_dfl_GLKit_get_f(glCheckFramebufferStatus);
  return f(target);
}

void mpsdk_dfl_glDeleteFramebuffers (int32_t n, const uint32_t *framebuffers)
{
  _mpsdk_dfl_GLKit_get_f(glDeleteFramebuffers);
  return f(n, framebuffers);
}

void mpsdk_dfl_glFramebufferRenderbuffer (uint32_t target, uint32_t attachment, uint32_t renderbuffertarget, uint32_t renderbuffer)
{
  _mpsdk_dfl_GLKit_get_f(glFramebufferRenderbuffer);
  return f(target, attachment, renderbuffertarget, renderbuffer);
}

void mpsdk_dfl_glFinish (void)
{
  _mpsdk_dfl_GLKit_get_f(glFinish);
  f();
  f();
}

uint32_t mpsdk_dfl_glCreateProgram (void)
{
  _mpsdk_dfl_GLKit_get_f(glCreateProgram);
  return f();
}

void mpsdk_dfl_glGetProgramiv (uint32_t program, uint32_t pname, int32_t *params)
{
  _mpsdk_dfl_GLKit_get_f(glGetProgramiv);
  return f(program, pname, params);
}


void mpsdk_dfl_glUseProgram (uint32_t program)
{
  _mpsdk_dfl_GLKit_get_f(glUseProgram);
  return f(program);
}

void mpsdk_dfl_glValidateProgram (uint32_t program)
{
  _mpsdk_dfl_GLKit_get_f(glValidateProgram);
  return f(program);
}

void mpsdk_dfl_glDeleteProgram (uint32_t program)
{
  _mpsdk_dfl_GLKit_get_f(glDeleteProgram);
  return f(program);
}

void mpsdk_dfl_glLinkProgram (uint32_t program)
{
  _mpsdk_dfl_GLKit_get_f(glLinkProgram);
  return f(program);
}

void mpsdk_dfl_glGetProgramInfoLog (uint32_t program, int32_t bufSize, int32_t *length, char *infoLog)
{
  _mpsdk_dfl_GLKit_get_f(glGetProgramInfoLog);
  return f(program, bufSize, length, infoLog);
}

uint32_t mpsdk_dfl_glCreateShader (uint32_t type)
{
  _mpsdk_dfl_GLKit_get_f(glCreateShader);
  return f(type);
}

void mpsdk_dfl_glShaderSource (uint32_t shader, int32_t count, const char* const *string, const int32_t *length)
{
  _mpsdk_dfl_GLKit_get_f(glShaderSource);
  return f(shader, count, string, length);
}

void mpsdk_dfl_glCompileShader (uint32_t shader)
{
  _mpsdk_dfl_GLKit_get_f(glCompileShader);
  return f(shader);
}

void mpsdk_dfl_glDeleteShader (uint32_t shader)
{
  _mpsdk_dfl_GLKit_get_f(glDeleteShader);
  return f(shader);
}

void mpsdk_dfl_glAttachShader (uint32_t program, uint32_t shader)
{
  _mpsdk_dfl_GLKit_get_f(glAttachShader);
  return f(program, shader);
}

void mpsdk_dfl_glDetachShader (uint32_t program, uint32_t shader)
{
  _mpsdk_dfl_GLKit_get_f(glDetachShader);
  return f(program, shader);
}

void mpsdk_dfl_glGetShaderInfoLog (uint32_t shader, int32_t bufSize, int32_t *length, char *infoLog)
{
  _mpsdk_dfl_GLKit_get_f(glGetShaderInfoLog);
  return f(shader, bufSize, length, infoLog);
}

void mpsdk_dfl_glGetShaderiv (uint32_t shader, uint32_t pname, int32_t *params)
{
  _mpsdk_dfl_GLKit_get_f(glGetShaderiv);
  return f(shader, pname, params);
}

int32_t mpsdk_dfl_glGetUniformLocation (uint32_t program, const char *name)
{
  _mpsdk_dfl_GLKit_get_f(glGetUniformLocation);
  return f(program, name);
}

void mpsdk_dfl_glBindAttribLocation (uint32_t program, uint32_t index, const char *name)
{
  _mpsdk_dfl_GLKit_get_f(glBindAttribLocation);
  return f(program, index, name);
}

void mpsdk_dfl_glUniform1i (int32_t location, int32_t v0)
{
  _mpsdk_dfl_GLKit_get_f(glUniform1i);
  return f(location, v0);
}

void mpsdk_dfl_glUniformMatrix3fv (int32_t location, int32_t count, uint8_t transpose, const float *value)
{
  _mpsdk_dfl_GLKit_get_f(glUniformMatrix3fv);
  return f(location, count, transpose, value);
}


void mpsdk_dfl_glViewport (int32_t x, int32_t y, int32_t width, int32_t height)
{
  _mpsdk_dfl_GLKit_get_f(glViewport);
  return f(x, y, width, height);
}

void mpsdk_dfl_glVertexAttribPointer (uint32_t index, int32_t size, uint32_t type, uint8_t normalized, int32_t stride, const void *pointer)
{
  _mpsdk_dfl_GLKit_get_f(glVertexAttribPointer);
  return f(index, size, type, normalized, stride, pointer);
}

void mpsdk_dfl_glEnableVertexAttribArray (uint32_t index)
{
  _mpsdk_dfl_GLKit_get_f(glEnableVertexAttribArray);
  return f(index);
}

void mpsdk_dfl_glDisableVertexAttribArray (uint32_t index)
{
  _mpsdk_dfl_GLKit_get_f(glDisableVertexAttribArray);
  return f(index);
}

void mpsdk_dfl_glBindTexture (uint32_t target, uint32_t texture)
{
  _mpsdk_dfl_GLKit_get_f(glBindTexture);
  return f(target, texture);
}

void mpsdk_dfl_glActiveTexture (uint32_t texture)
{
  _mpsdk_dfl_GLKit_get_f(glActiveTexture);
  return f(texture);
}

void mpsdk_dfl_glTexParameterf (uint32_t target, uint32_t pname, float param)
{
  _mpsdk_dfl_GLKit_get_f(glTexParameterf);
  return f(target, pname, param);
}

void mpsdk_dfl_glTexParameteri (uint32_t target, uint32_t pname, int32_t param)
{
  _mpsdk_dfl_GLKit_get_f(glTexParameteri);
  return f(target, pname, param);
}

void mpsdk_dfl_glUniform1f (int32_t location, float v0)
{
  _mpsdk_dfl_GLKit_get_f(glUniform1f);
  return f(location, v0);
}

void mpsdk_dfl_glDrawArrays (uint32_t mode, int32_t first, int32_t count)
{
  _mpsdk_dfl_GLKit_get_f(glDrawArrays);
  return f(mode, first, count);
}

void mpsdk_dfl_glFlush (void)
{
  _mpsdk_dfl_GLKit_get_f(glFlush);
  return f();
}

void mpsdk_dfl_glBindBuffer (uint32_t target, uint32_t buffer)
{
  _mpsdk_dfl_GLKit_get_f(glBindBuffer);
  return f(target, buffer);
}

void mpsdk_dfl_glBufferData (uint32_t target, intptr_t size, const void* data, uint32_t usage)
{
  _mpsdk_dfl_GLKit_get_f(glBufferData);
  return f(target, size, data, usage);
}

void mpsdk_dfl_glGenBuffers (int32_t n, uint32_t* buffers)
{
  _mpsdk_dfl_GLKit_get_f(glGenBuffers);
  return f(n, buffers);
}

void mpsdk_dfl_glBindVertexArrayOES (uint32_t array)
{
  _mpsdk_dfl_GLKit_get_f(glBindVertexArrayOES);
  return f(array);
}

void mpsdk_dfl_glGenVertexArraysOES (int32_t n, uint32_t *arrays)
{
  _mpsdk_dfl_GLKit_get_f(glGenVertexArraysOES);
  return f(n, arrays);
}

void mpsdk_dfl_glCullFace(uint32_t mode)
{
  _mpsdk_dfl_GLKit_get_f(glCullFace);
  return f(mode);
}


//NSString *mpsdk_dfl_kEAGLDrawablePropertyRetainedBacking(void)
//{
//    _mpsdk_dfl_GLKit_get_and_return_NSString(kEAGLDrawablePropertyRetainedBacking);
//}
//
//NSString *mpsdk_dfl_kEAGLDrawablePropertyColorFormat(void)
//{
//    _mpsdk_dfl_GLKit_get_and_return_NSString(kEAGLDrawablePropertyColorFormat);
//}
//
//NSString *mpsdk_dfl_kEAGLColorFormatRGBA8(void)
//{
//    _mpsdk_dfl_GLKit_get_and_return_NSString(kEAGLColorFormatRGBA8);
//}
//
//NSString *mpsdk_dfl_kEAGLColorFormatRGB565(void)
//{
//    _mpsdk_dfl_GLKit_get_and_return_NSString(kEAGLColorFormatRGB565);
//}

//NSString *mpsdk_dfl_kEAGLColorFormatSRGBA8(void)
//{
//    _mpsdk_dfl_GLKit_get_and_return_NSString(kEAGLColorFormatSRGBA8);
//}

#if __has_include(<MetalKit/MetalKit.h>) && !TARGET_IPHONE_SIMULATOR

#pragma mark - Metal Classes

_mpsdk_dfl_load_framework_once_impl_(Metal)
_mpsdk_dfl_handle_get_impl_(Metal)

#pragma mark - Metal API

#define _mpsdk_dfl_Metal_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(Metal, SYMBOL)

typedef id<MTLDevice> (*MTLCreateSystemDefaultDevice_type)(void);

id<MTLDevice> mpsdk_dfl_MTLCreateSystemDefaultDevice(void)
{
  _mpsdk_dfl_Metal_get_f(MTLCreateSystemDefaultDevice);
  return f();
}

#pragma mark - MetalKit Classes

#define _mpsdk_dfl_MetalKitLibrary_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(MetalKit, SYMBOL);

_mpsdk_dfl_load_framework_once_impl_(MetalKit)
_mpsdk_dfl_handle_get_impl_(MetalKit)

Class mpsdk_dfl_MTKViewClass(void)
{
  //_fbadsdk_dfl_MetalKitLibrary_get_c(MTKView);
  //Anatolii
  return NSClassFromString(@"MTKView");
}

#pragma mark - MetalKit API

#endif

#pragma mark - WebKit Classes

#define _mpsdk_dfl_WebKitLibrary_get_c(SYMBOL) _mpsdk_dfl_symbol_get_c(WebKit, SYMBOL);

_mpsdk_dfl_load_framework_once_impl_(WebKit)
_mpsdk_dfl_handle_get_impl_(WebKit)

//Class mpsdk_dfl_WKWebViewClass(void)
//{
//    _mpsdk_dfl_WebKitLibrary_get_c(WKWebView);
//    return c;
//}
//
//Class mpsdk_dfl_WKWebViewConfigurationClass(void)
//{
//    _mpsdk_dfl_WebKitLibrary_get_c(WKWebViewConfiguration);
//    return c;
//}
//
//Class mpsdk_dfl_WKProcessPoolClass(void)
//{
//    _mpsdk_dfl_WebKitLibrary_get_c(WKProcessPool);
//    return c;
//}

void mpsdk_dfl_WKWebViewSetAllowsLinkPreview (id target, BOOL allowsLinkPreview)
{
  Method method = class_getInstanceMethod(object_getClass(target), @selector(setAllowsLinkPreview:));
  if (method) {
    IMP imp = method_getImplementation(method);
    FB_IMP_BOOL f = (FB_IMP_BOOL)imp;
    f(target, @selector(setAllowsLinkPreview:), allowsLinkPreview);
  }
}

#pragma mark - WebKit API

#pragma mark - SystemConfiguration Classes

_mpsdk_dfl_load_framework_once_impl_(SystemConfiguration)
_mpsdk_dfl_handle_get_impl_(SystemConfiguration)

#pragma mark - SystemConfiguration API

#define _mpsdk_dfl_SystemConfiguration_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(SystemConfiguration, SYMBOL)

typedef SCNetworkReachabilityRef (*SCNetworkReachabilityCreateWithAddress_type)(CFAllocatorRef, const struct sockaddr *);
typedef Boolean (*SCNetworkReachabilityGetFlags_type)(SCNetworkReachabilityRef, SCNetworkReachabilityFlags *);

SCNetworkReachabilityRef mpsdk_dfl_SCNetworkReachabilityCreateWithAddress(CFAllocatorRef allocator, const struct sockaddr *address)
{
  _mpsdk_dfl_SystemConfiguration_get_f(SCNetworkReachabilityCreateWithAddress);
  return f(allocator, address);
}

BOOL mpsdk_dfl_SCNetworkReachabilityGetFlags(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags *flags)
{
  _mpsdk_dfl_SystemConfiguration_get_f(SCNetworkReachabilityGetFlags);
  return (BOOL)f(target, flags);
}

#pragma mark - zlib API

static void mpsdk_dfl_load_zlib_once(void *context) {
  *(void **)context = mpsdk_dfl_load_library_once("/usr/lib/libz.dylib");
}

_mpsdk_dfl_handle_get_impl_(zlib);

#define _mpsdk_dfl_zlib_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(zlib, SYMBOL)

typedef uLong (*compressBound_type)(uLong);
typedef int (*compress_type)(Bytef *, uLongf *, const Bytef *, uLong);

uLong mpsdk_dfl_zlib_compressBound (uLong sourceLen)
{
  _mpsdk_dfl_zlib_get_f(compressBound);
  return f(sourceLen);
}

int mpsdk_dfl_zlib_compress (Bytef *dest, uLongf *destLen,
                               const Bytef *source, uLong sourceLen)
{
  _mpsdk_dfl_zlib_get_f(compress);
  return f(dest, destLen, source, sourceLen);
}

#pragma mark - sqlite3 API

static void mpsdk_dfl_load_sqlite3_once(void *context) {
  *(void **)context = mpsdk_dfl_load_library_once("/usr/lib/libsqlite3.dylib");
}

_mpsdk_dfl_handle_get_impl_(sqlite3);

typedef int (*sqlite3_open_type)(const char *, sqlite3 **);
typedef int (*sqlite3_prepare_v2_type)(sqlite3 *, const char *, int, sqlite3_stmt **, const char **);
typedef int (*sqlite3_step_type)(sqlite3_stmt*);
typedef int (*sqlite3_finalize_type)(sqlite3_stmt *pStmt);
typedef int (*sqlite3_bind_text_type)(sqlite3_stmt*,int,const char*,int,void(*)(void*));
typedef int (*sqlite3_bind_int64_type)(sqlite3_stmt*, int, sqlite3_int64);
typedef int (*sqlite3_bind_double_type)(sqlite3_stmt*, int, double);

typedef const unsigned char * (*sqlite3_column_text_type)(sqlite3_stmt*, int);
typedef int (*sqlite3_column_int_type)(sqlite3_stmt*, int);
typedef sqlite3_int64 (*sqlite3_column_int64_type)(sqlite3_stmt*, int);
typedef double (*sqlite3_column_double_type)(sqlite3_stmt*, int);

typedef int (*sqlite3_extended_errcode_type)(sqlite3 *);
typedef const char * (*sqlite3_errmsg_type)(sqlite3 *);

typedef int (*sqlite3_close_type)(sqlite3 *);

#define _mpsdk_dfl_sqlite3_get_f(SYMBOL) _mpsdk_dfl_symbol_get_f(sqlite3, SYMBOL)

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_open(const char *filename, sqlite3 **ppDb)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_open);
  return f(filename, ppDb);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_prepare_v2(sqlite3 *db, const char *zSql, int nByte, sqlite3_stmt **ppStmt, const char **pzTail)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_prepare_v2);
  return f(db, zSql, nByte, ppStmt, pzTail);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_step(sqlite3_stmt *pStmt)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_step);
  return f(pStmt);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_finalize(sqlite3_stmt *pStmt)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_finalize);
  return f(pStmt);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_bind_text(sqlite3_stmt *pStmt, int idx, const char* str, int a, void(*b)(void* ))
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_bind_text);
  return f(pStmt, idx, str, a, b);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_bind_int64(sqlite3_stmt *pStmt, int idx, sqlite3_int64 value)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_bind_int64);
  return f(pStmt, idx, value);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_bind_double(sqlite3_stmt *pStmt, int idx, double value)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_bind_double);
  return f(pStmt, idx, value);
}

SQLITE_API const unsigned char * SQLITE_STDCALL mpsdk_dfl_sqlite3_column_text(sqlite3_stmt *pStmt, int iCol)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_column_text);
  return f(pStmt, iCol);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_column_int(sqlite3_stmt *pStmt, int iCol)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_column_int);
  return f(pStmt, iCol);
}

SQLITE_API sqlite3_int64 SQLITE_STDCALL mpsdk_dfl_sqlite3_column_int64(sqlite3_stmt *pStmt, int iCol)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_column_int64);
  return f(pStmt, iCol);
}

SQLITE_API double SQLITE_STDCALL mpsdk_dfl_sqlite3_column_double(sqlite3_stmt *pStmt, int iCol)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_column_double);
  return f(pStmt, iCol);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_extended_errcode(sqlite3 *db)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_extended_errcode);
  return f(db);
}

SQLITE_API const char * SQLITE_STDCALL mpsdk_dfl_sqlite3_errmsg(sqlite3 *db)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_errmsg);
  return f(db);
}

SQLITE_API int SQLITE_STDCALL mpsdk_dfl_sqlite3_close(sqlite3 *db)
{
  _mpsdk_dfl_sqlite3_get_f(sqlite3_close);
  return f(db);
}

#pragma mark - Foundation Classes

_mpsdk_dfl_load_framework_once_impl_(Foundation)
_mpsdk_dfl_handle_get_impl_(Foundation)

#pragma mark - Foundation API

#define _mpsdk_dfl_Foundation_get_and_return_NSString(SYMBOL) _mpsdk_dfl_get_and_return_NSString(Foundation, SYMBOL)

//NSString *mpsdk_dfl_NSExtensionHostWillEnterForegroundNotification(void)
//{
//    _mpsdk_dfl_Foundation_get_and_return_NSString(NSExtensionHostWillEnterForegroundNotification);
//}
//
//NSString *mpsdk_dfl_NSExtensionHostDidEnterBackgroundNotification(void)
//{
//    _mpsdk_dfl_Foundation_get_and_return_NSString(NSExtensionHostDidEnterBackgroundNotification);
//}
//
//NSString *mpsdk_dfl_NSExtensionHostWillResignActiveNotification(void)
//{
//    _mpsdk_dfl_Foundation_get_and_return_NSString(NSExtensionHostWillResignActiveNotification);
//}
//
//NSString *mpsdk_dfl_NSExtensionHostDidBecomeActiveNotification(void)
//{
//    _mpsdk_dfl_Foundation_get_and_return_NSString(NSExtensionHostDidBecomeActiveNotification);
//}


