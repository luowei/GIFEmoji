//
// Created by Luo Wei on 2017/12/26.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import "Categories.h"
#import <CommonCrypto/CommonDigest.h>


@implementation Categories {

}
@end

@implementation NSData (Ext)


//FILE SIGNATURES TABLE:https://www.garykessler.net/library/file_sigs.html
//List of file signatures:https://en.wikipedia.org/wiki/List_of_file_signatures

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
        case 0x66:{
            uint16_t s;
            [self getBytes:&s length:1];
            if(s == 0xFFFB){
                return @"video/x";
            }
            return @"application/octet-stream";
        }
        default:{
            return @"application/octet-stream";
        }

    }
    return nil;
}

/*
[4 byte offset]
66 74 79 70 33 67 70	 	[4 byte offset]
ftyp3gp
3GG, 3GP, 3G2	 	3rd Generation Partnership Project 3GPP multimedia files

[4 byte offset]
66 74 79 70 4D 34 41 20	 	[4 byte offset]
ftypM4A
M4A	 	Apple Lossless Audio Codec file

[4 byte offset]
66 74 79 70 4D 34 56 20	 	[4 byte offset]
ftypM4V
FLV, M4V	 	ISO Media, MPEG v4 system, or iTunes AVC-LC file.

[4 byte offset]
66 74 79 70 4D 53 4E 56	 	[4 byte offset]
ftypMSNV
MP4	 	MPEG-4 video file

[4 byte offset]
66 74 79 70 69 73 6F 6D	 	[4 byte offset]
ftypisom
MP4	 	ISO Base Media file (MPEG-4) v1

[4 byte offset]
66 74 79 70 6D 70 34 32	 	[4 byte offset]
ftypmp42
M4V	 	MPEG-4 video|QuickTime file

[4 byte offset]
66 74 79 70 71 74 20 20	 	[4 byte offset]
ftypqt
MOV	 	QuickTime movie file
 */
-(NSString *)videoType {

    uint16_t bytes[4];  // <=>
    [self getBytes:&bytes length:1];

    NSMutableString *str = nil;
    for(int i=0;i<4;i++){
        if(!str){
            str = @"".mutableCopy;
        }
        NSLog(@"===byte%d:%x",i,bytes[i]);
        [str appendFormat:@"%x",bytes[i]];
    }
    return str;
}

@end

@implementation NSString (Ext)

- (CGFloat)widthWithFont:(UIFont *)font {
    NSDictionary *attributes = @{NSFontAttributeName : font};
    return [[[NSAttributedString alloc] initWithString:self attributes:attributes] size].width;
}

- (CGFloat)heigthWithWidth:(CGFloat)width andFont:(UIFont *)font andAttributes:(NSDictionary *)attributes {

    NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:self attributes:attributes];
    CGRect rect = [attrStr boundingRectWithSize:CGSizeMake(width, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading context:nil];
    return rect.size.height;
}

- (void)enumerateCharactersUsingBlock:(void (^)(NSString *character, NSInteger idx, bool *stop))block {
    bool _stop = NO;
    for (NSInteger i = 0; i < [self length] && !_stop; i++) {
        NSString *character = [self substringWithRange:NSMakeRange(i, 1)];
        block(character, i, &_stop);
    }
}

-(NSString *)URLDecode{
    return [self stringByRemovingPercentEncoding];
}

-(NSString *)URLEncode{
    return [self stringByAddingPercentEncodingWithAllowedCharacters:
            [[NSCharacterSet characterSetWithCharactersInString:@"!*'\"();:@&=+$,/?%#[]% "] invertedSet] ];
}

@end

@implementation NSString (Encode)

//md5 32位 加密 （小写）
- (NSString *)md5 {
    const char *cStr = [self UTF8String];
    unsigned char result[16];
    CC_MD5(cStr, (CC_LONG) strlen(cStr), result);
    return [NSString stringWithFormat:
            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
            result[0], result[1], result[2], result[3],
            result[4], result[5], result[6], result[7],
            result[8], result[9], result[10], result[11],
            result[12], result[13], result[14], result[15]];
}
- (NSString*) mk_urlEncodedString { // mk_ prefix prevents a clash with a private api

    CFStringRef encodedCFString = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            (__bridge CFStringRef) self,
            nil,
            CFSTR("?!@#$^&%*+,:;='\"`<>()[]{}/\\| "),
            kCFStringEncodingUTF8);

    NSString *encodedString = [[NSString alloc] initWithString:(__bridge_transfer NSString*) encodedCFString];

    if(!encodedString)
        encodedString = @"";

    return encodedString;
}
@end

