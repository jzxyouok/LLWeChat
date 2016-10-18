//
//  LLMessageCellActionDelegate.h
//  LLWeChat
//
//  Created by GYJZH on 8/11/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LLMessageTextCell;
@class LLMessageImageCell;
@class LLMessageLocationCell;
@class LLMessageBaseCell;
@class LLMessageVideoCell;
@class LLMessageVoiceCell;

@protocol LLMessageCellActionDelegate <NSObject>
@optional

- (void)avatarImageDidTapped:(LLMessageBaseCell *)cell;

//点击了URL链接
- (void)cellLinkDidTapped:(LLMessageTextCell *)cell  linkURL:(NSURL *)url;

- (void)cellLinkDidLongPressed:(LLMessageTextCell *)cell linkURL:(NSURL *)url;

//点击了电话号码
- (void)cellPhoneNumberDidTapped:(LLMessageTextCell *)cell phoneNumberString:(NSString *)phone;

- (void)cellImageDidTapped:(LLMessageImageCell *)cell;

- (void)cellForLocationDidTapped:(LLMessageLocationCell *)cell;

- (void)cellVoiceDidTapped:(LLMessageVoiceCell *)cell;

- (void)cellVideoDidTapped:(LLMessageVideoCell *)cell;

- (void)resendMessage:(LLMessageModel *)model;

- (void)redownloadMessage:(LLMessageModel *)model;

- (void)selectControllDidTapped:(LLMessageModel *)model selected:(BOOL)selected;

#pragma mark - 菜单 -

- (void)willShowMenuForCell:(LLMessageBaseCell *)cell;

- (void)didShowMenuForCell:(LLMessageBaseCell *)cell;

- (void)willHideMenuForCell:(LLMessageBaseCell *)cell;

- (void)didHideMenuForCell:(LLMessageBaseCell *)cell;

//如果返回nil，则resign掉当前的FirstResponder，同时使得Cell为新的FirstResponder
//否则保留当前的FirstResponder，但需要当前FirstResponder负责Menu
- (UIResponder *)currentFirstResponderIfNeedRetain;

- (void)deleteMenuItemDidTapped:(LLMessageBaseCell *)cell;

- (void)moreMenuItemDidTapped:(LLMessageBaseCell *)cell;

@end
