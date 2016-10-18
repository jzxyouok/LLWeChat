//
//  LLMovieRecorder.m
//  LLWeChat
//
//  Created by GYJZH on 13/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMovieRecorder.h"

#import <AVFoundation/AVAssetWriter.h>
#import <AVFoundation/AVAssetWriterInput.h>

#import <AVFoundation/AVMediaFormat.h>
#import <AVFoundation/AVVideoSettings.h>
#import <AVFoundation/AVAudioSettings.h>

#define MOVIE_RECORDER_WRITING "MOVIE_RECORDER_WRITING"


#define LOG_STATUS_TRANSITIONS 0

typedef NS_ENUM( NSInteger, MovieRecorderStatus ) {
    MovieRecorderStatusIdle = 0,
    MovieRecorderStatusPreparingToRecord,
    MovieRecorderStatusRecording,
    MovieRecorderStatusFinishingRecordingPart1, // waiting for inflight buffers to be appended
    MovieRecorderStatusFinishingRecordingPart2, // calling finish writing on the asset writer
    MovieRecorderStatusFinished,	// terminal state
    MovieRecorderStatusFailed		// terminal state
}; // internal state machine


@interface LLMovieRecorder ()
{
    MovieRecorderStatus _status;
    
    __weak id <LLMovieRecorderDelegate> _delegate;
    dispatch_queue_t _delegateCallbackQueue;
    
    dispatch_queue_t _writingQueue;
    
    NSURL *_URL;
    
    AVAssetWriter *_assetWriter;
    BOOL _haveStartedSession;
    
    CMFormatDescriptionRef _audioTrackSourceFormatDescription;
    AVAssetWriterInput *_audioInput;
    
    CMFormatDescriptionRef _videoTrackSourceFormatDescription;
    CGAffineTransform _videoTrackTransform;
    AVAssetWriterInput *_videoInput;
}
@end

@implementation LLMovieRecorder

#pragma mark -
#pragma mark API

- (id)initWithURL:(NSURL *)URL
{
    if ( ! URL ) {
        return nil;
    }
    
    if ( self = [super init] ) {
        _writingQueue = dispatch_queue_create( MOVIE_RECORDER_WRITING, DISPATCH_QUEUE_SERIAL );
        _videoTrackTransform = CGAffineTransformIdentity;
        _URL = [URL copy];
    }
    return self;
}

- (void)addVideoTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription transform:(CGAffineTransform)transform
{
    if ( formatDescription == NULL ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL format description" userInfo:nil];
        return;
    }
    
    @synchronized( self ) {
        if ( _status != MovieRecorderStatusIdle ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add tracks while not idle" userInfo:nil];
            return;
        }
        
        if ( _videoTrackSourceFormatDescription ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add more than one video track" userInfo:nil];
            return;
        }
        
        _videoTrackSourceFormatDescription = (CMFormatDescriptionRef)CFRetain( formatDescription );
        _videoTrackTransform = transform;
    }
}

- (void)addAudioTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription
{
    if ( formatDescription == NULL ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL format description" userInfo:nil];
        return;
    }
    
    @synchronized( self ) {
        if ( _status != MovieRecorderStatusIdle ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add tracks while not idle" userInfo:nil];
            return;
        }
        
        if ( _audioTrackSourceFormatDescription ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Cannot add more than one audio track" userInfo:nil];
            return;
        }
        
        _audioTrackSourceFormatDescription = (CMFormatDescriptionRef)CFRetain( formatDescription );
    }
}


