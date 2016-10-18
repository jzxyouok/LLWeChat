//
//  LLMessageGifCell.m
//  LLWeChat
//
//  Created by GYJZH on 8/18/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageGifCell.h"
#import "UIKit+LLExt.h"
#import "LLEmotionModelManager.h"
#import "LLUtils.h"
#import "LLChatManager+MessageExt.h"
#import "LLGIFImageView.h"

#define GIF_IMAGE_SIZE 120

static NSArray<NSString *> *menuActionNames;
static NSArray<NSString *> *menuNames;

@interface LLMessageGifCell ()
@property (nonatomic) LLGIFImageView *gifImageView;

@end

@implementation LLMessageGifCell

+ (void)initialize {
    if (self == [LLMessageGifCell class]) {
        menuNames = @[@"添加到表情", @"转发", @"查看专集", @"删除", @"更多..."];
        menuActionNames = @[@"addToEmojiAction:", @"ForwardAction:", @"showAlbumAction:",@"deleteAction:", @"moreAction:"];
    }
    
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.gifImageView = [[LLGIFImageView alloc] initWithFrame:CGRectMake(0, CONTENT_SUPER_TOP, GIF_IMAGE_SIZE, GIF_IMAGE_SIZE)];
        self.gifImageView.contentMode = UIViewContentModeScaleAspectFit;
        [self.contentView addSubview:self.gifImageView];
        
        self.menuNames = [menuNames mutableCopy];
        self.menuActionNames = [menuActionNames mutableCopy];
    }
    
    return self;
}

- (void)setMessageModel:(LLMessageModel *)messageModel {
    [super setMessageModel:messageModel];
    
//    NSData *gifData = [[LLChatManager sharedManager] gifDataForGIFMessageModel:messageModel];
//    self.gifImageView.image = [UIImage sd_animatedGIFWithData:gifData];
//    self.gifImageView.gifData = gifData;
//    self.gifImageView.startShowIndex = self.messageModel.gifShowIndex;
//    [self.gifImageView startGIFAnimating];
}

- (void)layoutMessageContentViews:(BOOL)isFromMe {
    CGRect frame = self.gifImageView.frame;
    if (isFromMe) {
        frame.origin.x = CGRectGetMinX(self.avatarImage.frame) - CONTENT_AVATAR_MARGIN - frame.size.width;
    }else {
        frame.origin.x = CGRectGetMaxX(self.avatarImage.frame) + CONTENT_AVATAR_MARGIN;
    }
    
    self.gifImageView.frame = frame;

}

- (void)layoutMessageStatusViews:(BOOL)isFromMe {
    if (_indicatorView || _statusButton) {
        self.indicatorView.center = CGPointMake(CGRectGetMinX(self.gifImageView.frame) - CGRectGetWidth(self.indicatorView.frame)/2 - 16, CGRectGetMidY(self.gifImageView.frame) + ACTIVITY_VIEW_Y_OFFSET);
        self.statusButton.center = CGPointMake(CGRectGetMinX(self.gifImageView.frame) - CGRectGetWidth(self.statusButton.frame)/2 - 16, CGRectGetMidY(self.gifImageView.frame) + ACTIVITY_VIEW_Y_OFFSET);
    }

}


+ (CGFloat)heightForModel:(LLMessageModel *)model {
    return GIF_IMAGE_SIZE + CONTENT_SUPER_BOTTOM;
}

- (void)willDisplayCell {
    if (!self.gifImageView.gifData) {
        NSData *gifData = [[LLChatManager sharedManager] gifDataForGIFMessageModel:self.messageModel];
        
        self.gifImageView.gifData = gifData;
        self.gifImageView.startShowIndex = self.messageModel.gifShowIndex;
        [self.gifImageView startGIFAnimating];
    }
  
}

- (void)didEndDisplayingCell {
    self.gifImageView.gifData = nil;
}

- (void)willBeginScrolling {
    [super willBeginScrolling];
    self.messageModel.gifShowIndex = self.gifImageView.currentShowIndex;
}

- (void)didEndScrolling {
    
}


#pragma mark - 手势

- (UIView *)hitTestForTapGestureRecognizer:(CGPoint)point {
    return nil;
}

- (UIView *)hitTestForlongPressedGestureRecognizer:(CGPoint)point {
    CGPoint pointInView = [self.contentView convertPoint:point toView:self.gifImageView];
    
    if ([self.gifImageView pointInside:pointInView withEvent:nil]) {
        return self.gifImageView;
    }
    
    return nil;
}


- (void)contentEventLongPressedBeganInView:(UIView *)view {
    [self showMenuControllerInRect:self.gifImageView.bounds inView:self.gifImageView];
}


#pragma mark - 菜单

- (void)addToEmojiAction:(id)sender {
    
}

- (void)forwardAction:(id)sender {
    
}

- (void)showAlbumAction:(id)sender {
    
}


@end
