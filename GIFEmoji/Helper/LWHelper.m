//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWHelper.h"


@implementation LWHelper {

}

+(NSString *)getCurrentTimeStampText {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *timeStampText = [dateFormatter stringFromDate:[NSDate new]];
    return timeStampText;
}

//获取UserAgent
+(NSString *)getiOSUserAgent{
//    NSString *localizedModel = UIDevice.currentDevice.localizedModel;
//    NSString *name = UIDevice.currentDevice.name;
    NSString *model = UIDevice.currentDevice.model;
//    NSString *systemName = UIDevice.currentDevice.systemName;
    NSString *systemVersion = UIDevice.currentDevice.systemVersion;
    NSString *system_Version = [systemVersion stringByReplacingOccurrencesOfString:@"." withString:@"_"];
    NSString *UUIDString = UIDevice.currentDevice.identifierForVendor.UUIDString;
    NSString *randomId = [[UUIDString stringByReplacingOccurrencesOfString:@"-" withString:@""] substringToIndex:6];
    NSString *userAgent = [NSString stringWithFormat:@"Mozilla/5.0 (%@; CPU %@ OS %@ like Mac OS X) AppleWebKit/602.2.14 (KHTML, like Gecko) Version/%@ Mobile/%@ Safari/602.1",model,model,system_Version,systemVersion,randomId];
//    Log(@"====getiOSUserAgent:%@",userAgent);

    return userAgent;
}

//在Documents目录下创建一个名为InputBgImg的文件夹
+ (NSString *)createIfNotExistsDirectory:(NSString *)dirName {

    NSFileManager *fmanager = [NSFileManager defaultManager];
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *path = [documentsDirectory stringByAppendingPathComponent:dirName];
    BOOL isDir = NO;
    BOOL isDirExist = [fmanager fileExistsAtPath:path isDirectory:&isDir];
    if(!(isDirExist && isDir)){
        [fmanager createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}


@end