//
//  LLChatViewController.m
//  LLWeChat
//
//  Created by GYJZH on 7/21/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLChatViewController.h"
#import "LLConfig.h"
#import "LLMessageTextCell.h"
#import "LLMessageDateCell.h"
#import "LLMessageRecordingCell.h"
#import "LLChatInputView.h"
#import "LLChatManager.h"
#import "LLUtils.h"
#import "UIKit+LLExt.h"
#import "LLMessageCellActionDelegate.h"
#import "LLWebViewController.h"
#import "LLActionSheet.h"
#import "LLMessageImageCell.h"
#import "LLChatAssetDisplayController.h"
#import "LLImagePickerControllerDelegate.h"
#import "LLChatShareDelegate.h"
#import "LLAssetManager.h"
#import "LLImagePickerController.h"
#import "LLMessageGifCell.h"
#import "LLChatImageScrollView.h"
#import "LLGaoDeLocationViewController.h"
#import "LLMessageLocationCell.h"
#import "LLLocationShowController.h"
#import "LLAudioManager.h"
#import "LLAudioRecordDelegate.h"
#import "LLAudioPlayDelegate.h"
#import "LLNavigationController.h"
#import "LLTipView.h"
#import "LLMessageVoiceCell.h"
#import "LLMessageVideoCell.h"
#import "UIImagePickerController_L1.h"
#import "LLDeviceManager.h"
#import "LLBottomTipView.h"
#import "LLMessageCellManager.h"
#import "LLImageAnimationView.h"
#import "LLChatMoreBottomBar.h"
#import "LLChatSharePanel.h"
#import "LLSightCapatureController.h"

#import "EMSDK.h"
#import "LLMessageAttachmentDownloader.h"

@import AddressBookUI;
@import MediaPlayer;


@interface LLChatViewController () <UITableViewDelegate, UITableViewDataSource,
         UIScrollViewDelegate, LLMessageCellActionDelegate, LLChatImagePreviewDelegate,LLImagePickerControllerDelegate,LLChatShareDelegate, LLLocationViewDelegate, LLAudioRecordDelegate, LLAudioPlayDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, LLChatManagerMessageListDelegate, LLDeviceManagerDelegate, LLSightCapatureControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet LLChatInputView *chatInputView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *chatInputViewBottomConstraint;

@property (nonatomic) NSMutableArray<LLMessageModel *> *dataSource;

@property (strong, nonatomic) IBOutlet UIView *refreshView;

@property (strong, nonatomic) IBOutlet LLBottomTipView *bottomTipView;

@property (nonatomic) UIImagePickerController_L1 *imagePicker;

@property (nonatomic) LLVoiceIndicatorView *voiceIndicatorView;

@property (nonatomic) LLChatMoreBottomBar *chatMoreBottomBar;
@property (nonatomic) LLChatSharePanel *chatSharePanel;

@property (nonatomic) NSMutableArray<LLMessageModel *> *selectedMessageModels;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewBottomConstraint;


@end

@implementation LLChatViewController {
    BOOL navigationBarTranslucent;
    UITapGestureRecognizer *tapGesture;
    NSArray *rightBarButtonItems;
    BOOL isPulling;
    BOOL isLoading;
    
    NSInteger countDown;
    LLSightCapatureController *_sightController;
}


#pragma mark - UI/LifeCycle 相关 -

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = kLLBackgroundColor_gray;
    self.automaticallyAdjustsScrollViewInsets = NO;
    self.tableView.backgroundColor = kLLBackgroundColor_lightGray;
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    
    self.navigationItem.title = self.conversationModel.nickName;
    
    UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithTitle:@"Debug1" style:UIBarButtonItemStylePlain target:self action:@selector(debug1:)];
    
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"Debug2" style:UIBarButtonItemStylePlain target:self action:@selector(debug2:)];
    rightBarButtonItems = @[item, item2];
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    
    tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    tapGesture.numberOfTapsRequired = 1;
    tapGesture.numberOfTouchesRequired = 1;
    [self.tableView addGestureRecognizer:tapGesture];
    
    self.chatInputView.delegate = self;
    self.dataSource = [NSMutableArray array];
    
    self.refreshView.backgroundColor = kLLBackgroundColor_lightGray;
    isPulling = NO;
    isLoading = NO;
    
//    [self fetchMessageList];
}

- (void)updateViewConstraints {
    self.tableViewHeightConstraint.constant = SCREEN_HEIGHT - 64 - TABBAR_HEIGHT;
    
    [super updateViewConstraints];
    
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    self.refreshView.frame = CGRectMake(0, 0, SCREEN_WIDTH, 40);
    self.bottomTipView.frame = CGRectMake(0, 64, SCREEN_WIDTH, 45);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    self.chatInputView.delegate = self;
    [[LLChatManager sharedManager] markAllMessagesAsRead:self.conversationModel];
    [self.chatInputView registerKeyboardNotification];
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan=NO;
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [self.chatInputView unregisterKeyboardNotification];
    
    self.navigationController.interactivePopGestureRecognizer.delaysTouchesBegan=YES;
    [self stopPlayingVoiceWhenExit];
    [self cleanMessageModelWhenExit];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self registerApplicationNotification];
    [self registerChatManagerNotification];
    
    navigationBarTranslucent = self.navigationController.navigationBar.translucent;
    self.navigationController.navigationBar.translucent = YES;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //后退
    if (![self.navigationController.childViewControllers containsObject:self]) {
        UIActivityIndicatorView *indicator = self.refreshView.subviews[0];
        [indicator stopAnimating];
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        //后退时停止tableview滚动
        [self.tableView setContentOffset:self.tableView.contentOffset animated:NO];
        
        self.chatInputView.delegate = nil;
        
        isLoading = NO;
        isPulling = NO;
    }
    
    self.navigationController.navigationBar.translucent = navigationBarTranslucent;
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - Download/Upload -

- (void)registerChatManagerNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageUploadHandler:) name:LLMessageUploadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(messageDownloadHandler:) name:LLMessageDownloadStatusChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDownloadCompleteHandler:) name:LLMessageThumbnailDownloadCompleteNotification object:nil];

}

- (void)registerApplicationNotification {
    
}


- (void)dealloc {
    [_sightController.contentView.layer removeObserver:self forKeyPath:@"position"];
}

- (void)thumbnailDownloadCompleteHandler:(NSNotification *)notification {
    LLMessageModel *messageModel = notification.userInfo[LLChatManagerMessageModelKey];
    if (!messageModel)
        return;
    
    WEAK_SELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        LLMessageBaseCell *baseCell = [weakSelf visibleCellForMessageModel:messageModel];
        if (!baseCell) {
            messageModel.needsUpdateCell = YES;
            return;
        }
        
        messageModel.needsUpdateCell = NO;
        switch (messageModel.messageBodyType) {
            case kLLMessageBodyTypeVideo:
            case kLLMessageBodyTypeImage:
                [baseCell updateMessageThumbnail];
                break;
            default:
                break;
        }
    });

}

- (void)messageUploadHandler:(NSNotification *)notification {
    LLMessageModel *messageModel = notification.userInfo[LLChatManagerMessageModelKey];
    if (!messageModel)
        return;
    
    WEAK_SELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        LLMessageBaseCell *baseCell = [weakSelf visibleCellForMessageModel:messageModel];
        if (!baseCell) {
            messageModel.needsUpdateCell = YES;
            return;
        }
        
        messageModel.needsUpdateCell = NO;
        [baseCell updateMessageUploadStatus];
        
    });

}

- (void)messageDownloadHandler:(NSNotification *)notification {
    LLMessageModel *messageModel = notification.userInfo[LLChatManagerMessageModelKey];
    if (!messageModel)
        return;
    
    //派发下载错误提示
    if (messageModel.messageDownloadStatus == kLLMessageDownloadStatusFailed && messageModel.messageBodyType == kLLMessageBodyTypeVideo && self.navigationController.visibleViewController == self) {
        [LLUtils showMessageAlertWithTitle:nil message:@"下载失败" actionTitle:@"我知道了"];
    }
    
    WEAK_SELF;
    dispatch_async(dispatch_get_main_queue(), ^{
        LLMessageBaseCell *baseCell = [weakSelf visibleCellForMessageModel:messageModel];
        if (!baseCell) {
            messageModel.needsUpdateCell = YES;
            return;
        }
        
        messageModel.needsUpdateCell = NO;
        [baseCell updateMessageDownloadStatus];
    });
    
}


