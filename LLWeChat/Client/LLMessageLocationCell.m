//
//  LLMessageLocationCell.m
//  LLWeChat
//
//  Created by GYJZH on 8/26/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageLocationCell.h"
#import "LLColors.h"
#import "LLConfig.h"
#import <MAMapKit/MAMapKit.h>

#define LOCATION_IMAGE_WIDTH 260

#define LOCATION_TOP_HEIGHT_Big 58
#define LOCATION_TOP_HEIGHT_Small 40

#define LOCATION_BOTTOM_HEIGHT 92

#define Style_NeedReGeoCode 1
#define Style_EmptyAddress 2
#define Style_ReGeoCodeSuccess 3

static NSArray<NSString *> *menuActionNames;
static NSArray<NSString *> *menuNames;


@interface LLMessageLocationCell ()

@property (nonatomic) UILabel *topLabel;
@property (nonatomic) UILabel *bottomLabel;
@property (nonatomic) UIImageView *pinchView;
@property (nonatomic) UIImageView *mapImageView;
@property (nonatomic) UIView *locationView;

@property (nonatomic) UIActivityIndicatorView *reGeoIndicator;
@property (nonatomic) UIActivityIndicatorView *downloadIndicator;
@property (nonatomic) UIImageView *borderView;

@property (nonatomic) NSInteger style;

@end

@implementation LLMessageLocationCell {
    NSInteger location_top_height;
}

+ (void)initialize {
    if (self == [LLMessageLocationCell class]) {
        menuNames = @[@"复制", @"收藏", @"删除", @"更多..."];
        menuActionNames = @[@"copyAction:", @"favoriteAction:", @"deleteAction:", @"moreAction:"];
    }
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    if (self) {
        _locationView = [[UIView alloc] initWithFrame:CGRectMake(0, CONTENT_SUPER_TOP, LOCATION_IMAGE_WIDTH, LOCATION_TOP_HEIGHT_Big + LOCATION_BOTTOM_HEIGHT)];
        _locationView.backgroundColor = [UIColor whiteColor];
        [self.contentView addSubview:_locationView];

        _topLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 12, LOCATION_IMAGE_WIDTH - 24 - BUBBLE_MASK_ARROW, 20)];
        _topLabel.font = [UIFont systemFontOfSize:16];
        _topLabel.textColor = [UIColor blackColor];
        _topLabel.textAlignment = NSTextAlignmentLeft;
        [_locationView addSubview:_topLabel];

        _bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(12, 32, LOCATION_IMAGE_WIDTH - 24 - BUBBLE_MASK_ARROW, 20)];
        _bottomLabel.font = [UIFont systemFontOfSize:12];
        _bottomLabel.textColor = kLLTextColor_lightGray_system;
        _bottomLabel.textAlignment = NSTextAlignmentLeft;
        [_locationView addSubview:_bottomLabel];

        _mapImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, LOCATION_TOP_HEIGHT_Big, LOCATION_IMAGE_WIDTH,
                LOCATION_BOTTOM_HEIGHT)];
        _mapImageView.backgroundColor = kLLBackgroundColor_gray;
