//
//  LLChatAssetDisplayController.h
//  LLWeChat
//
//  Created by GYJZH on 8/16/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLViewController.h"
#import "LLMessageModel.h"
#import "LLChatImageScrollView.h"
#import "LLVideoDownloadStatusHUD.h"

@protocol LLChatImagePreviewDelegate <NSObject>

- (void)didFinishWithMessageModel:(LLMessageModel *)model targetView:(UIView *)assetView scrollToTop:(BOOL)scrollToTop;

@end


@interface LLChatAssetDisplayController : LLViewController

@property (nonatomic, weak) id<LLChatImagePreviewDelegate> delegate;
@property (nonatomic) NSArray<LLMessageModel *> *allAssets;
@property (nonatomic) LLMessageModel *curShowMessageModel;

@property (nonatomic) CGRect originalWindowFrame;
@property (nonatomic) UIView *originViewSnapshot;

- (void)HUDDidTapped:(LLVideoDownloadStatusHUD *)HUD;

@end
