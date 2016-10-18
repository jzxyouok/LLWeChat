//
//  LLLabel.h
//  LLWeChat
//
//  Created by GYJZH on 8/10/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LLLabelRichTextData;

typedef void (^LLLabelTapAction)(LLLabelRichTextData *data);

typedef void (^LLLabelLongPressAction)(LLLabelRichTextData *data, UIGestureRecognizerState state);


typedef NS_ENUM(NSInteger, LLLabelRichTextType) {
    kLLLabelRichTextTypeURL = 0,
    kLLLabelRichTextTypePhoneNumber
};


@interface LLLabelRichTextData : NSObject

@property (nonatomic) NSRange range;

@property (nonatomic) LLLabelRichTextType type;

@property (nonatomic) NSURL *url;

@property (nonatomic, copy) NSString *phoneNumber;

- (instancetype)initWithType:(LLLabelRichTextType)type;

@end


@interface LLLabel : UITextView

@property (nonatomic) NSMutableArray<LLLabelRichTextData *> *richTextDatas;

@property (nonatomic, copy) LLLabelTapAction tapAction;

@property (nonatomic, copy) LLLabelLongPressAction longPressAction;

- (BOOL)touchShouldBegin:(UITouch *)touch;

- (BOOL)shouldReceiveTouchAtPoint:(CGPoint)point;

- (void)cancelTouch:(UITouch *)touch;

@end