//        _mapImageView.backgroundColor = [UIColor redColor];
        _mapImageView.contentMode = UIViewContentModeCenter;
        _mapImageView.clipsToBounds = YES;
        [_locationView addSubview:_mapImageView];
        
        [self.bubbleImage removeFromSuperview];
        _locationView.layer.mask = self.bubbleImage.layer;
        _locationView.layer.masksToBounds = YES;
        
        self.borderView = [[UIImageView alloc] init];
        self.borderView.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:self.borderView];
        
        _pinchView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"located_pin"]];
        _pinchView.frame = CGRectMake(0, 0, 18, 38);
        _pinchView.layer.anchorPoint = CGPointMake(0.5, 0.96);
        _pinchView.center = _mapImageView.center;
        [_locationView addSubview:_pinchView];
        
        self.menuNames = [menuNames mutableCopy];
        self.menuActionNames = [menuActionNames mutableCopy];
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
    
    if ([messageModel.address isEqualToString:LOCATION_EMPTY_ADDRESS]) {
        self.topLabel.text = messageModel.address;
        self.bottomLabel.text = nil;
        [self setStyle:Style_EmptyAddress];
    }else if ([messageModel.address isEqualToString:LOCATION_UNKNOWE_ADDRESS]) {
        self.topLabel.text = nil;
        self.bottomLabel.text = nil;
        [self setStyle:Style_NeedReGeoCode];

    }else {
        self.topLabel.text = messageModel.locationName;
        self.bottomLabel.text = messageModel.address;
        [self setStyle:Style_ReGeoCodeSuccess];
    }
    
    if (messageModel.isFromMe) {
        [self updateMessageUploadStatus];
    }
    [self updateMessageDownloadStatus];
    
    [self layoutMessageContentViews:messageModel.isFromMe];
    [self layoutMessageStatusViews:messageModel.isFromMe];

}


- (void)updateMessageDownloadStatus {
    if (self.messageModel.snapshotImage) {
        self.mapImageView.image = self.messageModel.snapshotImage;
        _pinchView.hidden = NO;
        if (_downloadIndicator) {
            _downloadIndicator.hidden = YES;
            [_downloadIndicator stopAnimating];
        }
    }else {
        self.mapImageView.image = nil;
        _pinchView.hidden = YES;
        self.downloadIndicator.hidden = NO;
        [self.downloadIndicator startAnimating];
    }
}

- (void)setStyle:(NSInteger)style {
    _style = style;
    if (style == Style_NeedReGeoCode) {
        location_top_height = LOCATION_TOP_HEIGHT_Small;
        self.reGeoIndicator.hidden = NO;
        [self.reGeoIndicator startAnimating];
    }else if (style == Style_EmptyAddress) {
        location_top_height = LOCATION_TOP_HEIGHT_Small;
        if (_reGeoIndicator) {
            _reGeoIndicator.hidden = YES;
            [_reGeoIndicator stopAnimating];
        }
    }else if (style == Style_ReGeoCodeSuccess) {
        location_top_height = LOCATION_TOP_HEIGHT_Big;
        if (_reGeoIndicator) {
            _reGeoIndicator.hidden = YES;
            [_reGeoIndicator stopAnimating];
        }
    }
}

- (UIActivityIndicatorView *)reGeoIndicator {
    if (!_reGeoIndicator) {
        _reGeoIndicator = [[UIActivityIndicatorView alloc]
                initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_locationView addSubview:_reGeoIndicator];
        _reGeoIndicator.hidden = YES;
    }

    return _reGeoIndicator;
}

- (UIActivityIndicatorView *)downloadIndicator {
    if (!_downloadIndicator) {
        _downloadIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        [_locationView addSubview:_downloadIndicator];
        _downloadIndicator.hidden = YES;
    }
    
    return _downloadIndicator;
}

