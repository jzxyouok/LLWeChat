//
//  UIResponder+LLExt.m
//  LLWeChat
//
//  Created by GYJZH on 09/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "UIResponder+LLExt.h"

@interface ABCFirstResponderEvent : UIEvent
@property (nonatomic, strong) UIResponder *firstResponder;
@end

@implementation ABCFirstResponderEvent
@end

static __weak id currentFirstResponder;

@implementation UIResponder (LLExt)

- (void)abc_findFirstResponder:(id)sender event:(ABCFirstResponderEvent *)event {
    event.firstResponder = self;
}

+(id)currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

+ (UIResponder *)firstResponder {
    ABCFirstResponderEvent *event = [ABCFirstResponderEvent new];
    [[UIApplication sharedApplication] sendAction:@selector(abc_findFirstResponder:event:) to:nil from:nil forEvent:event];
    return event.firstResponder;
}

//该结果并不准确，可能返回firstResponder的superview
-(void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end