#pragma mark - 获取聊天数据
     
- (void)fetchMessageList {
    [LLChatManager sharedManager].messageListDelegate = self;
    self.conversationModel.referenceMessageModel = nil;
    [[LLChatManager sharedManager] asynLoadMoreMessagesForConversationModel:self.conversationModel maxCount:MESSAGE_LIMIT_FOR_ONE_FETCH isDirectionUp:YES];
}

- (void)loadMoreMessagesDidFinishedWithConversationModel:(LLConversationModel *)aConversationModel {
    if ((aConversationModel != self.conversationModel) && ![aConversationModel.conversationId isEqualToString:self.conversationModel.conversationId]) {
        return;
    }
    
    LLMessageBaseCell *cell;
    LLMessageModel *pullCellModel;
    CGFloat pullCellPointY = 0;
    for (UITableViewCell *item in self.tableView.visibleCells) {
        if ([item isKindOfClass:[LLMessageBaseCell class]]) {
            cell = (LLMessageBaseCell *)item;
            pullCellModel = cell.messageModel;
            pullCellPointY = [cell convertPoint:CGPointZero toView:self.view].y;
            break;
        }
    }
    
    if (aConversationModel.updateType == kLLMessageListUpdateTypeLoadMore) {
        if (!self.tableView.tableHeaderView) {
            self.tableView.tableHeaderView = self.refreshView;
        }
    }else if (aConversationModel.updateType == kLLMessageListUpdateTypeLoadMoreComplete) {
        self.tableView.tableHeaderView = nil;
    }

    self.conversationModel = aConversationModel;
    self.dataSource = [self processData:self.conversationModel];
    
    if (self.tableView.visibleCells.count == 0) {
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        
        [self scrollToBottom:NO];
    }else if (aConversationModel.updateType == kLLMessageListUpdateTypeNewMessage) {
        BOOL shouldScroolToBottom = [self shouldScrollToBottomForNewMessage];
        
        [self.tableView reloadData];
        [self.tableView layoutIfNeeded];
        
        if (shouldScroolToBottom) {
            [self scrollToBottom:YES];
        }
    }else {
        [self.tableView reloadData];
        
        NSInteger index = [self.dataSource indexOfObject:pullCellModel];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
        
        LLMessageBaseCell *newCell = [self.tableView cellForRowAtIndexPath:indexPath];
        
        CGFloat _offsetY = self.tableView.contentOffset.y;
        CGFloat _cellYInView = [newCell convertPoint:CGPointZero toView:self.view].y;
        CGFloat newoffsetY = _offsetY + (_cellYInView - pullCellPointY);
        if (newoffsetY < -64)
            newoffsetY = -64;
        
        [self.tableView setContentOffset:CGPointMake(0, newoffsetY) animated:NO];
        
        UIActivityIndicatorView *indicator = self.refreshView.subviews[0];
        [indicator stopAnimating];
        
        [self performSelectorOnMainThread:@selector(pullToRefreshFinished) withObject:nil waitUntilDone:NO];
    }

}

- (LLConversationModel *)currentConversationModel {
    return self.conversationModel;
}

- (BOOL)shouldScrollToBottomForNewMessage {
    CGFloat _h = self.tableView.contentSize.height - self.tableView.contentOffset.y - (CGRectGetHeight(self.tableView.frame) - self.tableView.contentInset.bottom);
    
    return _h <= 66 * 4;
}

#pragma mark - 下拉刷新
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.tableView.tableHeaderView && !isLoading &&!isPulling && (scrollView.isDragging || scrollView.isDecelerating) && scrollView.contentOffset.y <= 20 - scrollView.contentInset.top && self.conversationModel.allMessageModels.count > 0) {
        isPulling = YES;
        UIActivityIndicatorView *indicator = self.refreshView.subviews[0];
        if (![indicator isAnimating]) {
            [indicator startAnimating];
        }
    }
    
    if (_sightController) {
        [_sightController scrollViewPanGestureRecognizerStateChanged:scrollView.panGestureRecognizer];
    }
    
}

- (void)loadMoreMessagesAfterDeletionIfNeeded {
    if (self.tableView.tableHeaderView && !isLoading &&!isPulling && self.tableView.contentOffset.y <= 20 - self.tableView.contentInset.top) {
        UIActivityIndicatorView *indicator = self.refreshView.subviews[0];
        if (![indicator isAnimating]) {
            [indicator startAnimating];
        }
        [self pullToRefresh];
    }
}

- (void)pullToRefresh {
    isPulling = NO;
    isLoading = YES;
    
    NSLog(@"开始下拉刷新");
    self.conversationModel.referenceMessageModel = self.conversationModel.allMessageModels.count > 0 ? self.conversationModel.allMessageModels[0] : nil;
    [[LLChatManager sharedManager] asynLoadMoreMessagesForConversationModel:self.conversationModel maxCount:MESSAGE_LIMIT_FOR_ONE_FETCH isDirectionUp:YES];

}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    if (!isLoading && isPulling) {
        [self pullToRefresh];
    }
    
    if (scrollView == self.tableView) {
        for (UITableViewCell *cell in self.tableView.visibleCells) {
            if ([cell isKindOfClass:[LLMessageBaseCell class]]) {
                LLMessageBaseCell *chatCell = (LLMessageBaseCell *)cell;
                [chatCell didEndScrolling];
            }
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (isPulling) {
        [self pullToRefresh];
    }
    
    if (_sightController) {
        [_sightController scrollViewPanGestureRecognizerStateChanged:scrollView.panGestureRecognizer];
    }
}

- (void)pullToRefreshFinished {
    isLoading = NO;
}

- (NSMutableArray<LLMessageModel *> *)processData:(LLConversationModel *)conversationModel {
    NSMutableArray<LLMessageModel *> *messageList = [NSMutableArray array];
    NSArray<LLMessageModel *> *models = conversationModel.allMessageModels;
    for (NSInteger i = 0; i < models.count; i++) {
        if (i == 0 || (models[i].timestamp - models[i-1].timestamp > CHAT_CELL_TIME_INTERVEL)) {
            LLMessageModel *model = [[LLMessageModel alloc] initWithType:kLLMessageBodyTypeDateTime];
            model.timestamp = models[i].timestamp;
            [messageList addObject:model];
        }
        [messageList addObject:models[i]];
    }
    
    return messageList;
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  //  NSLog(@"numberOfSections");
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    NSLog(@"numberOfRows %ld", self.dataSource.count);
    return self.dataSource.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    [UIView setAnimationsEnabled:NO];
    LLMessageModel *messageModel = self.dataSource[indexPath.row];
    NSString *reuseId = [[LLMessageCellManager sharedManager] reuseIdentifierForMessegeModel:messageModel];
    UITableViewCell *_cell;

    switch (messageModel.messageBodyType) {
        case kLLMessageBodyTypeText:
        case kLLMessageBodyTypeVideo:
        case kLLMessageBodyTypeVoice:
        case kLLMessageBodyTypeImage:
        case kLLMessageBodyTypeLocation: {
            LLMessageBaseCell *cell = [[LLMessageCellManager sharedManager] staticReusableCellForMessageModel:messageModel];
            cell.delegate = self;
            _cell = cell;
            break;
        }
        case kLLMessageBodyTypeDateTime: {
            LLMessageDateCell *cell = [[LLMessageDateCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
            cell.messageModel = messageModel;
            _cell = cell;
            break;
        }
        case kLLMessageBodyTypeGif: {
            LLMessageGifCell *cell = [tableView dequeueReusableCellWithIdentifier: reuseId];
            if (!cell) {
                cell = [[LLMessageGifCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
                [cell prepareForUse:messageModel.isFromMe];
            }
            
            cell.messageModel = messageModel;
            cell.delegate = self;
            _cell = cell;
            break;
        }
        case kLLMessageBodyTypeRecording: {
            LLMessageRecordingCell *cell = [LLMessageRecordingCell sharedRecordingCell];
            cell.messageModel = messageModel;
            
            _cell = cell;
            break;
        }
        default:
            break;
    }
    
    if (messageModel.needsUpdateCell) {
        messageModel.needsUpdateCell = NO;
        ((LLMessageBaseCell *)_cell).messageModel = messageModel;
    }
    if ([_cell isKindOfClass:[LLMessageBaseCell class]]) {
        [(LLMessageBaseCell *)_cell setCellEditingAnimated:NO];
        
        if ([_cell isKindOfClass:[LLMessageLocationCell class]]) {
            if ([messageModel.address isEqualToString:LOCATION_UNKNOWE_ADDRESS] && !messageModel.isFetchingAddress) {
                WEAK_SELF;
                messageModel.isFetchingAddress = YES;
                [[LLChatManager sharedManager] asynReGeocodeMessageModel:messageModel completion:^(LLMessageModel *messageModel, LLError *error) {
                    messageModel.isFetchingAddress = NO;
                    [weakSelf reloadTableRowWithModel:messageModel];
                }];
            }
        }
    }
    
    [UIView setAnimationsEnabled:YES];
    return _cell;
    
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    LLMessageModel *messageModel = self.dataSource[indexPath.row];
  //  NSLog(@"Index row height %ld %.2f", indexPath.row, messageModel.cellHeight);
    if (messageModel.cellHeight != ceil(messageModel.cellHeight)) {
        
    }
    return messageModel.cellHeight;
    
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[LLMessageBaseCell class]]) {
        LLMessageBaseCell *baseCell = (LLMessageBaseCell *)cell;
        [baseCell didEndDisplayingCell];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[LLMessageBaseCell class]]) {
        LLMessageBaseCell *baseCell = (LLMessageBaseCell *)cell;
        [baseCell willDisplayCell];
    }
}

#pragma mark - TableView Cell相关方法 -

- (LLMessageBaseCell *)visibleCellForMessageModel:(LLMessageModel *)model {
    if (!model || ![self.conversationModel.conversationId isEqualToString:model.conversationId]) {
        return nil;
    }
    
    for (UITableViewCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:[LLMessageDateCell class]]){
            continue;
        }
        LLMessageBaseCell *chatCell = (LLMessageBaseCell *)cell;
        if ((chatCell.messageModel.messageBodyType == model.messageBodyType) &&
            [chatCell.messageModel.messageId isEqualToString:model.messageId]) {
            return chatCell;
        }
    }
    
    return nil;
}

