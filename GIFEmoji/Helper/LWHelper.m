//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LWHelper.h"
#import "FCFileManager.h"
#import "AppDefines.h"


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

//把bundle下的名为fileNmae的文件拷贝到沙盒目录下
+(NSString *)copy2DocumentsWithFileName:(NSString *)name{
    NSString *dbPath = [[NSBundle mainBundle] pathForResource:name ofType:nil];
    NSFileManager *fmanager = [NSFileManager defaultManager];
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *docFilePath = [documentsDirectory stringByAppendingPathComponent:name];

    //在Document是不存在
    if (![fmanager fileExistsAtPath:docFilePath]) {
        //先拷贝Bundle里下的到docment目录下
        NSError *error;
        [fmanager copyItemAtPath:dbPath toPath:docFilePath error:&error];
        if (error) {
            return dbPath;
        }
    }
    return docFilePath;
}

+(void)copySourcePath:(NSString *)sourcePath targetPath:(NSString *)targetPath option:(FileCopyOption)option{
    if([FCFileManager isDirectoryItemAtPath:sourcePath]){ //如果是文件夹
        Log(@"Is directory");
        [LWHelper copyDirectorySource:sourcePath targetPath:targetPath option:option];

    }else{  //拷贝文件
        [LWHelper copyFileSource:sourcePath targetPath:targetPath option:option];
    }
}

//拷贝文件夹
+ (void)copyDirectorySource:(NSString *)sourcePath targetPath:(NSString *)targetPath option:(FileCopyOption)option {
    //如果targetPath存在,并且是文件夹
    BOOL existsItem = [FCFileManager existsItemAtPath:targetPath];
    BOOL isDirectory = [FCFileManager isDirectoryItemAtPath:targetPath];
    if(existsItem){
        if(!isDirectory){   //如果不是文件夹就删除掉
            [FCFileManager removeItemAtPath:targetPath];
            NSError *error;
            [FCFileManager createDirectoriesForPath:targetPath error:&error];
            if(error){
                Log(@"createDirectoriesForFileAtPath:%@,error:%@",targetPath,error.localizedFailureReason);
                return;
            }
        } else if (option == FileExist_Replace) {    //如果target存在，并且是替换模式就将其删除
            [FCFileManager removeFilesInDirectoryAtPath:targetPath];
            [FCFileManager removeItemAtPath:targetPath];
        }

    }else{  //不存在targetPath文件夹，则创建
        NSError *error;
        [FCFileManager createDirectoriesForPath:targetPath error:&error];
        if(error){
            Log(@"createDirectoriesForFileAtPath:%@,error:%@",targetPath,error.localizedFailureReason);
            return;
        }
    }

    //遍历sourcePath下的文件或文件夹
    NSArray *itemPathes = [FCFileManager listItemsInDirectoryAtPath:sourcePath deep:NO];
    for(NSString *path in itemPathes){
        NSString *subPath = [path substringWithRange:NSMakeRange(sourcePath.length, path.length-sourcePath.length)];
        NSString *toPath = [targetPath stringByAppendingPathComponent:subPath];

        if([FCFileManager isDirectoryItemAtPath:path]){ //如果是文件夹
            [LWHelper copyDirectorySource:path targetPath:toPath option:option];

        }else{  //是文件就拷贝文件
            [LWHelper copyFileSource:path targetPath:toPath option:option];
        }
    }
}

//拷贝文件
+ (void)copyFileSource:(NSString *)sourcePath targetPath:(NSString *)targetPath option:(FileCopyOption)option {
    if ([FCFileManager existsItemAtPath:targetPath]) {    //Target下存在

        if ([FCFileManager isFileItemAtPath:targetPath]) {    //是文件
            if (option == FileExist_Replace || option == FileExsist_Update) {
                [FCFileManager removeItemAtPath:targetPath];
                [FCFileManager copyItemAtPath:sourcePath toPath:targetPath];
            }

        } else if ([FCFileManager isDirectoryItemAtPath:targetPath]) { //是文件夹
            if (option == FileExist_Replace) {    //如果是完全替换/更新模式
                [FCFileManager removeFilesInDirectoryAtPath:targetPath];
                [FCFileManager removeItemAtPath:targetPath];
            }

        }

    } else {  //不存就直接拷贝
        [FCFileManager copyItemAtPath:sourcePath toPath:targetPath];
    }
}

//截取视频
+ (void)getTrimmedVideoForFile:(NSString *)filePath
                     videoType:(NSString *)videoType
                 withStartTime:(Float64)startTime
                       endTime:(Float64)endTime
             completionHandler:(void (^)(NSString *))completionHandler {

//[[NSFileManager defaultManager] removeItemAtURL:outputURL error:nil];
    NSURL *videoURL = [NSURL fileURLWithPath:filePath];
    if(!videoURL){
        if(completionHandler){
            completionHandler(nil);
        }
        return;
    }
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
    CMTime dur = sourceAsset.duration;

// NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSAllDomainsMask, YES);
// NSString *outputURL = paths[0];
    NSFileManager *manager = [NSFileManager defaultManager];
// [manager createDirectoryAtPath:outputURL withIntermediateDirectories:YES attributes:nil error:nil];
// outputURL = [outputURL stringByAppendingPathComponent:@"output.mp4"];

    NSString *suffix = @"mp4";
    AVFileType outputFileType = AVFileTypeMPEG4;
    if([videoType containsString:@"video/m4v"]){
        suffix = @"m4v";
        outputFileType = AVFileTypeAppleM4V;

    }else if([videoType containsString:@"video/quicktime"]){
        suffix = @"mov";
        outputFileType = AVFileTypeQuickTimeMovie;

    }else if([videoType containsString:@"video/3gpp"]){
        suffix = @"3gp";
        outputFileType = AVFileType3GPP;
    }

    NSString *outputPath = [NSString stringWithFormat:@"%@%@.%@", NSTemporaryDirectory(),[LWHelper getCurrentTimeStampText],suffix];
    NSLog(@"OUTPUT Path: %@", outputPath);
// Remove Existing File
// [manager removeItemAtPath:outputURL error:nil];

    if (![manager fileExistsAtPath:outputPath]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:sourceAsset presetName:AVAssetExportPresetMediumQuality];
        exportSession.outputURL = [NSURL fileURLWithPath:outputPath];
        //exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputFileType = outputFileType;
        CMTime start = kCMTimeZero;
        CMTime duration = kCMTimeIndefinite;
        if (dur.value > endTime) {
            start = CMTimeMakeWithSeconds(startTime, 600);
            duration = CMTimeMakeWithSeconds(endTime, 600);
        }
        exportSession.timeRange = CMTimeRangeMake(start, duration);
        [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
            switch (exportSession.status) {
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"Export Complete %d %@", exportSession.status, exportSession.error);
                    if(completionHandler){
                        completionHandler(outputPath);
                    }
                    break;
                case AVAssetExportSessionStatusFailed:
                    NSLog(@"Failed:%@", exportSession.error);
                    if(completionHandler){
                        completionHandler(nil);
                    }
                    break;
                case AVAssetExportSessionStatusCancelled:
                    NSLog(@"Canceled:%@", exportSession.error);
                    if(completionHandler){
                        completionHandler(nil);
                    }
                    break;
                default:
                    if(completionHandler){
                        completionHandler(nil);
                    }
                    break;
            }
        }];
    } else {
        if(completionHandler){
            completionHandler(outputPath);
        }
    }
}

@end
