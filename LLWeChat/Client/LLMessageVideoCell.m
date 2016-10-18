//
//  LLMessageVideoCell.m
//  LLWeChat
//
//  Created by GYJZH on 8/30/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageVideoCell.h"
#import "LLUtils.h"
#import "UIKit+LLExt.h"
#import "LLSDK.h"
#import "LLVideoDownloadStatusHUD.h"

#define ACTION_TAG_RESEND 10
#define ACTION_TAG_CANCEL 11

#define MAX_CELL_SIZE 200

static NSArray<NSString *> *menuActionNames;
static NSArray<NSString *> *menuNames;
static UIImage *thunbmailDownloadImage;

@interface LLMessageVideoCell ()

@property (nonatomic) UILabel *sizeLabel;
@property (nonatomic) UILabel *durationLabel;
@property (nonatomic) UIButton *actionButton;
@property (nonatomic) LLVideoDownloadStatusHUD *messageVideoPlay;
@property (nonatomic) UIImageView *borderView;
@property (nonatomic) UIImageView *thumbnailImageView;

@end

@implementation LLMessageVideoCell {
    CGSize videoImageSize;
}

+ (void)initialize {
    if (self == [LLMessageVideoCell class]) {
        menuNames = @[@"转发", @"收藏", @"删除", @"更多..."];
        menuActionNames = @[@"transforAction:", @"favoriteAction:", @"deleteAction:", @"moreAction:"];
        
        thunbmailDownloadImage = [[[UIImage imageNamed:@"fts_search_moment_video"] resizeImageToSize:CGSizeMake(50, 40)] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.videoImageView = [[UIImageView alloc] init];
        self.videoImageView.contentMode = UIViewContentModeScaleAspectFill;
        self.videoImageView.tintColor = [UIColor whiteColor];
        self.videoImageView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.4];
        [self.contentView addSubview:self.videoImageView];
        
        self.thumbnailImageView = [[UIImageView alloc] initWithImage:thunbmailDownloadImage];
        [self.thumbnailImageView sizeToFit];
        self.thumbnailImageView.backgroundColor = [UIColor clearColor];
        self.thumbnailImageView.contentMode = UIViewContentModeCenter;
        self.thumbnailImageView.tintColor = [UIColor darkGrayColor];
        [self.contentView addSubview:self.thumbnailImageView];
        
        [self.bubbleImage removeFromSuperview];
        self.videoImageView.layer.mask = self.bubbleImage.layer;
        self.videoImageView.layer.masksToBounds = YES;
        
        self.borderView = [[UIImageView alloc] init];
        self.borderView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.borderView];
        
        _sizeLabel = [[UILabel alloc] init];
        _sizeLabel.backgroundColor = [UIColor clearColor];
        _sizeLabel.font = [UIFont systemFontOfSize:10];
        _sizeLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_sizeLabel];
        
        _durationLabel = [[UILabel alloc] init];
        _durationLabel.backgroundColor = [UIColor clearColor];
        _durationLabel.font = [UIFont systemFontOfSize:10];
        _durationLabel.textColor = [UIColor whiteColor];
        [self.contentView addSubview:_durationLabel];
        
        _actionButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_actionButton setImage:[UIImage imageNamed:@"MessageVideoDownloadBtn"] forState:UIControlStateNormal];
        [_actionButton setImage:[UIImage imageNamed:@"MessageVideoDownloadBtnHL"] forState:UIControlStateHighlighted];
        _actionButton.tag = ACTION_TAG_CANCEL;
        _actionButton.frame = CGRectMake(0, 0, 24, 24);
        [self.contentView addSubview:_actionButton];
        
        _messageVideoPlay = [[LLVideoDownloadStatusHUD alloc] initWithFrame:CGRectMake(0, 0, 36, 36)];
        _messageVideoPlay.progress = 0;
        _messageVideoPlay.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_messageVideoPlay];
        
        
        self.menuActionNames = [menuActionNames mutableCopy];
        self.menuNames = [menuNames mutableCopy];
    }
    
    return self;
}

