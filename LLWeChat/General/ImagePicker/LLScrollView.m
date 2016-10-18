//
//  LLScrollView.m
//  LLPickImageDemo
//
//  Created by GYJZH on 7/10/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLScrollView.h"
#import "LLUtils.h"


@implementation LLScrollView

- (instancetype)init {
    self = [super initWithFrame:SCREEN_FRAME];
    self.backgroundColor = [UIColor clearColor];
    self.pagingEnabled = NO;
    self.delaysContentTouches = YES;
    self.canCancelContentTouches = YES;
    self.bounces = YES;
    self.bouncesZoom = YES;
    self.showsVerticalScrollIndicator = NO;
    self.showsHorizontalScrollIndicator = NO;
   
    _imageView = [[UIImageView alloc] initWithFrame:SCREEN_FRAME];
    _imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:_imageView];

    _assetIndex = -1;

    return self;
}


- (void)setContentWithImage:(UIImage *)image {
    _imageSize = CGSizeMake(SCREEN_WIDTH, floor((SCREEN_WIDTH/image.size.width) * image.size.height));
    
    CGFloat _y = (SCREEN_HEIGHT > _imageSize.height) ? (SCREEN_HEIGHT - _imageSize.height)/2 : 0;
    _imageView.frame = CGRectMake(0, _y, SCREEN_WIDTH, _imageSize.height);
    _imageView.image = image;
    
    self.contentSize = _imageSize;
    
    //设置缩放范围
    self.minimumZoomScale = MinimumZoomScale;
    CGFloat vScale = SCREEN_HEIGHT / _imageSize.height;
    self.maximumZoomScale = MAX(vScale, MaximumZoomScale);

    [self hideLoadingIndicator];
}


- (void)showLoadingIndicator {
    self.imageView.hidden = YES;
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicatorView.center = CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT/2);
    indicatorView.tag = 1000;
    [self addSubview:indicatorView];
    
    [indicatorView startAnimating];
}


- (void)hideLoadingIndicator {
    UIActivityIndicatorView *indicatorView = [self viewWithTag:1000];
    if (indicatorView && indicatorView.isAnimating) {
        [indicatorView startAnimating];
        [indicatorView removeFromSuperview];
        self.imageView.hidden = NO;
    }
}


@end
