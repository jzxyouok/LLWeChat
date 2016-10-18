//
//  LLPushOptions.m
//  LLWeChat
//
//  Created by GYJZH on 9/15/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLPushOptions.h"

@implementation LLPushOptions

+ (instancetype)sharedOptions {
    static LLPushOptions *_options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _options = [[LLPushOptions alloc] init];
    });
    
    return _options;
}

@end
