//
//  LLBaseChatViewCell.m
//  LLWeChat
//
//  Created by GYJZH on 8/9/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageBaseCell.h"
#import "LLUtils.h"
#import "UIKit+LLExt.h"
#import "LLColors.h"
#import "LLTextView.h"

#define MENU_FRAME_HEIGHT 50

UIImage *ReceiverTextNodeBkg;
UIImage *ReceiverTextNodeBkgHL;
UIImage *SenderTextNodeBkg;
UIImage *SenderTextNodeBkgHL;

UIImage *ReceiverImageNodeBorder;
UIImage *ReceiverImageNodeMask;
UIImage *SenderImageNodeBorder;
UIImage *SenderImageNodeMask;

BOOL LLMessageCell_isEditing = NO;

@interface LLMessageBaseCell () <UIGestureRecognizerDelegate>

@property (nonatomic) NSMutableArray <UIMenuItem *> *menuItems;

@end


@implementation LLMessageBaseCell {
    UIView *tapView;
    UIView *longPressedView;
    
    UITapGestureRecognizer *tap;
    UILongPressGestureRecognizer *longPressGR;
}

@synthesize statusButton = _statusButton;
@synthesize indicatorView = _indicatorView;
@synthesize messageModel = _messageModel;
@synthesize selectControl = _selectControl;

+ (void)initialize {
    if (!ReceiverTextNodeBkg) {
        ReceiverTextNodeBkg = [[UIImage imageNamed:@"ReceiverTextNodeBkg"] resizableImage];
        ReceiverTextNodeBkgHL = [[UIImage imageNamed:@"ReceiverTextNodeBkgHL"] resizableImage];
        SenderTextNodeBkg = [[UIImage imageNamed:@"SenderTextNodeBkg"] resizableImage];
        SenderTextNodeBkgHL = [[UIImage imageNamed:@"SenderTextNodeBkgHL"] resizableImage];
        
        ReceiverImageNodeBorder = [[UIImage imageNamed:@"ReceiverImageNodeBorder"] resizableImage];
        ReceiverImageNodeMask = [[UIImage imageNamed:@"ReceiverImageNodeMask"] resizableImage];
        SenderImageNodeBorder = [[UIImage imageNamed:@"SenderImageNodeBorder"] resizableImage];
        SenderImageNodeMask = [[UIImage imageNamed:@"SenderImageNodeMask"] resizableImage];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.contentView.backgroundColor = kLLBackgroundColor_lightGray;
        
        self.avatarImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, AVATAR_WIDTH, AVATAR_HEIGHT)];
        self.avatarImage.contentMode = UIViewContentModeScaleAspectFill;
        [self.contentView addSubview:self.avatarImage];
        
        self.bubbleImage = [[UIImageView alloc] init];
        self.bubbleImage.contentMode = UIViewContentModeScaleToFill;
        [self.contentView addSubview:self.bubbleImage];

        [self setupGestureRecognizer];

    }
    
    return self;
}

- (UIActivityIndicatorView *)indicatorView {
    if (!_indicatorView) {
        _indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [self.contentView addSubview:_indicatorView];
        _indicatorView.hidden = YES;
    }

    return _indicatorView;
}

- (UIButton *)statusButton {
    if (!_statusButton) {
        _statusButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_statusButton setImage:[UIImage imageNamed:@"MessageSendFail"] forState:UIControlStateNormal];
        _statusButton.contentMode = UIViewContentModeScaleAspectFit;
        _statusButton.frame = CGRectMake(0, 0, 24, 24);
        [self.contentView addSubview:_statusButton];
        _statusButton.hidden = YES;
    }

    return _statusButton;
}

- (void)prepareForUse:(BOOL)isFromMe {
    self.avatarImage.image = [UIImage imageNamed:@"user"];

    self.bubbleImage.image = isFromMe ? SenderTextNodeBkg : ReceiverTextNodeBkg;
    self.bubbleImage.highlightedImage = isFromMe ? SenderTextNodeBkgHL : ReceiverTextNodeBkgHL;
    
    _isEditing = LLMessageCell_isEditing;
    if (_isEditing) {
        self.selectControl.frame = CGRectMake(3, (AVATAR_HEIGHT - EDIT_CONTROL_SIZE)/2, EDIT_CONTROL_SIZE, EDIT_CONTROL_SIZE);
    }

    if (isFromMe) {
        self.avatarImage.frame = CGRectMake(SCREEN_WIDTH - CGRectGetWidth(self.avatarImage.frame) - AVATAR_SUPER_LEFT,
                AVATAR_SUPER_TOP,
                AVATAR_WIDTH, AVATAR_HEIGHT);

    }else {
        CGFloat _x = _isEditing ? CGRectGetMaxX(self.selectControl.frame) + 3 : AVATAR_SUPER_LEFT;
        self.avatarImage.frame = CGRectMake(_x, AVATAR_SUPER_TOP, AVATAR_WIDTH, AVATAR_HEIGHT);
    }
}

