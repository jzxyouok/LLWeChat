//
//  UIResponder+LLExt.h
//  LLWeChat
//
//  Created by GYJZH on 09/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIResponder (LLExt)

+(id)currentFirstResponder;

+ (UIResponder *)firstResponder;

@end