- (void)layoutMessageContentViews:(BOOL)isFromMe {
    CGRect frame;
    if (isFromMe) {
        frame = _locationView.frame;
        frame.size.height = location_top_height + LOCATION_BOTTOM_HEIGHT;
        frame.origin.x = CGRectGetMinX(self.avatarImage.frame) - CONTENT_AVATAR_MARGIN - CGRectGetWidth(frame);
        _locationView.frame = frame;
        
        frame = _mapImageView.frame;
        frame.origin.x = 0;
        frame.origin.y = location_top_height;
        _mapImageView.frame = frame;
        
    }else {
        frame = _locationView.frame;
        frame.size.height = location_top_height + LOCATION_BOTTOM_HEIGHT;
        frame.origin.x = CGRectGetMaxX(self.avatarImage.frame) + CONTENT_AVATAR_MARGIN;
        _locationView.frame = frame;
        
        frame = _mapImageView.frame;
        frame.origin.x = BUBBLE_MASK_ARROW;
        frame.origin.y = location_top_height;
        _mapImageView.frame = frame;
    }

    frame = self.locationView.frame;
    frame.origin = CGPointZero;
    self.bubbleImage.frame = frame;
    
    frame = self.locationView.frame;
    frame.origin.x = CGRectGetMinX(frame) -1;
    frame.size.height += 2;
    frame.size.width += 1;
    self.borderView.frame = frame;

//    frame = _topLabel.frame;
//    frame.origin.x = CGRectGetMinX(_mapImageView.frame) + 10;
//    _topLabel.frame = frame;
//
//    frame = _bottomLabel.frame;
//    frame.origin.x = CGRectGetMinX(_topLabel.frame);
//    _bottomLabel.frame = frame;

    _pinchView.center = _mapImageView.center;
    
    if (_reGeoIndicator && !_reGeoIndicator.hidden) {
        _reGeoIndicator.center = CGPointMake(_mapImageView.center.x, CGRectGetMaxY(_mapImageView.frame) - 15);
    }
    
    if (_downloadIndicator && !_downloadIndicator.hidden) {
        _downloadIndicator.center = CGPointMake(_mapImageView.center.x, CGRectGetMaxY(_mapImageView.frame) - 53);
    }
}

- (void)layoutMessageStatusViews:(BOOL)isFromMe {
    if (_indicatorView || _statusButton) {
        self.indicatorView.center = CGPointMake(_locationView.center.x, CGRectGetMaxY(_locationView.frame) - 53);
        
        self.statusButton.center = CGPointMake(CGRectGetMinX(self.locationView.frame) - CGRectGetWidth(self.statusButton.frame)/2 - ACTIVITY_VIEW_X_OFFSET, CGRectGetMidY(self.locationView.frame) + ACTIVITY_VIEW_Y_OFFSET);
        
    }
}


+ (CGFloat)heightForModel:(LLMessageModel *)model {
    if ([model.address isEqualToString:LOCATION_EMPTY_ADDRESS]
        || [model.address isEqualToString:LOCATION_UNKNOWE_ADDRESS]) {
        return LOCATION_TOP_HEIGHT_Small + LOCATION_BOTTOM_HEIGHT + CONTENT_SUPER_BOTTOM;
    }else
        return LOCATION_TOP_HEIGHT_Big + LOCATION_BOTTOM_HEIGHT + CONTENT_SUPER_BOTTOM ;
}

#pragma mark - 手势

- (UIView *)hitTestForTapGestureRecognizer:(CGPoint)point {
    CGPoint pointInView = [self.contentView convertPoint:point toView:_locationView];
    if ([self.locationView pointInside:pointInView withEvent:nil]) {
        return self.locationView;
    }
    
    return nil;
}

- (UIView *)hitTestForlongPressedGestureRecognizer:(CGPoint)point {
    CGPoint pointInView = [self.contentView convertPoint:point toView:_locationView];
    if ([self.locationView pointInside:pointInView withEvent:nil]) {
        return self.locationView;
    }
    
    return nil;
}

- (void)contentEventTappedInView:(UIView *)view {
    if ([self.messageModel.address isEqualToString:LOCATION_UNKNOWE_ADDRESS])
        return;
    [self.delegate cellForLocationDidTapped:self];
}

- (void)contentEventLongPressedBeganInView:(UIView *)aView {
    [self showMenuControllerInRect:self.locationView.bounds inView:self.locationView];
    UIView *view = [[UIView alloc] initWithFrame:self.locationView.bounds];
    view.tag = 100;
    view.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.3];
    [self.locationView addSubview:view];
}

- (void)contentEventTouchCancelled {
    UIView *view = [self.locationView viewWithTag:100];
    [view removeFromSuperview];
}



#pragma mark - 菜单

- (void)copyAction:(id)sender {
    
}


- (void)favoriteAction:(id)sender {
    
}


@end
