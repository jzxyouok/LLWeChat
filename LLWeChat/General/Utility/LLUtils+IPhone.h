//
//  LLUtils+IPhone.h
//  LLWeChat
//
//  Created by GYJZH on 9/10/16.
//  Copyright © 2016 GYJZH. All rights reserved.
//

#import "LLUtils.h"
#import "Reachability.h"
#import <AudioToolbox/AudioToolbox.h>
#import <CoreTelephony/CTCarrier.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>

typedef NS_ENUM(NSInteger, LLNetconnectionType) {
    kLLNetconnectionTypeNone = 0,
    kLLNetconnectionType2G,
    kLLNetconnectionType3G,
    kLLNetconnectionType4G,
    kLLNetconnectionTypeWifi,
    kLLNetconnectionTypeOther
};

@interface LLUtils (IPhone)

+ (CGFloat)systemVersion;

//当前手机是否支持PhotoKit照片库框架
+ (BOOL)canUsePhotiKit;

//拨打电话
+ (void)callPhoneNumber:(NSString *)phone;

//复制字符串到系统剪贴板
+ (void)copyToPasteboard:(NSString *)string;

+ (NSString *)appName;

+ (NSString *)getApplicationScheme;

//获取当前网络类型
+ (LLNetconnectionType)getNetconnectionType;

//保存图片到系统相册
+ (void)saveImageToPhotoAlbum:(UIImage *)image;

//保存视频到系统相册
+ (void)saveVideoToPhotoAlbum:(NSString *)videoPath;

+ (NSString *)deviceModelName;



@end
