//
//  UINavigationController+LLExt.m
//  LLWeChat
//
//  Created by GYJZH on 8/24/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "UINavigationController+LLExt.h"

@implementation UINavigationController (LLExt)

- (UIViewController *)childViewControllerForStatusBarStyle {
    return self.topViewController;
}

- (UIViewController *)childViewControllerForStatusBarHidden {
    return self.topViewController;
}


@end
