//
// Created by luowei on 2018/1/24.
// Copyright (c) 2018 wodedata. All rights reserved.
//

#import "ShareCategories.h"

@implementation NSData (Ext)


/*
video files mimetype
Video Type	Extension	MIME Type
Flash	.flv	video/x-flv
MPEG-4	.mp4	video/mp4
iPhone Index	.m3u8	application/x-mpegURL
iPhone Segment	.ts	video/MP2T
3GP Mobile	.3gp	video/3gpp
QuickTime	.mov	video/quicktime
A/V Interleave	.avi	video/x-msvideo
Windows Media	.wmv	video/x-ms-wmv
 */

- (NSString *)mimeType {
    uint8_t c;
    [self getBytes:&c length:1];

    //文件头签名列表：https://en.wikipedia.org/wiki/List_of_file_signatures
    //mime type:https://www.sitepoint.com/mime-types-complete-list/
    switch (c) {
        case 0xFF:{
            uint16_t s;
            [self getBytes:&s length:1];
            if(s == 0xFFFB){
                return @"audio/mpeg3";
            }
            return @"image/jpeg";
        }
        case 0x89:{
            return @"image/png";
        }
        case 0x47:{
            return @"image/gif";
        }
        case 0x49:
        case 0x4D:{
            uint16_t s;
            [self getBytes:&s length:1];
            if(s == 0x4944){
                return @"audio/mpeg3";
            }
            return @"image/tiff";
        }
        case 0x25:{
            return @"application/pdf";
        }
        case 0xD0:{
            return @"application/vnd";
        }
        case 0x23:
        case 0x7b:  //rtf
        case 0x81:  //WordPerfect text file
        case 0x46:{
            return @"text/plain";
        }
        case 0x50:{  //zip,jar,odt,ods,odp,docx,xlsx,pptx,vsdx,apk,aar
            return @"application/zip";
        }
        case 0x52:{ //avi,wav
            return @"video/avi";
        }
        default:{
            return @"application/octet-stream";
        }

    }
    return nil;
}

@end


@implementation NSString (Addtion)

-(BOOL)isBlank{
    if([self length] == 0) { //string is empty or nil
        return YES;
    }
    return ![[self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length];
}

-(BOOL)isNotBlank{
    NSString *trimStr = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return [trimStr length] > 0;
}

-(BOOL)containsChineseCharacters{
    NSRange range = [self rangeOfString:@"\\p{Han}" options:NSRegularExpressionSearch];
    return range.location != NSNotFound;
}

- (NSString *)subStringWithRegex:(NSString *)regexText matchIndex:(NSUInteger)index{
    __block NSString *text = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexText options:NSRegularExpressionCaseInsensitive error:nil];
    [regex enumerateMatchesInString:self options:0 range:NSMakeRange(0, [self length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        if(match && match.range.length >= index){
            text = [self substringWithRange:[match rangeAtIndex:index]];
        }
    }];
    return text;
}

- (NSArray<NSString *> *)matchStringWithRegex:(NSString *)regexText{
    __block NSMutableArray *matchArr = @[].mutableCopy;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"([^&?]*?=[^&?]*)" options:NSRegularExpressionCaseInsensitive error:nil];
    [regex enumerateMatchesInString:self options:0 range:NSMakeRange(0, [self length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        if(match && match.range.length > 0){
            NSString *text = [self substringWithRange:[match rangeAtIndex:0]];
            [matchArr addObject:text];
        }
    }];
    return matchArr;
}


@end

@implementation NSString (Base64)

-(NSString *)base64Encode{
    NSData *encodeData = [self dataUsingEncoding:NSUTF8StringEncoding];
    NSString *base64String = [encodeData base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    return base64String;
}

-(NSString *)base64Decode{
    NSData *decodedData = [[NSData alloc] initWithBase64EncodedString:self options:0];
    NSString *decodedString = [[NSString alloc] initWithData:decodedData encoding:NSUTF8StringEncoding];
    return decodedString;
}

@end


@implementation UIResponder (Extension)

//获得指class类型的父视图
- (id)superViewWithClass:(Class)clazz {
    UIResponder *responder = self;
    while (![responder isKindOfClass:clazz]) {
        responder = [responder nextResponder];
        if (nil == responder) {
            break;
        }
    }
    return responder;
}


//打开指定url
- (void)openURLWithUrl:(NSURL *)url {
    UIResponder *responder = self;
    while ((responder = [responder nextResponder]) != nil) {
        if ([responder respondsToSelector:@selector(openURL:)]) {
            [responder performSelector:@selector(openURL:) withObject:url];
        }
    }
}

//打开指定urlString
- (void)openURLWithString:(NSString *)urlString {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    UIResponder *responder = self;
    while ((responder = [responder nextResponder]) != nil) {
        if ([responder respondsToSelector:@selector(openURL:)]) {
            [responder performSelector:@selector(openURL:) withObject:url];
        }
    }
}

//检查是否能打开指定urlString
- (BOOL)canOpenURLWithString:(NSString *)urlString {
    NSURL *url = [[NSURL alloc] initWithString:urlString];
    UIResponder *responder = self;
    while ((responder = [responder nextResponder]) != nil) {
        if ([responder respondsToSelector:@selector(canOpenURL:)]) {
            NSNumber *result = [responder performSelector:@selector(canOpenURL:) withObject:url];
            return result.boolValue;
        }
    }
    return NO;
}

@end


