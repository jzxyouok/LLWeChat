//
//  LLMainViewController.m
//  LLWeChat
//
//  Created by GYJZH on 9/9/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMainViewController.h"
#import "LLUtils.h"
#import "LLConfig.h"
#import "UIKit+LLExt.h"
#import "LLSDK.h"

#import "LLMessageCellManager.h"
#import "LLChatDataManager.h"

#import "LLConversationListController.h"
#import "LLContactController.h"
#import "LLDiscoveryController.h"
#import "LLMeViewController.h"
#import "LLChatViewController.h"
#import "LLWebViewController.h"

#define TAB_ITEM_NUM 4

@interface LLMainViewController ()<UITabBarDelegate, UINavigationControllerDelegate>

//@property (nonatomic) UINavigationController *rootNavigationController;

@property (nonatomic) UITabBar *tabBar;

@property (nonatomic) LLViewController *currentViewController;

//@property (nonatomic) LLChatViewController *chatViewController;

@end

@implementation LLMainViewController {
    LLViewController *tabBarViewControllers[TAB_ITEM_NUM];
}

- (instancetype)init {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [LLUtils addViewController:self.currentViewController toViewController:self];
    
//    self.rootNavigationController = [[UINavigationController alloc] initWithRootViewController:self.currentViewController];
//    self.delegate = self;
//    [self addChildViewController:self.rootNavigationController];
//    self.rootNavigationController.view.frame = SCREEN_FRAME;
//    [self.view addSubview:self.rootNavigationController.view];
//    self.edgesForExtendedLayout = UIRectEdgeNone;

 //   self.edgesForExtendedLayout = UIRectEdgeAll;
    self.tabBar = [[UITabBar alloc] initWithFrame:CGRectMake(0, SCREEN_HEIGHT - TABBAR_HEIGHT - TOP_LAYOUT_HEIGHT + 2, SCREEN_WIDTH, TABBAR_HEIGHT)];
    self.tabBar.delegate = self;
 //   [self.view addSubview:self.tabBar];
    [self setupTabbarItems];
    self.tabBar.selectedItem = self.tabBar.items[0];
    
    self.currentViewController = [self viewControllerForTabbarIndex:0];
    self.delegate = self;

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [[LLMessageCellManager sharedManager] deleteAllCells];
    [[LLChatDataManager sharedManager] deleteAllMessageModels];
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return NO;
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return [self.topViewController supportedInterfaceOrientations];
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
//    return UIInterfaceOrientationPortrait;
    return [self.visibleViewController preferredInterfaceOrientationForPresentation];
}

- (void)setCurrentViewController:(LLViewController *)currentViewController {
    if (_currentViewController == currentViewController)
        return;
    
    _currentViewController = currentViewController;
    [self setViewControllers:@[_currentViewController] animated:NO];
    [_currentViewController.view addSubview:self.tabBar];
}

- (void)setupTabbarItems {
    NSArray *images = @[@"tabbar_mainframe", @"tabbar_contacts", @"tabbar_discover", @"tabbar_me"];
    
    NSArray *selectedImages =  @[@"tabbar_mainframeHL", @"tabbar_contactsHL", @"tabbar_discoverHL", @"tabbar_meHL"];
    
    NSArray *titles = @[@"微信",@"通讯录", @"发现", @"我"];
    
    NSMutableArray<UITabBarItem *> *items = [NSMutableArray array];
    for (NSInteger i = 0; i < titles.count; i++) {
        UIImage *image = [UIImage imageNamed:images[i]];
        image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
        UIImage *imageHL = [UIImage imageNamed:selectedImages[i]];
        imageHL = [imageHL imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        
        UITabBarItem *item = [[UITabBarItem alloc]
                initWithTitle:titles[i]
                        image:image
                selectedImage:imageHL];
        item.tag = i;
        
        [item setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor lightGrayColor]} forState:UIControlStateNormal];
        
        [item setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor colorWithHexRGB:@"#68BB1E"]} forState:UIControlStateSelected];
        
        [items addObject:item];
    }
    
    self.tabBar.items = items;

}

