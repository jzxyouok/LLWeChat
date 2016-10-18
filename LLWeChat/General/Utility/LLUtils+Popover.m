//
//  LLUtils+Popover.m
//  LLWeChat
//
//  Created by GYJZH on 9/11/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLUtils+Popover.h"
#import "UIKit+LLExt.h"

@implementation LLUtils (Popover)

+ (UIViewController *)mostFrontViewController {
    UIViewController *vc = [self rootViewController];
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    return vc;
}


+ (void)showMessageAlertWithTitle:(NSString *)title message:(NSString *)message {
    [self showMessageAlertWithTitle:title message:message actionTitle:@"确定" actionHandler:nil];
}

+ (void)showMessageAlertWithTitle:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle {
    [self showMessageAlertWithTitle:title message:message actionTitle:actionTitle actionHandler:nil];
}

+ (void)showMessageAlertWithTitle:(NSString *)title message:(NSString *)message actionTitle:(NSString *)actionTitle actionHandler:(void (^ __nullable)())actionHandler {
    //IOS8.0及以后，采用UIAlertController
    if ([LLUtils systemVersion] >= 8.0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action;
        if (actionHandler) {
            action = [UIAlertAction actionWithTitle:actionTitle
                                              style:UIAlertActionStyleDefault
                                            handler:^(UIAlertAction *action){
                                                actionHandler();
                                            }];
        }else {
            action = [UIAlertAction actionWithTitle:actionTitle
                                              style:UIAlertActionStyleCancel
                                            handler:nil];
        }
        
        [alertController addAction:action];
        
        [[self mostFrontViewController] presentViewController:alertController animated:YES completion:nil];
        
    }
    
}

+ (void)showConfirmAlertWithTitle:(NSString *)title message:(NSString *)message yesTitle:(NSString *)yesTitle yesAction:(void (^ __nullable)())yesAction {
    [self showConfirmAlertWithTitle:title message:message yesTitle:yesTitle yesAction:yesAction cancelTitle:@"取消" cancelAction:nil];
}

+ (void)showConfirmAlertWithTitle:(NSString *)title message:(NSString *)message yesTitle:(NSString *)yesTitle yesAction:(void (^ __nullable)())yesAction cancelTitle:(NSString *)cancelTitle cancelAction:(void (^ __nullable)())cancelAction {
    //IOS8.0及以后，采用UIAlertController
    if ([LLUtils systemVersion] >= 8.0) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:yesTitle
                                                         style:UIAlertActionStyleDefault
                                                       handler:^(UIAlertAction *action){
                                                           if (yesAction)
                                                               yesAction();
                                                       }];
        
        UIAlertAction *action2 = [UIAlertAction actionWithTitle:cancelTitle
                                                          style:UIAlertActionStyleCancel
                                                        handler:^(UIAlertAction *action) {
                                                            if (cancelAction)
                                                                cancelAction();
                                                        }];
        
        [alertController addAction:action];
        [alertController addAction:action2];
        
        [[self mostFrontViewController] presentViewController:alertController animated:YES completion:nil];
        
    }
}


+ (void)showTipView:(UIView<LLTipDelegate> *)view {
    [LLTipView showTipView:view];
}

+ (void)hideTipView:(UIView<LLTipDelegate> *)tipView {
    [LLTipView hideTipView:tipView];
}

#pragma mark - HUD -

+ (UIView *)defaultHUDView {
    static UIView *containerView;
    if (!containerView) {
        containerView = [[UIView alloc] init];
    }
    
    return containerView;
}


+ (MBProgressHUD *)progressHUDInView:(UIView *)view {
    UIView *hudView = view;
    if (!hudView) {
        hudView = [self defaultHUDView];
        if (!hudView.superview) {
            [[LLUtils currentWindow] addSubview:hudView];
        }
        hudView.frame = [UIScreen mainScreen].bounds;
        [hudView.superview bringSubviewToFront:hudView];
    }
    
    MBProgressHUD *HUD = [[MBProgressHUD alloc] initWithView:hudView];
    [hudView addSubview:HUD];
    HUD.removeFromSuperViewOnHide = YES;
    HUD.delegate = view ? nil : [self sharedUtils];
       
    return HUD;
}

