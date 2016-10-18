//
//  LLVideoPlayController.m
//  LLWeChat
//
//  Created by GYJZH on 9/18/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLVideoPlayController.h"
#import "LLUtils.h"
#import "LLVideoPlaybackView.h"
#import "LLImagePickerController.h"
#import "LLAssetManager.h"
#import "LLConfig.h"
#import "UIKit+LLExt.h"
@import AVFoundation;

@interface LLVideoPlayController ()

@property (nonatomic) LLVideoPlaybackView *playbackView;

@property (nonatomic) AVPlayer *player;
@property (nonatomic) UIButton *playButton;

@property (nonatomic) UIView *toolBar;
@property (nonatomic) UIButton *okButton;

@end

@implementation LLVideoPlayController {
    BOOL shouldShowStatusBar;
    BOOL isPlayOver;
}

- (instancetype)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        shouldShowStatusBar = YES;
        isPlayOver = NO;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"视频预览";
    self.view.backgroundColor = [UIColor blackColor];
    
    [LLUtils configAudioSessionForPlayback];
    [self setupViews];
    [self prepareToPlay];
}

- (void)setupViews {
    _playbackView = [[LLVideoPlaybackView alloc] initWithFrame:SCREEN_FRAME];
    _playbackView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:_playbackView];
    
    _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_playButton setImage:[UIImage imageNamed:@"MMVideoPreviewPlay"] forState:UIControlStateNormal];
    [_playButton setImage:[UIImage imageNamed:@"MMVideoPreviewPlayHL"] forState:UIControlStateHighlighted];
    [_playButton addTarget:self action:@selector(tapHandler:) forControlEvents:UIControlEventTouchUpInside];
    [_playButton sizeToFit];
    _playButton.center = SCREEN_CENTER;
    [self.view addSubview:_playButton];
    
    
    _toolBar = [[UIView alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - 64, SCREEN_WIDTH, 64)];
    _toolBar.backgroundColor = UIColorRGB(40, 45, 51);
    UIView *blackBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(_toolBar.frame), 20)];
    blackBar.backgroundColor = [UIColor blackColor];
    [_toolBar addSubview:blackBar];
    
    
    _okButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _okButton.frame = CGRectMake(CGRectGetWidth(_toolBar.frame) - 6 - 50, 20, 50, 44);
    _okButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_okButton addTarget:self action:@selector(okButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_okButton setTitle:@"确定" forState:UIControlStateNormal];
    [_okButton setTitleColor:UIColorRGB(26, 175, 10) forState:UIControlStateNormal];
    
    [_toolBar addSubview:_okButton];
    [self.view addSubview:_toolBar];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandler:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tap];
    
}

- (void)prepareToPlay {
    [[LLAssetManager sharedAssetManager] getVideoWithAssetModel:_assetModel completion:^(AVPlayerItem *playerItem, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            _player = [AVPlayer playerWithPlayerItem:playerItem];
            [_playbackView setPlayer:_player];

            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playComplete) name:AVPlayerItemDidPlayToEndTimeNotification object:playerItem];
        });
    }];
}


- (BOOL)prefersStatusBarHidden {
    return !shouldShowStatusBar;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - 视频 播放 -

- (void)tapHandler:(id)sender {
    if ([self isPlaying]) {
        [self pause];
    }else {
        if (isPlayOver) {
            isPlayOver = NO;
            [self.playbackView.player seekToTime:kCMTimeZero];
        }
        [self play];
    }
    
    [self updatePlayerUI];
}


- (void)play {
    [self.playbackView.player play];
}

- (void)pause {
    [self.playbackView.player pause];
}

- (BOOL)isPlaying {
    return [self.playbackView.player rate] != 0.f;
}


- (void)updatePlayerUI {
    BOOL isPlaying = [self isPlaying];

    _toolBar.hidden = isPlaying;
    _playButton.hidden = isPlaying;
    
    [self.navigationController setNavigationBarHidden:isPlaying animated:NO];
    shouldShowStatusBar = !isPlaying;
    [self setNeedsStatusBarAppearanceUpdate];
}


- (void)playComplete {
    isPlayOver = YES;
    [self updatePlayerUI];
}

#pragma mark - 视频 发送 -

- (void)okButtonClick {
    if (self.okButton.tag == 0) {
        self.okButton.tag = 10;
    }else {
        return;
    }
    
    WEAK_SELF;
    [[LLAssetManager sharedAssetManager] getVideoAssetForAssetModel:self.assetModel completion:^(AVURLAsset * _Nonnull videoAsset) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.playButton.hidden = YES;
            
            [LLUtils compressVideoAssetForSend:videoAsset
            okCallback:^(NSString *mp4Path) {
                LLImagePickerController *imagePickerController = (LLImagePickerController *)weakSelf.navigationController;
                [imagePickerController didFinishPickingVideo:mp4Path assetGroupModel:self.assetGroupModel];
            }
            cancelCallback:^{
                weakSelf.playButton.hidden = NO;
                weakSelf.okButton.tag = 0;
            }
              failCallback:^{
                  weakSelf.playButton.hidden = NO;
                  weakSelf.okButton.tag = 0;
              }
             successCallback:^(NSString *mp4Path) {
                 weakSelf.playButton.hidden = NO;
             }];
        });
    }];
    
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