- (LLViewController *)viewControllerForTabbarIndex:(NSInteger)index {
    if (tabBarViewControllers[index]) {
        return tabBarViewControllers[index];
    }
    
    LLViewController *viewController;
    switch (index) {
        case 0: {
            viewController = [[LLConversationListController alloc] init];
            break;
        }
        case 1: {
            viewController = [[LLContactController alloc] init];
            break;
        }
        case 2 :{
            viewController = [[LLDiscoveryController alloc] init];
            break;
        }
            
        case 3: {
            viewController = [[LLUtils mainStoryboard] instantiateViewControllerWithIdentifier:SB_ME_VC_ID];
            break;
        }
            
        default:
            break;
    }
    
    tabBarViewControllers[index] = viewController;
    return viewController;
}


- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    LLViewController *targetVC = [self viewControllerForTabbarIndex:item.tag];
    if (self.currentViewController != targetVC) {
//        [LLUtils removeViewControllerFromParentViewController:self.currentViewController];
//        self.currentViewController = targetVC;
//        [LLUtils addViewController:self.currentViewController toViewController:self];
        self.currentViewController = targetVC;
//        [self setViewControllers:@[self.currentViewController] animated:NO];
//        [self.currentViewController.view addSubview:self.tabBar];
        
    }
}

- (void)setTabbarBadgeValue:(NSInteger)badge tabbarIndex:(LLMainTabbarIndex)tabbarIndex {
    self.tabBar.items[tabbarIndex].badgeValue = badge > 0 ? [NSString stringWithFormat:@"%ld", badge] : nil;
}


#pragma mark - Navigation -

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
  
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    
}

//- (LLChatViewController *)chatViewController {
//    if (!_chatViewController) {
//        _chatViewController = [[LLUtils mainStoryboard] instantiateViewControllerWithIdentifier:SB_CHAT_VC_ID];
//        _chatViewController.hidesBottomBarWhenPushed = YES;
//    }
//
//    return _chatViewController;
//}
//
//- (void)chatWithContact:(NSString *)userName {
//    self.chatViewController.conversationModel = [[LLChatManager sharedManager]
//                            getConversationWithConversationChatter:userName
//                            conversationType:kLLConversationTypeChat];
//    [self.chatViewController fetchMessageList];
//    
//    _currentViewController = [self viewControllerForTabbarIndex:0];
//    [_currentViewController.view addSubview:self.tabBar];
//    self.tabBar.selectedItem = self.tabBar.items[0];
//    [self setViewControllers:@[_currentViewController, self.chatViewController] animated:YES];
//}
//
//- (void)chatWithConversationModel:(LLConversationModel *)conversationModel {
//    self.chatViewController.conversationModel = [[LLChatManager sharedManager] getConversationWithConversationChatter:conversationModel.conversationId conversationType:conversationModel.conversationType];
//    [self.chatViewController fetchMessageList];
//    
//    [self pushViewController:self.chatViewController animated:YES];
//}


- (void)chatWithContact:(NSString *)buddy {
    for (UIViewController *vc in self.viewControllers) {
        if ([vc isKindOfClass:[LLChatViewController class]]) {
            return;
        }
    }
    
    LLChatViewController *vc = [[LLUtils mainStoryboard] instantiateViewControllerWithIdentifier:SB_CHAT_VC_ID];
    vc.hidesBottomBarWhenPushed = YES;
    vc.conversationModel = [[LLChatManager sharedManager]
                            getConversationWithConversationChatter:buddy
                            conversationType:kLLConversationTypeChat];
    [vc fetchMessageList];
    
    _currentViewController = [self viewControllerForTabbarIndex:0];
    [_currentViewController.view addSubview:self.tabBar];
    self.tabBar.selectedItem = self.tabBar.items[0];
    [self setViewControllers:@[_currentViewController, vc] animated:YES];
}

- (void)chatWithConversationModel:(LLConversationModel *)conversationModel {
    for (UIViewController *vc in self.viewControllers) {
        if ([vc isKindOfClass:[LLChatViewController class]]) {
            return;
        }
    }
    
    LLChatViewController *vc = [[LLUtils mainStoryboard] instantiateViewControllerWithIdentifier:SB_CHAT_VC_ID];
    vc.hidesBottomBarWhenPushed = YES;
    vc.conversationModel = [[LLChatManager sharedManager] getConversationWithConversationChatter:conversationModel.conversationId conversationType:conversationModel.conversationType];
    [vc fetchMessageList];
    
    [self pushViewController:vc animated:YES];
    
}


@end
