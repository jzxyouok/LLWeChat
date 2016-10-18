//
// Created by GYJZH on 7/19/16.
// Copyright (c) 2016 GYJZH. All rights reserved.
//

#import "LLConversationModel.h"
#import "EMMessage.h"
#import "LLUtils.h"
#import "NSDate+LLExt.h"
#import "EMMessage.h"
#import "EMTextMessageBody.h"


@interface LLConversationModel ()


@end


@implementation LLConversationModel

- (instancetype)initWithConversation:(EMConversation *)conversation {
    self = [super init];
    if (self) {
        _sdk_conversation = conversation;
        _conversationType = (LLConversationType)conversation.type;
    
        _unreadMessageNumber = -1;
        _allMessageModels = [[NSMutableArray alloc] init];
    }

    return self;
}

- (NSTimeInterval)latestMessageTimestamp {
    return self.sdk_conversation.latestMessage.timestamp;
}

- (NSString *)latestMessageTimeString {
    NSDate *date = [NSDate dateWithTimeIntervalInMilliSecondSince1970:[self latestMessageTimestamp]];
    
    return [date timeIntervalBeforeNowShortDescription];
}

- (NSString *)conversationId {
    return self.sdk_conversation.conversationId;
}

- (NSString *)nickName {
    return self.conversationId;
}

- (NSInteger)unreadMessageNumber {
    return self.sdk_conversation.unreadMessagesCount;
}

- (NSString *)latestMessage {
    EMMessage *latestMessage = self.sdk_conversation.latestMessage;
    return [LLMessageModel messageTypeTitle:latestMessage];
}

- (LLMessageStatus)latestMessageStatus {
    EMMessage *latestMessage = self.sdk_conversation.latestMessage;
    return (LLMessageStatus)latestMessage.status;
}


@end
