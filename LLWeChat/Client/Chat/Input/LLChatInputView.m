//
//  LLChatInputView.m
//  LLWeChat
//
//  Created by GYJZH on 7/25/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLChatInputView.h"
#import "LLShareInputView.h"
#import "LLEmotionInputView.h"
#import "LLConfig.h"
#import "LLUtils.h"
#import "UIKit+LLExt.h"
#import "LLEmotionModel.h"


#define SET_KEYBOARD_TYPE(_keyboardType) \
    keyboardShowHideInfo.toKeyboardType = _keyboardType; \
    self.keyboardType = _keyboardType

#define TEXT_VIEW_MAX_LINE 5

#define MIN_TEXT_HEIGHT 36

#define Regular_EdgeInset UIEdgeInsetsMake(9, 6, 0, 6)
//暂不支持自由设置，
//#define Compact_EdgeInset UIEdgeInsetsMake(4, 6, 4, 6)

@interface LLChatInputView () <UITextViewDelegate, NSLayoutManagerDelegate, ILLEmotionInputDelegate, LLChatShareDelegate>

@property (weak, nonatomic) IBOutlet UIButton *chatVoiceBtn;

@property (weak, nonatomic) IBOutlet UIButton *chatEmotionBtn;

@property (weak, nonatomic) IBOutlet UIButton *chatShareBtn;

@property (weak, nonatomic) IBOutlet UIButton *chatRecordBtn;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatTextViewHeightConstraint;

@property (nonatomic) LLShareInputView *shareInputView;

@property (nonatomic) BOOL lock;

@end


@implementation LLChatInputView {
    LLKeyboardShowHideInfo keyboardShowHideInfo;
    CGFloat lineHeight;
    UIView *viewview;
    BOOL changeLock;
    BOOL allowScrollAnimation;
    NSDictionary *attributes;
    CGFloat lineSpacing;
    
    CFTimeInterval touchDownTime;
    dispatch_block_t block;
    UIEvent *recordEvent;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _keyboardType = kLLKeyboardTypeNone;
    touchDownTime = 0;

    //在上面加一条线
    CALayer *line = [LLUtils lineWithLength:SCREEN_WIDTH atPoint:CGPointZero];
    [self.layer addSublayer:line];
    
    self.chatInputTextView.layer.cornerRadius = 5;
    self.chatInputTextView.layer.borderWidth = 1;
    self.chatInputTextView.layer.borderColor = [UIColor colorWithHexRGB:@"#DADADA"].CGColor;
    self.chatInputTextView.textContainer.lineFragmentPadding = 0;
    self.chatInputTextView.textContainerInset = Regular_EdgeInset;
    self.chatInputTextView.delegate = self;
    self.chatInputTextView.layoutManager.delegate = self;
    [self.chatInputTextView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:nil];
    [self.chatInputTextView addObserver:self forKeyPath:@"text" options:kNilOptions context:nil];
    
    lineSpacing = 1;
    lineHeight = self.chatInputTextView.font.lineHeight + lineSpacing;
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    paragraphStyle.lineSpacing = lineSpacing;

    
    attributes = @{
                   NSFontAttributeName:self.chatInputTextView.font,
                   NSParagraphStyleAttributeName: paragraphStyle
                   };
    
    self.shareInputView = [[LLShareInputView alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.frame), SCREEN_WIDTH, CHAT_KEYBOARD_PANEL_HEIGHT)];
    self.shareInputView.delegate = self;
    [self.superview addSubview:self.shareInputView];
    
    [self.superview addSubview:[LLEmotionInputView sharedInstance]];
    [[LLEmotionInputView sharedInstance] setNeedsUpdateConstraints];
    [LLEmotionInputView sharedInstance].delegate = self;
    
    _chatRecordBtn.backgroundColor = [UIColor clearColor];
    [self setRecordButtonStyleIsRecording:NO];
    _chatRecordBtn.layer.borderColor =  UIColorHexRGB(@"#C2C3C7").CGColor;
    _chatRecordBtn.layer.borderWidth = 0.5;
    _chatRecordBtn.layer.cornerRadius = 5.0;
    _chatRecordBtn.layer.masksToBounds = true;

    changeLock = NO;
    allowScrollAnimation = NO;
}

