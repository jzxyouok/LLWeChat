//
//  LLAssetCell.h
//  LLPickImageDemo
//
//  Created by GYJZH on 6/25/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLAssetModel.h"

@interface LLAssetCell : UIView

@property (nonatomic) LLAssetModel *assetModel;
@property (nonatomic, getter=isSelected) BOOL selected;

- (void)addTarget:(id)target selectAction:(SEL)action showAction:(SEL)action2;
@end