- (void)prepareForUse:(BOOL)isFromMe {
    [super prepareForUse:isFromMe];

    self.bubbleImage.image = isFromMe ? SenderImageNodeMask : ReceiverImageNodeMask;
    self.bubbleImage.highlightedImage = nil;

    self.borderView.image = isFromMe ? SenderImageNodeBorder : ReceiverImageNodeBorder;
}


- (void)setMessageModel:(LLMessageModel *)messageModel {
    _messageModel = messageModel;
    
    videoImageSize = [self.class videoImageViewSize:messageModel];
    _sizeLabel.text = [self.class getFileSizeString:messageModel.fileSize];
    _durationLabel.text = [self.class getDurationString:round(messageModel.mediaDuration)];
    
    [self updateMessageThumbnail];

    if (self.messageModel.isFromMe) {
        [self updateMessageUploadStatus];
    }else {
        [self updateMessageDownloadStatus];
    }
    
    [self layoutMessageViews:messageModel.isFromMe];

}

- (void)updateMessageThumbnail {
    _videoImageView.image = self.messageModel.thumbnailImage;
    self.thumbnailImageView.hidden = self.messageModel.thumbnailImage;
    self.messageVideoPlay.hidden = !self.thumbnailImageView.hidden;
}

- (void)setCellEditingAnimated:(BOOL)animated {
    if (self.isEditing == LLMessageCell_isEditing)
        return;
    self.isEditing = LLMessageCell_isEditing;
    
    [UIView animateWithDuration:animated ? DEFAULT_DURATION : 0
                     animations:^{
                         if (self.isEditing) {
                             self.selectControl.frame = CGRectMake(3, (AVATAR_HEIGHT - EDIT_CONTROL_SIZE)/2, EDIT_CONTROL_SIZE, EDIT_CONTROL_SIZE);
                             
                             if (!self.messageModel.isFromMe) {
                                 CGRect frame = self.avatarImage.frame;
                                 frame.origin.x = CGRectGetMaxX(self.selectControl.frame) + 3;
                                 self.avatarImage.frame = frame;
                                 
                                 [self layoutMessageViews:NO];
                             }
                         }else {
                             _selectControl.frame = CGRectMake(-EDIT_CONTROL_SIZE, (AVATAR_HEIGHT - EDIT_CONTROL_SIZE)/2, EDIT_CONTROL_SIZE, EDIT_CONTROL_SIZE);
                             
                             if (!self.messageModel.isFromMe) {
                                 CGRect frame = self.avatarImage.frame;
                                 frame.origin.x = AVATAR_SUPER_LEFT;
                                 self.avatarImage.frame = frame;
                                 
                                 [self layoutMessageViews:NO];
                             }
                         }
                     }];
}


