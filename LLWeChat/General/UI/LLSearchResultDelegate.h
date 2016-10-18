//
//  LLSearchResultDelegate.h
//  LLWeChat
//
//  Created by GYJZH on 8/24/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LLSearchResultDelegate <NSObject>

- (void)searchTextDidChange:(NSString *)searchText;

- (void)searchButtonDidTapped:(NSString *)searchText;

- (void)searchCancelButtonDidTapped;

@optional

//是否在SearchController动画前显示搜索结果Controller，默认为YES
- (BOOL)shouldShowSearchResultControllerBeforePresentation;

//当没有执行搜索时，是否隐藏搜索结果Controller，默认为NO
//注意：不是指没有搜索结果，而是指取消当前搜索，比如用户点击空白后取消SearchBar焦点，
//或者用户清空搜索字符串等
- (BOOL)shouldHideSearchResultControllerWhenNoSearch;

//动画不需要对self.view.frame做动画
- (void (^)())animationForPresentation;

//动画不需要对self.view.frame做动画
- (void (^)())animationForDismiss;

@end
