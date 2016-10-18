//
//  LLUserProfile.h
//  LLWeChat
//
//  Created by GYJZH on 7/24/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LLUserProfile : NSObject

@property (nonatomic, copy) NSString *userName;

@property (nonatomic, copy) NSString *nickName;

//用户头像资源
@property (nonatomic, copy) NSString *avatarURL;

+ (instancetype)myUserProfile;

- (void)initUserProfileWithUserName:(NSString *)userName nickName:(NSString *)nickName avatarURL:(NSString *)avatarURL;


@end