- (void)setDelegate:(id<LLMovieRecorderDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue; // delegate is weak referenced
{
    if ( delegate && ( delegateCallbackQueue == NULL ) )
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Caller must provide a delegateCallbackQueue" userInfo:nil];
    
    @synchronized( self ) {
        _delegate = delegate;
        _delegateCallbackQueue = delegateCallbackQueue;
    }
}

- (void)prepareToRecord
{
    @synchronized( self ) {
        if ( _status != MovieRecorderStatusIdle ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Already prepared, cannot prepare again" userInfo:nil];
            return;
        }
        
        [self transitionToStatus:MovieRecorderStatusPreparingToRecord error:nil];
    }
    
    dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_LOW, 0 ), ^{
        @autoreleasepool {
            NSError *error = nil;
            // AVAssetWriter will not write over an existing file.
            [[NSFileManager defaultManager] removeItemAtURL:_URL error:NULL];
            
            _assetWriter = [[AVAssetWriter alloc] initWithURL:_URL fileType:AVFileTypeMPEG4 error:&error];
            
            // Create and add inputs
            if ( ! error && _videoTrackSourceFormatDescription ) {
                [self setupAssetWriterVideoInput:_videoTrackSourceFormatDescription transform:_videoTrackTransform error:&error];
            }
            
            if ( ! error && _audioTrackSourceFormatDescription ) {
                [self setupAssetWriterAudioInput:_audioTrackSourceFormatDescription error:&error];
            }
            
            if ( ! error ) {
                BOOL success = [_assetWriter startWriting];
                if ( ! success )
                    error = _assetWriter.error;
            }
            
            @synchronized( self ) {
                if ( error )
                    [self transitionToStatus:MovieRecorderStatusFailed error:error];
                else
                    [self transitionToStatus:MovieRecorderStatusRecording error:nil];
            }
        }
    });
}

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeVideo];
}

- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    [self appendSampleBuffer:sampleBuffer ofMediaType:AVMediaTypeAudio];
}

- (void)finishRecording
{
    @synchronized( self ) {
        BOOL shouldFinishRecording = NO;
        switch ( _status ) {
            case MovieRecorderStatusIdle:
            case MovieRecorderStatusPreparingToRecord:
            case MovieRecorderStatusFinishingRecordingPart1:
            case MovieRecorderStatusFinishingRecordingPart2:
            case MovieRecorderStatusFinished:
                @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not recording" userInfo:nil];
                break;
            case MovieRecorderStatusFailed:
                // From the client's perspective the movie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when finishRecording is called and we are in an error state.
                NSLog( @"Recording has failed, nothing to do" );
                break;
            case MovieRecorderStatusRecording:
                shouldFinishRecording = YES;
                break;
        }
        
        if ( shouldFinishRecording )
            [self transitionToStatus:MovieRecorderStatusFinishingRecordingPart1 error:nil];
        else
            return;
    }
    
    dispatch_async( _writingQueue, ^{
        @autoreleasepool {
            @synchronized( self ) {
                // We may have transitioned to an error state as we appended inflight buffers. In that case there is nothing to do now.
                if ( _status != MovieRecorderStatusFinishingRecordingPart1 )
                    return ;
                
                // It is not safe to call -[AVAssetWriter finishWriting*] concurrently with -[AVAssetWriterInput appendSampleBuffer:]
                // We transition to MovieRecorderStatusFinishingRecordingPart2 while on _writingQueue, which guarantees that no more buffers will be appended.
                [self transitionToStatus:MovieRecorderStatusFinishingRecordingPart2 error:nil];
            }
            
            dispatch_block_t completionHandler = ^{
                @synchronized( self ) {
                    NSError *error = _assetWriter.error;
                    if ( error )
                        [self transitionToStatus:MovieRecorderStatusFailed error:error];
                    else
                        [self transitionToStatus:MovieRecorderStatusFinished error:nil];
                }
            };
            
            [_assetWriter finishWritingWithCompletionHandler:completionHandler];
        }
    });
}


#pragma mark -
#pragma mark Internal

