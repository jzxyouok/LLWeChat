//
//  LLContactManager.m
//  LLWeChat
//
//  Created by GYJZH on 9/9/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLContactManager.h"
#import "LLUtils.h"
#import "EMSDK.h"


#define CONTACT_QUEUE_ID "CONTACT_QUEUE_ID"

@interface LLContactManager () <EMContactManagerDelegate>

@property (nonatomic) dispatch_queue_t contact_queue;

@property (nonatomic) NSMutableArray<LLUserModel *> *allContacts;

@end

@implementation LLContactManager

CREATE_SHARED_MANAGER(LLContactManager)


- (instancetype)init {
    self = [super init];
    if (self) {
        _contact_queue = dispatch_queue_create(CONTACT_QUEUE_ID, DISPATCH_QUEUE_SERIAL);
        
        [[EMClient sharedClient].contactManager addDelegate:self delegateQueue:_contact_queue];
        
    }
    
    return self;
}


#pragma mark - 获取好友 -

- (void)getContacts:(void (^)(NSArray<LLUserModel *> *))complete {
    NSArray *buddyList = [[EMClient sharedClient].contactManager getContacts];
    
    NSMutableArray<LLUserModel *> *allContacts = [NSMutableArray arrayWithCapacity:buddyList.count + 1];
    for (NSString *buddy in buddyList) {
        LLUserModel *model = [[LLUserModel alloc] initWithBuddy:buddy];
        [allContacts addObject:model];
    }
    
    //        NSString *loginUsername = [[EMClient sharedClient] currentUsername];
    //        if (loginUsername && loginUsername.length > 0) {
    //            LLUserModel *model = [[LLUserModel alloc] initWithBuddy:loginUsername];
    //            [allContacts addObject:model];
    //        }
    
    if (complete) {
        dispatch_async(dispatch_get_main_queue(), ^{
            complete(allContacts);
        });
    }

}

- (void)asynGetContactsFromDB:(void (^ __nullable)(NSArray<LLUserModel *> *))complete {
    dispatch_async(_contact_queue, ^{
        NSArray *buddyList = [[EMClient sharedClient].contactManager getContactsFromDB];
        
        NSMutableArray<LLUserModel *> *allContacts = [NSMutableArray arrayWithCapacity:buddyList.count];
        for (NSString *buddy in buddyList) {
            LLUserModel *model = [[LLUserModel alloc] initWithBuddy:buddy];
            [allContacts addObject:model];
        }
        
//        NSString *loginUsername = [[EMClient sharedClient] currentUsername];
//        if (loginUsername && loginUsername.length > 0) {
//            LLUserModel *model = [[LLUserModel alloc] initWithBuddy:loginUsername];
//            [allContacts addObject:model];
//        }
        
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(allContacts);
            });
        }
        
    });

}

- (NSArray<LLUserModel *> *)getContactsFromDB {
    NSArray *buddyList = [[EMClient sharedClient].contactManager getContactsFromDB];
    
    NSMutableArray<LLUserModel *> *allContacts = [NSMutableArray arrayWithCapacity:buddyList.count];
    for (NSString *buddy in buddyList) {
        LLUserModel *model = [[LLUserModel alloc] initWithBuddy:buddy];
        [allContacts addObject:model];
    }
    
    //        NSString *loginUsername = [[EMClient sharedClient] currentUsername];
    //        if (loginUsername && loginUsername.length > 0) {
    //            LLUserModel *model = [[LLUserModel alloc] initWithBuddy:loginUsername];
    //            [allContacts addObject:model];
    //        }
    
    return allContacts;
}

