//
//  LLMessageModel.m
//  LLWeChat
//
//  Created by GYJZH on 7/21/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageModel.h"
#import "EMTextMessageBody.h"
#import "EMMessage.h"
#import "LLUserProfile.h"
#import "LLUtils.h"
#import "LLEmotionModelManager.h"
#import "EMImageMessageBody.h"
#import "EMSDK.h"
#import "LLConfig.h"
#import "UIKit+LLExt.h"
#import "LLChatManager+MessageExt.h"
#import "LLChatDataManager.h"
#import "LLMessageCellManager.h"

#import "LLMessageImageCell.h"
#import "LLMessageTextCell.h"
#import "LLMessageGifCell.h"
#import "LLMessageDateCell.h"
#import "LLMessageLocationCell.h"
#import "LLMessageVoiceCell.h"
#import "LLMessageVideoCell.h"
#import "LLMessageRecordingCell.h"

//缩略图正在下载时照片尺寸
#define DOWNLOAD_IMAGE_WIDTH 175
#define DOWNLOAD_IMAGE_HEIGHT 145

@interface LLMessageModel ()

@property (nonatomic, readwrite) LLMessageStatus messageStatus;

@property (nonatomic, readwrite) LLMessageDownloadStatus thumbnailDownloadStatus;

@property (nonatomic, readwrite) LLMessageDownloadStatus messageDownloadStatus;

@end

@implementation LLMessageModel


#pragma mark - 消息初始化 -

- (instancetype)initWithImageModel:(LLMessageModel *)messageModel {
    self = [super init];
    if (self) {
        _messageBodyType = kLLMessageBodyTypeImage;
        _thumbnailImageSize = messageModel.thumbnailImageSize;
        _messageDownloadStatus = kLLMessageDownloadStatusSuccessed;
        _thumbnailDownloadStatus = kLLMessageDownloadStatusSuccessed;
        _messageId = [NSString stringWithFormat:@"%f%d",[NSDate date].timeIntervalSince1970, arc4random()];
        _conversationId = [messageModel.conversationId copy];
        _cellHeight = messageModel.cellHeight;
        _fromMe = YES;
    }
    
    return self;
}


- (instancetype)initWithType:(LLMessageBodyType)type {
    self = [super init];
    if (self) {
        _messageBodyType = type;
        
        switch (type) {
            case kLLMessageBodyTypeDateTime:
                self.cellHeight = [LLMessageDateCell heightForModel:self];
                break;
            case kLLMessageBodyTypeVoice:
                self.cellHeight = [LLMessageVoiceCell heightForModel:self];
                break;
            case kLLMessageBodyTypeRecording:
                self.fromMe = YES;
                self.timestamp = [[NSDate date] timeIntervalSince1970];
                self.cellHeight = [LLMessageRecordingCell heightForModel:self];
            default:
                break;
        }
    }
    
    return self;
}

- (void)commonInit:(EMMessage *)message {
    _sdk_message = message;
    _messageBodyType = (LLMessageBodyType)_sdk_message.body.type;
    _messageId = [message.messageId copy];
    _conversationId = [message.conversationId copy];
    _messageStatus = kLLMessageStatusNone;
    _messageDownloadStatus = kLLMessageDownloadStatusNone;
    _thumbnailDownloadStatus = kLLMessageDownloadStatusNone;
    
    _from = [message.from copy];
    _to = [message.to copy];
    _fromMe = _sdk_message.direction == EMMessageDirectionSend;
    
//    if (_fromMe) {
        _timestamp = adjustTimestampFromServer(message.timestamp);
//    }else {
//        _timestamp = adjustTimestampFromServer(message.serverTime);
//    }
    
    _ext = message.ext;
    _error = nil;

    [self processModelForCell];
}

- (instancetype)initWithMessage:(EMMessage *)message {
    self = [super init];
    if (self) {
        [self commonInit:message];
    }
    
    return self;
}