- (LLMessageBaseCell *)cellForMessageModel:(LLMessageModel *)model {
    if (!model || ![self.conversationModel.conversationId isEqualToString:model.conversationId]) {
        return nil;
    }
    if (self.tableView.visibleCells.count == 0)
        return nil;
    
    NSArray<UITableViewCell *> *allcells = self.tableView.visibleCells[0].superview.subviews;
    for (UITableViewCell *cell in allcells) {
        if ([cell isKindOfClass:[LLMessageDateCell class]]){
            continue;
        }
        LLMessageBaseCell *chatCell = (LLMessageBaseCell *)cell;
        if ((chatCell.messageModel.messageBodyType == model.messageBodyType) &&
            [chatCell.messageModel.messageId isEqualToString:model.messageId]) {
            return chatCell;
        }
    }
    
    return nil;
}

- (void)addModelToDataSourceAndScrollToBottom:(LLMessageModel *)messageModel animated:(BOOL)animated {
    [self.conversationModel.allMessageModels addObject:messageModel];
    if (messageModel.timestamp - [self.dataSource lastObject].timestamp > CHAT_CELL_TIME_INTERVEL) {
        LLMessageModel *dateModel = [[LLMessageModel alloc] initWithType:kLLMessageBodyTypeDateTime];
        dateModel.timestamp = messageModel.timestamp;
        [self.dataSource addObject:dateModel];
    }
    [self.dataSource addObject:messageModel];
    
    [self refreshTableViewAndScrollToBottom:animated];
}

- (void)addModelOnlyToDataSourceAndScrollToBottom:(LLMessageModel *)model animated:(BOOL)animated {
    
    if (model.timestamp - [self.dataSource lastObject].timestamp > CHAT_CELL_TIME_INTERVEL) {
        LLMessageModel *dateModel = [[LLMessageModel alloc] initWithType:kLLMessageBodyTypeDateTime];
        dateModel.timestamp = model.timestamp;
        [self.dataSource addObject:dateModel];
    }
    [self.dataSource addObject:model];
    
    [self refreshTableViewAndScrollToBottom:animated];
}

- (void)reloadTableRowWithModel:(LLMessageModel *)model {
    LLMessageBaseCell *cell = [self visibleCellForMessageModel:model];
    if (cell) {
        //        NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
        //        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        cell.messageModel = model;
    }
}

- (void)deleteTableRowWithModel:(LLMessageModel *)model withRowAnimation:(UITableViewRowAnimation)animation {
    NSInteger index = [self.dataSource indexOfObject:model];
    NSMutableArray<NSIndexPath *> *deleteIndexPaths = [NSMutableArray array];
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
    [self.conversationModel.allMessageModels removeObject:model];
    [self.dataSource removeObjectAtIndex:index];
    [deleteIndexPaths addObject:indexPath];
    
    if (self.dataSource[index-1].messageBodyType == kLLMessageBodyTypeDateTime &&
        ((index == self.dataSource.count) || (self.dataSource[index].messageBodyType == kLLMessageBodyTypeDateTime))) {
        [self.dataSource removeObjectAtIndex:index - 1];
        [deleteIndexPaths addObject:[NSIndexPath indexPathForRow:index-1 inSection:0]];
    }
    
    [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:animation];
    WEAK_SELF;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf loadMoreMessagesAfterDeletionIfNeeded];
    });
}

- (void)deleteTableRowsWithMessageModelInArray:(NSArray<LLMessageModel *> *)messageModels {
    //获取后台实际删除的MessageModel
    NSMutableArray *deleteMessageModels = [[LLChatManager sharedManager] deleteMessages:messageModels fromConversation:self.conversationModel];
    
    NSMutableArray<NSIndexPath *> *deleteIndexPaths = [NSMutableArray array];
    NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
    for (LLMessageModel *messageModel in deleteMessageModels) {
        messageModel.isDeleting = YES;
        NSInteger index = [self.dataSource indexOfObject:messageModel];
        [indexSet addIndex:index];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [deleteIndexPaths addObject:indexPath];
    }
    
    //删除不必要的日期Cell
    NSInteger deleteDateIndex = -1;
    for (NSInteger index = 0, count = self.dataSource.count; index < count; index++) {
        LLMessageModel *messageModel = self.dataSource[index];
        if (messageModel.messageBodyType == kLLMessageBodyTypeDateTime) {
            if (deleteDateIndex >= 0) {
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:deleteDateIndex inSection:0];
                [deleteIndexPaths addObject:indexPath];
                [indexSet addIndex:deleteDateIndex];
            }
            
            deleteDateIndex = index;
        }else if (!messageModel.isDeleting){
            deleteDateIndex = -1;
        }
    }
    
    if (deleteDateIndex >= 0) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:deleteDateIndex inSection:0];
        [deleteIndexPaths addObject:indexPath];
        [indexSet addIndex:deleteDateIndex];
    }
    
    [self.conversationModel.allMessageModels removeObjectsInArray:deleteMessageModels];
    [self.dataSource removeObjectsAtIndexes:indexSet];
    
    [self.tableView beginUpdates];
    [self.tableView deleteRowsAtIndexPaths:deleteIndexPaths withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView endUpdates];
    
    WEAK_SELF;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf loadMoreMessagesAfterDeletionIfNeeded];
    });
}


#pragma mark - TableView 整体相关方法 -

- (void)refreshTableViewAndScrollToBottom:(BOOL)animated {
    [self.tableView reloadData];
    
    [self scrollToBottom:animated];
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    [self.chatInputView dismissKeyboard];
    
    if (scrollView == self.tableView) {
        for (UITableViewCell *cell in self.tableView.visibleCells) {
            if ([cell isKindOfClass:[LLMessageBaseCell class]]) {
                LLMessageBaseCell *chatCell = (LLMessageBaseCell *)cell;
                [chatCell willBeginScrolling];
            }
        }
    }
    
    if (_sightController) {
        [_sightController scrollViewPanGestureRecognizerStateChanged:scrollView.panGestureRecognizer];
    }
}

- (void)cleanMessageModelWhenExit {
    NSArray<LLMessageModel *> *models = self.conversationModel.allMessageModels;
    for (LLMessageModel *model in models) {
        [model cleanWhenConversationSessionEnded];
    }
}

