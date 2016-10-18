//
//  LLAlbumListController.m
//  LLPickImageDemo
//
//  Created by GYJZH on 6/28/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLAlbumListController.h"
#import "LLImagesListController.h"
#import "LLAssetManager.h"
#import "LLImagePickerController.h"
#import "LLVideoListController.h"
#import "LLUtils.h"


#define TABLE_CELL_HEIGHT 57

@interface LLImagePickerTableViewCell : UITableViewCell

@end

@implementation LLImagePickerTableViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGRect imgFrame = self.imageView.frame;
    imgFrame.origin.x = 0;
    self.imageView.frame = imgFrame;
    
    CGRect textFrame = self.textLabel.frame;
    self.textLabel.frame = CGRectMake(CGRectGetMaxX(imgFrame)+7, CGRectGetMinY(textFrame), CGRectGetWidth(textFrame), CGRectGetHeight(textFrame));
}

@end



@interface LLAlbumListController ()


@end

@implementation LLAlbumListController {
    CGSize posterImageSize;
}

- (instancetype)initWithStyle:(UITableViewStyle)style {
    self = [super initWithStyle:style];
    if (self) {
        posterImageSize = CGSizeMake(TABLE_CELL_HEIGHT, TABLE_CELL_HEIGHT);
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"照片";
    
    [self setupViews];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)setupViews {
    self.navigationItem.hidesBackButton = YES;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStyleDone target:self action:@selector(doCancel)];
//    [item setTitleTextAttributes:@{
//                                   NSFontAttributeName:[UIFont systemFontOfSize:16]
//                                   } forState:UIControlStateNormal];
    [item setTitlePositionAdjustment:UIOffsetMake(-6, 0) forBarMetrics:UIBarMetricsDefault];
    
    self.navigationItem.rightBarButtonItem = item;
    
//    UINavigationBar *navigationBar = self.navigationController.navigationBar;
//    navigationBar.translucent = YES;
//    navigationBar.barStyle = UIBarStyleBlack;
//    navigationBar.barTintColor = [UIColor blackColor];
//    navigationBar.tintColor = [UIColor whiteColor];
//    self.navigationController.navigationBar.titleTextAttributes = @{
//                                                                    NSFontAttributeName:[UIFont boldSystemFontOfSize:18],
//                                                                    NSForegroundColorAttributeName: [UIColor whiteColor],
//                                                                    };
    
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 10, 0, 0);
    
    UIBarButtonItem *backItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
//    [backItem setTitleTextAttributes:@{
//                                       NSFontAttributeName: [UIFont systemFontOfSize:16]
//                                       } forState:UIControlStateNormal];
    
//    [backItem setBackButtonTitlePositionAdjustment:UIOffsetMake(-3, 0) forBarMetrics:UIBarMetricsDefault];
    self.navigationItem.backBarButtonItem = backItem;
    self.tableView.rowHeight = TABLE_CELL_HEIGHT;
}



- (void)fetchDataComplete {
    [self.tableView reloadData];
}


- (void)doCancel {
    [(LLImagePickerController *)(self.navigationController) didCancelPickingImages];
}

//- (void)doBack {
//    [self.navigationController popViewControllerAnimated:YES];
//}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [LLAssetManager sharedAssetManager].allAssetsGroups.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *ID = @"Cell";
    LLImagePickerTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    
    if (cell == nil) {
        cell = [[LLImagePickerTableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:ID];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        
    }
    
    LLAssetsGroupModel *groupModel = [LLAssetManager sharedAssetManager].allAssetsGroups[indexPath.row];
    NSString *countStr = [NSString stringWithFormat:@"(%ld)", groupModel.numberOfAssets];
    NSString *str = [NSString stringWithFormat:@"%@  %@", groupModel.assetsGroupName, countStr];
    NSMutableAttributedString *attributeString = [[NSMutableAttributedString alloc] initWithString:str];
    
    NSRange range = [str rangeOfString:countStr];
    [attributeString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range: range];
    [attributeString addAttribute:NSFontAttributeName value:[UIFont boldSystemFontOfSize:17] range: NSMakeRange(0, range.location-2)];
    
    
    cell.textLabel.attributedText = attributeString;
    
    [groupModel fetchPosterImageWithPointSize:posterImageSize completeBlock:^(UIImage *image) {
        cell.imageView.image = image;
    }];
    
    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    LLAssetsGroupModel *model = [LLAssetManager sharedAssetManager].allAssetsGroups[indexPath.row];
    
    if (model.isVideoGroup) {
        LLVideoListController *videoListVC = [[LLVideoListController alloc] init];
        videoListVC.groupModel = model;
        
        [self.navigationController pushViewController:videoListVC animated:YES];
        
    }else {
        LLImagesListController *imageListVC = [[LLImagesListController alloc] init];
        imageListVC.groupModel = model;
        
        [self.navigationController pushViewController:imageListVC animated:YES];
    }
    
}



@end