+ (LLMessageModel *)messageModelFromPool:(EMMessage *)message {
    LLMessageModel *messageModel = [[LLMessageModel alloc] initWithMessage:message];
    [[LLChatDataManager sharedManager] addMessageModelToConversaion:messageModel];
    
    return messageModel;
}

- (void)updateMessage:(EMMessage *)aMessage {
    BOOL isMessageIdChanged = ![aMessage.messageId isEqualToString:_messageId];
    
    if (aMessage == _sdk_message) {
        if (isMessageIdChanged) {
            NSLog(@"更新消息时，消息ID发生了改变");
            LLMessageBaseCell *cell = [[LLMessageCellManager sharedManager] removeCellForMessageId:_messageId];
            _messageId = [aMessage.messageId copy];
            [[LLMessageCellManager sharedManager] addCell:cell forMessageId:aMessage.messageId];
        }
    }else {
        NSAssert(!isMessageIdChanged, @"更新消息发生异常:EMMessage和消息Id都改变了");
    }
    
    _sdk_message = aMessage;
    _ext = aMessage.ext;
    
    switch (self.messageBodyType) {
        case kLLMessageBodyTypeImage:
        case kLLMessageBodyTypeVideo:
        case kLLMessageBodyTypeLocation:
            [self processModelForCell];
            break;
        default:
            break;
    }
}

- (UIImage *)fullImage {
    if (self.messageBodyType == kLLMessageBodyTypeImage) {
        EMImageMessageBody *imgMessageBody = (EMImageMessageBody *)self.sdk_message.body;
        if ([[NSFileManager defaultManager] fileExistsAtPath:imgMessageBody.localPath]) {
            UIImage *fullImage = [UIImage imageWithContentsOfFile:imgMessageBody.localPath];
            return fullImage;
        }
    }
    
    return nil;
}


- (BOOL)isEqual:(id)object {
    if (self == object)
        return YES;
    
    if (!object || ![object isKindOfClass:[LLMessageModel class]]) {
        return NO;
    }
    
    LLMessageModel *model = (LLMessageModel *)object;
    return [self.messageId isEqualToString:model.messageId];
}

#pragma mark - 消息状态

- (void)internal_setMessageStatus:(LLMessageStatus)messageStatus {
    _messageStatus = messageStatus;
}

- (void)internal_setMessageDownloadStatus:(LLMessageDownloadStatus)messageDownloadStatus {
    _messageDownloadStatus = messageDownloadStatus;
}

- (void)internal_setThumbnailDownloadStatus:(LLMessageDownloadStatus)thumbnailDownloadStatus {
    _thumbnailDownloadStatus = thumbnailDownloadStatus;
}

- (void)internal_setIsFetchingAttachment:(BOOL)isFetchingAttachment {
    _isFetchingAttachment = isFetchingAttachment;
}

- (void)internal_setIsFetchingThumbnail:(BOOL)isFetchingThumbnail {
    _isFetchingThumbnail = isFetchingThumbnail;
}

- (LLMessageStatus)messageStatus {
    if (_messageStatus != kLLMessageStatusNone)
        return _messageStatus;
    
    return (LLMessageStatus)_sdk_message.status;
}

- (LLMessageDirection)messageDirection {
    return (LLMessageDirection)_sdk_message.direction;
}

- (LLMessageDownloadStatus)messageDownloadStatus {
    if (_messageDownloadStatus != kLLMessageDownloadStatusNone)
        return _messageDownloadStatus;
    
    EMFileMessageBody *body = (EMFileMessageBody *)(_sdk_message.body);
    if (body) {
        return (LLMessageDownloadStatus)(body.downloadStatus);
    }else {
        return kLLMessageDownloadStatusNone;
    }
}

