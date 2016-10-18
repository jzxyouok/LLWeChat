//
//  LLAssetsListController.m
//  LLPickImageDemo
//
//  Created by GYJZH on 6/25/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLImagesListController.h"
#import "LLAssetCell.h"
#import "LLPictureNumberView.h"
#import "LLImagePreviewController.h"
#import "LLPhotoToolbar.h"
#import "LLAssetManager.h"
#import "LLImagePickerController.h"
#import "LLConfig.h"
#import "LLUtils.h"

#define NUM_PER_ROW 4
#define CELL_INTEVEL 4.0


@interface LLImagesListController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) UITableView *tableView;
@property (nonatomic) LLPhotoToolbar *toolBar;

@end

@implementation LLImagesListController {
    CGFloat cellWidth;
    NSInteger totalRows;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    self.allSelectdAssets = [[NSMutableArray alloc] init];
    
    return self;
}


- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.groupModel.assetsGroupName;
    
    totalRows = 0;
    cellWidth = (SCREEN_WIDTH - (NUM_PER_ROW + 1) * CELL_INTEVEL) / NUM_PER_ROW;
    
    [self setupSubView];
    
    [self fetchData];
    
}


- (void)setupSubView {
    //UINavigationBar
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.barStyle = UIBarStyleBlack;
    
    //right item
    UIBarButtonItem *cancalItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(doCancel)];
    [cancalItem setTitlePositionAdjustment:UIOffsetMake(-6, 0) forBarMetrics:UIBarMetricsDefault];
//    [cancalItem setTitleTextAttributes:@{
//                                         NSFontAttributeName: [UIFont systemFontOfSize:16]
//                                         } forState:UIControlStateNormal];
    self.navigationItem.rightBarButtonItem = cancalItem;
    
//    navigationBar.titleTextAttributes = @{
//                                          NSFontAttributeName: [UIFont boldSystemFontOfSize:18]
//                                          };
    
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([UIScreen mainScreen].bounds), CGRectGetHeight([UIScreen mainScreen].bounds)) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 44, 0);
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 44, 0);
    self.tableView.rowHeight = cellWidth + CELL_INTEVEL;
    [self.view addSubview:self.tableView];
    
    self.toolBar = [[LLPhotoToolbar alloc] initWithStyle:kLLPhotoToolbarStyle1];
    [self.toolBar addTarget:self previewAction:@selector(doPreview) finishAction:@selector(doFinish)];
    [self.view addSubview:self.toolBar];

}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
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
        totalRows = ceil((double)groupModel.allAssets.count / NUM_PER_ROW);
        [self.tableView reloadData];
    } failureBlock:^(NSError * _Nullable error) {
        ;
    }];
    
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    CGFloat alpha = self.navigationController.navigationBar.subviews[0].alpha;
    __weak typeof(self) weakSelf = self;
    if (alpha < 1) {
        [UIView animateWithDuration:0.2 animations:^{
            weakSelf.navigationController.navigationBar.subviews[0].alpha = 1;
        }];
        
        self.toolBar.number = self.allSelectdAssets.count;
        [self.tableView reloadData];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (totalRows > 1) {
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:totalRows-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    
}


- (void)doFinish {
     [(LLImagePickerController *)self.navigationController didFinishPickingImages:self.allSelectdAssets WithError:nil assetGroupModel:self.groupModel];
}

- (void)doCancel {
    [(LLImagePickerController *)self.navigationController didCancelPickingImages];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
   return 1;
//    NSLog(@"numberOfSections");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    NSLog(@"tableView numberOfRowsInSection");
    return totalRows;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    NSLog(@"Get Cell %ld", indexPath.row);
    
    static NSString *ID = @"CELL";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:ID];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:ID];
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        for (int i = 0; i < NUM_PER_ROW; i++) {
            LLAssetCell *assetCell = [[LLAssetCell alloc] initWithFrame:CGRectMake(CELL_INTEVEL + (CELL_INTEVEL + cellWidth) * i, CELL_INTEVEL, cellWidth, cellWidth)];
            assetCell.tag = 10 + i;
            [cell addSubview:assetCell];
            [assetCell addTarget:self selectAction:@selector(handleAssetCellSelect:) showAction:@selector(handleAssetCellShow:)];

        }
    }
    
    NSInteger from = indexPath.row * NUM_PER_ROW;
    NSInteger end = MIN(from + NUM_PER_ROW, _groupModel.allAssets.count);
    
    NSInteger j = 0;
    for (NSInteger i=from; i<end; i++, j++) {
        LLAssetCell *assetCell = [cell viewWithTag:10+j ];
        assetCell.assetModel = _groupModel.allAssets[i];
        assetCell.selected = [self.allSelectdAssets containsObject:_groupModel.allAssets[i]];
        assetCell.hidden = NO;
    }
    
    for(; j< NUM_PER_ROW; j++) {
        LLAssetCell *assetCell = [cell viewWithTag:10+j ];
        assetCell.hidden = YES;
    }

    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (BOOL)handleAssetCellSelect:(LLAssetCell *)cell {
    if (!cell.isSelected) {
        if (self.allSelectdAssets.count == MAX_PHOTOS_CAN_SELECT) {
            [LLUtils showMessageAlertWithTitle:nil message:[NSString stringWithFormat:@"最多选择%d张照片", MAX_PHOTOS_CAN_SELECT] actionTitle:@"我知道了"];
            return NO;
        }else if (![self.allSelectdAssets containsObject:cell.assetModel]) {
            [self.allSelectdAssets addObject:cell.assetModel];
        }
    }else if (cell.isSelected && [self.allSelectdAssets containsObject:cell.assetModel]) {
        [self.allSelectdAssets removeObject:cell.assetModel];
    }
    
    self.toolBar.number = self.allSelectdAssets.count;
    
    return YES;
}

- (void)doPreview {
    LLImagePreviewController *previewController = [[LLImagePreviewController alloc] init];
    
    previewController.assetGroupModel = self.groupModel;
    previewController.allSelectdAssets = self.allSelectdAssets;
    previewController.curShowAsset = self.allSelectdAssets[0];
    previewController.allAssets = [self.allSelectdAssets copy];
    
    [self.navigationController pushViewController:previewController animated:YES];
}

- (void)handleAssetCellShow:(LLAssetCell *)cell {
    LLImagePreviewController *previewController = [[LLImagePreviewController alloc] init];
    
    previewController.assetGroupModel = self.groupModel;
    previewController.curShowAsset = cell.assetModel;
    previewController.allSelectdAssets = self.allSelectdAssets;
    previewController.allAssets = self.groupModel.allAssets;
    
    [self.navigationController pushViewController:previewController animated:YES];
}


@end
