//
//  LLAssetManager.m
//  LLPickImageDemo
//
//  Created by GYJZH on 7/12/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLAssetManager.h"
#import "LLUtils.h"
#import "UIKit+LLExt.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"


static LLAssetManager *_instance;

static int SIZE_BYTES_THRESHOLD =  1024 * 1024;
static long long  MAX_ACCEPT_BITMAP_SIZE = 50 * 1024 * 1024;
//最多有三个后台线程在获取照片
#define SEMAPHORE_NUM 3

//使用AssetLibrary框架时，缓存图片的最大数目
#define CACHE_COUNT_LIMIT 8
#define SCALE_THRESHOLD 2


@interface LLAssetManager ()

@property (nonatomic) NSMutableArray<LLAssetsGroupModel *> *allAssetsGroups_m;
@property (nonatomic) PHCachingImageManager *imageManager;
@property (nonatomic) PHImageRequestOptions *fullResolutionRequestOptions;
@property (nonatomic) PHImageRequestOptions *requestOptions;

@property (nonatomic) NSCache *imagesCache;
@property (nonatomic) dispatch_semaphore_t semaphore;
@property (nonatomic) NSMutableArray<NSNumber *> *loadingAssetIndexes;

@property (nonatomic, copy) LLCheckAuthorizationCompletionBlock authorizationBlock;

@end



@implementation LLAssetManager {
    CGSize thumbmainSize;
    
}


+ (instancetype)sharedAssetManager {
    if (!_instance) {
        _instance = [[LLAssetManager alloc] init];
    }
    
    return _instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _allAssetsGroups_m = [[NSMutableArray alloc] init];
        
        _imageManager = [[PHCachingImageManager alloc] init];
        
        _fullResolutionRequestOptions = [[PHImageRequestOptions alloc] init];
        _fullResolutionRequestOptions.resizeMode = PHImageRequestOptionsResizeModeExact;
        _fullResolutionRequestOptions.synchronous = YES;
        _fullResolutionRequestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        
        _requestOptions = [[PHImageRequestOptions alloc] init];
        _requestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        _requestOptions.synchronous = NO;
        _requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;

        
        _loadingAssetIndexes = [[NSMutableArray alloc] init];
        _imagesCache = [[NSCache alloc] init];
        _imagesCache.countLimit = CACHE_COUNT_LIMIT;
        _semaphore = dispatch_semaphore_create(SEMAPHORE_NUM);
    
    }
    
    return self;
}


- (NSArray<LLAssetsGroupModel *> *)allAssetsGroups {
    return _allAssetsGroups_m;
}

+ (void)destroyAssetManager {
    _instance = nil;
}

#pragma mark - 检测相册权限

- (void)chechAuthorizationStatus:(LLCheckAuthorizationCompletionBlock)block {
    self.authorizationBlock = block;
    if ([LLUtils canUsePhotiKit]) {
        [self checkAuthorizationStatus_PhotoKit];
    }else {
        [self checkAuthorizationStatus_AssetLibrary];
    }
}

- (void)checkAuthorizationStatus_AssetLibrary
{
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusDenied) {
        self.authorizationBlock(kLLAuthorizationTypeDenied);
    }else {
        self.authorizationBlock(kLLAuthorizationTypeAuthorized);
    }
}

- (void)checkAuthorizationStatus_PhotoKit
{
    PHAuthorizationStatus status = [PHPhotoLibrary authorizationStatus];
    switch (status)
    {
        case PHAuthorizationStatusNotDetermined:
            [self requestAuthorizationStatus_PhotoKit];
            break;
        case PHAuthorizationStatusRestricted:
        case PHAuthorizationStatusDenied:
            self.authorizationBlock(kLLAuthorizationTypeDenied);
            break;
        case PHAuthorizationStatusAuthorized:
            self.authorizationBlock(kLLAuthorizationTypeAuthorized);
            break;
    }
    
}

- (void)requestAuthorizationStatus_PhotoKit
{
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status){
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case PHAuthorizationStatusAuthorized:
                    self.authorizationBlock(kLLAuthorizationTypeAuthorized);
                    break;
                default:
                    self.authorizationBlock(kLLAuthorizationTypeDenied);
                    break;
            }
        });
    }];
}


