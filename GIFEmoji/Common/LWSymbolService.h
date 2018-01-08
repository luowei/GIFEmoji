//
// Created by Luo Wei on 2017/11/26.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "sqlite3+sqlcipher.h"

@class LWCategory;
@class LWSymbol;


@interface LWSymbolService : NSObject

#pragma mark - Category

@property(nonatomic, strong) NSString *dbPath;

+ (LWSymbolService *)symbolService;

//获取分类列表
- (NSMutableArray<LWCategory *> *)categoriesList;

//查询categories
-(NSMutableArray <LWCategory *>*)categoriesWithType:(NSString *)type;

//根据type与name 查询 categoryId
-(NSUInteger)categoryIdWithType:(NSString *)type name:(NSString *)name;

//根据type找出当前选中的Category
-(LWCategory *)selectedCategoryWithType:(NSString *)type;

//更新select字段
- (BOOL)updateSelectedWithCategoryId:(NSUInteger)categoryId type:(NSString *)type;

//更新并获取默认的选中字段
- (LWCategory *)getAndUpdateDefaultSelectedCategoryWithType:(NSString *)type;

- (BOOL)updateSymbolWithId:(NSUInteger)symbolId file_url:(NSString *)file_url text:(NSString *)text;

//插入一种类型
-(BOOL)insertCategoryWithType:(NSString *)type
                         name:(NSString *)name
                      en_name:(NSString *)en_name
                     file_url:(NSString *)file_url
                     http_url:(NSString *)http_url;

//根据id删除类型
-(BOOL)deleteCategoryWithId:(NSUInteger)_id;



#pragma mark - Symbol

//查询指定类型的符号list
-(NSMutableArray <LWSymbol *>*)symbolsWithCategoryId:(NSUInteger)categoryId;

//插入一种符号
-(BOOL)insertSymbolWithCategoryId:(NSUInteger)categoryId
                            title:(NSString *)title
                             text:(NSString *)text
                         file_url:(NSString *)file_url
                         http_url:(NSString *)http_url;

- (BOOL)exsitSymbolWithText:(NSString *)text;

//根据categoryId删除的符号
-(BOOL)deleteSymbolWithCategoryId:(NSUInteger)categroyId;

//根据id删除Symbol
-(BOOL)deleteSymbolWithId:(NSUInteger)_id;

//根据id设置url
- (BOOL)updateSymbolWithId:(NSUInteger)_id file_url:(NSString *)file_url http_url:(NSString *)http_url;

@end


@interface LWCategory : NSObject<NSCopying>

@property (nonatomic) NSUInteger _id;
@property (nonatomic,strong) NSString *type;
@property (nonatomic,strong) NSString *name;
@property (nonatomic,strong) NSString *en_name;
@property (nonatomic,strong) NSString *file_url;
@property (nonatomic,strong) NSString *http_url;
@property (nonatomic) BOOL select;
@property (nonatomic) NSUInteger order;

- (instancetype)initWithId:(NSUInteger)_id
                      type:(NSString *)type
                      name:(NSString *)name
                   en_name:(NSString *)en_name
                  file_url:(NSString *)file_url
                  http_url:(NSString *)http_url
                    select:(BOOL)select
                    order:(NSUInteger)order;

@end

@interface LWSymbol : NSObject

@property (nonatomic) NSUInteger _id;
@property (nonatomic) NSUInteger categoryId;
@property (nonatomic,strong) NSString *title;
@property (nonatomic,strong) NSString *text;
@property (nonatomic,strong) NSString *file_url;
@property (nonatomic,strong) NSString *http_url;
@property (nonatomic) NSUInteger frequency;
@property (nonatomic) NSUInteger order;

- (instancetype)initWithId:(NSUInteger)_id
                categoryId:(NSUInteger)categoryId
                     title:(NSString *)title
                      text:(NSString *)text
                  file_url:(NSString *)file_url
                  http_url:(NSString *)http_url
                 frequency:(NSUInteger)frequency
                     order:(NSUInteger)order;

@end
