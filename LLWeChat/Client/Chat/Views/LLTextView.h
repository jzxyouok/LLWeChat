//
//  LLTextView.h
//  LLWeChat
//
//  Created by GYJZH on 08/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LLMessageBaseCell.h"


@interface LLTextView : UITextView

@property (nonatomic) LLMessageBaseCell *targetCell;

@end