#pragma mark - 获取全部相册

- (void)fetchAllAssetsGroups:(LLFetchAssetsGroupsSuccessBlock)sucessCallback failureBlock:(LLFetchAssetsGroupsFailureBlock)failureCallback {

    if ([LLUtils canUsePhotiKit]) {
        [self fetchAllAssetsGroups_PhotoKit:sucessCallback failureBlock:failureCallback];
    }else {
        [self fetchAllAssetsGroups_AssetLibrary:sucessCallback failureBlock:failureCallback];
    }
}

//小于IOS8系统，采用AssetsLibrary框架, 异步调用
- (void)fetchAllAssetsGroups_AssetLibrary:(LLFetchAssetsGroupsSuccessBlock)sucessCallback failureBlock:(LLFetchAssetsGroupsFailureBlock)failureCallback {
    
    __weak typeof(self) weakSelf = self;
    static ALAssetsLibrary *library = nil;
    if (library == nil) {
        library = [[ALAssetsLibrary alloc] init];
    }
    
    void (^enummerateBlock)(ALAssetsGroup*, BOOL*) =  ^(ALAssetsGroup *group, BOOL *stop) {
        if (group != nil) {
            [group setAssetsFilter: [ALAssetsFilter allPhotos]];

            if (group.numberOfAssets > 0) {
                LLAssetsGroupModel *groupModel = [[LLAssetsGroupModel alloc] init];
                groupModel.assetsGroup_AL = group;
                groupModel.numberOfAssets = group.numberOfAssets;
                groupModel.assetsGroupName = [group valueForProperty:ALAssetsGroupPropertyName];
                
                if ([[group valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos) {
                    [weakSelf.allAssetsGroups_m insertObject:groupModel atIndex:0];
                }else {
                    [weakSelf.allAssetsGroups_m addObject:groupModel];
                }
            }
        }else {
            dispatch_async(dispatch_get_main_queue(), ^{
                 sucessCallback();
            });
        }
 
    };
    
    void (^failureBlock)(NSError *) = ^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
           if (failureCallback)failureCallback(error);
            self.authorizationBlock(kLLAuthorizationTypeDenied);
        });
    };
    
    
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos | ALAssetsGroupAlbum | ALAssetsGroupLibrary
        usingBlock:enummerateBlock failureBlock:failureBlock];
    
}


//IOS8及其上系统，采用Photos框架, 同步调用
- (void)fetchAllAssetsGroups_PhotoKit:(LLFetchAssetsGroupsSuccessBlock)sucessCallback failureBlock:(LLFetchAssetsGroupsFailureBlock)failureCallbak {
    
    void (^enumerateBlock)(PHAssetCollection *, NSUInteger idx, BOOL *) = ^(PHAssetCollection * _Nonnull collection, NSUInteger idx, BOOL * _Nonnull stop) {
        if (collection.estimatedAssetCount == 0) {
            return ;
        }
        
        PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        NSUInteger numberOfAssets;
        if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumVideos) {
            numberOfAssets = [assetsResult countOfAssetsWithMediaType:PHAssetMediaTypeVideo];
        }else {
            numberOfAssets = [assetsResult countOfAssetsWithMediaType:PHAssetMediaTypeImage];
        }
        
        if (numberOfAssets == 0) {
            return;
        }
        
        LLAssetsGroupModel *groupModel = [[LLAssetsGroupModel alloc] init];
        groupModel.assetsGroup_PH = collection;
        groupModel.numberOfAssets = numberOfAssets;
        groupModel.assetsGroupName = collection.localizedTitle;
        
        [self.allAssetsGroups_m addObject:groupModel];

    };
    
    PHAssetCollectionSubtype smartSubtypes[] = {
        PHAssetCollectionSubtypeSmartAlbumUserLibrary,
        PHAssetCollectionSubtypeSmartAlbumScreenshots,
        PHAssetCollectionSubtypeSmartAlbumRecentlyAdded,
        PHAssetCollectionSubtypeSmartAlbumFavorites,
        PHAssetCollectionSubtypeSmartAlbumVideos
    };
    
    for (int i=0; i<5; i++) {
        PHFetchResult *userSmartAlbumsResult = [PHAssetCollection
             fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
             subtype:smartSubtypes[i]
             options:nil];
        [userSmartAlbumsResult enumerateObjectsUsingBlock:enumerateBlock];
    }
    
    //获取用户自己建立的相册
    PHAssetCollectionSubtype albumSubtypes[] = {
        PHAssetCollectionSubtypeAlbumRegular,
        PHAssetCollectionSubtypeAlbumImported,
        PHAssetCollectionSubtypeAlbumSyncedAlbum
    };
    
    for (int i=0; i<3; i++) {
        PHFetchResult *userAlbumsResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                      subtype:albumSubtypes[i]
                      options:nil];
        [userAlbumsResult enumerateObjectsUsingBlock:enumerateBlock];
    }
    
    sucessCallback();
    
}

