//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LWHelper : NSObject

+(NSString *)getCurrentTimeStampText;

//获取UserAgent
+(NSString *)getiOSUserAgent;

//在Documents目录下创建一个名为InputBgImg的文件夹
+ (NSString *)createIfNotExistsDirectory:(NSString *)dirName;

@end