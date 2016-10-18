//
//  LLMessageVideoCell.h
//  LLWeChat
//
//  Created by GYJZH on 8/30/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageBaseCell.h"

@interface LLMessageVideoCell : LLMessageBaseCell

@property (nonatomic) UIImageView *videoImageView;

@property (nonatomic) NSInteger uploadProgress;

@property (nonatomic) NSInteger downloadProgress;

//- (void)uploadResult:(BOOL)successed;
//
//- (void)downloadResult:(BOOL)sucessed;

+ (UIView *)getSnapshot:(UIView *)targetView messageModel:(LLMessageModel *)messageModel;

@end