- (void)updateConstraints {
    NSLayoutConstraint *constraint1 = [NSLayoutConstraint
                constraintWithItem:[LLEmotionInputView sharedInstance]
                         attribute:NSLayoutAttributeTop
                         relatedBy:NSLayoutRelationEqual
                            toItem:self
                         attribute:NSLayoutAttributeBottom
                        multiplier:1
                          constant:0];
    
    
    NSLayoutConstraint *constraint2 = [NSLayoutConstraint
                constraintWithItem:self.shareInputView
                         attribute:NSLayoutAttributeTop
                         relatedBy:NSLayoutRelationEqual
                            toItem:self
                         attribute:NSLayoutAttributeBottom
                        multiplier:1
                          constant:0];
    
    [NSLayoutConstraint activateConstraints:@[constraint1, constraint2]];
    
    [super updateConstraints];
}

#pragma mark - 切换键盘

- (IBAction)voiceButtonPressed:(UIButton *)btn {
    switch (self.keyboardType) {
        case kLLKeyboardTypeRecord:
            SET_KEYBOARD_TYPE(kLLKeyboardTypeDefault);
            [self.chatInputTextView becomeFirstResponder];
            break;
        case kLLKeyboardTypeDefault:
            SET_KEYBOARD_TYPE(kLLKeyboardTypeRecord);
            [self.chatInputTextView resignFirstResponder];
            break;
        case kLLKeyboardTypePanel:
        case kLLKeyboardTypeEmotion:
        case kLLKeyboardTypeNone:
        {
            SET_KEYBOARD_TYPE(kLLKeyboardTypeRecord);
            keyboardShowHideInfo.keyboardHeight = 0;
            keyboardShowHideInfo.duration = 0.25;
            [self.delegate updateKeyboard:keyboardShowHideInfo];
        }
            
    }
}


- (IBAction)emotionButtonPressed:(UIButton *)sender {

    switch (self.keyboardType) {
        case kLLKeyboardTypeEmotion:
            SET_KEYBOARD_TYPE(kLLKeyboardTypeDefault);
            [self.chatInputTextView becomeFirstResponder];
            break;
        case kLLKeyboardTypeDefault:
            SET_KEYBOARD_TYPE(kLLKeyboardTypeEmotion);
            keyboardShowHideInfo.keyboardHeight = CHAT_KEYBOARD_PANEL_HEIGHT;
            [self.chatInputTextView resignFirstResponder];
            break;
        case kLLKeyboardTypePanel:
            self.keyboardType = kLLKeyboardTypeEmotion;
            [self showEmotionKeyboard:YES];
            break;
        case kLLKeyboardTypeNone:
        case kLLKeyboardTypeRecord:
        {
            keyboardShowHideInfo.keyboardHeight = CHAT_KEYBOARD_PANEL_HEIGHT;
            SET_KEYBOARD_TYPE(kLLKeyboardTypeEmotion);
            keyboardShowHideInfo.duration = 0.25;
            [self.delegate updateKeyboard:keyboardShowHideInfo];
            [self showEmotionKeyboard:NO];
        }
            
    }
 
}

- (IBAction)shareButtonPressed:(id)sender {
    switch (self.keyboardType) {
        case kLLKeyboardTypePanel:
            SET_KEYBOARD_TYPE(kLLKeyboardTypeDefault);
            [self.chatInputTextView becomeFirstResponder];
            break;
        case kLLKeyboardTypeDefault:
            SET_KEYBOARD_TYPE(kLLKeyboardTypePanel);
            keyboardShowHideInfo.keyboardHeight = CHAT_KEYBOARD_PANEL_HEIGHT;
            [self.chatInputTextView resignFirstResponder];
            break;
        case kLLKeyboardTypeEmotion:
            self.keyboardType = kLLKeyboardTypePanel;
            [self showPanelKeyboard:YES];
            break;
        case kLLKeyboardTypeNone:
        case kLLKeyboardTypeRecord:
        {
            keyboardShowHideInfo.keyboardHeight = CHAT_KEYBOARD_PANEL_HEIGHT;
            SET_KEYBOARD_TYPE(kLLKeyboardTypePanel);
            keyboardShowHideInfo.duration = 0.25;
            [self.delegate updateKeyboard:keyboardShowHideInfo];
            [self showPanelKeyboard:NO];
        }
            
    }
    
}


