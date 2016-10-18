//
//  LLChatImageScrollView.h
//  LLWeChat
//
//  Created by GYJZH on 8/16/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLAssetDisplayView.h"

#define MinimumZoomScale 1
#define MaximumZoomScale 2


@interface LLChatImageScrollView : UIScrollView<LLAssetDisplayView>

@property (nonatomic) CGSize imageSize;

@property (nonatomic) UIImageView *imageView;

//- (void)showInViewAnimated:(CGRect)originFrame;

- (void)layoutImageView:(CGSize)size;

- (void)setDownloadFailImage;

- (BOOL)shouldZoom;

//- (void)showLoadingIndicator;
//
//- (void)hideLoadingIndicator;

//- (void)setContentWithImage:(UIImage *)image;


@end
