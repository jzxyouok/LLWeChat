//
//  LLMessageVoiceCell.m
//  LLWeChat
//
//  Created by GYJZH on 8/30/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageVoiceCell.h"
#import "LLColors.h"
#import "LLUtils.h"
#import "UIKit+LLExt.h"

#define OFFSET_Y 5
#define RECORD_ANIMATION_KEY @"RecordAnimate"

static NSArray<NSString *> *menuActionNames;
static NSArray<NSString *> *menuNames;
//static UIImage *downloadingImage;

@interface LLMessageVoiceCell ()

@property (strong, nonatomic) UIImageView *voiceImageView;
@property (nonatomic) UILabel *durationLabel;
@property (nonatomic) UIView *isMediaPlayedIndicator;

@property (nonatomic) UIImageView *downloadingImageView;

@end

@implementation LLMessageVoiceCell {
//    CGRect bubbleFrame;
//    CGFloat width;
}

+ (void)initialize {
    if (self == [LLMessageVoiceCell class]) {
        menuNames = @[@"听筒播放", @"收藏", @"转文字", @"删除", @"更多..."];
        menuActionNames = @[@"playAction:", @"favoriteAction:", @"translateToWordsAction:",@"deleteAction:", @"moreAction:"];
//        UIImage *image = [UIImage imageNamed:@"SenderVoiceNodeDownloading"];
//        downloadingImage = [image resizableImage];
    }
    
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        _voiceImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, OFFSET_Y + (AVATAR_HEIGHT - 17)/2, 12.5, 17)];
        _voiceImageView.contentMode = UIViewContentModeCenter;
        _voiceImageView.animationDuration = 1;
        [self.contentView addSubview:_voiceImageView];
        
        _durationLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, OFFSET_Y + 20, 100, 20)];
        _durationLabel.font = [UIFont systemFontOfSize:16];
        _durationLabel.textColor = kLLTextColor_lightGray_7;
        [self.contentView addSubview:_durationLabel];
        
        _isMediaPlayedIndicator = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 10)];
        _isMediaPlayedIndicator.backgroundColor = kLLBackgroundColor_SlightDardRed;
        _isMediaPlayedIndicator.layer.cornerRadius = 5;
        _isMediaPlayedIndicator.clipsToBounds = YES;
        [self.contentView addSubview:_isMediaPlayedIndicator];
        
        self.bubbleImage.frame = CGRectMake(0, -BUBBLE_TOP_BLANK + OFFSET_Y, 100, AVATAR_HEIGHT + BUBBLE_TOP_BLANK + BUBBLE_BOTTOM_BLANK);
        
        self.menuNames = [menuNames mutableCopy];
        self.menuActionNames = [menuActionNames mutableCopy];
    }
    
    return self;
}

- (void)prepareForUse:(BOOL)isFromMe {
    [super prepareForUse:isFromMe];

    CGRect frame = self.avatarImage.frame;
    frame.origin.y = OFFSET_Y;
    self.avatarImage.frame = frame;

}

- (void)setMessageModel:(LLMessageModel *)messageModel {
    _messageModel = messageModel;
    
    if (messageModel.isMediaPlaying) {
        [self startVoicePlaying];
    }else {
        [self stopVoicePlaying];
    }
    
    self.isMediaPlayedIndicator.hidden = messageModel.fromMe || messageModel.isMediaPlayed;
    self.durationLabel.text = [NSString stringWithFormat:@"%.0f''", round(messageModel.mediaDuration)];
    
    if (self.messageModel.isFromMe) {
        [self updateMessageUploadStatus];
    }else {
        [self updateMessageDownloadStatus];
    }
    
    if (messageModel.needAnimateVoiceCell) {
        messageModel.needAnimateVoiceCell = NO;
        [self layoutSubviewsWithAnimation:YES];
    }else {
        [self layoutSubviewsNoAnimation:self.messageModel.isFromMe];

    }

}