- (void)showEmotionKeyboard:(BOOL)animated {
    [LLEmotionInputView sharedInstance].hidden = NO;
    
    if (animated) {
        [LLEmotionInputView sharedInstance].top_LL = CGRectGetMaxY(self.frame) + CHAT_KEYBOARD_PANEL_HEIGHT;
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             [LLEmotionInputView sharedInstance].top_LL = CGRectGetMaxY(self.frame);
                         } completion:nil];
    }else {
        [LLEmotionInputView sharedInstance].top_LL = CGRectGetMaxY(self.frame);
    }
    
}

- (void)showPanelKeyboard:(BOOL)animated {
    [LLEmotionInputView sharedInstance].hidden = YES;
    
    if (animated) {
        self.shareInputView.top_LL = CGRectGetMaxY(self.frame) + CHAT_KEYBOARD_PANEL_HEIGHT;
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                             self.shareInputView.top_LL = CGRectGetMaxY(self.frame);
                         } completion:nil];
    
    }else {
        self.shareInputView.top_LL = CGRectGetMaxY(self.frame);
    }
}


//只处理本类的UI显示,不负责键盘高度调整
- (void)setKeyboardType:(LLKeyboardType)keyboardType {
    if (_keyboardType == keyboardType)return;
    _keyboardType = keyboardType;
    
    self.chatRecordBtn.hidden = keyboardType != kLLKeyboardTypeRecord;
    self.chatInputTextView.hidden = !self.chatRecordBtn.hidden;
    [LLEmotionInputView sharedInstance].hidden = keyboardType != kLLKeyboardTypeEmotion;
    
    if (keyboardType == kLLKeyboardTypeEmotion) {
        [self setButton:self.chatEmotionBtn image:@"tool_keyboard_1" highlightedImage:@"tool_keyboard_2"];
    }else {
        [self setButton:self.chatEmotionBtn image:@"tool_emotion_1" highlightedImage:@"tool_emotion_2"];
    }
    
    if (keyboardType == kLLKeyboardTypeRecord) {
        [self setButton:self.chatVoiceBtn image:@"tool_keyboard_1" highlightedImage:@"tool_keyboard_2"];
    }else {
        [self setButton:self.chatVoiceBtn image:@"tool_voice_1" highlightedImage:@"tool_voice_2"];
    }
    
}

- (void)setButton:(UIButton *)button image:(NSString *)image highlightedImage:(NSString *)highlightedImage {
    [button setImage:[UIImage imageNamed:image] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:highlightedImage] forState:UIControlStateHighlighted];
}

#pragma mark - 注册键盘


- (void)registerKeyboardNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardDidHideNotification object:nil];
}

- (void)unregisterKeyboardNotification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)keyboardFrameChange:(NSNotification *)notify {
    __weak typeof(self) weakSelf = self;
    self.lock = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDictionary *userinfo = notify.userInfo;
        if (!userinfo) {
            self.lock = NO;
            return;
        }else if ([notify.name isEqualToString:UIKeyboardDidShowNotification] ||
                  [notify.name isEqualToString:UIKeyboardDidHideNotification]) {
            self.lock = NO;
            return;
        }
        
        if ([notify.name isEqualToString:UIKeyboardWillHideNotification] &&
            self.keyboardType == kLLKeyboardTypeDefault) {
            keyboardShowHideInfo.toKeyboardType = kLLKeyboardTypeNone;
        }else if ([notify.name isEqualToString:UIKeyboardWillShowNotification]) {
            keyboardShowHideInfo.toKeyboardType = kLLKeyboardTypeDefault;
        }
        [weakSelf handleKeyboardFrameChange:notify];
    });
    
    return;
}

