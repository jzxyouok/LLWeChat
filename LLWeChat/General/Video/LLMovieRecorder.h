//
//  LLMovieRecorder.h
//  LLWeChat
//
//  Created by GYJZH on 13/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CMFormatDescription.h>
#import <CoreMedia/CMSampleBuffer.h>

@protocol LLMovieRecorderDelegate;

@interface LLMovieRecorder : NSObject

- (id)initWithURL:(NSURL *)URL;

// Only one audio and video track each are allowed.
- (void)addVideoTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription transform:(CGAffineTransform)transform;
- (void)addAudioTrackWithSourceFormatDescription:(CMFormatDescriptionRef)formatDescription;

- (void)setDelegate:(id<LLMovieRecorderDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue; // delegate is weak referenced

- (void)prepareToRecord; // Asynchronous, might take several hunderd milliseconds. When finished the delegate's recorderDidFinishPreparing: or recorder:didFailWithError: method will be called.

- (void)appendVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer;
- (void)appendAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer;

- (void)finishRecording; // Asynchronous, might take several hundred milliseconds. When finished the delegate's recorderDidFinishRecording: or recorder:didFailWithError: method will be called.

@end

@protocol LLMovieRecorderDelegate <NSObject>
@required
- (void)movieRecorderDidFinishPreparing:(LLMovieRecorder *)recorder;
- (void)movieRecorder:(LLMovieRecorder *)recorder didFailWithError:(NSError *)error;
- (void)movieRecorderDidFinishRecording:(LLMovieRecorder *)recorder;
@end