- (void)scrollToBottom:(BOOL)animated {
    if (self.dataSource.count == 0)
        return;
    
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.dataSource.count - 1 inSection:0];
//    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        NSLog(@"短距离 滑动到底部");
        CGFloat offsetY = self.tableView.contentSize.height + self.tableView.contentInset.bottom - CGRectGetHeight(self.tableView.frame);
        if (offsetY < -self.tableView.contentInset.top)
            offsetY = -self.tableView.contentInset.top;
        [self.tableView setContentOffset:CGPointMake(0, offsetY) animated:animated];
    }else {
        NSLog(@"远距离 滑动到底部");
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:animated];
    }

}


#pragma mark - 处理键盘事件

- (void)updateKeyboard:(LLKeyboardShowHideInfo)keyboardInfo {
    CGFloat constant = keyboardInfo.toKeyboardType == kLLKeyboardTypeNone ? 0 :
    keyboardInfo.keyboardHeight;

    [UIView animateWithDuration:keyboardInfo.duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState |
                                keyboardInfo.curve
                     animations:^() {
                         self.chatInputViewBottomConstraint.constant = constant;
                         [self.view layoutIfNeeded];
                         self.tableView.contentInset = UIEdgeInsetsMake(constant, 0, 0, 0);
                         self.tableView.scrollIndicatorInsets = self.tableView.contentInset;

                     }
                     completion: nil];
    [self scrollToBottom:YES];

}

- (void)tapHandler:(UITapGestureRecognizer *)tap {
    [self.chatInputView dismissKeyboard];
    
    if (_sightController) {
        [self sightCapatureControllerDidCancel:_sightController];
    }
}


#pragma mark - 处理Cell动作

- (void)cellPhoneNumberDidTapped:(LLMessageTextCell *)cell phoneNumberString:(NSString *)phone {
    [self.chatInputView dismissKeyboard];
    NSString *title = [NSString stringWithFormat:@"%@可能是一个电话号码,你可以", phone];
    LLActionSheet *actionSheet = [[LLActionSheet alloc] initWithTitle:title];
    LLActionSheetAction *action1 = [LLActionSheetAction actionWithTitle:@"呼叫"
                handler:^(LLActionSheetAction *action) {
                    [LLUtils callPhoneNumber:phone];
                                                        }];
    WEAK_SELF;
    LLActionSheetAction *action2 = [LLActionSheetAction actionWithTitle:@"添加到手机通讯录"
                handler:^(LLActionSheetAction *action) {
                    [weakSelf addToContact:phone];
                                                        }] ;

    [actionSheet addActions:@[action1, action2]];

    [actionSheet showInWindow:[LLUtils popOverWindow]];
}

- (void)addToContact:(NSString *)phone {
    NSString *title = [NSString stringWithFormat:@"%@可能是一个电话号码,你可以", phone];
    LLActionSheet *actionSheet = [[LLActionSheet alloc] initWithTitle:title];
    LLActionSheetAction *action1 = [LLActionSheetAction actionWithTitle:@"创建新联系人"
                        handler:^(LLActionSheetAction *action) {
                                                                   
                                                                }];
    
    LLActionSheetAction *action2 = [LLActionSheetAction actionWithTitle:@"添加到现有联系人"
                                                                handler:^(LLActionSheetAction *action) {
                                                                    
                                                                }] ;
    
    [actionSheet addActions:@[action1, action2]];
    
    [actionSheet showInWindow:[LLUtils popOverWindow]];
}


- (void)cellLinkDidTapped:(LLMessageTextCell *)cell linkURL:(NSURL *)url {
    [self.chatInputView dismissKeyboard];
    
    LLWebViewController *web = [[LLWebViewController alloc] initWithNibName:nil bundle:nil];
    web.fromViewController = self;
    web.url = url;
    
    [self.navigationController pushViewController:web animated:YES];
}

- (void)cellLinkDidLongPressed:(LLMessageTextCell *)cell linkURL:(NSURL *)url {
    [self.chatInputView dismissKeyboard];
    
    LLActionSheet *actionSheet = [[LLActionSheet alloc] initWithTitle:url.absoluteString];
    LLActionSheetAction *action = [LLActionSheetAction actionWithTitle:@"复制链接"
                        handler:^(LLActionSheetAction *action) {
                        [LLUtils copyToPasteboard:url.absoluteString];
                                                               }];
    [actionSheet addAction:action];

    [actionSheet showInWindow:[LLUtils popOverWindow]];
}

#pragma mark - 处理Cell菜单 -

- (void)willShowMenuForCell:(LLMessageBaseCell *)cell {
//    self.chatInputView.delegate = nil;
//    [self.chatInputView becomeFirstResponder];
//    [self becomeFirstResponder];
}

- (void)didShowMenuForCell:(LLMessageBaseCell *)cell {
//    self.chatInputView.delegate = self;
}

- (void)willHideMenuForCell:(LLMessageBaseCell *)cell {
//    [self.view removeGestureRecognizer:tapGesture];
}

- (void)didHideMenuForCell:(LLMessageBaseCell *)cell {
//    [self.view addGestureRecognizer:tapGesture];
    self.chatInputView.chatInputTextView.targetCell = nil;
}

- (UIResponder *)currentFirstResponderIfNeedRetain {
    UITextView *textView = self.chatInputView.chatInputTextView;
    
    return textView.isFirstResponder ? textView : nil;
}

- (void)cellWithTagDidTapped:(NSInteger)tag {
    switch (tag) {
        case TAG_Photo:
            [self presentImagePickerController];
            break;
        case TAG_Location:
            [self presendLocationViewController];
            break;
        case TAG_Camera:
            [self takePictureAndVideoAction];
            break;
        case TAG_Sight:
            [self presentSightController];
            break;
        default:
            break;
    }
}

- (void)deleteMenuItemDidTapped:(LLMessageBaseCell *)cell {
    LLActionSheet *actionSheet = [[LLActionSheet alloc] initWithTitle:@"是否删除该条消息？"];
    LLActionSheetAction *action = [LLActionSheetAction actionWithTitle:@"确定"
               handler:^(LLActionSheetAction *action) {
                   LLMessageModel *model = cell.messageModel;
                   BOOL result = [[LLChatManager sharedManager] deleteMessage:model fromConversation:self.conversationModel];
                   if (result) {
                       [self deleteTableRowWithModel:model withRowAnimation:UITableViewRowAnimationFade];
                   }
                                   } style:kLLActionStyleDestructive];
    
    [actionSheet addAction:action];
    
    [actionSheet showInWindow:[LLUtils popOverWindow]];
}

- (LLChatMoreBottomBar *)chatMoreBottomBar {
    if (!_chatMoreBottomBar) {
        NSArray *views = [[NSBundle mainBundle] loadNibNamed:@"LLChatMoreBottomBar" owner:self options:nil];
        _chatMoreBottomBar = views[0];
        _chatMoreBottomBar.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 50);
        
        _chatSharePanel = views[1];
        _chatSharePanel.frame = self.view.bounds;
    }
    
    return _chatMoreBottomBar;
}

- (void)moreMenuItemDidTapped:(LLMessageBaseCell *)aCell {
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancelEditing:)];
    self.navigationItem.leftBarButtonItem = cancel;
    self.navigationItem.rightBarButtonItems = nil;
    [LLMessageBaseCell setEditing:YES];
    
    self.selectedMessageModels = [@[aCell.messageModel] mutableCopy];
    self.chatMoreBottomBar.isButtonsEnabled = YES;
    aCell.isSelected = YES;
    for (UITableViewCell *cell in aCell.superview.subviews) {
        if ([cell isKindOfClass:[LLMessageBaseCell class]]) {
            LLMessageBaseCell *baseCell = (LLMessageBaseCell *)cell;
            [baseCell setCellEditingAnimated:YES];
        }
    }
    
    self.chatInputView.delegate = nil;
    [self.chatInputView dismissKeyboard];
    [self.view addSubview:self.chatMoreBottomBar];
    self.view.backgroundColor = kLLBackgroundColor_lightGray;
    self.chatMoreBottomBar.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 50);
    [UIView animateWithDuration:0.3 animations:^{
        self.chatMoreBottomBar.frame = CGRectMake(0, SCREEN_HEIGHT - TABBAR_HEIGHT, SCREEN_WIDTH, TABBAR_HEIGHT);
        self.chatInputViewBottomConstraint.constant = -CGRectGetHeight(self.chatInputView.frame);
        self.tableViewBottomConstraint.constant = TABBAR_HEIGHT;
        [self.view layoutIfNeeded];
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
    }];

}

