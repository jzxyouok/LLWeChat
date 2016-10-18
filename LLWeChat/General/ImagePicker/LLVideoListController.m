//
//  LLVideoListController.m
//  LLWeChat
//
//  Created by GYJZH on 9/18/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLVideoListController.h"
#import "LLUtils.h"
#import "LLPhotoToolbar.h"
#import "LLImagePickerController.h"
#import "LLVideoCell.h"
#import "LLVideoPlayController.h"

#define NUM_PER_ROW 4
#define CELL_INTEVEL 4.0

#define COLLECTION_CELL_ID @"ID"

@interface LLVideoListController () <UICollectionViewDelegate, UICollectionViewDataSource>

@property (nonatomic) UICollectionView *collectionView;

@property (nonatomic) LLPhotoToolbar *toolBar;

@end

@implementation LLVideoListController {
    CGFloat cellWidth;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barStyle = UIBarStyleBlack;
    
    //right item
    UIBarButtonItem *cancalItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(doCancel)];
    [cancalItem setTitlePositionAdjustment:UIOffsetMake(-6, 0) forBarMetrics:UIBarMetricsDefault];
    [cancalItem setTitleTextAttributes:@{
                                         NSFontAttributeName: [UIFont systemFontOfSize:16]
                                         } forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = cancalItem;
    
    navigationBar.titleTextAttributes = @{
                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:18]
                                          };
    
    self.title = self.groupModel.assetsGroupName;
    
    cellWidth = floor((SCREEN_WIDTH - (NUM_PER_ROW + 1) * CELL_INTEVEL) / NUM_PER_ROW);
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.itemSize = CGSizeMake(cellWidth, cellWidth);
    flowLayout.minimumLineSpacing = CELL_INTEVEL;
    flowLayout.minimumInteritemSpacing = 0;
    flowLayout.sectionInset = UIEdgeInsetsMake(CELL_INTEVEL, CELL_INTEVEL, 0, CELL_INTEVEL);
    
    self.collectionView = [[UICollectionView alloc] initWithFrame:SCREEN_FRAME collectionViewLayout:flowLayout];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.collectionView];
    
    [self.collectionView registerClass:[LLVideoCell class] forCellWithReuseIdentifier:COLLECTION_CELL_ID];

    self.toolBar = [[LLPhotoToolbar alloc] initWithStyle:kLLPhotoToolbarStyle1];
    [self.view addSubview:self.toolBar];
    
    [self fetchData];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)doCancel {
    [(LLImagePickerController *)(self.navigationController) didCancelPickingImages];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}


- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    NSInteger count = self.groupModel.allAssets.count;
    if (count > 1) {
        [self.collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:count - 1 inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
    }
    
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - 获取数据

- (void)fetchData {
    [[LLAssetManager sharedAssetManager] fetchAllAssetsInGroup:self.groupModel successBlock:^(LLAssetsGroupModel * _Nonnull groupModel) {
        [self.collectionView reloadData];
    } failureBlock:^(NSError * _Nullable error) {
        ;
    }];
    
}



#pragma mark - Data Source - 

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.groupModel.allAssets.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    LLVideoCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:COLLECTION_CELL_ID forIndexPath:indexPath];
    cell.assetModel = self.groupModel.allAssets[indexPath.item];
    
    return cell;
}


#pragma mark - Delegate -

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:NO];
    
    LLVideoCell *cell = (LLVideoCell *)[collectionView cellForItemAtIndexPath:indexPath];
    LLVideoPlayController *vc = [[LLVideoPlayController alloc] init];
    vc.assetModel = cell.assetModel;
    vc.assetGroupModel = self.groupModel;
    
    [self.navigationController pushViewController:vc animated:YES];
}



@end