- (LLMessageDownloadStatus)thumbnailDownloadStatus {
    if (_thumbnailDownloadStatus != kLLMessageDownloadStatusNone)
        return _thumbnailDownloadStatus;
    
    switch (self.messageBodyType) {
        case kLLMessageBodyTypeImage: {
            EMImageMessageBody *body = (EMImageMessageBody *)(_sdk_message.body);
            return (LLMessageDownloadStatus)body.thumbnailDownloadStatus;
        }
        case kLLMessageBodyTypeVideo: {
            EMVideoMessageBody *body = (EMVideoMessageBody *)(_sdk_message.body);
            return (LLMessageDownloadStatus)body.thumbnailDownloadStatus;
        }
        default:
            return kLLMessageDownloadStatusNone;
    }

}

- (NSInteger)fileAttachmentSize {
    switch (_messageBodyType) {
        case kLLMessageBodyTypeImage:
        case kLLMessageBodyTypeVideo:
        case kLLMessageBodyTypeFile:
            return ((EMFileMessageBody *)(_sdk_message.body)).fileLength;

        default:
            return 0;
    }

}

- (BOOL)isVideoPlayable {
    return (_sdk_message.body.type == EMMessageBodyTypeVideo) && (self.fromMe || self.messageDownloadStatus == kLLMessageDownloadStatusSuccessed);
}

- (BOOL)isFullImageAvailable {
    return (_sdk_message.body.type == EMMessageBodyTypeImage) && (self.fromMe || self.messageDownloadStatus == kLLMessageDownloadStatusSuccessed);
}

- (BOOL)isVoicePlayable {
    return (_sdk_message.body.type == EMMessageBodyTypeVoice) && (self.fromMe || self.messageDownloadStatus == kLLMessageDownloadStatusSuccessed);
}

#pragma mark - 数据预处理

+ (NSString *)messageTypeTitle:(EMMessage *)message {
    NSString *typeTitle;
    
    switch (message.body.type) {
        case EMMessageBodyTypeText:{
            if ([message.ext[MESSAGE_EXT_TYPE_KEY] isEqualToString:MESSAGE_EXT_GIF_KEY]) {
                typeTitle = @"动画表情";
            }else {
                EMTextMessageBody *body = (EMTextMessageBody *)message.body;
                typeTitle = body.text;
            }
            break;
        }
        case EMMessageBodyTypeImage:
            typeTitle = @"[图片]";
            break;
        case EMMessageBodyTypeVideo:
            typeTitle = @"[视频]";
            break;
        case EMMessageBodyTypeLocation:
            typeTitle = @"[位置]";
            break;
         case EMMessageBodyTypeVoice:
            typeTitle = @"[语音]";
            break;
        case EMMessageBodyTypeFile:
            if ([message.ext[MESSAGE_EXT_TYPE_KEY] isEqualToString:MESSAGE_EXT_LOCATION_KEY]) {
                typeTitle = @"位置";
            }else {
                typeTitle = @"文件";
            }
            break;
        case EMMessageBodyTypeCmd:
            typeTitle = @"[CMD]";
            break;
            
    }
    
    return typeTitle;
}