- (void)handleKeyboardFrameChange:(NSNotification *)notify {
    NSDictionary *userinfo = notify.userInfo;
    
    CGFloat duration = [userinfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve _curve = [userinfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    keyboardShowHideInfo.curve = animationOptionsWithCurve(_curve);
    
    if (keyboardShowHideInfo.toKeyboardType == kLLKeyboardTypeDefault) {
        CGRect toFrame = [(NSValue *)userinfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGFloat keyboardHeight = CGRectGetHeight(toFrame);
        keyboardShowHideInfo.keyboardHeight = keyboardHeight;
        SET_KEYBOARD_TYPE(kLLKeyboardTypeDefault);
        keyboardShowHideInfo.duration = duration;
    }else {
        if (keyboardShowHideInfo.toKeyboardType == kLLKeyboardTypeEmotion) {
            keyboardShowHideInfo.duration = duration * 2;
            
            [LLEmotionInputView sharedInstance].top_LL = CGRectGetMaxY(self.frame) + CHAT_KEYBOARD_PANEL_HEIGHT;
            [UIView animateWithDuration:duration * 2
                                  delay:0
                                options:UIViewAnimationOptionBeginFromCurrentState |
                                        UIViewAnimationOptionCurveEaseInOut
                             animations:^{
                                 [LLEmotionInputView sharedInstance].top_LL = CGRectGetMaxY(self.frame);
                             } completion:nil];
        }else if (keyboardShowHideInfo.toKeyboardType == kLLKeyboardTypePanel) {
             keyboardShowHideInfo.duration = duration * 2;
        }else if (keyboardShowHideInfo.toKeyboardType == kLLKeyboardTypeRecord) {
            keyboardShowHideInfo.keyboardHeight = 0;
            keyboardShowHideInfo.duration = duration;
        }else
            self.keyboardType = kLLKeyboardTypeNone;
    }
    
    
    [self.delegate updateKeyboard:keyboardShowHideInfo];

}


- (void)dismissKeyboard {
    if (self.keyboardType == kLLKeyboardTypeRecord ||
        self.keyboardType == kLLKeyboardTypeNone)
        return;
    SET_KEYBOARD_TYPE(kLLKeyboardTypeNone);
    
    if (self.chatInputTextView.isFirstResponder) {
        [self.chatInputTextView resignFirstResponder];
    }else {
        keyboardShowHideInfo.duration = 0.25;
        [self.delegate updateKeyboard:keyboardShowHideInfo];
    }

}


#pragma mark - 处理文字输入

- (CGSize)calSize:(NSString *)text {
    static CGSize calSize;
    static CGFloat textViewWidth = 0;
    if (textViewWidth == 0) {
        textViewWidth = self.chatInputTextView.frame.size.width - self.chatInputTextView.textContainerInset.left - self.chatInputTextView.textContainerInset.right - 2 * self.chatInputTextView.textContainer.lineFragmentPadding;

        calSize = CGSizeMake(textViewWidth, MAXFLOAT);
    }

    CGRect rect = [text boundingRectWithSize:calSize
                                     options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                                  attributes:attributes
                                     context:nil];

    return rect.size;
}

- (void)textViewDidChange:(UITextView *)textView {
    [[LLEmotionInputView sharedInstance] sendEnabled:textView.text && textView.text.length > 0];
    
    keyboardShowHideInfo.curve = UIViewAnimationOptionCurveEaseInOut;
    keyboardShowHideInfo.duration = 0.25;
    keyboardShowHideInfo.toKeyboardType = self.keyboardType;
    
    CGSize size = [self calSize: self.chatInputTextView.text];
    [self.chatInputTextView.textStorage addAttributes:attributes range:NSMakeRange(0, self.chatInputTextView.text.length)];
    
    //单行文本
    if (size.height < lineHeight + FLT_EPSILON) {
        self.chatInputTextView.scrollEnabled = YES;
        self.chatInputTextView.textContainerInset = Regular_EdgeInset;
        size.height = MIN_TEXT_HEIGHT;
        allowScrollAnimation = YES;
        [self.chatInputTextView setContentOffset:CGPointZero animated:NO];
        allowScrollAnimation = NO;
        
        if (self.chatTextViewHeightConstraint.constant == size.height)
            return;

        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut |
                                    UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.chatTextViewHeightConstraint.constant = size.height;
                             [self.superview layoutIfNeeded];
                         }
                         completion:nil
         ];
        [self.delegate updateKeyboard:keyboardShowHideInfo];
    }else{
        if (size.height >= (TEXT_VIEW_MAX_LINE * lineHeight - lineSpacing - FLT_EPSILON)) {
            size.height = TEXT_VIEW_MAX_LINE * lineHeight - lineSpacing;
            
            self.chatInputTextView.scrollEnabled = YES;
            UIEdgeInsets inset = UIEdgeInsetsMake(lineSpacing, 6, 3, 6);
            inset.bottom += (ceil(size.height) - size.height )/2;
            inset.top += (ceil(size.height) - size.height )/2;
            self.chatInputTextView.textContainerInset = inset;
            
            size.height = size.height + self.chatInputTextView.textContainerInset.top
            + self.chatInputTextView.textContainerInset.bottom;

            
        }else if (size.height < (TEXT_VIEW_MAX_LINE -1) * lineHeight - lineSpacing + FLT_EPSILON) {
            self.chatInputTextView.scrollEnabled = NO;
            UIEdgeInsets inset = UIEdgeInsetsMake(3, 6, 5, 6);
            self.chatInputTextView.textContainerInset = inset;
        
            size.height = ceil(size.height) + self.chatInputTextView.textContainerInset.top
            + self.chatInputTextView.textContainerInset.bottom;
            
        }
        
        [self performSelector:@selector(adjustTextViewPosition) withObject:nil afterDelay:0.1];
        
        if (self.chatTextViewHeightConstraint.constant == size.height)
            return;
        
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionCurveEaseInOut |
                                    UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             self.chatTextViewHeightConstraint.constant = size.height;
                             [self.superview layoutIfNeeded];
                         }
                         completion: nil
         ];
        [self.delegate updateKeyboard:keyboardShowHideInfo];
    }
}