+ (MBProgressHUD *)showActionSuccessHUD:(NSString *)title {
    return [self showActionSuccessHUD:title inView:nil];
}

+ (MBProgressHUD *)showActionSuccessHUD:(NSString *)title inView:(UIView *)view {
    MBProgressHUD *HUD = [self progressHUDInView:view];
    
    HUD.mode = MBProgressHUDModeCustomView;
    UIImage *image = [UIImage imageNamed:@"operationbox_successful"];
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    HUD.customView = [[UIImageView alloc] initWithImage:image];
    HUD.square = YES;
    HUD.margin = 8;
    HUD.minSize = CGSizeMake(120, 120);
    
    HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    HUD.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    HUD.label.text = title;
    HUD.label.font = [UIFont systemFontOfSize:14];
    HUD.contentColor = [UIColor colorWithWhite:1 alpha:1];
    
    [HUD layoutIfNeeded];
    HUD.label.top_LL += 10;
    
    [HUD showAnimated:YES];
    [HUD hideAnimated:YES afterDelay:2];
    
    return HUD;
    
}

+ (MBProgressHUD *)showTextHUD:(NSString *)text {
    return [self showTextHUD:text inView:nil];
}

+ (MBProgressHUD *)showTextHUD:(NSString *)text inView:(nullable UIView *)view {
    MBProgressHUD *HUD = [self progressHUDInView:view];
    
    HUD.mode = MBProgressHUDModeText;
    HUD.margin = 8;
    HUD.minSize = CGSizeMake(120, 30);
    
    HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    HUD.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    HUD.contentColor = [UIColor colorWithWhite:1 alpha:1];
    
    HUD.label.text = text;
    HUD.label.font = [UIFont systemFontOfSize:15];
    
    [HUD layoutIfNeeded];
    HUD.bezelView.bottom_LL = SCREEN_HEIGHT - 60;
    
    [HUD showAnimated:YES];
    [HUD hideAnimated:YES afterDelay:2];
    
    return HUD;
}

+ (MBProgressHUD *)showCircleProgressHUDInView:(UIView *)view {
    MBProgressHUD *HUD = [self progressHUDInView:view];
    
    HUD.mode = MBProgressHUDModeDeterminate;
    HUD.margin = 8;
    HUD.square = YES;
    HUD.minSize = CGSizeMake(120, 120);
    
    [HUD showAnimated:YES];
    
    return HUD;
}

+ (MBProgressHUD *)showActivityIndicatiorHUDWithTitle:(NSString *)title {
    return [self showActivityIndicatiorHUDWithTitle:title inView:nil];
}

+ (MBProgressHUD *)showActivityIndicatiorHUDWithTitle:(NSString *)title inView:(UIView *)view {
    MBProgressHUD *HUD = [self progressHUDInView:view];
    
    HUD.mode = MBProgressHUDModeIndeterminate;
    HUD.margin = 8;
    HUD.minSize = CGSizeMake(120, 120);
    
    HUD.bezelView.style = MBProgressHUDBackgroundStyleSolidColor;
    HUD.bezelView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];
    HUD.label.text = title;
    HUD.label.font = [UIFont systemFontOfSize:14];
    HUD.contentColor = [UIColor colorWithWhite:1 alpha:1];
    
    [HUD layoutIfNeeded];
    HUD.label.top_LL += 10;
    
    [HUD showAnimated:YES];
    
    return HUD;
}

+ (void)hideHUD:(MBProgressHUD *)HUD animated:(BOOL)animated {
    HUD.removeFromSuperViewOnHide = YES;
    [HUD hideAnimated:animated];
}

- (void)hudWasHidden:(MBProgressHUD *)hud {
    if ([LLUtils defaultHUDView].subviews.count == 0) {
        [[LLUtils defaultHUDView] removeFromSuperview];
    }
}

@end
