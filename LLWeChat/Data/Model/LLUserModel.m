//
//  LLUserModel.m
//  LLWeChat
//
//  Created by GYJZH on 9/9/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLUserModel.h"
#import "LLUtils.h"

@implementation LLUserModel

- (instancetype)initWithBuddy:(NSString *)buddy {
    self = [super init];
    if (self) {
        _userName = buddy;
        _pinyinOfUserName = [LLUtils pinyinOfString:_userName];
        _nickname = @"";
        _avatarImage = [UIImage imageNamed:@"icon_avatar"];
    }
    
    return self;
}

@end