- (void)layoutMessageViews:(BOOL)isFromMe {
    CGRect frame = CGRectZero;
    frame.size = videoImageSize;
    
    if (isFromMe) {
        frame.origin.x = CGRectGetMinX(self.avatarImage.frame) - CONTENT_AVATAR_MARGIN - frame.size.width;
        frame.origin.y = CONTENT_SUPER_TOP;
        self.videoImageView.frame = frame;

        CGPoint point = CGPointZero;
        point.x = CGRectGetMinX(self.videoImageView.frame) - 21;
        point.y = self.videoImageView.center.y;
        _actionButton.center = point;
        
        frame.size = _sizeLabel.intrinsicContentSize;
        frame.origin.x = 10 + CGRectGetMinX(self.videoImageView.frame);
        frame.origin.y = CGRectGetMaxY(self.videoImageView.frame) - 15;
        _sizeLabel.frame = frame;
        
        frame.size = _durationLabel.intrinsicContentSize;
        frame.origin.x = CGRectGetMaxX(self.videoImageView.frame) - 5 - BUBBLE_RIGHT_BLANK- CGRectGetWidth(frame);
        frame.origin.y = CGRectGetMinY(_sizeLabel.frame);
        _durationLabel.frame = frame;
        
        _messageVideoPlay.center = self.videoImageView.center;
        frame = _messageVideoPlay.frame;
        frame.origin.x -= BUBBLE_RIGHT_BLANK/2;
        _messageVideoPlay.frame = frame;
        
    }else {
        frame.origin.x = CGRectGetMaxX(self.avatarImage.frame) + CONTENT_AVATAR_MARGIN;
        frame.origin.y = CONTENT_SUPER_TOP;
        self.videoImageView.frame = frame;
        
        CGPoint point = CGPointZero;
        point.x = CGRectGetMaxX(frame) + 21;
        point.y = self.videoImageView.center.y;
        _actionButton.center = point;
        
        frame.size = _sizeLabel.intrinsicContentSize;
        frame.origin.x = 10 + CGRectGetMinX(self.videoImageView.frame) + BUBBLE_LEFT_BLANK;
        frame.origin.y = CGRectGetMaxY(self.videoImageView.frame) - 15;
        _sizeLabel.frame = frame;
        
        frame.size = _durationLabel.intrinsicContentSize;
        frame.origin.x = CGRectGetMaxX(self.videoImageView.frame) - 5 - CGRectGetWidth(frame);
        frame.origin.y = CGRectGetMinY(_sizeLabel.frame);
        _durationLabel.frame = frame;
        
        _messageVideoPlay.center = self.videoImageView.center;
        frame = _messageVideoPlay.frame;
        frame.origin.x += BUBBLE_LEFT_BLANK/2;
        _messageVideoPlay.frame = frame;
    }
    
    frame = self.videoImageView.frame;
    frame.origin.x = CGRectGetMinX(frame) -1;
    frame.size.height += 2;
    frame.size.width += 1;
    self.borderView.frame = frame;
    
    self.thumbnailImageView.center = _messageVideoPlay.center;
    
    self.bubbleImage.frame = self.videoImageView.bounds;

}


- (void)updateMessageUploadStatus {
    self.indicatorView.hidden = YES;
    self.statusButton.hidden = YES;
    self.thumbnailImageView.hidden = YES;
    
    switch (self.messageModel.messageStatus) {
        case kLLMessageStatusDelivering:
            if (self.messageModel.fileUploadProgress >= 100) {
                WEAK_SELF;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    weakSelf.actionButton.hidden = YES;
                    weakSelf.messageVideoPlay.progress = 100;
                    weakSelf.messageVideoPlay.status = kLLVideoDownloadHUDStatusSuccess;
                });
            }else if (self.messageModel.fileUploadProgress <= 0){
                self.actionButton.hidden = NO;
                [self actionButtonIsUpDowning:YES];
                _messageVideoPlay.progress = 0;
                _messageVideoPlay.status = kLLVideoDownloadHUDStatusWaiting;
            }else {
                self.actionButton.hidden = NO;
                [self actionButtonIsUpDowning:YES];
                _messageVideoPlay.status = kLLVideoDownloadHUDStatusDownloading;
                _messageVideoPlay.progress = self.messageModel.fileUploadProgress;
            }
            
            break;
        case kLLMessageStatusSuccessed:
            self.actionButton.hidden = YES;
            _messageVideoPlay.progress = 100;
            _messageVideoPlay.status = kLLVideoDownloadHUDStatusSuccess;
            break;
        case kLLMessageStatusFailed:
        case kLLMessageStatusPending:
            self.actionButton.hidden = NO;
            [self actionButtonIsUpDowning:NO];
            _messageVideoPlay.progress = 0;
            _messageVideoPlay.status = kLLVideoDownloadHUDStatusPending;
            break;
        case kLLMessageStatusWaiting:
            self.actionButton.hidden = NO;
            [self actionButtonIsUpDowning:YES];
            _messageVideoPlay.progress = 0;
            _messageVideoPlay.status = kLLVideoDownloadHUDStatusWaiting;
            break;
        default:
            break;
    }
    
}

