//
//  LLMessageTextCell.m
//  LLWeChat
//
//  Created by GYJZH on 7/21/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageTextCell.h"
#import "LLUtils.h"
#import "LLConfig.h"
#import "UIKit+LLExt.h"
#import "LLLabel.h"


//Label的约束
#define LABEL_BUBBLE_LEFT 12
#define LABEL_BUBBLE_RIGHT 12
#define LABEL_BUBBLE_TOP 14
#define LABEL_BUBBLE_BOTTOM 12

#define CONTENT_MIN_WIDTH  53
#define CONTENT_MIN_HEIGHT 41

static CGFloat preferredMaxTextWidth;
static NSArray<NSString *> *menuActionNames;
static NSArray<NSString *> *menuNames;


@interface LLMessageTextCell ()

@property (nonatomic) LLLabel *contentLabel;

@end



@implementation LLMessageTextCell

+ (void)initialize {
    if (self == [LLMessageTextCell class]) {
        preferredMaxTextWidth = SCREEN_WIDTH * CHAT_BUBBLE_MAX_WIDTH_FACTOR;
        menuNames = @[@"复制", @"转发", @"收藏", @"翻译", @"删除", @"更多..."];
        menuActionNames = @[@"copyAction:", @"transforAction:", @"favoriteAction:", @"translateAction:",@"deleteAction:", @"moreAction:"];
    }
}


- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentLabel = [[LLLabel alloc] init];
        self.contentLabel.font = [self.class font];
        self.contentLabel.textAlignment = NSTextAlignmentLeft;
        self.contentLabel.backgroundColor = [UIColor clearColor];
        self.contentLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        WEAK_SELF;
        self.contentLabel.longPressAction = ^(LLLabelRichTextData *data,UIGestureRecognizerState state) {
            if (!data)return;
//            if (data.type == kLLLabelRichTextTypeURL) {
//                if (state == UIGestureRecognizerStateBegan) {
//                    [weakSelf.delegate cellLinkDidLongPressed:weakSelf linkURL:data.url];
//                }
//            }else {
                if (state == UIGestureRecognizerStateBegan) {
                    [weakSelf contentEventLongPressedBeganInView:nil];
                }else if (state == UIGestureRecognizerStateEnded) {
                    [weakSelf contentEventLongPressedEndedInView:nil];
                }
//            }
  
        };
        self.contentLabel.tapAction = ^(LLLabelRichTextData *data) {
            if (!data)return;
            if (data.type == kLLLabelRichTextTypeURL) {
                [weakSelf.delegate cellLinkDidTapped:weakSelf linkURL:data.url];
            }else if (data.type == kLLLabelRichTextTypePhoneNumber) {
                [weakSelf.delegate cellPhoneNumberDidTapped:weakSelf phoneNumberString:data.phoneNumber];
            }
        };
        
        [self.contentView addSubview:self.contentLabel];

        self.menuActionNames = [menuActionNames mutableCopy];
        self.menuNames = [menuNames mutableCopy];
        
    }
    
    return self;
}

- (void)setMessageModel:(LLMessageModel *)messageModel {
    self.contentLabel.attributedText = messageModel.richTestString;
    [super setMessageModel:messageModel];
}