- (LLAssetsGroupModel *)assetsGroupModelForLocalIdentifier:(NSString *)localIdentifier {
    if ([LLUtils canUsePhotiKit]) {
        if (!localIdentifier) {
            for (LLAssetsGroupModel *groupModel in self.allAssetsGroups_m) {
                if ((groupModel.assetsGroup_PH.assetCollectionType == PHAssetCollectionTypeSmartAlbum) && (groupModel.assetsGroup_PH.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary)) {
                    return groupModel;
                }
            }
        }else {
            for (LLAssetsGroupModel *groupModel in self.allAssetsGroups_m) {
                if ([groupModel.assetsGroup_PH.localIdentifier isEqualToString:localIdentifier]) {
                    return groupModel;
                }
            }
        }
    }else {
        if (!localIdentifier) {
            for (LLAssetsGroupModel *groupModel in self.allAssetsGroups_m) {
                if ([[groupModel.assetsGroup_AL valueForProperty:ALAssetsGroupPropertyType] intValue] == ALAssetsGroupSavedPhotos) {
                    return groupModel;
                }
            }
        }else {
            for (LLAssetsGroupModel *groupModel in self.allAssetsGroups_m) {
                if ([[groupModel.assetsGroup_AL valueForProperty:ALAssetsGroupPropertyPersistentID] isEqualToString:localIdentifier]) {
                    return groupModel;
                }
            }
        }
    }
    
    return nil;
}

#pragma mark - 获取相册下所有照片

- (void)fetchAllAssetsInGroup:(LLAssetsGroupModel *)groupModel successBlock:(nullable LLFetchAllAssetsSucessBlock)successCallback failureBlock:(nullable LLFetchAllAssetsFailureBlock)failureCallback {
 
    //该相册已经获取过了
    if (groupModel.allAssets.count > 0) {
        if (successCallback)successCallback(groupModel);
        return;
    }
    
    if ([LLUtils canUsePhotiKit]) {
        [self fetchAllAssetsInGroup_PhotoKit:groupModel successBlock:successCallback failureBlock:failureCallback];
    }else {
        [self fetchAllAssetsInGroup_AssetLibrary:groupModel successBlock:successCallback failureBlock:failureCallback];
    }

}

- (void)fetchAllAssetsInGroup_AssetLibrary:(LLAssetsGroupModel *)groupModel successBlock:(nullable LLFetchAllAssetsSucessBlock)successCallback failureBlock:(nullable LLFetchAllAssetsFailureBlock)failureCallback {
    ALAssetsGroup *group = groupModel.assetsGroup_AL;
    if (group == nil)return;
    
    if (!groupModel.allAssets) {
        groupModel.allAssets = [[NSMutableArray alloc] init];
    }
    
    __block NSInteger numberOfAssets = 0;
    //该方法为同步执行，不是异步
    [group enumerateAssetsUsingBlock:^(ALAsset *asset, NSUInteger index, BOOL *stop) {
        if (asset){
            LLAssetModel *assetModel = [[LLAssetModel alloc] init];
            assetModel.asset_AL = asset;
            assetModel.assetIndex = numberOfAssets;
            
            [groupModel.allAssets addObject:assetModel];
            numberOfAssets ++;
        }
    }];
    
    BOOL isSuccess = groupModel.numberOfAssets == numberOfAssets;
    if (successCallback != nil && isSuccess)
        successCallback(groupModel);
    else if (failureCallback != nil && !isSuccess) {
        failureCallback(nil);
    }
    
}