@implementation NSString (Match)


- (BOOL)isMatchString:(NSString *)pattern {
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];
    if (error) {
        return NO;
    }
    NSTextCheckingResult *res = [regex firstMatchInString:self options:0 range:NSMakeRange(0, self.length)];
    return res != nil;
}

- (BOOL)isiTunesURL {
    return [self isMatchString:@"\\/\\/itunes\\.apple\\.com\\/"];
}

//是否是域名
- (BOOL)isDomain {
    return [self isMatchString:@"^([a-zA-Z0-9]([a-zA-Z0-9\\-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,6}$"]
            || [self isMatchString:@"^(www.|[a-zA-Z].)[a-zA-Z0-9\\-\\.]+\\.(com|edu|gov|mil|net|org|biz|info|name|museum|us|ca|uk)(\\:[0-9]+)*(/($|[a-zA-Z0-9\\.\\,\\;\\?\\'\\\\\\+&amp;%\\$#\\=~_\\-]+))*$"];
}

//是否是网址
- (BOOL)isHttpURL {
    return [self isMatchString:@"(http|ftp|https):\\/\\/[\\w\\-_]+(\\.[\\w\\-_]+)+([\\w\\-\\.,@?^=%&amp;:/~\\+#]*[\\w\\-\\@?^=%&amp;/~\\+#])?"]
            || [self isMatchString:@"^(http|https|ftp)\\://([a-zA-Z0-9\\.\\-]+(\\:[a-zA-Z0-9\\.&amp;%\\$\\-]+)*@)?((25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])|([a-zA-Z0-9\\-]+\\.)*[a-zA-Z0-9\\-]+\\.[a-zA-Z]{2,4})(\\:[0-9]+)?(/[^/][a-zA-Z0-9\\.\\,\\?\\'\\\\/\\+&amp;%\\$#\\=~_\\-@]*)*$"]
            || [self isMatchString:@"^(http|https|ftp)\\://([a-zA-Z0-9\\.\\-]+(\\:[a-zA-Z0-9\\.&amp;%\\$\\-]+)*@)*((25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9])\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]{1}[0-9]{2}|[1-9]{1}[0-9]{1}|[0-9])|localhost|([a-zA-Z0-9\\-]+\\.)*[a-zA-Z0-9\\-]+\\.(com|edu|gov|int|mil|net|org|biz|arpa|info|name|pro|aero|coop|museum|[a-zA-Z]{2}))(\\:[0-9]+)*(/($|[a-zA-Z0-9\\.\\,\\?\\'\\\\\\+&amp;%\\$#\\=~_\\-]+))*$"];
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


@implementation NSURL (Extension)

- (NSDictionary *)queryDictionary {
    NSMutableDictionary *queryStrings = @{}.mutableCopy;
    for (NSString *qs in [self.query componentsSeparatedByString:@"&"]) {
        // Get the parameter name
        NSString *key = [[qs componentsSeparatedByString:@"="] objectAtIndex:0];
        // Get the parameter value
        NSString *value = [[qs componentsSeparatedByString:@"="] objectAtIndex:1];
        //value = [value stringByReplacingOccurrencesOfString:@"+" withString:@" "];
        value = [value stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];

        queryStrings[key] = value;
    }
    return queryStrings;
}

-(BOOL)urlIsImage {
    NSMutableURLRequest *request = [[NSURLRequest requestWithURL:self] mutableCopy];
    NSURLResponse *response = nil;
    NSError *error = nil;
    [request setValue:@"HEAD" forKey:@"HTTPMethod"];
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    NSString *mimeType = [response MIMEType];
    if(!mimeType){
        return false;
    }
    NSRange range = [mimeType rangeOfString:@"image"];
    return (range.location != NSNotFound);
}

@end