- (BOOL)isVoicePlaying {
    return self.voiceImageView.isAnimating;
}

- (void)stopVoicePlaying {
    self.voiceImageView.image = self.messageModel.isFromMe ?
    [UIImage imageNamed:@"SenderVoiceNodePlaying"] :
    [UIImage imageNamed:@"ReceiverVoiceNodePlaying"];
    [self.voiceImageView stopAnimating];
    self.voiceImageView.animationImages = nil;
    self.isMediaPlayedIndicator.hidden = YES;
}

- (void)startVoicePlaying {
    self.voiceImageView.animationImages = self.messageModel.isFromMe ?
    @[[UIImage imageNamed:@"SenderVoiceNodePlaying001"],
      [UIImage imageNamed:@"SenderVoiceNodePlaying002"],
      [UIImage imageNamed:@"SenderVoiceNodePlaying003"]] :
    @[[UIImage imageNamed:@"ReceiverVoiceNodePlaying001"],
      [UIImage imageNamed:@"ReceiverVoiceNodePlaying002"],
      [UIImage imageNamed:@"ReceiverVoiceNodePlaying003"]];
    [self.voiceImageView startAnimating];
    self.isMediaPlayedIndicator.hidden = YES;
}

- (void)updateVoicePlayingStatus {
    if (self.messageModel.isMediaPlaying) {
        [self startVoicePlaying];
    }else {
        [self stopVoicePlaying];
    }
}

#pragma mark - 布局 -

