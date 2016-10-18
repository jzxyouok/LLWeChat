//
//  LLMessageCellManager.m
//  LLWeChat
//
//  Created by GYJZH on 9/25/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLMessageCellManager.h"
#import "LLUtils.h"

#define INITIAL_CAPACITY 60

typedef NSMutableDictionary<NSString *, LLMessageBaseCell *> *DICT_TYPE;


@interface LLMessageCellManager ()

@property (nonatomic) DICT_TYPE allCells;

@end

@implementation LLMessageCellManager

CREATE_SHARED_MANAGER(LLMessageCellManager)

- (instancetype)init {
    self = [super init];
    if (self) {
        _allCells = [NSMutableDictionary dictionaryWithCapacity:INITIAL_CAPACITY];
    }
    
    return self;
}

- (void)deleteAllCells {
    [_allCells removeAllObjects];
}

- (NSString *)reuseIdentifierForMessegeModel:(LLMessageModel *)model {
    switch (model.messageBodyType) {
        case kLLMessageBodyTypeText:
            return model.fromMe ? @"messageTypeTextMe" : @"messageTypeText";
        case kLLMessageBodyTypeImage:
            return model.fromMe ? @"messageTypeImageMe" : @"messageTypeImage";
        case kLLMessageBodyTypeDateTime:
            return @"messageTypeDateTime";
        case kLLMessageBodyTypeVoice:
            return model.fromMe ? @"messageTypeVoiceMe" : @"messageTypeVoice";
        case kLLMessageBodyTypeGif:
            return model.fromMe ? @"messageTypeGifMe" : @"messageTypeGif";
        case kLLMessageBodyTypeLocation:
            return model.fromMe ? @"messageTypeLocationMe" : @"messageTypeLocation";
        case kLLMessageBodyTypeVideo:
            return model.fromMe ? @"messageTypeVideoMe" : @"messageTypeVideo";
        default:
            break;
    }
    
    return @"messageTypeNone";
}

- (LLMessageBaseCell *)staticReusableCellForMessageModel:(LLMessageModel *)messageModel {
    LLMessageBaseCell *_cell = _allCells[messageModel.messageId];
    if (_cell) {
        return _cell;
    }
    
    NSString *reuseId = [self reuseIdentifierForMessegeModel:messageModel];
    switch (messageModel.messageBodyType) {
        case kLLMessageBodyTypeText: {
            LLMessageTextCell *cell =  [[LLMessageTextCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
            [cell prepareForUse:messageModel.isFromMe];
            cell.messageModel = messageModel;

            _cell = cell;
            break;
        }
        case kLLMessageBodyTypeImage: {
            LLMessageImageCell *cell = [(LLMessageImageCell *)[LLMessageImageCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
            [cell prepareForUse:messageModel.isFromMe];
            cell.messageModel = messageModel;

            _cell = cell;
            break;
        }
        case kLLMessageBodyTypeGif: {
            LLMessageGifCell *cell = [[LLMessageGifCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
            [cell prepareForUse:messageModel.isFromMe];
            cell.messageModel = messageModel;
            
            _cell = cell;
            break;
        }
        case kLLMessageBodyTypeLocation: {
            LLMessageLocationCell *cell = [[LLMessageLocationCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
            [cell prepareForUse:messageModel.isFromMe];
            cell.messageModel = messageModel;
            
            _cell = cell;
            break;
        }
        case kLLMessageBodyTypeVoice: {
            LLMessageVoiceCell *cell = [[LLMessageVoiceCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
            [cell prepareForUse:messageModel.isFromMe];
            cell.messageModel = messageModel;
            
            _cell = cell;
            break;
        }
        case kLLMessageBodyTypeVideo: {
            LLMessageVideoCell *cell = [[LLMessageVideoCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseId];
            [cell prepareForUse:messageModel.isFromMe];
            cell.messageModel = messageModel;
            
            _cell = cell;
            break;
        }
        default:
            break;
            
    }
    if (_cell) {
        _allCells[messageModel.messageId] = _cell;
        [_cell setNeedsLayout];
        [_cell layoutIfNeeded];
    }
    
    return _cell;
}

- (LLMessageBaseCell *)cellForMessageId:(NSString *)messageId {
    return self.allCells[messageId];
}

- (LLMessageBaseCell *)removeCellForMessageId:(NSString *)messageId {
    LLMessageBaseCell *cell = self.allCells[messageId];
    [self.allCells removeObjectForKey:messageId];
    return cell;
}

- (void)removeCellsForMessageIdsInArray:(NSArray<NSString *> *)messageIds {
    [self.allCells removeObjectsForKeys:messageIds];
}

- (void)addCell:(LLMessageBaseCell *)cell  forMessageId:(NSString *)messageId {
    self.allCells[messageId] = cell;
}

- (void)deleteConversation:(NSString *)conversationId {
    NSMutableArray<NSString *> *keys = [NSMutableArray array];
    for (NSString *key in self.allCells) {
        LLMessageBaseCell *cell = self.allCells[key];
        if ([cell.messageModel.conversationId isEqualToString:conversationId]) {
            [keys addObject:key];
        }
    }
    
    if (keys.count > 0)
        [self.allCells removeObjectsForKeys:keys];
    
}


@end
