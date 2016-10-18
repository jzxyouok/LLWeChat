//
//  LLNavigationBackButtonView.m
//  LLWeChat
//
//  Created by GYJZH on 9/22/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLNavigationBackButtonView.h"

@implementation LLNavigationBackButtonView

- (instancetype)init {
    self = [super init];
    if (self) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        [btn setImage:[UIImage imageNamed:@"barbuttonicon_back"] forState:UIControlStateNormal];
        [self addSubview:btn];
        
        [btn setTitle:@"返回" forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:15.8];
        
        
    }
    
    return self;
}

@end