- (void)processModelForCell {
    switch (self.messageBodyType) {
        case kLLMessageBodyTypeText: {
            if ([self.ext[MESSAGE_EXT_TYPE_KEY] isEqualToString:MESSAGE_EXT_GIF_KEY]) {
                EMTextMessageBody *textBody = (EMTextMessageBody *)(self.sdk_message.body);
                self.messageBody_Text = [NSString stringWithFormat:@"[%@]", textBody.text];
                _messageBodyType = kLLMessageBodyTypeGif;
                self.cellHeight = [LLMessageGifCell heightForModel:self];
                
            }else {
                EMTextMessageBody *textBody = (EMTextMessageBody *)(self.sdk_message.body);
                self.messageBody_Text = textBody.text;
                self.richTestString = [[LLEmotionModelManager sharedManager]
                                       convertToEmotionWithAttachment:textBody.text font:[LLMessageTextCell font]];
                
                self.richTestString = [LLUtils parseText:(self.richTestString)];
                
                self.cellHeight = [LLMessageTextCell heightForModel:self];
            }
            
        }
            break;
        case kLLMessageBodyTypeDateTime:
            self.cellHeight = [LLMessageDateCell heightForModel:self];
            break;
        case kLLMessageBodyTypeImage:{
            EMImageMessageBody *imgMessageBody = (EMImageMessageBody *)self.sdk_message.body;
            
            self.thumbnailImage = nil;
            self.thumbnailImageSize = [LLMessageImageCell thumbnailSize:imgMessageBody.size];
            if (_fromMe || (imgMessageBody.downloadStatus == EMDownloadStatusSuccessed)) {
                UIImage *fullImage = [UIImage imageWithContentsOfFile:imgMessageBody.localPath];
                self.thumbnailImageSize = [LLMessageImageCell thumbnailSize:fullImage.size];
                self.thumbnailImage = [fullImage resizeImageToSize:self.thumbnailImageSize];
                _thumbnailDownloadStatus = kLLMessageDownloadStatusSuccessed;
                _messageDownloadStatus = kLLMessageDownloadStatusSuccessed;
            }
            
            if (!self.thumbnailImage && imgMessageBody.thumbnailDownloadStatus == EMDownloadStatusSuccessed) {
                self.thumbnailImage = [UIImage imageWithContentsOfFile:imgMessageBody.thumbnailLocalPath];
                _thumbnailDownloadStatus = kLLMessageDownloadStatusSuccessed;
            }
            
            self.fileLocalPath = imgMessageBody.localPath;
            self.cellHeight = [LLMessageImageCell heightForModel:self];
            break;
        }
        case kLLMessageBodyTypeEMLocation: {
            EMLocationMessageBody *locationMessageBody = (EMLocationMessageBody *)self.sdk_message.body;
            double latitude = locationMessageBody.latitude;
            double longitude = locationMessageBody.longitude;
            _coordinate2D.latitude = latitude;
            _coordinate2D.longitude = longitude;
            self.address = locationMessageBody.address;
            
            self.cellHeight = [LLMessageLocationCell heightForModel:self];
            
            break;
        }
        case kLLMessageBodyTypeFile:
        case kLLMessageBodyTypeLocation: {
            NSDictionary *messageExt = self.sdk_message.ext;
            
            if ([messageExt[MESSAGE_EXT_TYPE_KEY] isEqualToString:MESSAGE_EXT_LOCATION_KEY]) {
                _messageBodyType = kLLMessageBodyTypeLocation;
                [[LLChatManager sharedManager] decodeMessageExtForLocationType:self];
                EMFileMessageBody *body = (EMFileMessageBody *)self.sdk_message.body;
                
                if (_fromMe || (body.downloadStatus == EMDownloadStatusSuccessed)) {
                    NSData *data = [NSData dataWithContentsOfFile:body.localPath];
                    self.snapshotImage = [UIImage imageWithData:data scale:_snapshotScale];
                    _messageDownloadStatus = kLLMessageDownloadStatusSuccessed;
                }
                
                self.fileLocalPath = body.localPath;
                self.cellHeight = [LLMessageLocationCell heightForModel:self];
            }
            
            break;
        }
        case kLLMessageBodyTypeVoice: {
            EMVoiceMessageBody *voiceBody = (EMVoiceMessageBody *)self.sdk_message.body;
            self.mediaDuration = voiceBody.duration;
            self.isMediaPlayed = NO;
            self.isMediaPlaying = NO;
            if (_sdk_message.ext) {
                self.isMediaPlayed = [_sdk_message.ext[@"isPlayed"] boolValue];
            }
            // 音频路径
            self.fileLocalPath = voiceBody.localPath;
            self.cellHeight = [LLMessageVoiceCell heightForModel:self];
            
            break;
        }
        case kLLMessageBodyTypeVideo: {
            [[LLChatManager sharedManager] decodeMessageExtForVideoType:self];
            EMVideoMessageBody *videoBody = (EMVideoMessageBody *)self.sdk_message.body;
            
            self.thumbnailImage = nil;
            // 视频路径
            self.fileLocalPath = videoBody.localPath;
            if ((videoBody.downloadStatus == EMDownloadStatusSuccessed) || _fromMe) {
                self.thumbnailImage = [LLUtils getVideoThumbnailImage:videoBody.localPath];
                _messageDownloadStatus = kLLMessageDownloadStatusSuccessed;
                _thumbnailDownloadStatus = kLLMessageDownloadStatusSuccessed;
                
//                if (!_playerItem) {
//                    WEAK_SELF;
//                    dispatch_async(dispatch_get_main_queue(), ^{
//                        [weakSelf initAVPlayerItem];
//                    });
//                }
            }
            
            if (!self.thumbnailImage && videoBody.thumbnailDownloadStatus == EMDownloadStatusSuccessed) {
                self.thumbnailImage = [UIImage imageWithContentsOfFile:videoBody.thumbnailLocalPath];
                _thumbnailDownloadStatus = kLLMessageDownloadStatusSuccessed;
            }
            
            self.cellHeight = [LLMessageVideoCell heightForModel:self];
            
            break;
        }
            
        case kLLMessageBodyTypeGif:
            self.cellHeight = [LLMessageGifCell heightForModel:self];
            break;
        default:
            break;
            
    }
    
}