- (void)setIsSelected:(BOOL)isSelected {
    _isSelected = isSelected;
    self.selectControl.image = [UIImage imageNamed:isSelected ? @"CellBlueSelected": @"CellNotSelected"];
}

- (UIImageView *)selectControl {
    if (!_selectControl) {
        _selectControl = [[UIImageView alloc] initWithFrame:CGRectMake(-EDIT_CONTROL_SIZE, (AVATAR_HEIGHT - EDIT_CONTROL_SIZE)/2, EDIT_CONTROL_SIZE, EDIT_CONTROL_SIZE)];
        _selectControl.contentMode = UIViewContentModeCenter;
        self.isSelected = self.isSelected;
        [self.contentView addSubview:_selectControl];
    }
    
    return _selectControl;
}

- (void)setCellEditingAnimated:(BOOL)animated {
    if (_isEditing == LLMessageCell_isEditing)
        return;
    _isEditing = LLMessageCell_isEditing;
    
    [UIView animateWithDuration:animated ? DEFAULT_DURATION : 0
                     animations:^{
    if (_isEditing) {
        self.selectControl.frame = CGRectMake(3, (AVATAR_HEIGHT - EDIT_CONTROL_SIZE)/2, EDIT_CONTROL_SIZE, EDIT_CONTROL_SIZE);
                                 
        if (!self.messageModel.isFromMe) {
            self.avatarImage.frame = CGRectMake(CGRectGetMaxX(self.selectControl.frame) + 3,AVATAR_SUPER_TOP, AVATAR_WIDTH, AVATAR_HEIGHT);
            [self layoutMessageContentViews:NO];
            [self layoutMessageStatusViews:NO];
        }
     }else {
         _selectControl.frame = CGRectMake(-EDIT_CONTROL_SIZE, (AVATAR_HEIGHT - EDIT_CONTROL_SIZE)/2, EDIT_CONTROL_SIZE, EDIT_CONTROL_SIZE);
         
         if (!self.messageModel.isFromMe) {
             self.avatarImage.frame = CGRectMake(AVATAR_SUPER_LEFT,AVATAR_SUPER_TOP, AVATAR_WIDTH, AVATAR_HEIGHT);
             [self layoutMessageContentViews:NO];
             [self layoutMessageStatusViews:NO];
         }
     }
                     }];
}

- (void)willDisplayCell {
    
}

- (void)didEndDisplayingCell {
    
}

- (void)willBeginScrolling {
    [self contentEventTouchCancelled];
}

- (void)didEndScrolling {

}

//- (void)selectButtonTapped:(UIButton *)btn {
//    self.isSelected = !self.isSelected;
//}

- (void)setMessageModel:(LLMessageModel *)messageModel {
    _messageModel = messageModel;

    if (self.messageModel.isFromMe) {
        [self updateMessageUploadStatus];
    }else {
        [self updateMessageDownloadStatus];
    }

    [self layoutMessageContentViews:messageModel.isFromMe];
    [self layoutMessageStatusViews:messageModel.isFromMe];
}

#pragma mark - 布局 -

+ (void)setEditing:(BOOL)_isEditing {
    LLMessageCell_isEditing = _isEditing;
}

- (void)updateMessageUploadStatus {
    switch (self.messageModel.messageStatus) {
        case kLLMessageStatusDelivering:
        case kLLMessageStatusWaiting:
            self.statusButton.hidden = YES;
            self.indicatorView.hidden = NO;
            [self.indicatorView startAnimating];
            break;
        case kLLMessageStatusSuccessed:
            _statusButton.hidden = YES;
            _indicatorView.hidden = YES;
            [_indicatorView stopAnimating];
            break;
        case kLLMessageStatusFailed:
        case kLLMessageStatusPending:
            self.statusButton.hidden = NO;
            self.indicatorView.hidden = YES;
            [self.indicatorView stopAnimating];
            break;
        default:
            break;
    }
}

- (void)updateMessageDownloadStatus {
    
}

- (void)updateMessageThumbnail {
    
}

- (void)layoutMessageContentViews:(BOOL)isFromMe {

}

