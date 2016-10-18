//
//  LLChatManager+MessageExt.h
//  LLWeChat
//
//  Created by GYJZH on 9/4/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLChatManager.h"

@interface LLChatManager (MessageExt)

- (NSMutableDictionary *)encodeGifMessageExtForEmotionModel:(LLEmotionModel *)emotionModel;
- (NSData *)gifDataForGIFMessageModel:(LLMessageModel *)model;

- (NSMutableDictionary *)encodeMessageExtForVideoType:(CGFloat)fileSize duration:(CGFloat)duration naturalSize:(CGSize)naturalSize;

- (void)decodeMessageExtForVideoType:(LLMessageModel *)messageModel;

- (NSMutableDictionary *)encodeLocationMessageExt:(double)latitude longitude:(double)longitude address:(NSString *)address name:(NSString *)name zoomLevel:(CGFloat)zoomLevel;

- (void)decodeMessageExtForLocationType:(LLMessageModel *)messageModel;

@end
