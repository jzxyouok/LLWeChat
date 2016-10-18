//
//  LLAlphaNoTouchImageView.m
//  LLWeChat
//
//  Created by GYJZH on 8/30/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLAlphaNoTouchImageView.h"
#import "LLUtils.h"

@implementation LLAlphaNoTouchImageView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
    }
    
    return self;
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    UITouch *touch = [event.allTouches anyObject];
    UIColor *color = [LLUtils colorAtPoint:[touch locationInView:self] fromImageView:self];
    const CGFloat *components = CGColorGetComponents(color.CGColor);
    if (NULL != components) {
        float aplphaF = components[3];
        if ((aplphaF >= 0.9)) {
            return YES;
        }
    }
    return NO;
    
}

@end
