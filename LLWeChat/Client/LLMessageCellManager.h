//
//  LLMessageCellManager.h
//  LLWeChat
//
//  Created by GYJZH on 9/25/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LLMessageBaseCell.h"
#import "LLMessageImageCell.h"
#import "LLMessageTextCell.h"
#import "LLMessageGifCell.h"
#import "LLMessageLocationCell.h"
#import "LLMessageVoiceCell.h"
#import "LLMessageVideoCell.h"
#import "LLMessageRecordingCell.h"

@interface LLMessageCellManager : NSObject

+ (instancetype)sharedManager;

- (void)deleteAllCells;

- (LLMessageBaseCell *)staticReusableCellForMessageModel:(LLMessageModel *)messageModel;

- (NSString *)reuseIdentifierForMessegeModel:(LLMessageModel *)model;

- (LLMessageBaseCell *)cellForMessageId:(NSString *)messageId;

- (LLMessageBaseCell *)removeCellForMessageId:(NSString *)messageId;

- (void)removeCellsForMessageIdsInArray:(NSArray<NSString *> *)messageIds;

- (void)addCell:(LLMessageBaseCell *)cell  forMessageId:(NSString *)messageId;

- (void)deleteConversation:(NSString *)conversationId;

@end
