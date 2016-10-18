//
//  LLMessageModel.h
//  LLWeChat
//
//  Created by GYJZH on 7/21/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EMMessage.h"
#import "LLError.h"
#import "LLSDKType.h"
#import <MapKit/MapKit.h>
@import AVFoundation;

@interface LLMessageModel : NSObject

//展示消息的CellHeight，计算一次，然后缓存
@property (nonatomic) CGFloat cellHeight;

@property (nonatomic, copy, readonly) NSString *messageId;
@property (nonatomic, copy, readonly) NSString *conversationId;

//消息发送方
@property (nonatomic, copy) NSString *from;
//消息接收方
@property (nonatomic, copy) NSString *to;

@property (nonatomic, getter=isFromMe) BOOL fromMe;

@property (nonatomic, readonly) LLMessageBodyType messageBodyType;

@property (nonatomic, readonly) LLMessageDirection messageDirection;

@property (nonatomic) NSTimeInterval timestamp;

@property (nonatomic) NSString *messageBody_Text;

@property (nonatomic) NSMutableAttributedString *richTestString;

@property (nonatomic) NSDictionary *ext;

//消息即将被删除
@property (nonatomic) BOOL isDeleting;

//GIF动画停止时，显示的照片索引。在恢复动画时，从此帧开始播放
@property (nonatomic) NSInteger gifShowIndex;

#pragma mark - 图片消息

@property (nonatomic) UIImage *thumbnailImage;

@property (nonatomic) CGSize thumbnailImageSize;

- (UIImage *)fullImage;

#pragma mark - 地址消息

@property (nonatomic, copy) NSString *address;
@property (nonatomic, copy) NSString *locationName;

@property (nonatomic) CLLocationCoordinate2D coordinate2D;

@property (nonatomic) UIImage *snapshotImage;
@property (nonatomic) CGFloat snapshotScale;
@property (nonatomic) CGFloat zoomLevel;

@property (nonatomic) BOOL isFetchingAddress;
@property (nonatomic) BOOL isLoadingLocationSnapshot;

#pragma mark - 音频、视频

@property (nonatomic) BOOL isMediaPlaying;

@property (nonatomic) BOOL isMediaPlayed;

@property (nonatomic) BOOL needAnimateVoiceCell;

- (BOOL)isVideoPlayable;

- (BOOL)isFullImageAvailable;

- (BOOL)isVoicePlayable;

//单位为妙
@property (nonatomic) CGFloat mediaDuration;

#pragma mark - 附件、文件
//附件下载地址
@property (nonatomic, copy) NSString *fileRemotePath;
//附件本地地址
@property (nonatomic, copy) NSString *fileLocalPath;
//单位为字节
@property (nonatomic) long long fileSize;
//附件上传进度，范围为0--100
@property (nonatomic) NSInteger fileUploadProgress;
//附件下载进度，范围为0--100
@property (nonatomic) NSInteger fileDownloadProgress;

@property (nonatomic, readonly) BOOL isFetchingThumbnail;

@property (nonatomic, readonly) BOOL isFetchingAttachment;

@property (nonatomic) LLError *error;

//该方法供外部代码调用
+ (LLMessageModel *)messageModelFromPool:(EMMessage *)message;

- (instancetype)initWithType:(LLMessageBodyType)type;

- (void)updateMessage:(EMMessage *)aMessage;

+ (NSString *)messageTypeTitle:(EMMessage *)message;

- (NSInteger)fileAttachmentSize;

- (void)cleanWhenConversationSessionEnded;

#pragma mark - 消息状态 -
@property (nonatomic, readonly) LLMessageStatus messageStatus;

@property (nonatomic, readonly) LLMessageDownloadStatus messageDownloadStatus;

@property (nonatomic, readonly) LLMessageDownloadStatus thumbnailDownloadStatus;

@property (nonatomic) BOOL needsUpdateCell;


#pragma mark - 以下方法 Client代码不直接访问 -
@property (nonatomic) EMMessage * sdk_message;

@property (nonatomic) BOOL isDownloadingAttachment;

- (instancetype)initWithMessage:(EMMessage *)message;

- (void)internal_setMessageStatus:(LLMessageStatus)messageStatus;

- (void)internal_setMessageDownloadStatus:(LLMessageDownloadStatus)messageDownloadStatus;

- (void)internal_setThumbnailDownloadStatus:(LLMessageDownloadStatus)thumbnailDownloadStatus;

- (void)internal_setIsFetchingAttachment:(BOOL)isFetchingAttachment;

- (void)internal_setIsFetchingThumbnail:(BOOL)isFetchingThumbnail;

#pragma mark - 以下方法仅供测试使用 -
- (instancetype)initWithImageModel:(LLMessageModel *)messageModel;

@end