- (void)cleanWhenConversationSessionEnded {
    _gifShowIndex = 0;
}

//- (void)initAVPlayerItem {
//    NSURL *videoURL = [NSURL fileURLWithPath:self.fileLocalPath];
//    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
//    
//    NSArray *requestedKeys = @[@"playable"];
//    
//    /* Tells the asset to load the values of any of the specified keys that are not already loaded. */
//    WEAK_SELF;
//    [asset loadValuesAsynchronouslyForKeys:requestedKeys completionHandler:
//     ^{
//         dispatch_async( dispatch_get_main_queue(),
//                        ^{
//                            /* IMPORTANT: Must dispatch to main queue in order to operate on the AVPlayer and AVPlayerItem. */
//                            [weakSelf prepareToPlayAsset:asset withKeys:requestedKeys];
//                        });
//     }];
//}
//
///*
// Invoked at the completion of the loading of the values for all keys on the asset that we require.
// Checks whether loading was successfull and whether the asset is playable.
// If so, sets up an AVPlayerItem and an AVPlayer to play the asset.
// */
//- (void)prepareToPlayAsset:(AVURLAsset *)asset withKeys:(NSArray *)requestedKeys
//{
//    /* Make sure that the value of each key has loaded successfully. */
//    for (NSString *thisKey in requestedKeys)
//    {
//        NSError *error = nil;
//        AVKeyValueStatus keyStatus = [asset statusOfValueForKey:thisKey error:&error];
//        if (keyStatus == AVKeyValueStatusFailed)
//        {
//            return;
//        }
//        /* If you are also implementing -[AVAsset cancelLoading], add your code here to bail out properly in the case of cancellation. */
//    }
//    
//    /* Use the AVAsset playable property to detect whether the asset can be played. */
//    if (!asset.playable)
//    {
//        /* Generate an error describing the failure. */
//        //        NSString *localizedDescription = NSLocalizedString(@"Item cannot be played", @"Item cannot be played description");
//        //        NSString *localizedFailureReason = NSLocalizedString(@"The assets tracks were loaded, but could not be made playable.", @"Item cannot be played failure reason");
//        //        NSDictionary *errorDict = [NSDictionary dictionaryWithObjectsAndKeys:
//        //                                   localizedDescription, NSLocalizedDescriptionKey,
//        //                                   localizedFailureReason, NSLocalizedFailureReasonErrorKey,
//        //                                   nil];
//        //        NSError *assetCannotBePlayedError = [NSError errorWithDomain:@"StitchedStreamPlayer" code:0 userInfo:errorDict];
//        
//        /* Display the error to the user. */
//        
//        return;
//    }
//    /* Create a new instance of AVPlayerItem from the now successfully loaded AVAsset. */
//    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
//}


@end