- (void)layoutMessageContentViews:(BOOL)isFromMe {
    CGSize textSize = [self.class sizeForLabel:self.messageModel.richTestString];
    CGSize size = textSize;
    size.width += LABEL_BUBBLE_LEFT + LABEL_BUBBLE_RIGHT;
    size.height += LABEL_BUBBLE_TOP + LABEL_BUBBLE_BOTTOM;
    if (size.width < CONTENT_MIN_WIDTH) {
        size.width = CONTENT_MIN_WIDTH;
    }else {
        size.width = ceil(size.width);
    }
    
    if (size.height < CONTENT_MIN_HEIGHT) {
        size.height = CONTENT_MIN_HEIGHT;
    }else {
        size.height = ceil(size.height);
    }

    if (isFromMe) {
        CGRect frame = CGRectMake(0,
                  CONTENT_SUPER_TOP - BUBBLE_TOP_BLANK,
                  size.width + BUBBLE_LEFT_BLANK + BUBBLE_RIGHT_BLANK,
                  size.height + BUBBLE_TOP_BLANK + BUBBLE_BOTTOM_BLANK);
        frame.origin.x = CGRectGetMinX(self.avatarImage.frame) - CGRectGetWidth(frame) - CONTENT_AVATAR_MARGIN;
        self.bubbleImage.frame = frame;

        self.contentLabel.frame = CGRectMake(CGRectGetMinX(self.bubbleImage.frame) + LABEL_BUBBLE_RIGHT + BUBBLE_LEFT_BLANK,
                    CGRectGetMinY(self.bubbleImage.frame) + LABEL_BUBBLE_TOP + BUBBLE_TOP_BLANK,
                                             textSize.width, textSize.height);

    }else {
        self.bubbleImage.frame = CGRectMake(CONTENT_AVATAR_MARGIN + CGRectGetMaxX(self.avatarImage.frame),
                    CONTENT_SUPER_TOP - BUBBLE_TOP_BLANK, size.width + BUBBLE_LEFT_BLANK + BUBBLE_RIGHT_BLANK, size.height +
                    BUBBLE_TOP_BLANK + BUBBLE_BOTTOM_BLANK);
        
        self.contentLabel.frame = CGRectMake(CGRectGetMinX(self.bubbleImage.frame) + LABEL_BUBBLE_LEFT + BUBBLE_LEFT_BLANK,
                    CGRectGetMinY(self.bubbleImage.frame) + LABEL_BUBBLE_TOP + BUBBLE_TOP_BLANK,
                                             textSize.width, textSize.height);
    }
    
}

+ (CGSize)sizeForLabel:(NSAttributedString *)text {
    CGRect frame = [text boundingRectWithSize:CGSizeMake(preferredMaxTextWidth, MAXFLOAT) options:(NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading) context:nil];
    
    return frame.size;
}

+ (UIFont *)font {
    static UIFont *_font;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _font = [UIFont systemFontOfSize:LL_MESSAGE_FONT_SIZE];
    });
    return _font;
}


+ (CGFloat)heightForModel:(LLMessageModel *)model {
    CGSize size = [self sizeForLabel:model.richTestString];
    
    CGFloat bubbleHeight = size.height + LABEL_BUBBLE_TOP + LABEL_BUBBLE_BOTTOM;
    if (bubbleHeight < CONTENT_MIN_HEIGHT)
        bubbleHeight = CONTENT_MIN_HEIGHT;
    else
        bubbleHeight = ceil(bubbleHeight);
    
    return bubbleHeight + CONTENT_SUPER_BOTTOM;
}

#pragma mark - 手势

- (UIView *)hitTestForTapGestureRecognizer:(CGPoint)point {
    return nil;
}

- (UIView *)hitTestForlongPressedGestureRecognizer:(CGPoint)point {
    CGPoint bubblePoint = [self.contentView convertPoint:point toView:self.bubbleImage];
    
    if (CGRectContainsPoint(self.bubbleImage.bounds, bubblePoint) && ![self.contentLabel shouldReceiveTouchAtPoint:[self.contentView convertPoint:point toView:self.contentLabel]]) {
        return self.bubbleImage;
    }
    return nil;
}

- (void)contentEventLongPressedBeganInView:(UIView *)view {
    self.bubbleImage.highlighted = YES;
    [self showMenuControllerInRect:self.bubbleImage.bounds inView:self.bubbleImage];
}


- (void)contentEventTouchCancelled {
    self.bubbleImage.highlighted = NO;
    [self.contentLabel cancelTouch:nil];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || !self.userInteractionEnabled || self.alpha <= 0.01)
        return nil;
    
    if (LLMessageCell_isEditing) {
        if ([self.contentView pointInside:[self convertPoint:point toView:self.contentView] withEvent:event]) {
            return self.contentView;
        }
    }else {
        if ([self.contentLabel pointInside:[self convertPoint:point toView:self.contentLabel] withEvent:event]) {
            return self.contentLabel;
        }else if ([self.contentView pointInside:[self convertPoint:point toView:self.contentView] withEvent:event]) {
            return self.contentView;
        }
    }

    return nil;
}

#pragma mark - 弹出菜单

- (void)copyAction:(id)sender {
    [LLUtils copyToPasteboard:self.messageModel.messageBody_Text];
}

- (void)transforAction:(id)sender {
    
}

- (void)favoriteAction:(id)sender {
    
}

- (void)translateAction:(id)sender {
    
}




@end