- (void)updateMessageDownloadStatus {
    self.indicatorView.hidden = YES;
    self.statusButton.hidden = YES;
    
    switch (self.messageModel.messageDownloadStatus) {
        case kLLMessageDownloadStatusDownloading:
            if (self.messageModel.fileDownloadProgress >= 100) {
                WEAK_SELF;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    weakSelf.actionButton.hidden = YES;
                    weakSelf.messageVideoPlay.status = kLLVideoDownloadHUDStatusSuccess;
                });
                
            }else if (self.messageModel.fileDownloadProgress <=0) {
                _actionButton.hidden = NO;
                [self actionButtonIsUpDowning:YES];
                _messageVideoPlay.status = kLLVideoDownloadHUDStatusWaiting;
            }else {
                _actionButton.hidden = NO;
                [self actionButtonIsUpDowning:YES];
                _messageVideoPlay.progress = self.messageModel.fileDownloadProgress;
                _messageVideoPlay.status = kLLVideoDownloadHUDStatusDownloading;
            }
            
            break;
        case kLLMessageDownloadStatusWaiting:
            _actionButton.hidden = NO;
            [self actionButtonIsUpDowning:YES];
            _messageVideoPlay.progress = kLLVideoDownloadHUDStatusWaiting;
            break;
        case kLLMessageDownloadStatusPending:
            self.actionButton.hidden = YES;
            _messageVideoPlay.status = kLLVideoDownloadHUDStatusPending;
            break;
        case kLLMessageDownloadStatusFailed: //视频下载出错不显示重新下载按钮
            self.actionButton.hidden = YES;
            [self actionButtonIsUpDowning:NO];
            _messageVideoPlay.status = kLLVideoDownloadHUDStatusPending;
            break;
        case kLLMessageDownloadStatusSuccessed:
            self.actionButton.hidden = YES;
            _messageVideoPlay.progress = 100;
            _messageVideoPlay.status = kLLVideoDownloadHUDStatusSuccess;
            break;
        case kLLMessageDownloadStatusNone:
            break;
            
    }

}

- (void)actionButtonIsUpDowning:(BOOL)isUpDowning {
    if (isUpDowning) {
        [_actionButton setImage:[UIImage imageNamed:@"MessageVideoDownloadBtn"] forState:UIControlStateNormal];
        [_actionButton setImage:[UIImage imageNamed:@"MessageVideoDownloadBtnHL"] forState:UIControlStateHighlighted];
        _actionButton.tag = ACTION_TAG_CANCEL;
    }else {
        [_actionButton setImage:[UIImage imageNamed:@"MessageSendFail"] forState:UIControlStateNormal];
        [_actionButton setImage:[UIImage imageNamed:@"MessageSendFail"] forState:UIControlStateHighlighted];
        _actionButton.tag = ACTION_TAG_RESEND;
    }
}

+ (CGFloat)heightForModel:(LLMessageModel *)model {
    CGSize ret = [self videoImageViewSize:model];
    
    return ret.height + CONTENT_SUPER_BOTTOM;
}

+ (CGSize)videoImageViewSize:(LLMessageModel *)model {
    CGSize size = model.thumbnailImageSize;
    CGSize ret;
    if (size.width <= size.height) {
        if (size.height > MAX_CELL_SIZE) {
            CGFloat scale = MAX_CELL_SIZE / size.height;
            ret.height = MAX_CELL_SIZE;
            ret.width = size.width * scale;
        }else {
            ret = size;
        }
    }else {
        if (size.width > MAX_CELL_SIZE) {
            CGFloat scale = MAX_CELL_SIZE / size.width;
            ret.width = MAX_CELL_SIZE;
            ret.height = size.height * scale;
        }else {
            ret = size;
        }
    }

    return ret;
}