- (void)cancelEditing:(id)sender {
    self.navigationItem.leftBarButtonItem = nil;
    self.navigationItem.rightBarButtonItems = rightBarButtonItems;
    [LLMessageBaseCell setEditing:NO];
    
    if (self.tableView.visibleCells.count > 0){
        NSArray *allCells = self.tableView.visibleCells[0].superview.subviews;
        for (UITableViewCell *cell in allCells) {
            if ([cell isKindOfClass:[LLMessageBaseCell class]]) {
                LLMessageBaseCell *baseCell = (LLMessageBaseCell *)cell;
                baseCell.isSelected = NO;
                [baseCell setCellEditingAnimated:NO];
            }
        }
    }
    
    self.chatInputView.delegate = self;
    [UIView animateWithDuration:0.3 animations:^{
        self.chatMoreBottomBar.frame = CGRectMake(0, SCREEN_HEIGHT, SCREEN_WIDTH, 50);
        self.chatInputViewBottomConstraint.constant = 0;
        self.tableViewBottomConstraint.constant = 0;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.view.backgroundColor = kLLBackgroundColor_gray;
        [self.chatMoreBottomBar removeFromSuperview];
    }];
}

- (IBAction)deleteAction:(id)sender {
    if (self.selectedMessageModels.count == 0)
        return;
    
    LLActionSheet *actionSheet = [[LLActionSheet alloc] initWithTitle:nil];
    LLActionSheetAction *action = [LLActionSheetAction actionWithTitle:@"删除"
       handler:^(LLActionSheetAction *action) {
           [self deleteSelectedModels];
       } style:kLLActionStyleDestructive];
    
    [actionSheet addAction:action];
    
    [actionSheet showInWindow:[LLUtils popOverWindow]];

}

- (void)selectControllDidTapped:(LLMessageModel *)model selected:(BOOL)selected {
    if (selected) {
        [self.selectedMessageModels addObject:model];
    }else {
        [self.selectedMessageModels removeObject:model];
    }
    
    self.chatMoreBottomBar.isButtonsEnabled = self.selectedMessageModels.count > 0;
}

- (void)deleteSelectedModels {
    if (self.tableView.visibleCells.count == 0) {
        [self cancelEditing:nil];
        return;
    }
    [self cancelEditing:nil];
    
    if (self.selectedMessageModels.count > 0) {
        WEAK_SELF;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf deleteTableRowsWithMessageModelInArray:self.selectedMessageModels];
        });
    }
    
}

- (IBAction)shareAction:(id)sender {
    [self.chatSharePanel show];
}

#pragma mark - 处理照片

- (void)sendImageMessage:(NSData *)imageData imageSize:(CGSize)imageSize {
    LLChatType chatType = chatTypeForConversationType(self.conversationModel.conversationType);
    LLMessageModel * messageModel = [[LLChatManager sharedManager]
                     sendImageMessageWithData:imageData
                                     imageSize:imageSize
                     to:self.conversationModel.conversationId
                     messageType:chatType
                     messageExt:nil
                     progress:nil
                     completion:nil];
    
    [self addModelToDataSourceAndScrollToBottom:messageModel animated:YES];
    
}


- (void)cellImageDidTapped:(LLMessageImageCell *)cell {
    if (cell.messageModel.thumbnailImage) {
        [self showAssetFromCell:cell];
    }else if (!cell.messageModel.isFetchingThumbnail){
        [[LLChatManager sharedManager] asyncDownloadMessageThumbnail:cell.messageModel completion:nil];
    }
    
}

- (void)presentImagePickerController {
    LLImagePickerController *vc = [[LLImagePickerController alloc] init];
    vc.pickerDelegate = self;
    [self.navigationController presentViewController:vc animated:YES completion:nil];
}

- (void)imagePickerControllerDidCancel:(id)picker {
    if ([picker isKindOfClass:[LLImagePickerController class]]) {
        [((LLImagePickerController *)picker).presentingViewController
         dismissViewControllerAnimated:YES completion:nil];
    }else if ([picker isKindOfClass:[UIImagePickerController_L1 class]]) {
        [((UIImagePickerController_L1 *)picker).presentingViewController
         dismissViewControllerAnimated:YES completion:nil];
    }
    
}

- (void)imagePickerController:(LLImagePickerController *)picker
       didFinishPickingImages:(NSArray<LLAssetModel *> *)assets
                    withError:(NSError *)error {

    [picker.presentingViewController dismissViewControllerAnimated:YES
                                                        completion:nil];
    
    if (error || assets.count == 0) return;

    for (LLAssetModel *model in assets) {
        [self sendImageMessage:[[LLAssetManager sharedAssetManager] fetchImageDataFromAssetModel:model] imageSize:model.imageSize];
    }

}

#pragma mark - 拍摄照片、视频

- (UIImagePickerController *)imagePicker {
    if (_imagePicker == nil) {
        _imagePicker = [[UIImagePickerController_L1 alloc] init];
        _imagePicker.modalPresentationStyle= UIModalPresentationOverFullScreen;
        _imagePicker.modalPresentationCapturesStatusBarAppearance = YES;
        _imagePicker.delegate = self;
    }
    
    return _imagePicker;
}

- (void)takePictureAndVideoAction {
    [self.chatInputView dismissKeyboard];
    
#if TARGET_IPHONE_SIMULATOR
    
#elif TARGET_OS_IPHONE
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.mediaTypes = @[(NSString *)kUTTypeImage,(NSString *)kUTTypeMovie];
    self.imagePicker.videoMaximumDuration = MAX_VIDEO_DURATION_FOR_CHAT;
    [self presentViewController:self.imagePicker animated:YES completion:NULL];
#endif
    
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:(NSString *)kUTTypeMovie]) {
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];

        WEAK_SELF;
        [LLUtils convertVideoFromMOVToMP4:videoURL complete:^(NSString *mp4Path, BOOL finished) {
            [LLUtils removeFileAtPath:videoURL.path];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (finished){
                    CGFloat fileSize = [LLUtils getFileSize:mp4Path];
                    NSString *fileSizeString = [LLChatViewController getFileSizeString:fileSize];
                    NSString *msg = [NSString stringWithFormat:@"视频压缩后文件大小为%@，确定要发送吗？",fileSizeString];
                    [LLUtils showConfirmAlertWithTitle:@"提示" message:msg yesTitle:@"发送" yesAction:^{
                        [picker dismissViewControllerAnimated:YES completion:^(){
                            [weakSelf sendVideoMessageWithURL:mp4Path];
                        }];
                    } cancelTitle:@"取消" cancelAction:^{
                        [picker dismissViewControllerAnimated:YES completion:nil];
                    }];
                }else {
                    [LLUtils showTextHUD:@"视频压缩失败"];
                    [picker dismissViewControllerAnimated:YES completion:nil];
                }
            });
        }];

    }else{
        UIImage *orgImage = info[UIImagePickerControllerOriginalImage];
        [self sendImageMessage:UIImageJPEGRepresentation(orgImage, 1) imageSize:[orgImage pixelSize]];
        
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    
}


- (void)imagePickerController:(LLImagePickerController *)picker didFinishPickingVideo:(NSString *)videoPath {
    [picker dismissViewControllerAnimated:YES completion:^(){
        [self sendVideoMessageWithURL:videoPath];
    }];
    
}


/**
 *  发送视频文件
 *
 *  @param fileURL
 */
- (void)sendVideoMessageWithURL:(NSString *)filePath {
    LLChatType chatType = chatTypeForConversationType(self.conversationModel.conversationType);
    
    LLMessageModel *model = [[LLChatManager sharedManager]
            sendVideoMessageWithLocalPath:filePath
                          to:self.conversationModel.conversationId
                 messageType:chatType
                  messageExt:nil
                    progress:nil
                    completion:nil];

    [self addModelToDataSourceAndScrollToBottom:model animated:YES];
    
}

/**
 *  播放本地视频
 *
 */
