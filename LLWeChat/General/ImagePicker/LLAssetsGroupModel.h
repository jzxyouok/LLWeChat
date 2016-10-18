//
//  LLAssetGroupModel.h
//  LLPickImageDemo
//
//  Created by GYJZH on 7/11/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

@import UIKit;
@import AssetsLibrary;
@import Photos;

#import "LLAssetModel.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@interface LLAssetsGroupModel : NSObject

@property (nonatomic) NSUInteger numberOfAssets;
@property (nonatomic) NSMutableArray<LLAssetModel *> *allAssets;
@property (nonatomic, copy) NSString *assetsGroupName;

@property (nonatomic) PHAssetCollection *assetsGroup_PH;
@property (nonatomic) ALAssetsGroup *assetsGroup_AL;


/**
 *  获取相册缩略图，对于Photo框架，获取相册中最后一个资源的缩略图
 *
 *  @param size            缩略图大小，单位为point
 *  @param completeCallack 完成回调
 */
- (void)fetchPosterImageWithPointSize:(CGSize)size completeBlock:(void (^)(UIImage *image))completeCallack;

- (BOOL)isVideoGroup;

- (NSString *)localIdentifier;

@end

#pragma clang diagonstic pop
