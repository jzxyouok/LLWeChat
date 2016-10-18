//
//  LLBigSelectView.h
//  LLPickImageDemo
//
//  Created by GYJZH on 6/27/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LLBigSelectView : UIView

- (void)addTarget:(id)target action:(SEL)action;
@property (nonatomic, getter=isSelected) BOOL selected;

@end