- (void)fetchAllAssetsInGroup_PhotoKit:(LLAssetsGroupModel *)groupModel successBlock:(nullable LLFetchAllAssetsSucessBlock)successCallback failureBlock:(nullable LLFetchAllAssetsFailureBlock)failureCallback {
    if (groupModel.assetsGroup_PH == nil)return;
    
    PHFetchOptions *fetchOptions = [PHFetchOptions new];
    PHAssetMediaType mediaType = groupModel.isVideoGroup ? PHAssetMediaTypeVideo : PHAssetMediaTypeImage;
    fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %d", mediaType];
    
    PHFetchResult *assetsResult = [PHAsset fetchAssetsInAssetCollection:groupModel.assetsGroup_PH options:fetchOptions];
    
    if (!groupModel.allAssets) {
        groupModel.allAssets = [[NSMutableArray alloc] init];
    }
    
    __block NSInteger numberOfAssets = 0;
    //该方法为同步执行, This method executes synchronously.
    [assetsResult enumerateObjectsUsingBlock:^(PHAsset * _Nonnull asset, NSUInteger index, BOOL * _Nonnull stop) {
        if (asset) {
            LLAssetModel *assetModel = [[LLAssetModel alloc] init];
            assetModel.asset_PH = asset;
            assetModel.assetIndex = numberOfAssets;
            
            [groupModel.allAssets addObject:assetModel];
            numberOfAssets ++;
        }
        
    }];
    
    BOOL isSuccess = groupModel.numberOfAssets == numberOfAssets;
    if (successCallback != nil && isSuccess)
        successCallback(groupModel);
    else if (failureCallback != nil && !isSuccess) {
        failureCallback(nil);
    }
    
}



#pragma mark - 加载单张图片

- (void)fetchImageFromAssetModel:(LLAssetModel *)assetModel asyncBlock:(nullable LLFetchImageAsyncCallbackBlock)asyncCallback syncBlock:(nullable LLFetchImageSyncCallbackBlock)syncCallback {
    
    if ([LLUtils canUsePhotiKit]) {
        [self fetchImageFromAssetModel_PhotoKit:assetModel asyncBlock:asyncCallback syncBlock:syncCallback];
        
    }else {
        [self fetchImageFromAssetModel_AssetLibrary:assetModel asyncBlock:asyncCallback syncBlock:syncCallback];
    }
}


- (void)fetchImageFromAssetModel_PhotoKit:(LLAssetModel *)assetModel asyncBlock:(nullable LLFetchImageAsyncCallbackBlock)asyncCallback syncBlock:(nullable LLFetchImageSyncCallbackBlock)syncCallback {
    
    PHAsset *asset = assetModel.asset_PH;

    if ([self needFetchFullResolutionImage:CGSizeMake(asset.pixelWidth, asset.pixelHeight)]) {
        syncCallback(nil, YES);
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
            [_imageManager requestImageForAsset:assetModel.asset_PH
                          targetSize:PHImageManagerMaximumSize
                          contentMode:PHImageContentModeDefault
                          options:_fullResolutionRequestOptions
                          resultHandler:^(UIImage *image, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    asyncCallback(image, assetModel);
                });
            }];
        
        });
    }else {
        
        CGFloat scale = [UIScreen mainScreen].scale;
        CGFloat imageHeight = floor((SCREEN_WIDTH/asset.pixelWidth) * asset.pixelHeight);
        CGSize pixSize = CGSizeMake(SCREEN_WIDTH * scale, imageHeight * scale);
        
        [_imageManager requestImageForAsset:assetModel.asset_PH targetSize:pixSize contentMode:PHImageContentModeAspectFill options:_requestOptions resultHandler:^(UIImage *image, NSDictionary *info) {
            asyncCallback(image, assetModel);
        }];
        
    }
 
}




