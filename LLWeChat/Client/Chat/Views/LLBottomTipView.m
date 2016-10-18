//
//  LLBottomTipView.m
//  LLWeChat
//
//  Created by GYJZH on 9/20/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLBottomTipView.h"
#import "LLUtils.h"

@implementation LLBottomTipView

- (void)removeWithAnimation {
    [UIView animateWithDuration:0.5
                     animations:^{
                         self.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         [self removeFromSuperview];
                     }];
}

- (IBAction)closeButtonPressed:(UIButton *)sender {
    [self removeWithAnimation];
}


@end