- (void)adjustTextViewPosition {
    if (!self.chatInputTextView.selectedTextRange) return;
    
    CGFloat _gap = self.chatInputTextView.contentSize.height - CGRectGetHeight(self.chatInputTextView.frame);
    
    if (_gap >= FLT_EPSILON) {
        CGRect rect = [self.chatInputTextView caretRectForPosition:self.chatInputTextView.selectedTextRange.end];
        BOOL isLastLine = CGRectGetMaxY(rect) + lineHeight > self.chatInputTextView.contentSize.height;
        
        rect.origin.y -= (self.chatInputTextView.textContainerInset.top -1);
        rect.size.height += self.chatInputTextView.textContainerInset.top -1 +
        (isLastLine ? (self.chatInputTextView.textContainerInset.bottom - 0.5) :(lineSpacing - 0.5));
        

        allowScrollAnimation = YES;
        [UIView animateWithDuration:0.25
                              delay:0
                            options:UIViewAnimationOptionBeginFromCurrentState |
                                    UIViewAnimationOptionCurveEaseInOut
                         animations:^{
                            [self.chatInputTextView scrollRectToVisible:rect animated:NO];
                             if (_gap < self.chatInputTextView.contentOffset.y) {
                                 [self.chatInputTextView setContentOffset:CGPointMake(0, _gap) animated:NO];
                             }
                             
        }
                         completion:^(BOOL finished) {
                allowScrollAnimation = NO;
        }];

    }else {
        allowScrollAnimation = YES;
        [self.chatInputTextView setContentOffset:CGPointZero animated:NO];
        allowScrollAnimation = NO;
    }
    
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"contentOffset"]) {
        if (self.chatInputTextView.dragging || self.chatInputTextView.isDecelerating || allowScrollAnimation) {
            
        }else {
            if (changeLock)return;
            changeLock = YES;
            self.chatInputTextView.contentOffset = [change[NSKeyValueChangeOldKey] CGPointValue];
            changeLock = NO;
        }
    }else if ([keyPath isEqualToString:@"text"]) {
        [self textViewDidChange:self.chatInputTextView];
    }
    
}

- (void)dealloc {
    [self.chatInputTextView removeObserver:self forKeyPath:@"contentOffset"];
    [self.chatInputTextView removeObserver:self forKeyPath:@"text"];
}


#pragma mark - 发送文字消息

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]){
        [self sendTextMessage:textView.text];
        return NO;
    }
    
    return YES;
}