- (void)fetchImageFromAssetModel_AssetLibrary:(LLAssetModel *)assetModel asyncBlock:(nullable LLFetchImageAsyncCallbackBlock)asyncCallback syncBlock:(nullable LLFetchImageSyncCallbackBlock)syncCallback {
    
    NSString *key = [NSString stringWithFormat:@"%ld", assetModel.assetIndex];
    UIImage *image = [_imagesCache objectForKey:key];
    
    if (image) {
        syncCallback(image, NO);
    }else {
        ALAssetRepresentation *representation = [assetModel.asset_AL defaultRepresentation];
        
        //如果图片小，那就直接加载
        if (representation.size <= SIZE_BYTES_THRESHOLD) {
            if ([self needFetchFullResolutionImage:representation.dimensions]) {
                syncCallback(nil, YES);
                [self fetchImageInBackground:assetModel isFullResolution:YES asyncBlock:asyncCallback];
            }else {
                image = [[UIImage alloc] initWithCGImage:[representation fullScreenImage]];
                syncCallback(image, NO);
            }
        //如果图片过大，就先用一张低质量图片，然后后台加载高质量图片
        }else {
            image = [[UIImage alloc] initWithCGImage:assetModel.asset_AL.aspectRatioThumbnail];
            
            if ([self needFetchFullResolutionImage:representation.dimensions]) {
                syncCallback(nil, YES);
                [self fetchImageInBackground:assetModel isFullResolution:YES asyncBlock:asyncCallback];
            }else {
                syncCallback(image, YES);
                [self fetchImageInBackground:assetModel isFullResolution:NO asyncBlock:asyncCallback];
            }
            
        }
        
    }
    
}



- (BOOL)needFetchFullResolutionImage:(CGSize)dimensions {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGFloat maxSize = SCREEN_HEIGHT * scale;
    CGSize imageSize = dimensions;
    if (imageSize.width > maxSize) {
        imageSize.height *= maxSize / imageSize.width;
        imageSize.width = maxSize;
    }
    if (imageSize.height > maxSize) {
        imageSize.width *= maxSize / imageSize.height;
        imageSize.height = maxSize;
    }
    
    
    //fullScreen和原图相差无几，直接返回NO
    if (fabs(dimensions.width - imageSize.width) <= 3)
        return NO;
    
    //原图解码后内存占用过大，则不获取原图以避免内存警告
    if (dimensions.width * dimensions.height * 4 >= MAX_ACCEPT_BITMAP_SIZE)
        return NO;
    
    //如果fullScreen放大倍数不太高，不会造成明显图像失真，则不获取原图
    if (imageSize.width * SCALE_THRESHOLD >= scale * SCREEN_WIDTH)
        return NO;
    
    return YES;
}


- (void)fetchImageInBackground:(LLAssetModel *)assetModel isFullResolution:(BOOL)isFullResolution asyncBlock:(nullable LLFetchImageAsyncCallbackBlock)asyncCallback {
    if ([_loadingAssetIndexes containsObject:@(assetModel.assetIndex)]) return;
    
    __weak typeof(self) weakSelf = self;
    
    void (^fetchImageBlock)() = ^() {
        if (weakSelf == nil)return;
        dispatch_semaphore_wait(weakSelf.semaphore, DISPATCH_TIME_FOREVER);
        
        ALAssetRepresentation *representation = [assetModel.asset_AL defaultRepresentation];
        
        UIImage *image;
        if (isFullResolution) {
            image = [[UIImage alloc] initWithCGImage:[representation fullResolutionImage] scale:representation.scale orientation:(UIImageOrientation)representation.orientation];
        }else {
            image = [[UIImage alloc] initWithCGImage:[representation fullScreenImage]];
        }
        
        
        //照片在子线程中就调整到合适大小，加快绘制
        image = [image resizeImageToSize:CGSizeMake(SCREEN_WIDTH, floor((SCREEN_WIDTH/image.size.width) * image.size.height))];
        NSLog(@"获得了 %ld 的高质量图", assetModel.assetIndex);
        
        NSString *key = [NSString stringWithFormat:@"%ld", assetModel.assetIndex];
        [weakSelf.imagesCache setObject:image forKey:key];
        [weakSelf.loadingAssetIndexes removeObject:@(assetModel.assetIndex)];
        
        dispatch_semaphore_signal(weakSelf.semaphore);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            asyncCallback(image, assetModel);
        });
        
    };
    
    
    [_loadingAssetIndexes addObject:@(assetModel.assetIndex)];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), fetchImageBlock);
}