- (void)layoutMessageStatusViews:(BOOL)isFromMe {
    if (_indicatorView || _statusButton) {
        _indicatorView.center = CGPointMake(CGRectGetMinX(self.bubbleImage.frame) - CGRectGetWidth(_indicatorView.frame)/2 - ACTIVITY_VIEW_X_OFFSET, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
        
        _statusButton.center = CGPointMake(CGRectGetMinX(self.bubbleImage.frame) - CGRectGetWidth(_statusButton.frame)/2 - ACTIVITY_VIEW_X_OFFSET, CGRectGetMidY(self.bubbleImage.frame) + ACTIVITY_VIEW_Y_OFFSET);
    }

}


+ (UIImage *)bubbleImageForModel:(LLMessageModel *)model {
    return model.isFromMe ? SenderTextNodeBkg : ReceiverTextNodeBkg;
}

+ (CGFloat)heightForModel:(LLMessageModel *)model {
    return 68;
}

- (CGRect)contentFrameInWindow {
    return CGRectZero;
}

#pragma mark - 手势

- (void)setupGestureRecognizer {
    tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(contentTapped:)];
    tap.delaysTouchesBegan = NO;
    tap.delaysTouchesEnded = YES;
    tap.delegate = self;
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.contentView addGestureRecognizer:tap];
    
    longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(contentLongPressed:)];
    longPressGR.delegate = self;
//    longPressGR.delaysTouchesBegan = YES;
//    longPressGR.delaysTouchesEnded = YES;
    longPressGR.minimumPressDuration = 0.6;
    longPressGR.allowableMovement = 1000;
    [self.contentView addGestureRecognizer:longPressGR];
    
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    NSAssert(!self.hidden, @"怎么可能");
    if (self.hidden || !self.userInteractionEnabled || self.alpha <= 0.01)
        return NO;
    BOOL isTapGestureRecognizer = [gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]];
    
    //在编辑模式下点击Cell任意地方都相当于点击了Select Controll
    if (LLMessageCell_isEditing) {
        tapView = _selectControl;
        longPressedView = nil;
        return isTapGestureRecognizer ? YES : NO;
    }

    BOOL isMenuVisible = [UIMenuController sharedMenuController].menuVisible;
    if (isMenuVisible && isTapGestureRecognizer) {
        [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
    }
    
    if (!self.messageModel)
        return isTapGestureRecognizer ? isMenuVisible : NO;

    if (_statusButton && !_statusButton.hidden) {
        CGPoint point = [touch locationInView:_statusButton];
        if ([_statusButton pointInside:point withEvent:nil]) {
            tapView = _statusButton;
            return isTapGestureRecognizer ? YES : NO;
        }
    }

    CGPoint point = [touch locationInView:self.avatarImage];
    if ([self.avatarImage pointInside:point withEvent:nil]) {
        tapView = self.avatarImage;
        return isTapGestureRecognizer ? YES : NO;
    }
    
    
    UIView *hitTestView;
    point = [touch locationInView:self.contentView];
    if (isTapGestureRecognizer) {
        tapView = [self hitTestForTapGestureRecognizer:point];
        hitTestView = tapView;
    }else {
        longPressedView = [self hitTestForlongPressedGestureRecognizer:point];
        hitTestView = longPressedView;
    }

    if (hitTestView) {
        [self performSelector:@selector(delayedCallback:) withObject:touch
                   afterDelay:0.2];
        return YES;
    }
    
    return isTapGestureRecognizer ? isMenuVisible : NO;
}


- (UIView *)hitTestForTapGestureRecognizer:(CGPoint)point {
    return self.contentView;
}

- (UIView *)hitTestForlongPressedGestureRecognizer:(CGPoint)point {
    return self.contentView;
}

- (void)delayedCallback:(id)_touch {
    UITouch *touch = (UITouch *)_touch;
    if (!touch)
        return;
    
    if (touch.phase == UITouchPhaseEnded || touch.phase == UITouchPhaseCancelled) {
        return;
    }
    
    [self contentEventTouchBeganInView:tapView];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (LLMessageCell_isEditing) {
        [self toggleSelectStatus];
    }
}


- (void)contentTapped:(UITapGestureRecognizer *)tap {
    if (!self.messageModel || !tapView)
        return;

    if (tapView == self.avatarImage) {
        if ([self.delegate respondsToSelector:@selector(avatarImageDidTapped:)]){
            [self.delegate avatarImageDidTapped:self];
        }
    }else if (_statusButton && tapView == _statusButton) {
        if (self.messageModel.fromMe) {
            SAFE_SEND_MESSAGE(self.delegate, resendMessage:) {
                [self.delegate resendMessage:self.messageModel];
            }
        }else {
            SAFE_SEND_MESSAGE(self.delegate, redownloadMessage:) {
                [self.delegate redownloadMessage:self.messageModel];
            }
        }
    }else if (_selectControl && tapView == _selectControl) {
        [self toggleSelectStatus];
    }else {
        [self contentEventTappedInView:tapView];
    }
    
    tapView = nil;
    
}


- (void)contentLongPressed:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
     [self contentEventLongPressedBeganInView:longPressedView];
    }else if (longPress.state == UIGestureRecognizerStateChanged) {
        
    }else if (longPress.state == UIGestureRecognizerStateEnded) {
       [self contentEventLongPressedEndedInView:longPressedView];
       longPressedView = nil;
    }
    
}

