//
//  LLMessageRecordingCell.m
//  LLWeChat
//
//  Created by GYJZH on 9/19/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageRecordingCell.h"
#import "UIKit+LLExt.h"
#import "LLMessageVoiceCell.h"

#define RECORD_ANIMATION_KEY @"RecordAnimate"

@interface LLMessageRecordingCell ()

@property (nonatomic) UIImageView *downloadingImageView;

@property (nonatomic) CAKeyframeAnimation *keyFrameAnimation;

@end

@implementation LLMessageRecordingCell

+ (instancetype)sharedRecordingCell {
    static LLMessageRecordingCell *cell;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        cell = [[LLMessageRecordingCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
        [cell prepareForUse:YES];
        cell.userInteractionEnabled = NO;
    });
    
    return cell;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        UIImage *image = [UIImage imageNamed:@"SenderVoiceNodeDownloading"];
        _downloadingImageView = [[UIImageView alloc] initWithImage:[image resizableImage]];
        
        [self.contentView insertSubview:self.downloadingImageView belowSubview:self.bubbleImage];
        
    }
    
    return self;
}

- (void)prepareForUse:(BOOL)isFromMe {
    [super prepareForUse:isFromMe];
     if (isFromMe) {
        CGRect frame = CGRectZero;
        frame.size.width = MIN_CELL_WIDTH + BUBBLE_LEFT_BLANK + BUBBLE_RIGHT_BLANK;
        frame.size.height = AVATAR_HEIGHT + BUBBLE_TOP_BLANK + BUBBLE_BOTTOM_BLANK;
        frame.origin.x = CGRectGetMinX(self.avatarImage.frame) - CGRectGetWidth(frame) - CONTENT_AVATAR_MARGIN;
        frame.origin.y = -BUBBLE_TOP_BLANK;

        self.bubbleImage.frame = frame;
        
        self.downloadingImageView.frame = self.bubbleImage.frame;
        [self.bubbleImage.layer addAnimation:self.keyFrameAnimation forKey:RECORD_ANIMATION_KEY];
    }
}


- (CAKeyframeAnimation *)keyFrameAnimation {
    if (!_keyFrameAnimation) {
        _keyFrameAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        _keyFrameAnimation.duration = 2;
        _keyFrameAnimation.repeatCount = HUGE_VALF;
        _keyFrameAnimation.removedOnCompletion = NO;
        _keyFrameAnimation.calculationMode = kCAAnimationLinear;
        _keyFrameAnimation.keyTimes = @[@(0), @(0.7), @(1)];
        _keyFrameAnimation.values = @[@(1), @(0), @(1)];
        _keyFrameAnimation.timingFunctions = @[
                                               [CAMediaTimingFunction functionWithName: kCAMediaTimingFunctionEaseInEaseOut],
                                               [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut]
                                               ];
    }
    
    return _keyFrameAnimation;
}

- (void)endRecordAnimation {
//    [UIView animateWithDuration:0.25
//                          delay:0
//                        options:UIViewAnimationOptionCurveEaseInOut
//                     animations:^{
//                         width = MIN_CELL_WIDTH + (MAX_CELL_WIDTH - MIN_CELL_WIDTH) * sin(self.messageModel.mediaDuration / 60);
//                         self.durationLabel.top_LL = OFFSET_Y + 20;
//                         [self layoutExtendSubviews:self.messageModel.isFromMe];
//                     }
//                     completion:nil];
    
}

- (void)setMessageModel:(LLMessageModel *)messageModel {
    _messageModel = messageModel;
}


+ (CGFloat)heightForModel:(LLMessageModel *)model {
    return AVATAR_HEIGHT + CONTENT_SUPER_BOTTOM;
}

@end