- (void)appendSampleBuffer:(CMSampleBufferRef)sampleBuffer ofMediaType:(NSString *)mediaType
{
    if ( sampleBuffer == NULL ) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"NULL sample buffer" userInfo:nil];
        return;
    }
    
    @synchronized( self ) {
        if ( _status < MovieRecorderStatusRecording ) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Not ready to record yet" userInfo:nil];
            return;
        }
    }
    
    CFRetain( sampleBuffer );
    dispatch_async( _writingQueue, ^{
        @autoreleasepool {
            @synchronized( self ) {
                // From the client's perspective the movie recorder can asynchronously transition to an error state as the result of an append.
                // Because of this we are lenient when samples are appended and we are no longer recording.
                // Instead of throwing an exception we just release the sample buffers and return.
                if ( _status > MovieRecorderStatusFinishingRecordingPart1 ) {
                    CFRelease( sampleBuffer );
                    return;
                }
            }
            
            if ( ! _haveStartedSession ) {
                [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
                _haveStartedSession = YES;
            }
            
            AVAssetWriterInput *input = ( mediaType == AVMediaTypeVideo ) ? _videoInput : _audioInput;
            
            if ( input.readyForMoreMediaData ) {
                BOOL success = [input appendSampleBuffer:sampleBuffer];
                if ( ! success ) {
                    NSError *error = _assetWriter.error;
                    @synchronized( self ) {
                        [self transitionToStatus:MovieRecorderStatusFailed error:error];
                    }
                }
            }
            else {
                NSLog( @"%@ input not ready for more media data, dropping buffer", mediaType );
            }
            CFRelease( sampleBuffer );
        }
    });
}

// call under @synchonized( self )
- (void)transitionToStatus:(MovieRecorderStatus)newStatus error:(NSError *)error
{
    BOOL shouldNotifyDelegate = NO;
    
#if LOG_STATUS_TRANSITIONS
    NSLog( @"MovieRecorder state transition: %@->%@", [self stringForStatus:_status], [self stringForStatus:newStatus] );
#endif
    
    if ( newStatus != _status ) {
        // terminal states
        if ( ( newStatus == MovieRecorderStatusFinished ) || ( newStatus == MovieRecorderStatusFailed ) ) {
            shouldNotifyDelegate = YES;
            // make sure there are no more sample buffers in flight before we tear down the asset writer and inputs
            
            dispatch_async( _writingQueue, ^{
                [self teardownAssetWriterAndInputs];
                if ( newStatus == MovieRecorderStatusFailed ) {
                    [[NSFileManager defaultManager] removeItemAtURL:_URL error:NULL];
                }
            });
            
#if LOG_STATUS_TRANSITIONS
            if ( error )
                NSLog( @"MovieRecorder error: %@, code: %i", error, (int)error.code );
#endif
        }
        else if ( newStatus == MovieRecorderStatusRecording ) {
            shouldNotifyDelegate = YES;
        }
        
        _status = newStatus;
    }
    
    if ( shouldNotifyDelegate && _delegate ) {
        dispatch_async( _delegateCallbackQueue, ^{
            @autoreleasepool {
                switch ( newStatus ) {
                    case MovieRecorderStatusRecording:
                        [_delegate movieRecorderDidFinishPreparing:self];
                        break;
                    case MovieRecorderStatusFinished:
                        [_delegate movieRecorderDidFinishRecording:self];
                        break;
                    case MovieRecorderStatusFailed:
                        [_delegate movieRecorder:self didFailWithError:error];
                        break;
                    default:
                        break;
                }
            }
        });
    }
}

#if LOG_STATUS_TRANSITIONS

- (NSString *)stringForStatus:(MovieRecorderStatus)status
{
    NSString *statusString = nil;
    
    switch ( status ) {
        case MovieRecorderStatusIdle:
            statusString = @"Idle";
            break;
        case MovieRecorderStatusPreparingToRecord:
            statusString = @"PreparingToRecord";
            break;
        case MovieRecorderStatusRecording:
            statusString = @"Recording";
            break;
        case MovieRecorderStatusFinishingRecordingPart1:
            statusString = @"FinishingRecordingPart1";
            break;
        case MovieRecorderStatusFinishingRecordingPart2:
            statusString = @"FinishingRecordingPart2";
            break;
        case MovieRecorderStatusFinished:
            statusString = @"Finished";
            break;
        case MovieRecorderStatusFailed:
            statusString = @"Failed";
            break;
        default:
            statusString = @"Unknown";
            break;
    }
    return statusString;
    
}

#endif // LOG_STATUS_TRANSITIONS

- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)audioFormatDescription error:(NSError **)errorOut
{
    //音频配置
    AudioChannelLayout acl;
    bzero( &acl, sizeof(acl));
    acl.mChannelLayoutTag = kAudioChannelLayoutTag_Mono;

    NSDictionary* audioOutputSettings = @{
                                          AVFormatIDKey : @(kAudioFormatMPEG4AAC),
                                          AVEncoderBitRateKey : @(64000),
                                          AVSampleRateKey : @(44100.0),
                                          AVNumberOfChannelsKey : @(1),
                                          AVChannelLayoutKey :[NSData dataWithBytes:&acl length: sizeof(acl)]
                                          };


    if ( [_assetWriter canApplyOutputSettings:audioOutputSettings forMediaType:AVMediaTypeAudio] ) {
        _audioInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeAudio outputSettings:audioOutputSettings sourceFormatHint:audioFormatDescription];
        _audioInput.expectsMediaDataInRealTime = YES;
        
        if ( [_assetWriter canAddInput:_audioInput] )
            [_assetWriter addInput:_audioInput];
        else {
            if ( errorOut )
                *errorOut = [[self class] cannotSetupInputError];
            return NO;
        }
    }
    else {
        if ( errorOut )
            *errorOut = [[self class] cannotSetupInputError];
        return NO;
    }
    
    return YES;
}

- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef)videoFormatDescription transform:(CGAffineTransform)transform error:(NSError **)errorOut
{
    float bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(videoFormatDescription);
    int numPixels = dimensions.width * dimensions.height;
    int bitsPerSecond;
    
    // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
    if ( numPixels < (640 * 480) )
        bitsPerPixel = 4.05; // This bitrate approximately matches the quality produced by AVCaptureSessionPresetMedium or Low.
    else
        bitsPerPixel = 10.1; // This bitrate approximately matches the quality produced by AVCaptureSessionPresetHigh.
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                              AVVideoCodecH264, AVVideoCodecKey,
                                              [NSNumber numberWithInteger:dimensions.width], AVVideoWidthKey,
                                              [NSNumber numberWithInteger:dimensions.height], AVVideoHeightKey,
                                              [NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithInteger:bitsPerSecond], AVVideoAverageBitRateKey,
                                               [NSNumber numberWithInteger:30], AVVideoMaxKeyFrameIntervalKey,
                                               nil], AVVideoCompressionPropertiesKey,
                                              AVVideoScalingModeResizeAspectFill,AVVideoScalingModeKey,
                                              nil];
    if ( [_assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo] ) {
        _videoInput = [[AVAssetWriterInput alloc] initWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings sourceFormatHint:videoFormatDescription];
        _videoInput.expectsMediaDataInRealTime = YES;
        _videoInput.transform = transform;
        
        //缓存区设置
        NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];
        
        [AVAssetWriterInputPixelBufferAdaptor assetWriterInputPixelBufferAdaptorWithAssetWriterInput:_videoInput                        sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
        
        if ( [_assetWriter canAddInput:_videoInput] )
            [_assetWriter addInput:_videoInput];
        else {
            if ( errorOut )
                *errorOut = [[self class] cannotSetupInputError];
            return NO;
        }
    }
    else {
        if ( errorOut )
            *errorOut = [[self class] cannotSetupInputError];
        return NO;
    }
    
    return YES;
}

+ (NSError *)cannotSetupInputError
{
    NSString *localizedDescription = NSLocalizedString( @"Recording cannot be started", nil );
    NSString *localizedFailureReason = NSLocalizedString( @"Cannot setup asset writer input.", nil );
    NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
                               localizedDescription, NSLocalizedDescriptionKey,
                               localizedFailureReason, NSLocalizedFailureReasonErrorKey,
                               nil];
    return [NSError errorWithDomain:@"com.apple.dts.samplecode" code:0 userInfo:errorDict];
}

- (void)teardownAssetWriterAndInputs
{
    _videoInput = nil;
    _audioInput = nil;
    _assetWriter = nil;
}

@end

