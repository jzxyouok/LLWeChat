//
//  LLSightSessionManager.h
//  LLWeChat
//
//  Created by GYJZH on 13/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@protocol LLSightSessionManagerDelegate;

@interface LLSightSessionManager : NSObject

+ (instancetype)sharedManager;

- (void)setDelegate:(id<LLSightSessionManagerDelegate>)delegate callbackQueue:(dispatch_queue_t)delegateCallbackQueue; // delegate is weak referenced

// Consider renaming this class VideoSnakeCapturePipeline
// These methods are synchronous
- (void)startRunning;
- (void)stopRunning;

// Must be running before starting recording
// These methods are asynchronous, see the recording delegate callbacks
- (void)startRecording;
- (void)stopRecording;

@property (readwrite) BOOL renderingEnabled; // When set to false the GPU will not be used after the setRenderingEnabled: call returns.

@property (readwrite) AVCaptureVideoOrientation recordingOrientation; // client can set the orientation for the recorded movie

- (CGAffineTransform)transformFromVideoBufferOrientationToOrientation:(AVCaptureVideoOrientation)orientation withAutoMirroring:(BOOL)mirroring; // only valid after startRunning has been called

// Stats
@property (readonly) float videoFrameRate;
@property (readonly) CMVideoDimensions videoDimensions;

@end

@protocol LLSightSessionManagerDelegate <NSObject>
@required

- (void)sessionManager:(LLSightSessionManager *)sessionManager didStopRunningWithError:(NSError *)error;

// Recording
- (void)sessionManagerRecordingDidStart:(LLSightSessionManager *)manager;
- (void)sessionManager:(LLSightSessionManager *)manager recordingDidFailWithError:(NSError *)error; // Can happen at any point after a startRecording call, for example: startRecording->didFail (without a didStart), willStop->didFail (without a didStop)
- (void)sessionManagerRecordingWillStop:(LLSightSessionManager *)manager;
- (void)sessionManagerRecordingDidStop:(LLSightSessionManager *)manager;

@end
