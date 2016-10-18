//
//  LLContactManager.h
//  LLWeChat
//
//  Created by GYJZH on 9/9/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LLUserModel.h"
#import "LLError.h"
#import "InvitationManager.h"

#define LLContactChangedNotification @"LLContactChangedNotification"

NS_ASSUME_NONNULL_BEGIN

@interface LLContactManager : NSObject

+ (instancetype)sharedManager;

- (void)asynGetContactsFromDB:(void (^ __nullable)(NSArray<LLUserModel *> *))complete;

- (NSArray<LLUserModel *> *)getContactsFromDB;

- (void)asynGetContactsFromServer:(void (^ __nullable)(NSArray<LLUserModel *> *))complete;

- (LLError *)addContact:(NSString *)buddyName;

- (void)acceptInvitationWithApplyEntity:(ApplyEntity *)entity completeCallback:(void (^ __nullable)(LLError *error))completeCallback;

NS_ASSUME_NONNULL_END

@end