- (void)cellVideoDidTapped:(LLMessageVideoCell *)cell {
    if (cell.messageModel.isFromMe || cell.messageModel.thumbnailImage) {
        [self showAssetFromCell:cell];
    }else if (!cell.messageModel.isFetchingThumbnail){
        [[LLChatManager sharedManager] asyncDownloadMessageThumbnail:cell.messageModel completion:nil];
    }
  
}


#pragma mark - 视频、图片弹出、弹入动画 -

- (void)showAssetFromCell:(LLMessageBaseCell *)cell {
    [[LLAudioManager sharedManager] stopPlaying];
    [self.chatInputView dismissKeyboard];
    
    NSMutableArray *array = [NSMutableArray array];
    for (LLMessageModel *model in self.dataSource) {
        if (model.messageBodyType == kLLMessageBodyTypeImage ||
            model.messageBodyType == kLLMessageBodyTypeVideo) {
            [array addObject:model];
        }
    }
    
    LLChatAssetDisplayController *vc = [[LLChatAssetDisplayController alloc] initWithNibName:nil bundle:nil];
    vc.allAssets = array;
    vc.curShowMessageModel = cell.messageModel;
    vc.originalWindowFrame = [cell contentFrameInWindow];
    vc.delegate = self;
    
    if ([cell isKindOfClass:[LLMessageVideoCell class]]) {
        vc.originViewSnapshot = [LLMessageVideoCell getSnapshot:nil messageModel:cell.messageModel];
    }
    
    [self.navigationController pushViewController:vc animated:NO];

}


- (void)didFinishWithMessageModel:(LLMessageModel *)model targetView:(UIView *)assetView scrollToTop:(BOOL)scrollToTop {
    NSInteger index = [self.dataSource indexOfObject:model];
    NSIndexPath *cellIndexPath = [NSIndexPath indexPathForRow:index inSection:0];
    if (scrollToTop) {
        [self.tableView scrollToRowAtIndexPath:cellIndexPath atScrollPosition:UITableViewScrollPositionNone animated:NO];
    }
    LLMessageBaseCell *cell = [self visibleCellForMessageModel:model];
    [cell layoutIfNeeded];
    self.tableView.scrollEnabled = NO;
    
    UIView *blackView = [[UIView alloc] initWithFrame:SCREEN_FRAME];
    blackView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:blackView];
    
    //cell不可见
    if (!cell) {
        UIView *targetView = [assetView snapshotViewAfterScreenUpdates:NO];
        [self.view addSubview:targetView];
        
        [UIView animateWithDuration:DEFAULT_DURATION delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            blackView.alpha = 0;
            targetView.alpha = 0;
        } completion:^(BOOL finished) {
            [blackView removeFromSuperview];
            [targetView removeFromSuperview];
            self.tableView.scrollEnabled = YES;
        }];
    }else {
        CGRect targetFrame;
        UIView *targetView;
        UIImage *maskImage;
        LLMessageImageCell *imageCell;
        LLMessageVideoCell *videoCell;
        
        if (model.messageBodyType == kLLMessageBodyTypeImage) {
            imageCell = (LLMessageImageCell *)cell;
            imageCell.chatImageView.hidden = YES;
            
            maskImage = [LLMessageImageCell bubbleImageForModel:model];
            targetView = [LLMessageImageCell getSnapshot:((LLChatImageScrollView *)assetView).imageView messageModel:model];
            targetFrame = [imageCell.chatImageView convertRect:imageCell.chatImageView.bounds toView:self.view];
        }else if (model.messageBodyType == kLLMessageBodyTypeVideo) {
            videoCell = (LLMessageVideoCell *)cell;
            videoCell.videoImageView.hidden = YES;
            
            maskImage = [LLMessageVideoCell bubbleImageForModel:model];
            targetView = [[UIImageView alloc] initWithImage:model.thumbnailImage];
            targetView.frame = CGRectMake(0, 0, SCREEN_WIDTH, model.thumbnailImage.size.height / model.thumbnailImage.size.width * SCREEN_WIDTH);

            targetFrame = [videoCell.videoImageView convertRect:videoCell.videoImageView.bounds toView:self.view];
        }
        
        targetView.top_LL = CGRectGetHeight(targetView.frame) > SCREEN_HEIGHT ? 0 : (SCREEN_HEIGHT - CGRectGetHeight(targetView.frame))/2;
        [self.view addSubview:targetView];
        
        UIImageView *imageView = [[UIImageView alloc] initWithImage:maskImage];
        imageView.contentMode = UIViewContentModeScaleToFill;
        imageView.frame = targetView.bounds;
        targetView.layer.mask = imageView.layer;
        targetView.layer.masksToBounds = YES;

        NSInteger index = [self.view.subviews indexOfObject:self.chatInputView];
        [self.view addSubview:self.chatInputView];
        
        [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
            targetView.frame = targetFrame;
            imageView.frame = targetView.bounds;
        } completion:^(BOOL finished) {
            [targetView removeFromSuperview];
            imageCell.chatImageView.hidden = NO;
            videoCell.videoImageView.hidden = NO;
            [self.view insertSubview:self.chatInputView atIndex:index];
            self.tableView.scrollEnabled = YES;
        }];
        
        [UIView animateWithDuration:0.15 delay:0.15 options:UIViewAnimationOptionCurveLinear animations:^{
            blackView.alpha = 0;
        } completion:^(BOOL finished) {
            [blackView removeFromSuperview];
        }];
    }
    
}

#pragma mark - 重新发送/下载消息


- (void)resendMessage:(LLMessageModel *)model {
    [[LLChatManager sharedManager] resendMessage:model
        progress:nil
      completion:nil];
    
    LLMessageBaseCell *cell = [self visibleCellForMessageModel:model];
    if (cell) {
        [cell updateMessageUploadStatus];
    }

}

- (void)redownloadMessage:(LLMessageModel *)model {
    switch (model.messageBodyType) {
        case kLLMessageBodyTypeImage:
            break;
        case kLLMessageBodyTypeVoice:
        case kLLMessageBodyTypeVideo:
            [[LLChatManager sharedManager] asynDownloadMessageAttachments:model progress:nil completion:nil];
            break;
        default:
            break;
    }
    
}


#pragma mark -
#pragma mark - 发送消息 -
#pragma mark -

#pragma mark 发送GIF
- (void)sendGifMessage:(LLEmotionModel *)emotionModel {
    if ([emotionModel.group.groupName isEqualToString:@"custom"]) {
        NSLog(@"暂不支持");
        return;
    }
    
    LLChatType chatType = chatTypeForConversationType(self.conversationModel.conversationType);
    LLMessageModel *model = [[LLChatManager sharedManager]
                             sendGIFTextMessage:emotionModel.text
                             to:self.conversationModel.conversationId
                             messageType:chatType
                             emotionModel:emotionModel
                             completion:nil];
    
    [self addModelToDataSourceAndScrollToBottom:model animated:YES];
}

#pragma mark - 发送文字消息

- (void)sendTextMessage:(NSString *)text {
    
    LLChatType chatType = chatTypeForConversationType(self.conversationModel.conversationType);
    LLMessageModel *model = [[LLChatManager sharedManager]
                             sendTextMessage:text
                             to:self.conversationModel.conversationId
                             messageType:chatType
                             messageExt:nil
                             completion:nil];
    
    [self addModelToDataSourceAndScrollToBottom:model animated:YES];
}


#pragma mark - 发送位置消息

- (void)presendLocationViewController {
    LLGaoDeLocationViewController *locationVC = [[LLGaoDeLocationViewController alloc] init];
    locationVC.delegate = self;
    
    LLNavigationController *navigationVC = [[LLNavigationController alloc] initWithRootViewController:locationVC];
    
    [self.navigationController presentViewController:navigationVC animated:YES completion:nil];
}

- (void)didFinishWithLocationLatitude:(double)latitude
                            longitude:(double)longitude
                                 name:(NSString *)name
                              address:(NSString *)address
                            zoomLevel:(double)zoomLevel
                             snapshot:(UIImage *)snapshot {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    
    LLChatType chatType = chatTypeForConversationType(self.conversationModel.conversationType);

    LLMessageModel *locationModel = [[LLChatManager sharedManager]
            sendLocationMessageWithLatitude:latitude
                                  longitude:longitude
                                  zoomLevel:zoomLevel
                                       name:name
                                    address:address
                                   snapshot:snapshot
                                         to:self.conversationModel.conversationId
                                messageType:chatType
                                 completion:nil];
    
    [self addModelToDataSourceAndScrollToBottom:locationModel animated:YES];
    
}

