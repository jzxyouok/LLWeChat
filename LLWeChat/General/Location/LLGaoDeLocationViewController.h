//
//  LLGaoDeLocationViewController.h
//  LLWeChat
//
//  Created by GYJZH on 8/22/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MAMapKit/MAMapKit.h>
#import <AMapLocationKit/AMapLocationKit.h>
#import <AMapSearchKit/AMapSearchKit.h>

@class LLGaoDeLocationViewController;
@protocol LLLocationViewDelegate <NSObject>
@optional

//发送地址消息，delegate收到该消息后，应该注销掉LocationManager
-(void)didFinishWithLocationLatitude:(double)latitude
                           longitude:(double)longitude
                                name:(NSString *)name
                             address:(NSString *)address
                           zoomLevel:(double)zoomLevel
                            snapshot:(UIImage *)snapshot;

- (void)didCancelLocationViewController:(LLGaoDeLocationViewController *)locationViewController;

@end



@interface LLGaoDeLocationViewController : UIViewController

@property (nonatomic, weak) id<LLLocationViewDelegate> delegate;

- (void)didRowWithModelSelected:(AMapPOI *)poiModel;

@end
