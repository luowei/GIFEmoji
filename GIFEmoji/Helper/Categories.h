//
// Created by Luo Wei on 2017/12/26.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface Categories : NSObject


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