- (void)didCancelLocationViewController:(LLGaoDeLocationViewController *)locationViewController {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}


- (void)cellForLocationDidTapped:(LLMessageLocationCell *)cell {
    [self.chatInputView dismissKeyboard];
    
    LLLocationShowController *locationVC = [[LLLocationShowController alloc] init];
    locationVC.model = cell.messageModel;
    [self.navigationController pushViewController:locationVC animated:YES];
}


#pragma mark - 录音

- (LLVoiceIndicatorView *)voiceIndicatorView {
    if (!_voiceIndicatorView) {
        _voiceIndicatorView = [[NSBundle mainBundle] loadNibNamed:@"LLVoiceIndicatorView" owner:nil options:nil][0];
    }
    
    return _voiceIndicatorView;
}

- (void)voiceRecordingShouldStart {
    [[LLAudioManager sharedManager] stopPlaying];
    
    if (![LLAudioManager sharedManager].isRecording)
        [[LLAudioManager sharedManager] startRecordingWithDelegate:self];
}

- (void)voicRecordingShouldFinish {
    [[LLAudioManager sharedManager] stopRecording];
}

- (void)voiceRecordingShouldCancel {
    [[LLAudioManager sharedManager] cancelRecording];
}

- (void)voiceRecordingDidDragoutside {
    if (_voiceIndicatorView.superview && _voiceIndicatorView.style != kLLVoiceIndicatorStyleTooLong)
        [self.voiceIndicatorView setStyle:kLLVoiceIndicatorStyleCancel];
}

- (void)voiceRecordingDidDraginside {
    if (_voiceIndicatorView.superview && _voiceIndicatorView.style != kLLVoiceIndicatorStyleTooLong)
        [self.voiceIndicatorView setStyle:kLLVoiceIndicatorStyleRecord];
}

- (void)voiceRecordingTooShort {
    [[LLAudioManager sharedManager] cancelRecording];
    
    [LLTipView showTipView:self.voiceIndicatorView];
    [self.voiceIndicatorView setStyle:kLLVoiceIndicatorStyleTooShort];
    
    [self hideVoiceIndicatorViewAfterDelay:2];
}

- (void)audioRecordAuthorizationDidGranted {
    [LLTipView showTipView:self.voiceIndicatorView];
    [self.voiceIndicatorView setStyle:kLLVoiceIndicatorStyleRecord];
}

//录音开始，此时做一个录音动画
- (void)audioRecordDidStartRecordingWithError:(NSError *)error {
    if (error) {
        if (_voiceIndicatorView.superview)
            [LLTipView hideTipView:_voiceIndicatorView];
        return;
    }
    
    LLMessageModel *messageModel = [[LLMessageModel alloc] initWithType:kLLMessageBodyTypeRecording];
    
    [self addModelOnlyToDataSourceAndScrollToBottom:messageModel animated:YES];
}

- (void)audioRecordDidUpdateVoiceMeter:(double)averagePower {
    if (_voiceIndicatorView.superview) {
        [_voiceIndicatorView updateMetersValue:averagePower];
    }
}

- (LLMessageModel *)getRecordingModel {
    for (NSInteger i = self.dataSource.count-1; i >= 0; i--) {
        if (self.dataSource[i].messageBodyType == kLLMessageBodyTypeRecording) {
            return self.dataSource[i];
        }
    }

    return nil;
}

//移除录音动画
- (void)audioRecordDidFailed {
    if (_voiceIndicatorView.superview) {
        [_voiceIndicatorView setCountDown:0];
        [LLTipView hideTipView:_voiceIndicatorView];
    }
    
    LLMessageModel *voiceModel = [self getRecordingModel];
    if (voiceModel) {
        WEAK_SELF;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf deleteTableRowWithModel:voiceModel withRowAnimation:UITableViewRowAnimationFade];
        });
    }
 
}

- (void)audioRecordDidCancelled {
    [self audioRecordDidFailed];
}

- (NSTimeInterval)audioRecordMaxRecordTime {
    return MAX_RECORD_TIME_ALLOWED - 10;
}

- (void)audioRecordDurationTooShort {
    LLMessageModel *voiceModel = [self getRecordingModel];
    if (voiceModel) {
        WEAK_SELF;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf deleteTableRowWithModel:voiceModel withRowAnimation:UITableViewRowAnimationFade];
        });
    }else {
        [LLTipView showTipView:self.voiceIndicatorView];
        [self.voiceIndicatorView setStyle:kLLVoiceIndicatorStyleTooShort];
        
        [self hideVoiceIndicatorViewAfterDelay:2];
    }
}

- (void)audioRecordDurationTooLong {
    if (_voiceIndicatorView.superview) {
        countDown = 9;
        NSTimer *countDownTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(showCountDownIndicator:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:countDownTimer forMode:NSRunLoopCommonModes];
    }
    
}

- (void)showCountDownIndicator:(NSTimer *)timer {
    if (_voiceIndicatorView.superview && countDown > 0) {
        [_voiceIndicatorView setCountDown:countDown];
        --countDown;
    }else {
        [_voiceIndicatorView setCountDown:0];
        [timer invalidate];
        
        [[LLAudioManager sharedManager] stopRecording];
        
    }
}


//声音录制结束
- (void)audioRecordDidFinishSuccessed:(NSString *)voiceFilePath duration:(CFTimeInterval)duration {
    if (_voiceIndicatorView.superview)  {
        if (_voiceIndicatorView.style == kLLVoiceIndicatorStyleTooLong) {
            WEAK_SELF;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.75 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                STRONG_SELF;
                if (strongSelf->_voiceIndicatorView.superview)
                    [LLTipView hideTipView:strongSelf->_voiceIndicatorView];
                
                [weakSelf.chatInputView cancelRecordButtonTouchEvent];
            });
        }else {
            [LLTipView hideTipView:_voiceIndicatorView];
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground) {
                [self.chatInputView cancelRecordButtonTouchEvent];
            }
        }
    }
    
    LLChatType chatType = chatTypeForConversationType(self.conversationModel.conversationType);
    
    LLMessageModel *voiceModel = [[LLChatManager sharedManager]
            sendVoiceMessageWithLocalPath:voiceFilePath
                                 duration:duration
                                       to:self.conversationModel.conversationId
                              messageType:chatType
                               messageExt:nil
                               completion:nil];
    
    LLMessageModel *recordingModel = [self getRecordingModel];
    if (recordingModel) {
        NSInteger index = [self.dataSource indexOfObject:recordingModel];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [[LLChatManager sharedManager] updateMessageModelWithTimestamp:voiceModel timestamp:recordingModel.timestamp];
        [self.dataSource replaceObjectAtIndex:index withObject:voiceModel];

        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        
    }else {
        [self addModelToDataSourceAndScrollToBottom:voiceModel animated:YES];
    }

}

#pragma mark - 播放录音 -

- (void)cellVoiceDidTapped:(LLMessageVoiceCell *)cell {
    LLMessageModel *messageModel = cell.messageModel;
    
    if (!messageModel.isVoicePlayable) {
        if (messageModel.messageDownloadStatus == kLLMessageDownloadStatusPending || messageModel.messageDownloadStatus == kLLMessageDownloadStatusFailed) {
            [[LLChatManager sharedManager] asynDownloadMessageAttachments:messageModel progress:nil completion:nil];
        }
        
        return;
    }
    
    if (messageModel.isMediaPlaying) {
        messageModel.isMediaPlaying = NO;
        [cell updateVoicePlayingStatus];
        [[LLAudioManager sharedManager] stopPlaying];
   
    }else {
        [[LLAudioManager sharedManager] startPlayingWithPath:messageModel.fileLocalPath delegate:self userinfo:cell.messageModel continuePlaying:NO];
    }
    
}

- (void)audioPlayDidStarted:(id)userinfo {
    LLMessageModel *messageModel = (LLMessageModel *)userinfo;
    LLMessageVoiceCell *cell = (LLMessageVoiceCell *)[self cellForMessageModel:messageModel];
    
    [[LLChatManager sharedManager] changeVoiceMessageModelPlayStatus:messageModel];
    messageModel.isMediaPlaying = YES;
    [cell updateVoicePlayingStatus];
    
    [[LLDeviceManager sharedManager] enableProximitySensor];
    [LLDeviceManager sharedManager].delegate = self;
}

