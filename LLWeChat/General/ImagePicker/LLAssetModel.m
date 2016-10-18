//
//  LLAssetModel.m
//  LLPickImageDemo
//
//  Created by GYJZH on 7/11/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLAssetModel.h"
#import "LLAssetManager.h"
#import "LLUtils.h"


#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

@implementation LLAssetModel

- (void)fetchThumbnailWithPointSize:(CGSize)size completion:(nonnull void (^)(UIImage * _Nullable))completionCallback {
    if ([LLUtils canUsePhotiKit]) {
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSize pixelSize = CGSizeMake(scale * size.width, scale * size.height);
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        requestOptions.synchronous = NO;
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        
        
        [[PHImageManager defaultManager] requestImageForAsset:self.asset_PH targetSize:pixelSize contentMode:PHImageContentModeAspectFill options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {

            completionCallback(result);
        }];

    } else {
       completionCallback([UIImage imageWithCGImage:[self.asset_AL thumbnail]]);
    }
}

- (NSString *)duration {
    if (!_duration) {
        CGFloat duration = _asset_PH ? _asset_PH.duration : 0;
        _duration = [self.class getDurationString:round(duration)];
    }
    
    return _duration;
}

+ (NSString *)getDurationString:(NSInteger)duration {
    NSInteger minutes = duration / 60;
    NSInteger seconds = duration % 60;
    NSString *ret = [NSString stringWithFormat:@"%ld:%02ld", (long)minutes, seconds];
    
    return ret;
}

- (CGSize)imageSize {
    if (self.asset_PH) {
        return CGSizeMake(self.asset_PH.pixelWidth, self.asset_PH.pixelHeight);
    }else {
        return self.asset_AL.defaultRepresentation.dimensions;
    }
}


@end

#pragma clang diagonstic pop
