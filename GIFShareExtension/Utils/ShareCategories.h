//
// Created by luowei on 2018/1/24.
// Copyright (c) 2018 wodedata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NSData (Ext)

- (NSString *)mimeType;

-(NSString *)videoType;

@end


@interface NSString (Addtion)

-(BOOL)isBlank;

-(BOOL)isNotBlank;

-(BOOL)containsChineseCharacters;

- (NSString *)subStringWithRegex:(NSString *)regexText matchIndex:(NSUInteger)index;

- (NSArray<NSString *> *)matchStringWithRegex:(NSString *)regexText;

@end

@interface NSString (Base64)

-(NSString *)base64Encode;

-(NSString *)base64Decode;

@end

@interface UIResponder (Extension)

//获得指class类型的父视图
- (id)superViewWithClass:(Class)clazz;

//打开指定url
- (void)openURLWithUrl:(NSURL *)url;
//打开指定urlString
- (void)openURLWithString:(NSString *)urlString;

//检查是否能打开指定urlString
- (BOOL)canOpenURLWithString:(NSString *)urlString;

@end



