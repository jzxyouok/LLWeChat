//
//  LLAssetModel.h
//  LLPickImageDemo
//
//  Created by GYJZH on 7/11/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
@import Photos;
@import AssetsLibrary;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


@interface LLAssetModel : NSObject

@property (nonatomic) NSInteger assetIndex;

@property (nullable, nonatomic) PHAsset *asset_PH;

@property (nullable, nonatomic) ALAsset *asset_AL;

@property (nullable, nonatomic, copy) NSString *duration;

- (void)fetchThumbnailWithPointSize:(CGSize)size completion:(nonnull void (^)(UIImage * _Nullable))completionCallback;

- (CGSize)imageSize;

@end

#pragma clang diagonstic pop
