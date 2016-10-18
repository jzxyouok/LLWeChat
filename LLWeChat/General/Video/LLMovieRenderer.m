//
//  LLMovieRenderer.m
//  LLWeChat
//
//  Created by GYJZH on 13/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMovieRenderer.h"

static CVPixelBufferPoolRef CreatePixelBufferPool(int32_t width, int32_t height, OSType pixelFormat, int32_t maxBufferCount)
{
    CVPixelBufferPoolRef outputPool = NULL;
    
    CFMutableDictionaryRef sourcePixelBufferOptions = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFNumberRef number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &pixelFormat);
    CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelBufferPixelFormatTypeKey, number);
    CFRelease(number);
    
    number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &width);
    CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelBufferWidthKey, number);
    CFRelease(number);
    
    number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &height);
    CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelBufferHeightKey, number);
    CFRelease(number);
    
    CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelFormatOpenGLESCompatibility, kCFBooleanTrue);
    
    CFDictionaryRef ioSurfaceProps = CFDictionaryCreate(kCFAllocatorDefault, NULL, NULL, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (ioSurfaceProps) {
        CFDictionaryAddValue(sourcePixelBufferOptions, kCVPixelBufferIOSurfacePropertiesKey, ioSurfaceProps);
        CFRelease(ioSurfaceProps);
    }
    
    number = CFNumberCreate(kCFAllocatorDefault, kCFNumberSInt32Type, &maxBufferCount);
    CFDictionaryRef pixelBufferPoolOptions = CFDictionaryCreate(kCFAllocatorDefault, (const void**)&kCVPixelBufferPoolMinimumBufferCountKey, (const void**)&number, 1, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    CFRelease(number);
    
    CVPixelBufferPoolCreate(kCFAllocatorDefault, pixelBufferPoolOptions, sourcePixelBufferOptions, &outputPool);
    
    CFRelease(sourcePixelBufferOptions);
    CFRelease(pixelBufferPoolOptions);
    return outputPool;
}

static CFDictionaryRef CreatePixelBufferPoolAuxAttributes(int32_t maxBufferCount)
{
    // CVPixelBufferPoolCreatePixelBufferWithAuxAttributes() will return kCVReturnWouldExceedAllocationThreshold if we have already vended the max number of buffers
    NSDictionary *auxAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt:maxBufferCount], (id)kCVPixelBufferPoolAllocationThresholdKey, nil];
    return (CFDictionaryRef)CFBridgingRetain(auxAttributes);
}

static void PreallocatePixelBuffersInPool( CVPixelBufferPoolRef pool, CFDictionaryRef auxAttributes )
{
    // Preallocate buffers in the pool, since this is for real-time display/capture
    NSMutableArray *pixelBuffers = [[NSMutableArray alloc] init];
    while ( 1 ) {
        CVPixelBufferRef pixelBuffer = NULL;
        OSStatus err = CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, pool, auxAttributes, &pixelBuffer );
        
        if ( err == kCVReturnWouldExceedAllocationThreshold )
            break;
        assert( err == noErr );
        
        [pixelBuffers addObject:(id)CFBridgingRelease(pixelBuffer)];
    }
}


@implementation LLMovieRenderer
{
    CVPixelBufferPoolRef _bufferPool;
    CFDictionaryRef _bufferPoolAuxAttributes;
    CMFormatDescriptionRef _outputFormatDescription;
}

- (void)prepareWithOutputDimensions:(CMVideoDimensions)outputDimensions retainedBufferCountHint:(size_t)retainedBufferCountHint
{
    [self deleteBuffers];
    if (![self initializeBuffersWithOutputDimensions:outputDimensions retainedBufferCountHint:retainedBufferCountHint]) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Problem preparing renderer." userInfo:nil];
    }
}

- (BOOL)initializeBuffersWithOutputDimensions:(CMVideoDimensions)outputDimensions retainedBufferCountHint:(size_t)clientRetainedBufferCountHint
{
    BOOL success = YES;
    
    size_t maxRetainedBufferCount = clientRetainedBufferCountHint;
    
    _bufferPool = CreatePixelBufferPool(outputDimensions.width, outputDimensions.height, kCVPixelFormatType_32BGRA, (int32_t)maxRetainedBufferCount);
    if (!_bufferPool) {
        NSLog(@"Problem initializing a buffer pool.");
        success = NO;
        goto bail;
    }
    
    _bufferPoolAuxAttributes = CreatePixelBufferPoolAuxAttributes((int32_t)maxRetainedBufferCount);
    PreallocatePixelBuffersInPool(_bufferPool, _bufferPoolAuxAttributes);
    
    CMFormatDescriptionRef outputFormatDescription = NULL;
    CVPixelBufferRef testPixelBuffer = NULL;
    CVPixelBufferPoolCreatePixelBufferWithAuxAttributes( kCFAllocatorDefault, _bufferPool, _bufferPoolAuxAttributes, &testPixelBuffer );
    if (!testPixelBuffer) {
        NSLog(@"Problem creating a pixel buffer.");
        success = NO;
        goto bail;
    }
    CMVideoFormatDescriptionCreateForImageBuffer( kCFAllocatorDefault, testPixelBuffer, &outputFormatDescription );
    _outputFormatDescription = outputFormatDescription;
    CFRelease(testPixelBuffer);
    
bail:
    if (!success) {
        [self deleteBuffers];
    }
    return success;
}

- (void)reset
{
    [self deleteBuffers];
}

- (void)deleteBuffers
{
    if (_bufferPool) {
        CFRelease(_bufferPool);
        _bufferPool = NULL;
    }
    if (_bufferPoolAuxAttributes) {
        CFRelease(_bufferPoolAuxAttributes);
        _bufferPoolAuxAttributes = NULL;
    }
    if (_outputFormatDescription) {
        CFRelease(_outputFormatDescription);
        _outputFormatDescription = NULL;
    }
}

- (CMFormatDescriptionRef)outputFormatDescription
{
    return _outputFormatDescription;
}

@end