- (void)audioPlayVolumeTooLow {
    [LLUtils showTipView:self.voiceIndicatorView];
    [self.voiceIndicatorView setStyle:kLLVoiceIndicatorStyleVolumeTooLow];

}

- (void)voiceCellDidEndPlaying:(id)userinfo {
    [[LLDeviceManager sharedManager] disableProximitySensor];
    [LLDeviceManager sharedManager].delegate = nil;
    
    if (_voiceIndicatorView.superview)
        [LLTipView hideTipView:_voiceIndicatorView];
    
    LLMessageModel *messageModel = (LLMessageModel *)userinfo;
    LLMessageVoiceCell *cell = (LLMessageVoiceCell *)[self cellForMessageModel:messageModel];
    cell.messageModel.isMediaPlaying = NO;
    [cell updateVoicePlayingStatus];

}

- (void)audioPlayDidFailed:(id)userinfo {
    [self voiceCellDidEndPlaying:userinfo];
}

- (void)audioPlayDidStopped:(id)userinfo {
    [self voiceCellDidEndPlaying:userinfo];
}

- (void)audioPlayDidFinished:(id)userinfo {
    [self hideVoiceIndicatorViewAfterDelay:3];
    
    LLMessageModel *messageModel = (LLMessageModel *)userinfo;
    LLMessageVoiceCell *cell = (LLMessageVoiceCell *)[self cellForMessageModel:messageModel];
    cell.messageModel.isMediaPlaying = NO;
    [cell updateVoicePlayingStatus];
    
    NSMutableArray<LLMessageModel *> *allMessageModels = self.dataSource;
    for (NSInteger index = [allMessageModels indexOfObject:messageModel] + 1, r = allMessageModels.count; index < r; index ++ ) {
        LLMessageModel *model = allMessageModels[index];
    
        if (model.messageBodyType == kLLMessageBodyTypeVoice && !model.isMediaPlayed && !model.isMediaPlaying && !model.isFromMe && model.isVoicePlayable) {
            
            [[LLChatManager sharedManager] changeVoiceMessageModelPlayStatus:model];
            LLMessageBaseCell *cell = [self visibleCellForMessageModel:model];
            if (cell) {
                cell.messageModel = cell.messageModel;
            }

            [[LLAudioManager sharedManager] startPlayingWithPath:model.fileLocalPath delegate:self userinfo:model continuePlaying:YES];
            
            return;
        }
    }
    
    [[LLAudioManager sharedManager] stopPlaying];

}

- (void)stopPlayingVoiceWhenExit {
    if (self.tableView.visibleCells.count == 0)
        return;
    NSArray<UITableViewCell *> *allcells = self.tableView.visibleCells[0].superview.subviews;
    [[LLAudioManager sharedManager] stopPlaying];
    for (UITableViewCell *cell in allcells) {
        if ([cell isKindOfClass:[LLMessageVoiceCell class]]) {
            LLMessageVoiceCell *voiceCell = (LLMessageVoiceCell *)cell;
            if (voiceCell.isVoicePlaying) {
                [voiceCell stopVoicePlaying];
            }
            if (voiceCell.messageModel.isMediaPlaying) {
                voiceCell.messageModel.isMediaPlaying = NO;
                voiceCell.messageModel.isMediaPlayed = YES;
            }
        }
    }
}

- (void)deviceIsCloseToUser:(BOOL)isCloseToUser {
    if (isCloseToUser) {
        //切换为听筒播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    }else {
        //切换为扬声器播放
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:nil];
    }
    
    if (!isCloseToUser && !self.bottomTipView.superview) {
        WEAK_SELF;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.view addSubview:self.bottomTipView];
            weakSelf.bottomTipView.alpha = 0;
            [UIView animateWithDuration:0.5 animations:^{
                weakSelf.bottomTipView.alpha = 1;
            }];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [weakSelf.bottomTipView removeWithAnimation];
            });
        });
        
        
    }
}

- (void)hideVoiceIndicatorViewAfterDelay:(CGFloat)delay {
    if (_voiceIndicatorView.superview) {
        WEAK_SELF;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            STRONG_SELF;
            if (strongSelf->_voiceIndicatorView.superview)
                [LLTipView hideTipView:strongSelf->_voiceIndicatorView];
        });
    }
}

#pragma mark - Sight 小视频 -

#define DIM_VIEW_TAG 1000

- (void)presentSightController {
    self.chatInputView.delegate = nil;
    [self.chatInputView dismissKeyboard];
    self.chatInputView.delegate = self;
    
    _sightController = [[LLSightCapatureController alloc] initWithNibName:nil bundle:nil];
    _sightController.delegate = self;
    
    UIView *dimView = [[UIView alloc] initWithFrame:self.view.bounds];
    dimView.backgroundColor = [UIColor blackColor];
    dimView.alpha = 0;
    dimView.userInteractionEnabled = NO;
    dimView.tag = DIM_VIEW_TAG;
    [self.view addSubview:dimView];
    
    [self addChildViewController:_sightController];
    CGFloat _height = THE_GOLDEN_RATIO * SCREEN_HEIGHT;
    _sightController.view.frame = CGRectMake(0, SCREEN_HEIGHT - 320, SCREEN_WIDTH, _height);

    self.view.backgroundColor = kLLBackgroundColor_lightGray;
    [UIView animateWithDuration:DEFAULT_DURATION animations:^{
        self.chatInputViewBottomConstraint.constant = -CGRectGetHeight(self.chatInputView.frame);
        self.tableViewBottomConstraint.constant = TABBAR_HEIGHT;
        
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, _height - TABBAR_HEIGHT, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
        [self.view layoutIfNeeded];
        [self scrollToBottom:NO];
    } completion:^(BOOL finished) {
        [self.view addSubview:_sightController.view];
        [_sightController.contentView.layer addObserver:self forKeyPath:@"position" options:NSKeyValueObservingOptionNew context:nil];
        
        [UIView animateWithDuration:DEFAULT_DURATION animations:^{
            dimView.alpha = 0.4;
            _sightController.view.bottom_LL = SCREEN_HEIGHT;
        }];
    }];

}

- (void)sightCapatureControllerDidCancel:(LLSightCapatureController *)sightController {
    UIView *dimView = [self.view viewWithTag:DIM_VIEW_TAG];
    [_sightController.contentView.layer removeObserver:self forKeyPath:@"position"];
    _sightController = nil;
    
    [UIView animateWithDuration:DEFAULT_DURATION animations:^{
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.tableView.scrollIndicatorInsets = self.tableView.contentInset;
        sightController.view.top_LL = SCREEN_HEIGHT;
        dimView.alpha = 0;
    
    } completion:^(BOOL finished) {
        [sightController.view removeFromSuperview];
        [sightController removeFromParentViewController];
        [dimView removeFromSuperview];
        
        [UIView animateWithDuration:DEFAULT_DURATION animations:^{
            self.tableViewBottomConstraint.constant = 0;
            self.chatInputViewBottomConstraint.constant = 0;
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.view.backgroundColor = kLLBackgroundColor_gray;
        }];
    }];
}



#pragma - KVO -

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"position"]) {
        UIView *dimView = [self.view viewWithTag:DIM_VIEW_TAG];
        dimView.alpha = 0.4 * (1 - CGRectGetMinY(_sightController.contentView.frame) / CGRectGetHeight(_sightController.view.frame));
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}


#pragma mark - Debug


- (void)debug1:(id)sender {
    
}


- (void)debug2:(id)sender {
    [LLUtils showTextHUD:[NSString stringWithFormat:@"共有Cell %ld个", self.dataSource.count]];
    return;
    
}

#pragma mark - 辅助方法

+ (NSString *)getFileSizeString:(CGFloat)fileSize {
    NSString *ret;
    fileSize /= 1024;
    if (fileSize < 1024) {
        ret = [NSString stringWithFormat:@"%.0fK", round(fileSize)];
    }else {
        ret = [NSString stringWithFormat:@"%.2fM", fileSize/1024];
    }
    
    return ret;
}


#pragma mark - 其他 -

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
