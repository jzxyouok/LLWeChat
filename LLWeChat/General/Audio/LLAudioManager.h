//
//  LLAudioManager.h
//  LLWeChat
//
//  Created by GYJZH on 8/29/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLAudioRecordDelegate.h"
#import "LLAudioPlayDelegate.h"
@import AVFoundation;


typedef NS_ENUM(NSInteger, LLErrorRecordType) {
    kLLErrorRecordTypeAuthorizationDenied,
    kLLErrorRecordTypeInitFailed,
    kLLErrorRecordTypeCreateAudioFileFailed,
    kLLErrorRecordTypeMultiRequest,
    kLLErrorRecordTypeRecordError,
};

typedef NS_ENUM(NSInteger, LLErrorPlayType) {
    kLLErrorPlayTypeInitFailed = 0,
    kLLErrorPlayTypeFileNotExist,
    kLLErrorPlayTypePlayError,
};


#define LLErrorAudioRecord

#define LLErrorAudioRecordDurationTooShort -400
#define LLErrorFileTypeConvertionFailure -401
#define LLErrorAudioRecordStoping -402
#define LLErrorAudioRecordNotStarted -403

@interface LLAudioManager : NSObject

@property (nonatomic) BOOL isRecording;
@property (nonatomic) BOOL isCancelRecording;
@property (nonatomic) BOOL isFinishRecording;

@property (nonatomic) BOOL isPlaying;



+ (instancetype)sharedManager;

- (void)startRecordingWithDelegate:(id<LLAudioRecordDelegate>)delegate;

- (void)stopRecording;

- (void)cancelRecording;


- (void)startPlayingWithPath:(NSString *)aFilePath
                        delegate:(id<LLAudioPlayDelegate>)delegate
                        userinfo:(id)userinfo
                 continuePlaying:(BOOL)continuePlaying;

//关闭整个播放Session
- (void)stopPlaying;

//仅仅停止当前文件的播放，不关闭Session
- (void)stopCurrentPlaying;

@end
