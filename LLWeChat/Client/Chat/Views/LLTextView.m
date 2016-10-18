//
//  LLTextView.m
//  LLWeChat
//
//  Created by GYJZH on 08/10/2016.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLTextView.h"

@implementation LLTextView

-(BOOL)canPerformAction:(SEL)action withSender:(id)sender{
    if (self.targetCell) {
        NSArray<NSString *> *menuActionNames = self.targetCell.menuActionNames;
        
        for (NSInteger i = 0; i < menuActionNames.count; i++) {
            if (action == NSSelectorFromString(menuActionNames[i])) {
                return YES;
            }
        }
        
        return NO;//隐藏系统默认的菜单项
    }else {
        return [super canPerformAction:action withSender:sender];
    }
    
}


#pragma mark - 来自LLMessageCell的Action -

- (void)deleteAction:(id)sender {
    [self.targetCell deleteAction:sender];
}

- (void)moreAction:(id)sender {
    [self.targetCell moreAction:sender];
}

- (void)copyAction:(id)sender {
    [self.targetCell copyAction:sender];
}

- (void)transforAction:(id)sender {
    [self.targetCell transforAction:sender];
}

- (void)favoriteAction:(id)sender {
    [self.targetCell favoriteAction:sender];
}

- (void)translateAction:(id)sender {
    [self.targetCell transforAction:sender];
}

- (void)addToEmojiAction:(id)sender {
    [self.targetCell addToEmojiAction:sender];
}

- (void)forwardAction:(id)sender {
    [self.targetCell forwardAction:sender];
}

- (void)showAlbumAction:(id)sender {
    [self.targetCell showAlbumAction:sender];
}

- (void)playAction:(id)sender {
    [self.targetCell playAction:sender];
}

- (void)translateToWordsAction:(id)sender {
    [self.targetCell translateToWordsAction:sender];
}


@end
