//
//  LLPhotoAlbumController.m
//  LLPickImageDemo
//
//  Created by GYJZH on 6/24/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLImagePickerController.h"
#import "LLAlbumListController.h"
#import "LLImagesListController.h"
#import "LLAssetManager.h"
#import "LLVideoListController.h"
#import "LLUtils.h"

NSString *const LLImagePickerControllerReferenceURL = @"LLImagePickerControllerReferenceURL";

NSString *const LLImagePickerControllerThumbnailImage = @"LLImagePickerControllerThumbnailImage";

static NSString *lastAssertGroupIdentifier;

@interface LLRootViewController : UIViewController

@property (nonatomic) UILabel *label;

@end


@implementation LLRootViewController

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.view.backgroundColor = [UIColor whiteColor];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGFloat _width = SCREEN_WIDTH * 0.8;
    _label = [[UILabel alloc] initWithFrame:CGRectMake((SCREEN_WIDTH - _width)/2, 128, _width, 64)];
    _label.numberOfLines = 0;
    _label.textAlignment = NSTextAlignmentCenter;
    _label.font = [UIFont systemFontOfSize:16];
    _label.textColor = [UIColor blackColor];
    NSString *appName = [LLUtils appName];
    _label.text = [NSString stringWithFormat:@"请在IPhone的“设置-隐私-照片”选项中，允许%@访问你的手机相册", appName];
    _label.hidden = YES;
    [self.view addSubview:_label];
    
    self.title = @"";
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(dismissSelf:)];
    self.navigationItem.rightBarButtonItem = rightItem;


}

- (void)dismissSelf:(id)sender {
    LLImagePickerController *picker = (LLImagePickerController *)(self.navigationController);
    [picker.pickerDelegate imagePickerControllerDidCancel:picker];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}


@end



@interface LLImagePickerController ()

@property (nonatomic) LLRootViewController *rootViewController;

@property (nonatomic) LLAlbumListController *albumVC;

@end

@implementation LLImagePickerController

@dynamic delegate;

- (instancetype)init {
    self.rootViewController = [[LLRootViewController alloc] initWithNibName:nil bundle:nil];
    self = [super initWithRootViewController:self.rootViewController];
    if (self) {
        UINavigationBar *navigationBar = self.navigationBar;
        navigationBar.translucent = YES;
//        navigationBar.barStyle = UIBarStyleBlack;
//        navigationBar.barTintColor = [UIColor blackColor];
//        navigationBar.tintColor = [UIColor whiteColor];
        
        [self chechAuthorizationStatus];
    }
    
    return self;
}


- (void)chechAuthorizationStatus {
    __weak typeof(self) weakSelf = self;
    LLCheckAuthorizationCompletionBlock block = ^(LLAuthorizationType type) {
        switch (type) {
            case kLLAuthorizationTypeAuthorized:
            {
                _albumVC = [[LLAlbumListController alloc] initWithStyle:UITableViewStylePlain];
                [weakSelf pushViewController:_albumVC animated:NO];
                [weakSelf fetchAlbumData];
            }
                break;
            case kLLAuthorizationTypeDenied:
            case kLLAuthorizationTypeRestricted:
            {
                [weakSelf popToRootViewControllerAnimated:YES];
                weakSelf.rootViewController.label.hidden = NO;
            }
                break;
            default:
                break;
        }
    };
    
    [[LLAssetManager sharedAssetManager] chechAuthorizationStatus:block];

}

- (void)viewDidLoad {
    [super viewDidLoad];

}


- (void)fetchAlbumData {
    WEAK_SELF;
    LLFetchAssetsGroupsSuccessBlock successBlock = ^() {
        LLAssetsGroupModel *model = [[LLAssetManager sharedAssetManager] assetsGroupModelForLocalIdentifier:lastAssertGroupIdentifier];
        
        if (model.isVideoGroup) {
            LLVideoListController *videoListVC = [[LLVideoListController alloc] init];
            videoListVC.groupModel = model;
            
            [weakSelf pushViewController:videoListVC animated:YES];
            
        }else {
            LLImagesListController *imageListVC = [[LLImagesListController alloc] init];
            imageListVC.groupModel = model;
            
            [weakSelf pushViewController:imageListVC animated:YES];
        }
        
        [weakSelf.albumVC fetchDataComplete];
    };
    
    LLFetchAssetsGroupsFailureBlock failureBlock = ^(NSError * _Nullable error) {
    };
    
    [[LLAssetManager sharedAssetManager] fetchAllAssetsGroups:successBlock failureBlock:failureBlock];
}

- (void)didFinishPickingImages:(NSArray<LLAssetModel *> *)assets WithError:(NSError *)error assetGroupModel:(LLAssetsGroupModel *)assetGroupModel {
    lastAssertGroupIdentifier = assetGroupModel.localIdentifier;
    
    [self prepareForDismiss];
    [self.pickerDelegate imagePickerController:self didFinishPickingImages:assets withError:error];
}

- (void)didCancelPickingImages {
    [self prepareForDismiss];
    [self.pickerDelegate imagePickerControllerDidCancel:self];
}

- (void)didFinishPickingVideo:(NSString *)videoPath assetGroupModel:(LLAssetsGroupModel *)assetGroupModel {
//    SAFE_SEND_MESSAGE(self.pickerDelegate, imagePickerController:didFinishPickingVideo:) {
    lastAssertGroupIdentifier = assetGroupModel.localIdentifier;
        [self.pickerDelegate imagePickerController:self didFinishPickingVideo:videoPath];
//    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)prepareForDismiss {
    [LLAssetManager destroyAssetManager];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}



@end
