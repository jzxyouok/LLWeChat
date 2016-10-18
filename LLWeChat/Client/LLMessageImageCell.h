//
//  LLMessageImageCell.h
//  LLWeChat
//
//  Created by GYJZH on 8/12/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageBaseCell.h"

@interface LLMessageImageCell : LLMessageBaseCell

@property (nonatomic) UIImageView *chatImageView;

+ (CGSize)thumbnailSize:(CGSize)size;

+ (UIView *)getSnapshot:(UIView *)targetView messageModel:(LLMessageModel *)messageModel;

@end