- (void)layoutSubviewsWithAnimation:(BOOL)isFromMe {
    CGRect frame = self.bubbleImage.frame;
    frame.size.width = MIN_CELL_WIDTH + BUBBLE_LEFT_BLANK + BUBBLE_RIGHT_BLANK;
    frame.origin.x = CGRectGetMinX(self.avatarImage.frame) - CGRectGetWidth(frame) - CONTENT_AVATAR_MARGIN;
    self.bubbleImage.frame = frame;
    
    frame = self.durationLabel.frame;
    frame.origin.x = CGRectGetMinX(self.bubbleImage.frame) - self.durationLabel.intrinsicContentSize.width;
    frame.origin.y = OFFSET_Y + 10;
    self.durationLabel.frame = frame;
    
    frame = self.voiceImageView.frame;
    frame.origin.x = CGRectGetMaxX(self.bubbleImage.frame) - BUBBLE_LEFT_BLANK - 15 - CGRectGetWidth(frame);
    self.voiceImageView.frame = frame;
    
    if (_indicatorView || _statusButton) {
        _indicatorView.center = CGPointMake(CGRectGetMinX(self.bubbleImage.frame) - 7, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
        
        _statusButton.center = CGPointMake(CGRectGetMinX(self.bubbleImage.frame) - 40, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
    }
    
    [UIView animateWithDuration:DEFAULT_DURATION animations:^{
        CGRect frame = self.bubbleImage.frame;
        frame.size.width = [self cellWidth] + BUBBLE_LEFT_BLANK + BUBBLE_RIGHT_BLANK;
        frame.origin.x = CGRectGetMinX(self.avatarImage.frame) - CGRectGetWidth(frame) - CONTENT_AVATAR_MARGIN;
        self.bubbleImage.frame = frame;
        
        frame = self.durationLabel.frame;
        frame.origin.x = CGRectGetMinX(self.bubbleImage.frame) - self.durationLabel.intrinsicContentSize.width;
        frame.origin.y = OFFSET_Y + 20;
        self.durationLabel.frame = frame;
        
        frame = self.voiceImageView.frame;
        frame.origin.x = CGRectGetMaxX(self.bubbleImage.frame) - BUBBLE_LEFT_BLANK - 15 - CGRectGetWidth(frame);
        self.voiceImageView.frame = frame;
        
        if (_indicatorView || _statusButton) {
            _indicatorView.center = CGPointMake(CGRectGetMinX(self.bubbleImage.frame) - 7, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
            
            _statusButton.center = CGPointMake(CGRectGetMinX(self.bubbleImage.frame) - 40, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
        }
    }];

}

- (void)layoutSubviewsNoAnimation:(BOOL)isFromMe {
    CGRect frame;
    
    if (isFromMe) {
        frame = self.bubbleImage.frame;
        frame.size.width = [self cellWidth] + BUBBLE_LEFT_BLANK + BUBBLE_RIGHT_BLANK;
        frame.origin.x = CGRectGetMinX(self.avatarImage.frame) - CGRectGetWidth(frame) - CONTENT_AVATAR_MARGIN;
        self.bubbleImage.frame = frame;
        
        frame = self.voiceImageView.frame;
        frame.origin.x = CGRectGetMaxX(self.bubbleImage.frame) - BUBBLE_LEFT_BLANK - 15 - CGRectGetWidth(frame);
        self.voiceImageView.frame = frame;
        
        frame = self.durationLabel.frame;
        frame.origin.x = CGRectGetMinX(self.bubbleImage.frame) - self.durationLabel.intrinsicContentSize.width;
        frame.origin.y = OFFSET_Y + 20;
        self.durationLabel.frame = frame;
        
        if (_indicatorView || _statusButton) {
            _indicatorView.center = CGPointMake(CGRectGetMinX(self.bubbleImage.frame) - 7, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
            
            _statusButton.center = CGPointMake(CGRectGetMinX(self.bubbleImage.frame) - 40, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
        }
    }else {
        frame = self.bubbleImage.frame;
        frame.size.width = [self cellWidth] + BUBBLE_LEFT_BLANK + BUBBLE_RIGHT_BLANK;
        frame.origin.x = CONTENT_AVATAR_MARGIN + CGRectGetMaxX(self.avatarImage.frame);
        self.bubbleImage.frame = frame;

        frame = self.voiceImageView.frame;
        frame.origin.x = CGRectGetMinX(self.bubbleImage.frame) + BUBBLE_LEFT_BLANK + 15;
        self.voiceImageView.frame = frame;
        
        frame = self.durationLabel.frame;
        frame.origin.x = CGRectGetMaxX(self.bubbleImage.frame);
        frame.origin.y = OFFSET_Y + 20;
        self.durationLabel.frame = frame;
        
        frame = _isMediaPlayedIndicator.frame;
        frame.origin.x = CGRectGetMaxX(self.bubbleImage.frame);
        _isMediaPlayedIndicator.frame = frame;
        
        if (_indicatorView || _statusButton) {
            _indicatorView.center = CGPointMake(CGRectGetMaxX(self.bubbleImage.frame) + 40, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
            
            _statusButton.center = _indicatorView.center;
        }
    
    }
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
                                 
                                 [self layoutSubviewsNoAnimation:NO];
                             }
                         }else {
                             _selectControl.frame = CGRectMake(-EDIT_CONTROL_SIZE, (AVATAR_HEIGHT - EDIT_CONTROL_SIZE)/2, EDIT_CONTROL_SIZE, EDIT_CONTROL_SIZE);
                             
                             if (!self.messageModel.isFromMe) {
                                 CGRect frame = self.avatarImage.frame;
                                 frame.origin.x = AVATAR_SUPER_LEFT;
                                 self.avatarImage.frame = frame;
                                 
                                 [self layoutSubviewsNoAnimation:NO];
                             }
                         }
                     }];
}

- (CGFloat)cellWidth {
    return MIN_CELL_WIDTH + (MAX_CELL_WIDTH - MIN_CELL_WIDTH) * sin(self.messageModel.mediaDuration / MAX_RECORD_TIME_ALLOWED);
}

- (void)updateMessageUploadStatus {
    switch (self.messageModel.messageStatus) {
        case kLLMessageStatusPending:
        case kLLMessageStatusFailed:
            goto LABEL_MessageStatusFailed;
            
        case kLLMessageStatusDelivering:
        case kLLMessageStatusWaiting:
            if (self.messageModel.mediaDuration > 20) {
                goto LABEL_MessageStatusDelivering;
            }else {
                goto LABEL_MessageStatusSuccessed;
            }
            
        case kLLMessageStatusSuccessed:
            goto LABEL_MessageStatusSuccessed;
        default:
            break;
    }

    
LABEL_MessageStatusDelivering:
    self.durationLabel.hidden = YES;
    self.voiceImageView.hidden = YES;
    self.statusButton.hidden = YES;
    self.indicatorView.hidden = NO;
    [self.indicatorView startAnimating];
    goto END;
    
LABEL_MessageStatusSuccessed:
    self.voiceImageView.hidden = NO;
    self.statusButton.hidden = YES;
    self.durationLabel.hidden = NO;
    self.indicatorView.hidden = YES;
    [self.indicatorView stopAnimating];
    goto END;
    
LABEL_MessageStatusFailed:
    self.voiceImageView.hidden = NO;
    self.statusButton.hidden = NO;
    self.durationLabel.hidden = NO;
    self.indicatorView.hidden = YES;
    [self.indicatorView stopAnimating];

END:
    return;

}


- (void)updateMessageDownloadStatus {
    switch (self.messageModel.messageDownloadStatus) {
        case kLLMessageDownloadStatusWaiting:
        case kLLMessageDownloadStatusDownloading:
            self.indicatorView.hidden = NO;
            self.statusButton.hidden = YES;
            [self.indicatorView startAnimating];
            break;
        case kLLMessageDownloadStatusPending:
        case kLLMessageDownloadStatusFailed:
            self.indicatorView.hidden = YES;
            [self.indicatorView stopAnimating];
            self.statusButton.hidden = NO;
            break;
        case kLLMessageDownloadStatusSuccessed:
            _indicatorView.hidden = YES;
            [_indicatorView stopAnimating];
            _statusButton.hidden = YES;
            break;
            
        default:
            break;
    }
}

+ (CGFloat)heightForModel:(LLMessageModel *)model {
    return AVATAR_HEIGHT + CONTENT_SUPER_BOTTOM + OFFSET_Y;
}


#pragma mark - 手势 -

- (UIView *)hitTestForTapGestureRecognizer:(CGPoint)point {
    CGPoint pointInView = [self.contentView convertPoint:point toView:self.bubbleImage];

    if ([self.bubbleImage pointInside:pointInView withEvent:nil]) {
        return self.bubbleImage;
    }
    
    return nil;
}

- (UIView *)hitTestForlongPressedGestureRecognizer:(CGPoint)point  {
    CGPoint pointInView = [self.contentView convertPoint:point toView:self.bubbleImage];
    
    if ([self.bubbleImage pointInside:pointInView withEvent:nil]) {
        return self.bubbleImage;
    }
    
    return nil;
}


- (void)contentEventTouchBeganInView:(UIView *)view {
    self.bubbleImage.highlighted = YES;
}

- (void)contentEventTouchCancelled {
    self.bubbleImage.highlighted = NO;
}

- (void)contentEventTappedInView:(UIView *)view {
    self.bubbleImage.highlighted = NO;
    
    if ([self.delegate respondsToSelector:@selector(cellVoiceDidTapped:)]) {
        [self.delegate cellVoiceDidTapped:self];
    }
}

- (void)contentEventLongPressedBeganInView:(UIView *)view {
    self.bubbleImage.highlighted = YES;
    [self showMenuControllerInRect:self.bubbleImage.bounds inView:self.bubbleImage];
}


#pragma mark - 菜单

- (void)playAction:(id)sender {
    [self contentEventTappedInView:nil];
}

- (void)favoriteAction:(id)sender {
    
}

- (void)translateToWordsAction:(id)sender {
    
}



@end
