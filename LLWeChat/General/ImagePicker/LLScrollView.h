//
//  LLScrollView.h
//  LLPickImageDemo
//
//  Created by GYJZH on 7/10/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLAssetModel.h"


#define MinimumZoomScale 1
#define MaximumZoomScale 2


@interface LLScrollView : UIScrollView

@property (nonatomic) NSInteger assetIndex;
@property (nonatomic) LLAssetModel *assetModel;

@property (nonatomic) CGSize imageSize;

@property (nonatomic) UIImageView *imageView;

- (void)showLoadingIndicator;

- (void)hideLoadingIndicator;

- (void)setContentWithImage:(UIImage *)image;


@end
