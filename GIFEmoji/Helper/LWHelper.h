//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_OPTIONS(NSUInteger, FileCopyOption) {
    FileExsist_Update = 0,       //已存在的文件覆盖，不存在的文件新增
    FileExsist_Ignore = 1,       //已存在的文件忽略，不存在的文件新增，境量拷贝
    FileExist_Replace = 2,      //已存在的文件或文件夹删除，再拷贝，完全替换
};

@interface LWHelper : NSObject

+(NSString *)getCurrentTimeStampText;

//获取UserAgent
+(NSString *)getiOSUserAgent;

//在Documents目录下创建一个名为InputBgImg的文件夹
+ (NSString *)createIfNotExistsDirectory:(NSString *)dirName;


//把bundle下的名为fileNmae的文件拷贝到沙盒目录下
+(NSString *)copy2DocumentsWithFileName:(NSString *)name;

//Copy Path
+(void)copySourcePath:(NSString *)sourcePath targetPath:(NSString *)targetPath option:(FileCopyOption)option;

//拷贝文件夹
+ (void)copyDirectorySource:(NSString *)sourcePath targetPath:(NSString *)targetPath option:(FileCopyOption)option;

//拷贝文件
+ (void)copyFileSource:(NSString *)sourcePath targetPath:(NSString *)targetPath option:(FileCopyOption)option;

//截取视频
+ (void)getTrimmedVideoForFile:(NSString *)filePath
                     videoType:(NSString *)videoType
                 withStartTime:(Float64)startTime
                       endTime:(Float64)endTime
             completionHandler:(void (^)(NSString *))completionHandler;

@end