//
// Created by Luo Wei on 2017/12/26.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Categories : NSObject


@end

@interface NSData (Ext)

- (NSString *)mimeType;

-(NSString *)videoType;

@end


@interface NSString (Ext)

- (CGFloat)widthWithFont:(UIFont *)font;

- (CGFloat)heigthWithWidth:(CGFloat)width andFont:(UIFont *)font andAttributes:(NSDictionary *)attributes;

- (void)enumerateCharactersUsingBlock:(void (^)(NSString *character, NSInteger idx, bool *stop))block;

-(NSString *)URLDecode;
-(NSString *)URLEncode;

@end

@interface NSString (Encode)

- (NSString *)md5;
- (NSString*) mk_urlEncodedString;

@end

@interface NSString(Match)

- (BOOL)isMatchString:(NSString *)pattern;

- (BOOL)isiTunesURL;

- (BOOL)isDomain;

- (BOOL)isHttpURL;

@end


@interface NSString (Addtion)

-(BOOL)isBlank;

-(BOOL)isNotBlank;

-(BOOL)containsChineseCharacters;

- (NSString *)subStringWithRegex:(NSString *)regexText matchIndex:(NSUInteger)index;

- (NSArray<NSString *> *)matchStringWithRegex:(NSString *)regexText;

@end


@interface NSURL (Extension)


- (NSDictionary *)queryDictionary;
-(BOOL)urlIsImage;


@end

@interface NSArray (Contains)

-(BOOL)containsString:(NSString *)str;

@end