#pragma mark - 获取照片Data
- (NSData *)fetchImageDataFromAssetModel:(LLAssetModel *)model {
    __block NSData *data;
    if (model.asset_AL) {
        ALAssetRepresentation* assetRepresentation = [model.asset_AL defaultRepresentation];
        Byte* buffer = (Byte*)malloc([assetRepresentation size]);
        NSUInteger bufferSize = [assetRepresentation getBytes:buffer fromOffset:0.0 length:[assetRepresentation size] error:nil];
        data = [NSData dataWithBytesNoCopy:buffer length:bufferSize freeWhenDone:YES];
        
    }else if (model.asset_PH) {
        if (model.asset_PH.mediaType == PHAssetMediaTypeImage) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.version = PHImageRequestOptionsVersionCurrent;
            options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
            options.synchronous = YES;
            [[PHImageManager defaultManager] requestImageDataForAsset:model.asset_PH
                                                              options:options
                                                        resultHandler:
             ^(NSData *imageData,
               NSString *dataUTI,
               UIImageOrientation orientation,
               NSDictionary *info) {
                 data = [NSData dataWithData:imageData];
             }];
        }
    }
    
    return data;
}


- (LLAssetModel *)fetchAssetModelWithURL:(NSURL *)url {
    PHFetchResult<PHAsset *> *result =  [PHAsset fetchAssetsWithALAssetURLs:@[url] options:nil];
    if (!result || result.count == 0) return nil;
    
    PHAsset *asset = [result firstObject];
    LLAssetModel *model = [[LLAssetModel alloc] init];
    model.asset_PH = asset;
    
    return model;
}

-(void)fetchFullScreenImageWithURL:(NSURL *)url asyncBlock:(nullable LLFetchImageAsyncCallbackBlock)asyncCallback syncBlock:(nullable LLFetchImageSyncCallbackBlock)syncCallback {
    LLAssetModel *model = [self fetchAssetModelWithURL:url];
    if (!model)return;
    
    [self fetchImageFromAssetModel_PhotoKit:model
                                 asyncBlock:asyncCallback
                                  syncBlock:syncCallback];

}

- (void)fetchThumbmailImageWithURL:(NSURL *)url pointSize:(CGSize)size completion:(nonnull void (^)(UIImage * _Nullable))completionCallback {
    LLAssetModel *model = [self fetchAssetModelWithURL:url];
    if (!model)return;
    
    [model fetchThumbnailWithPointSize:size
                            completion:completionCallback];
}


#pragma mark - Video -

- (void)getVideoWithAssetModel:(LLAssetModel *)assetModel completion:(void (^)(AVPlayerItem * _Nullable, NSDictionary * _Nullable))completion {
    if (assetModel.asset_PH) {
        [[PHImageManager defaultManager] requestPlayerItemForVideo:assetModel.asset_PH options:nil resultHandler:^(AVPlayerItem * _Nullable playerItem, NSDictionary * _Nullable info) {
            if (completion)
                completion(playerItem,info);
        }];
    }else if (assetModel.asset_AL) {
        ALAsset *alAsset = (ALAsset *)assetModel.asset_AL;
        ALAssetRepresentation *defaultRepresentation = [alAsset defaultRepresentation];
        NSString *uti = [defaultRepresentation UTI];
        NSURL *videoURL = [[alAsset valueForProperty:ALAssetPropertyURLs] valueForKey:uti];
        AVPlayerItem *playerItem = [[AVPlayerItem alloc] initWithURL:videoURL];
        if (completion && playerItem)
            completion(playerItem,nil);
    }
}


- (void)getVideoAssetForAssetModel:(LLAssetModel *)assetModel completion:(void (^)(AVURLAsset *videoAsset))completion {
    if (assetModel.asset_PH) {
        PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
        options.version = PHVideoRequestOptionsVersionOriginal;
        options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
        options.networkAccessAllowed = NO;
        [[PHImageManager defaultManager] requestAVAssetForVideo:assetModel.asset_PH options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
            AVURLAsset *videoAsset = (AVURLAsset*)avasset;
            if (completion)
                completion(videoAsset);
        }];
    }else if (assetModel.asset_AL) {
        NSURL *videoURL =[assetModel.asset_AL valueForProperty:ALAssetPropertyAssetURL];
        AVURLAsset *videoAsset = [[AVURLAsset alloc]initWithURL:videoURL options:nil];
        if (completion)
            completion(videoAsset);
    }
}


#pragma clang diagonstic pop

@end