- (void)asynGetContactsFromServer:(void (^)(NSArray<LLUserModel *> *))complete {
    [[EMClient sharedClient].contactManager asyncGetContactsFromServer:^(NSArray *buddyList) {
        NSMutableArray<LLUserModel *> *allContacts = [NSMutableArray arrayWithCapacity:buddyList.count];
        for (NSString *buddy in buddyList) {
            LLUserModel *model = [[LLUserModel alloc] initWithBuddy:buddy];
            [allContacts addObject:model];
        }
        
//        NSString *loginUsername = [[EMClient sharedClient] currentUsername];
//        if (loginUsername && loginUsername.length > 0) {
//            LLUserModel *model = [[LLUserModel alloc] initWithBuddy:loginUsername];
//            [allContacts addObject:model];
//        }
        
        if (complete) {
            dispatch_async(dispatch_get_main_queue(), ^{
                complete(allContacts);
            });
        }
        
    } failure:^(EMError *aError) {
        
    }];
}

- (LLError *)addContact:(NSString *)buddyName {
    EMError *error = [[EMClient sharedClient].contactManager addContact:buddyName message:@"你不点一下吗？"];
    
    return error ? [LLError errorWithEMError:error] : nil;
}

#pragma mark - 好友关系变化回调 -

/**
 *  对方同意加我为好友
 *
 *  @param aUsername <#aUsername description#>
 */
- (void)didReceiveAgreedFromUsername:(NSString *)aUsername {
    [LLUtils showTextHUD:[NSString stringWithFormat:@"%@同意加你为好友", aUsername]];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:LLContactChangedNotification object:[LLContactManager sharedManager]];}

/**
 *  对方拒绝加我为好友
 *
 *  @param aUsername <#aUsername description#>
 */
- (void)didReceiveDeclinedFromUsername:(NSString *)aUsername {
    
}

/**
 *  对方删除与我的好友关系
 *
 *  @param aUsername <#aUsername description#>
 */
- (void)didReceiveDeletedFromUsername:(NSString *)aUsername {
    [[NSNotificationCenter defaultCenter] postNotificationName:LLContactChangedNotification object:[LLContactManager sharedManager]];}


/**
 *  好友关系建立，双方都收到该回调
 *
 *  @param aUsername <#aUsername description#>
 */
- (void)didReceiveAddedFromUsername:(NSString *)aUsername {
    [[NSNotificationCenter defaultCenter] postNotificationName:LLContactChangedNotification object:[LLContactManager sharedManager]];
}


/**
 *  收到对方发来的好友申请请求
 *
 *  @param aUsername <#aUsername description#>
 *  @param aMessage  <#aMessage description#>
 */
- (void)didReceiveFriendInvitationFromUsername:(NSString *)aUsername
                                       message:(NSString *)aMessage {
    if (!aUsername) {
        return;
    }
    
    [self addNewApply:aUsername];

}


- (void)addNewApply:(NSString *)userName {
    if (userName.length > 0) {
        //new apply
        ApplyEntity * newEntity= [[ApplyEntity alloc] init];
        newEntity.applicantUsername = userName;
        
        NSString *loginName = [[EMClient sharedClient] currentUsername];
        newEntity.receiverUsername = loginName;
        
        [[InvitationManager sharedInstance] addInvitation:newEntity loginUser:loginName];
        
    }
  
}

- (void)acceptInvitationWithApplyEntity:(ApplyEntity *)entity completeCallback:(void (^ __nullable)(LLError *error))completeCallback {
    MBProgressHUD *HUD = [LLUtils showActivityIndicatiorHUDWithTitle:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        EMError *error = [[EMClient sharedClient].contactManager acceptInvitationForUsername:entity.applicantUsername];
        dispatch_async(dispatch_get_main_queue(), ^{
            [LLUtils hideHUD:HUD animated:YES];
            if (!error) {
                NSString *loginUsername = [[EMClient sharedClient] currentUsername];
                [[InvitationManager sharedInstance] removeInvitation:entity loginUser:loginUsername];
            }else {
                [LLUtils showMessageAlertWithTitle:nil message:@"同意添加好友时发生错误"];
            }
            
            if (completeCallback) {
                completeCallback(error ? [LLError errorWithEMError:error] : nil);
            }
        });
    });
    
}

@end