- (void)toggleSelectStatus {
    if (LLMessageCell_isEditing) {
        self.isSelected = !self.isSelected;
        SAFE_SEND_MESSAGE(self.delegate, selectControllDidTapped:selected:) {
            [self.delegate selectControllDidTapped:self.messageModel selected:_isSelected];
        }
    }
    
}

- (void)cancelContentTouch {
    [self contentEventTouchCancelled];
}

- (void)contentEventTouchBeganInView:(UIView *)view {
    
}

- (void)contentEventTouchCancelled {
    
}

- (void)contentEventTappedInView:(UIView *)view {
    
}

- (void)contentEventLongPressedBeganInView:(UIView *)view {
    
}

- (void)contentEventLongPressedEndedInView:(UIView *)view {
    
}


- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if (self.hidden || !self.userInteractionEnabled || self.alpha <= 0.01)
        return nil;
    
    if ([self.contentView pointInside:[self convertPoint:point toView:self.contentView] withEvent:event]) {
        return self.contentView;
    }
    
    return nil;
}

#pragma mark - 弹出菜单

- (BOOL)canBecomeFirstResponder{
    return YES;
}

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    for (NSInteger i = 0; i < self.menuActionNames.count; i++) {
        if (action == NSSelectorFromString(self.menuActionNames[i])) {
            return YES;
        }
    }
    
    return NO;//隐藏系统默认的菜单项
    
}

- (void)showMenuControllerInRect:(CGRect)rect inView:(UIView *)view {
    UIResponder *firstResponder;
    SAFE_SEND_MESSAGE(self.delegate, currentFirstResponderIfNeedRetain) {
        firstResponder = [self.delegate currentFirstResponderIfNeedRetain];
    }
    
    LLTextView *textView;
    if ([firstResponder isKindOfClass:[LLTextView class]]) {
        textView = (LLTextView *)firstResponder;
    }
    
    UIMenuController *menu = [UIMenuController sharedMenuController];
    if (!self.menuItems) {
        self.menuItems = [NSMutableArray arrayWithCapacity:self.menuNames.count];
        
        for (NSInteger i =0; i < self.menuNames.count; i++) {
            UIMenuItem *item = [[UIMenuItem alloc] initWithTitle:self.menuNames[i] action:NSSelectorFromString(self.menuActionNames[i])];
            [self.menuItems addObject:item];
        }
        
    }
    [menu setMenuItems:self.menuItems];
    [menu setTargetRect:rect inView:view];
    menu.arrowDirection = UIMenuControllerArrowDefault;
    
    //设置当前Cell为FirstResponder
    if (!textView) {
        [self becomeFirstResponder];
    
    //保留TextView为FirstResponder，当需其负责Menu显示
    }else {
        textView.targetCell = self;
    }
    
    [menu setMenuVisible:YES animated:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidHideCallback:) name:UIMenuControllerDidHideMenuNotification object:menu];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuWillHideCallback:) name:UIMenuControllerWillHideMenuNotification object:menu];
//    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidShowCallback:) name:UIMenuControllerDidShowMenuNotification object:menu];
    
}

- (void)menuWillHideCallback:(NSNotification *)notify {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerWillHideMenuNotification object:nil];
    
    SAFE_SEND_MESSAGE(self.delegate, willHideMenuForCell:) {
        [self.delegate willHideMenuForCell:self];
    }
}

- (void)menuDidHideCallback:(NSNotification *)notify {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidHideMenuNotification object:nil];
    
    [self cancelContentTouch];
    ((UIMenuController *)notify.object).menuItems = nil;
    SAFE_SEND_MESSAGE(self.delegate, didHideMenuForCell:) {
        [self.delegate didHideMenuForCell:self];
    }
}

- (void)menuDidShowCallback:(NSNotification *)notify {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerDidShowMenuNotification object:nil];
    
    SAFE_SEND_MESSAGE(self.delegate, didShowMenuForCell:) {
        [self.delegate didShowMenuForCell:self];
    }
}

- (void)deleteAction:(id)sender {
    [self.delegate deleteMenuItemDidTapped:self];
}

- (void)moreAction:(id)sender {
    [self.delegate moreMenuItemDidTapped:self];
}

- (void)copyAction:(id)sender {
    
}

- (void)transforAction:(id)sender {
    
}

- (void)favoriteAction:(id)sender {
    
}

- (void)translateAction:(id)sender {
    
}

- (void)addToEmojiAction:(id)sender {
    
}

- (void)forwardAction:(id)sender {
    
}

- (void)showAlbumAction:(id)sender {
    
}

- (void)playAction:(id)sender {
    
}

- (void)translateToWordsAction:(id)sender {
    
}

@end