- (void)sendTextMessage:(NSString *)text {
    if (text.length > 0) {
        NSString * str = [text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (str.length == 0) {
            [LLUtils showMessageAlertWithTitle:nil message:@"不能发送空白消息"];
        }else {
            self.chatInputTextView.text = nil;
            [self.delegate sendTextMessage:text];
        }
    }
    
}


#pragma mark - 输入表情

- (void)emojiCellDidSelected:(LLEmotionModel *)model {
    self.chatInputTextView.text = [NSString stringWithFormat:@"%@[%@]", self.chatInputTextView.text, model.text];
    
}

- (void)gifCellDidSelected:(LLEmotionModel *)model {
    [self.delegate sendGifMessage:model];
}

- (void)sendCellDidSelected {
    [self sendTextMessage:self.chatInputTextView.text];
}

- (void)deleteCellDidSelected {
    NSString *text = self.chatInputTextView.text;
    if (text.length == 0) return;
    
    NSRange range = [[LLEmotionModelManager sharedManager] rangeOfEmojiAtEndOfString:text];
    if (range.location == NSNotFound) {
        self.chatInputTextView.text = [text substringToIndex:text.length-1];
    }else {
        self.chatInputTextView.text = [text substringToIndex:range.location];
    }

}


- (void)cellWithTagDidTapped:(NSInteger)tag {
    [self.delegate cellWithTagDidTapped:tag];
}

#pragma mark - 录音

- (IBAction)recordButtonTouchDown:(id)sender {
    touchDownTime = CACurrentMediaTime();
    [self recordActionStart];
    
    if ([self.delegate respondsToSelector:@selector(voiceRecordingShouldStart)]) {
        WEAK_SELF;
        block = dispatch_block_create(0, ^{
            [weakSelf.delegate voiceRecordingShouldStart];
        });
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
    }
}

- (IBAction)recordButtonTouchUpinside:(id)sender {
    CFTimeInterval currentTime = CACurrentMediaTime();
    if (currentTime - touchDownTime < MIN_RECORD_TIME_REQUIRED + 0.25) {
        self.chatRecordBtn.enabled = NO;
        if (!dispatch_block_testcancel(block))
            dispatch_block_cancel(block);
        block = nil;
        
        if ([self.delegate respondsToSelector:@selector(voiceRecordingTooShort)]) {
            [self.delegate voiceRecordingTooShort];
        }
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.chatRecordBtn.enabled = YES;
            [self recordActionEnd];
        });
        
    }else {
        [self recordActionEnd];
        if ([self.delegate respondsToSelector:@selector(voicRecordingShouldFinish)]) {
            [self.delegate voicRecordingShouldFinish];
        }
    }

}

- (IBAction)recordButtonTouchUpoutside:(id)sender {
    [self recordActionEnd];
    
    if (!dispatch_block_testcancel(block))
        dispatch_block_cancel(block);
    block = nil;
    
    if ([self.delegate respondsToSelector:@selector(voiceRecordingShouldCancel)]) {
        [self.delegate voiceRecordingShouldCancel];
    }

}



- (void)cancelRecordButtonTouchEvent {
    [self.chatRecordBtn cancelTrackingWithEvent:recordEvent];
    [self recordActionEnd];
}

- (IBAction)recordButtonDragEnter:(id)sender {
    if ([self.delegate respondsToSelector:@selector(voiceRecordingDidDraginside)]) {
        [self.delegate voiceRecordingDidDraginside];
    }
}

- (IBAction)recordButtonDragExit:(id)sender {
    if ([self.delegate respondsToSelector:@selector(voiceRecordingDidDragoutside)]) {
        [self.delegate voiceRecordingDidDragoutside];
    }
}


- (void)recordActionStart {
    [self setRecordButtonStyleIsRecording:YES];
}

- (void)recordActionEnd {
    [self setRecordButtonStyleIsRecording:NO];
    recordEvent = nil;
}

- (void)setRecordButtonStyleIsRecording:(BOOL)isRecording {
    if (isRecording) {
        _chatRecordBtn.backgroundColor = UIColorHexRGB(@"#C6C7CB");
        [_chatRecordBtn setTitle:@"松开 结束" forState:UIControlStateNormal];
    }else {
        _chatRecordBtn.backgroundColor = UIColorHexRGB(@"#F3F4F8");
        [_chatRecordBtn setTitle:@"按住 说话" forState:UIControlStateNormal];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    if (view == self.chatRecordBtn) {
        recordEvent = event;
    }
    
    return view;
}


@end