+ (NSString *)getFileSizeString:(CGFloat)fileSize {
    NSString *ret = [NSString stringWithFormat:@"%.1fM", fileSize/1024/1024];
    return ret;
}

+ (NSString *)getDurationString:(NSInteger)duration {
    NSInteger minutes = duration / 60;
    NSInteger seconds = duration % 60;
    NSString *ret = [NSString stringWithFormat:@"%ld:%02ld", minutes, seconds];
    
    return ret;
}


#pragma mark - 弹出、弹入动画 -

- (CGRect)contentFrameInWindow {
    return [self.videoImageView convertRect:self.videoImageView.bounds toView:self.videoImageView.window];
}

+ (UIView *)getSnapshot:(UIView *)targetView messageModel:(LLMessageModel *)messageModel {
    UIImageView *videoView = [[UIImageView alloc] init];
    videoView.contentMode = UIViewContentModeScaleAspectFit;
    videoView.image = messageModel.thumbnailImage;
    
    CGRect frame = CGRectZero;
    frame.size = [self videoImageViewSize:messageModel];
    videoView.frame = frame;
    
    return videoView;
}

+ (UIImage *)bubbleImageForModel:(LLMessageModel *)model {
    return model.isFromMe ? SenderImageNodeMask : ReceiverImageNodeMask;
}


#pragma mark - 手势

- (UIView *)hitTestForTapGestureRecognizer:(CGPoint)point {
    CGPoint pointInView = [self.contentView convertPoint:point toView:self.videoImageView];
    if ([self.videoImageView pointInside:pointInView withEvent:nil]) {
        return self.videoImageView;
    }
    
    if (!self.actionButton.hidden) {
        pointInView = [self.contentView convertPoint:point toView:self.actionButton];
        if ([self.actionButton pointInside:pointInView withEvent:nil]) {
            return self.actionButton;
        }
    }
    
    return nil;
}

- (UIView *)hitTestForlongPressedGestureRecognizer:(CGPoint)point {
    CGPoint pointInView = [self.contentView convertPoint:point toView:self.videoImageView];
    if ([self.videoImageView pointInside:pointInView withEvent:nil]) {
        return self.videoImageView;
    }
    
    return nil;
}



- (void)contentEventTappedInView:(UIView *)view {
    if (self.videoImageView == view) {
        SAFE_SEND_MESSAGE(self.delegate, cellVideoDidTapped:) {
            [self.delegate cellVideoDidTapped:self];
        }
    }else if (!self.actionButton.hidden && self.actionButton == view){
        if (self.messageModel.isFromMe) {
            if (_actionButton.tag == ACTION_TAG_CANCEL){
                NSLog(@"暂不支持取消上传");
            }else {
                SAFE_SEND_MESSAGE(self.delegate, resendMessage:) {
                    [self.delegate resendMessage:self.messageModel];
                }
            }
        }else {
            if (_actionButton.tag == ACTION_TAG_CANCEL) {
                NSLog(@"暂不支持取消下载");
            }else {
                SAFE_SEND_MESSAGE(self.delegate, redownloadMessage:) {
                    [self.delegate redownloadMessage:self.messageModel];
                }
            }
        }
    }

}

- (void)contentEventLongPressedBeganInView:(UIView *)view {
    [self showMenuControllerInRect:self.videoImageView.bounds inView:self.videoImageView];
}




#pragma mark - 菜单

- (void)copyAction:(id)sender {
    
}

- (void)transforAction:(id)sender {
    
}

- (void)favoriteAction:(id)sender {
    
}

#pragma mark - 缓存优化 -

- (void)willDisplayCell {
    if (!self.videoImageView.image) {
        self.videoImageView.image = self.messageModel.thumbnailImage;
    }
}

- (void)didEndDisplayingCell {
    self.videoImageView.image = nil;
}


@end



