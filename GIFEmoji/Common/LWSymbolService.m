//
// Created by Luo Wei on 2017/11/26.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import <sqlite3.h>
#import "LWSymbolService.h"
#import "AppDefines.h"
#import "LWHelper.h"


@implementation LWSymbolService {
    sqlite3 *_db;
}

+ (LWSymbolService *)symbolService {
    NSString *dbPath = [LWHelper copy2DocumentsWithFileName:DBFileName];
    LWSymbolService *service = [[LWSymbolService alloc] initWithDBPath:dbPath];
    return service;
}


- (instancetype)initWithDBPath:(NSString *)dbPath {
    self = [super init];
    if (self) {
        self.dbPath = dbPath;
        //打开Wubi数据库
        [self openDatabase];
    }

    return self;
}


//打开数据库
- (BOOL)openDatabase {
    int result = sqlite3_open([self.dbPath UTF8String], &_db);
    if (SQLITE_OK != result) {
        NSLog(@"打开 BihuaWords DB失败 = %d", result);
        sqlite3_close(_db);
        _db = nil;
        return NO;
    }
//    //验证密码
//    const char* key = [@"luowei.wodedata.com" UTF8String];
//    sqlite3_key(_db, key, (int) strlen(key));
    int res = sqlite3_exec(_db, (const char*) "SELECT count(*) FROM sqlite_master;", NULL, NULL, NULL);
    if (res == SQLITE_OK) {
        Log(@"password is correct, or, database has been initialized");
    } else {
        Log(@"incorrect password! errCode:%d",result);
        return NO;
    }

    return YES;
}

- (void)dealloc {
    sqlite3_close(_db);
    _db = nil;
}

#pragma mark - Category

//获取分类列表
- (NSMutableArray<LWCategory *> *)categoriesList {
    if (!_db) {
        [self openDatabase];
    }

    NSMutableArray <LWCategory *>*list = @[].mutableCopy;

    NSString *sqlQuery = [NSString stringWithFormat:@"select `id`,`type`,`name`,`en_name`,`file_url`,`http_url`,`selected` from categories order by `id`;"];
    //NSString *sqlQuery = [NSString stringWithFormat:@"SELECT * FROM words_wubi_combined WHERE code LIKE '%@%' ORDER BY count ASC LIMIT 20", param];
    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(_db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSUInteger _id = (NSUInteger) sqlite3_column_int(statement, 0);
            NSString *typeText = [self stringWith:statement index:1];;
            NSString *name = [self stringWith:statement index:2];;
            NSString *en_name = [self stringWith:statement index:3];;
            NSString *file_url = [self stringWith:statement index:4];;
            NSString *http_url = [self stringWith:statement index:5];;
            BOOL selectStatus = sqlite3_column_int(statement, 6) != 0;
            LWCategory *categroy = [[LWCategory alloc] initWithId:_id type:typeText name:name en_name:en_name file_url:file_url http_url:http_url select:selectStatus order:0];
            [list addObject:categroy];
        }
        sqlite3_finalize(statement);
    }
    return list;
}


//查询categories
- (NSMutableArray <LWCategory *> *)categoriesWithType:(NSString *)type {
    if (!_db) {
        [self openDatabase];
    }

    NSMutableArray *list = @[].mutableCopy;

    type = [self handleWhereParame:type];
    NSString *sqlQuery = [NSString stringWithFormat:@"select `id`,`type`,`name`,`en_name`,`file_url`,`http_url`,`selected` from categories where `type` %@ order by `id`;", type];
    //NSString *sqlQuery = [NSString stringWithFormat:@"SELECT * FROM words_wubi_combined WHERE code LIKE '%@%' ORDER BY count ASC LIMIT 20", param];
    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(_db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSUInteger _id = (NSUInteger) sqlite3_column_int(statement, 0);
            NSString *typeText = [self stringWith:statement index:1];;
            NSString *name = [self stringWith:statement index:2];;
            NSString *en_name = [self stringWith:statement index:3];;
            NSString *file_url = [self stringWith:statement index:4];;
            NSString *http_url = [self stringWith:statement index:5];;
            BOOL selectStatus = sqlite3_column_int(statement, 6) != 0;
            LWCategory *categroy = [[LWCategory alloc] initWithId:_id type:typeText name:name en_name:en_name file_url:file_url http_url:http_url select:selectStatus order:0];
            [list addObject:categroy];
        }
        sqlite3_finalize(statement);
    }
    return list;
}

//根据type与name 查询 categoryId
- (NSUInteger)categoryIdWithType:(NSString *)type name:(NSString *)name {
    if (!_db) {
        [self openDatabase];
    }

    type = [self handleWhereParame:type];
    name = [self handleWhereParame:name];

    NSString *sqlQuery = [NSString stringWithFormat:@"select `id`,`type`,`name`,`en_name`,`file_url`,`http_url`,`selected` from categories where `type` %@ and `name` %@ order by `id`;", type, name];
    //NSString *sqlQuery = [NSString stringWithFormat:@"SELECT * FROM words_wubi_combined WHERE code LIKE '%@%' ORDER BY count ASC LIMIT 20", param];
    sqlite3_stmt *statement;

    NSUInteger _id = 0;
    if (sqlite3_prepare_v2(_db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            _id = (NSUInteger) sqlite3_column_int(statement, 0);
            break;
        }
        sqlite3_finalize(statement);
    }
    return _id;
}

//根据type找出当前选中的Category
-(LWCategory *)selectedCategoryWithType:(NSString *)type {
    if (!_db) {
        [self openDatabase];
    }

    type = [self handleWhereParame:type];

    NSString *sqlQuery = [NSString stringWithFormat:@"select `id`,`type`,`name`,`en_name`,`file_url`,`http_url`,`selected` from categories where `selected` <> 0 and `type` %@ order by `id`;", type];
    sqlite3_stmt *statement;

    LWCategory *categroy = nil;
    if (sqlite3_prepare_v2(_db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSUInteger _id = (NSUInteger) sqlite3_column_int(statement, 0);
            NSString *typeText = [self stringWith:statement index:1];;
            NSString *name = [self stringWith:statement index:2];;
            NSString *en_name = [self stringWith:statement index:3];;
            NSString *file_url = [self stringWith:statement index:4];;
            NSString *http_url = [self stringWith:statement index:5];;
            BOOL selectStatus = sqlite3_column_int(statement, 6) != 0;
            categroy = [[LWCategory alloc] initWithId:_id type:typeText name:name en_name:en_name file_url:file_url http_url:http_url select:selectStatus order:0];
            break;
        }
        sqlite3_finalize(statement);
    }

    return categroy;
}

//更新Category Name
- (BOOL)updateCategoryName:(NSString *)name byId:(NSUInteger)id {
    if (!_db) {
        [self openDatabase];
    }

    BOOL isSuccess = NO;
    //NSString *numCode = [self convert2NumCode:code];
    if (!name || [name length] <= 0) {
        return isSuccess;
    }

    name = [self handleUpdateParame:name];
    NSString *unselectSql = [NSString stringWithFormat:@"update categories set `name` = %@ where `id` = %d;", name,id];
    isSuccess = [self updateSql:unselectSql];

    return isSuccess;
}


//更新select字段
- (BOOL)updateSelectedWithCategoryId:(NSUInteger)categoryId type:(NSString *)type {
    if (!_db) {
        [self openDatabase];
    }

    BOOL isSuccess = NO;
    //NSString *numCode = [self convert2NumCode:code];
    if (!type || [type length] <= 0) {
        return isSuccess;
    }

    type = [self handleWhereParame:type];

    NSString *unselectSql = [NSString stringWithFormat:@"update categories set `selected` = 0 where type %@ and `selected` <> 0;", type];
    NSString *selectSql = [NSString stringWithFormat:@"update categories set `selected` = 1 where id = %i;", categoryId];
    [self updateSql:unselectSql];
    isSuccess = [self updateSql:selectSql];

    return isSuccess;
}

//更新并获取默认的选中字段
- (LWCategory *)getAndUpdateDefaultSelectedCategoryWithType:(NSString *)type {
    if (!_db) {
        [self openDatabase];
    }
    type = [self handleWhereParame:type];

    //查询
    NSString *selectSQL = [NSString stringWithFormat:@"select `id`,`type`,`name`,`en_name`,`file_url`,`http_url`,`selected` from categories where type %@ order by `id` limit 1;",type];
    sqlite3_stmt *statement;

    LWCategory *categroy = nil;
    if (sqlite3_prepare_v2(_db, [selectSQL UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSUInteger _id = (NSUInteger) sqlite3_column_int(statement, 0);
            NSString *typeText = [self stringWith:statement index:1];;
            NSString *name = [self stringWith:statement index:2];;
            NSString *en_name = [self stringWith:statement index:3];;
            NSString *file_url = [self stringWith:statement index:4];;
            NSString *http_url = [self stringWith:statement index:5];;
            BOOL selectStatus = sqlite3_column_int(statement, 6) != 0;
            categroy = [[LWCategory alloc] initWithId:_id type:typeText name:name en_name:en_name file_url:file_url http_url:http_url select:selectStatus order:0];
            break;
        }
        sqlite3_finalize(statement);
    }

    //更新
    NSString *updateSQL = [NSString stringWithFormat:@"update categories set selected = 1 where id = %i;",categroy._id];
    [self updateSql:updateSQL];
    categroy.select = YES;

    return categroy;
}


//插入一种类型
- (BOOL)insertCategoryWithType:(NSString *)type
                          name:(NSString *)name
                       en_name:(NSString *)en_name
                      file_url:(NSString *)file_url
                      http_url:(NSString *)http_url {
    if (!_db) {
        [self openDatabase];
    }

    NSString *update_type = [self handleUpdateParame:type];
    NSString *update_name = [self handleUpdateParame:name];
    NSString *update_en_name = [self handleUpdateParame:en_name];
    NSString *update_file_url = [self handleUpdateParame:file_url];
    NSString *update_http_url = [self handleUpdateParame:http_url];

    NSString *where_type = [self handleWhereParame:type];
    NSString *where_name = [self handleWhereParame:name];
    NSString *where_en_name = [self handleWhereParame:en_name];
    NSString *where_file_url = [self handleWhereParame:file_url];
    NSString *where_http_url = [self handleWhereParame:http_url];

    BOOL isSuccess = NO;
    NSString *insertSql = [NSString stringWithFormat:@"insert into categories(`type`,`name`,`en_name`,`file_url`,`http_url`,`selected`) values(%@,%@,%@,%@,%@,0);", update_type, update_name, update_en_name, update_file_url, update_http_url];
    isSuccess = [self updateSql:insertSql];

    return isSuccess;
}

//根据id删除类型
- (BOOL)deleteCategoryWithId:(NSUInteger)_id {
    if (!_db) {
        [self openDatabase];
    }
    BOOL isSuccess = NO;
    NSString *deleteSql = [NSString stringWithFormat:@"delete from categories where `id` = %i", _id];
    isSuccess = [self execSql:deleteSql];
    return isSuccess;
}


#pragma mark - Symbol

//查询指定类型的符号list
- (NSMutableArray <LWSymbol *> *)symbolsWithCategoryId:(NSUInteger)categoryId {
    if (!_db) {
        [self openDatabase];
    }
    NSMutableArray *list = @[].mutableCopy;
    NSString *sqlQuery = [NSString stringWithFormat:@"select `id`,`category_id`,`title`,`text`,`file_url`,`http_url`,`frequency` from symbols where category_id = %i order by `id` asc,`frequency` desc,`modify_date` desc;", categoryId];
    //NSString *sqlQuery = [NSString stringWithFormat:@"SELECT * FROM words_wubi_combined WHERE code LIKE '%@%' ORDER BY count ASC LIMIT 20", param];
    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(_db, [sqlQuery UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSUInteger _id = (NSUInteger) sqlite3_column_int(statement, 0);
            NSUInteger categyId = (NSUInteger) sqlite3_column_int(statement, 1);
            NSString *title = [self stringWith:statement index:2];
            NSString *text = [self stringWith:statement index:3];;
            NSString *file_url = [self stringWith:statement index:4];;
            NSString *http_url = [self stringWith:statement index:5];;
            NSUInteger frequency = (NSUInteger) sqlite3_column_int(statement, 6);
            LWSymbol *symbol = [[LWSymbol alloc] initWithId:_id categoryId:categyId title:title text:text file_url:file_url http_url:http_url frequency:frequency order:0];
            [list addObject:symbol];
        }
        sqlite3_finalize(statement);
    }
    return list;
}


//插入一种符号
- (BOOL)insertSymbolWithCategoryId:(NSUInteger)categoryId
                             title:(NSString *)title
                              text:(NSString *)text
                          file_url:(NSString *)file_url
                          http_url:(NSString *)http_url {
    if (!_db) {
        [self openDatabase];
    }
    BOOL isSuccess = NO;

    NSString *update_title = [self handleUpdateParame:title];
    NSString *update_text = [self handleUpdateParame:text];
    NSString *update_file_url = [self handleUpdateParame:file_url];
    NSString *update_http_url = [self handleUpdateParame:http_url];

    NSString *insertSql = [NSString stringWithFormat:@"insert into symbols(`category_id`,`title`,`text`,`file_url`,`http_url`) values(%i,%@,%@,%@,%@)", categoryId, update_title, update_text, update_file_url, update_http_url];
    isSuccess = [self updateSql:insertSql];

    return isSuccess;
}

- (BOOL)updateSymbolWithId:(NSUInteger)_id file_url:(NSString *)file_url http_url:(NSString *)http_url {
    if (_id == 0) {
        return NO;
    }
    if (!_db) {
        [self openDatabase];
    }
    BOOL isSuccess = NO;

    file_url = [self handleUpdateParame:file_url];
    http_url = [self handleUpdateParame:http_url];

    NSString *insertSql = [NSString stringWithFormat:@"update symbols set file_url = %@,http_url = %@ where id = %i", file_url, http_url, _id];
    isSuccess = [self updateSql:insertSql];
    return isSuccess;
}


- (BOOL)updateSymbolWithId:(NSUInteger)_id file_url:(NSString *)file_url text:(NSString *)text {
    if (_id == 0) {
        return NO;
    }
    if (!_db) {
        [self openDatabase];
    }
    BOOL isSuccess = NO;

    file_url = [self handleUpdateParame:file_url];
    text = [self handleUpdateParame:text];

    NSString *insertSql = [NSString stringWithFormat:@"update symbols set file_url = %@,text = %@ where id = %i", file_url, text, _id];
    isSuccess = [self updateSql:insertSql];
    return isSuccess;
}


- (BOOL)exsitSymbolWithText:(NSString *)text {
    BOOL isExsit = NO;

    text = [self handleWhereParame:text];
    NSString *exsitSql = [NSString stringWithFormat:@"select count(*) from symbols where text %@",text];
    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(_db, [exsitSql UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSUInteger count = (NSUInteger) sqlite3_column_int(statement, 0);
            if(count > 0){
                isExsit = YES;
            }
        }
        sqlite3_finalize(statement);
    }
    return isExsit;
}

- (BOOL)exsitSymbolWithHttpURL:(NSString *)urlstring {
    BOOL isExsit = NO;

    urlstring = [self handleWhereParame:urlstring];
    NSString *exsitSql = [NSString stringWithFormat:@"select count(*) from symbols where http_url %@",urlstring];
    sqlite3_stmt *statement;

    if (sqlite3_prepare_v2(_db, [exsitSql UTF8String], -1, &statement, nil) == SQLITE_OK) {
        while (sqlite3_step(statement) == SQLITE_ROW) {
            NSUInteger count = (NSUInteger) sqlite3_column_int(statement, 0);
            if(count > 0){
                isExsit = YES;
            }
        }
        sqlite3_finalize(statement);
    }
    return isExsit;
}


//根据categoryId删除的符号
- (BOOL)deleteSymbolWithCategoryId:(NSUInteger)categroyId {
    if (!_db) {
        [self openDatabase];
    }
    BOOL isSuccess = NO;
    NSString *deleteSql = [NSString stringWithFormat:@"delete from symbols where `category_id` = %i", categroyId];
    isSuccess = [self execSql:deleteSql];
    return isSuccess;
}

//根据id删除Symbol
- (BOOL)deleteSymbolWithId:(NSUInteger)_id {
    if (!_db) {
        [self openDatabase];
    }
    BOOL isSuccess = NO;
    NSString *deleteSql = [NSString stringWithFormat:@"delete from symbols where `id` = %i", _id];
    isSuccess = [self execSql:deleteSql];
    return isSuccess;
}


//更新记录
- (BOOL)updateSql:(NSString *)query {
    BOOL isSuccess = YES;
    sqlite3_stmt *updateStmt = nil;
    //重新打开数据库
//    sqlite3_close(_db);
    if(!_db){
        [self openDatabase];
    }

    if (sqlite3_prepare_v2(_db, [query UTF8String], -1, &updateStmt, NULL) != SQLITE_OK) {
        isSuccess = NO;
    }
    int resultNO = sqlite3_step(updateStmt);
    if (SQLITE_DONE != resultNO) {
        isSuccess = NO;
    }
    sqlite3_reset(updateStmt);
    sqlite3_finalize(updateStmt);
    return isSuccess;

    //sqlite3_close(dbBihuaWords);
}

//执行sql语句
- (BOOL)execSql:(NSString *)sql {
    //重新打开数据库
//    sqlite3_close(_db);
    if(!_db){
        [self openDatabase];
    }

    char *err;
    if (sqlite3_exec(_db, [sql UTF8String], NULL, NULL, &err) != SQLITE_OK) {
        //sqlite3_close(dbBihuaWords);
        NSLog(@"数据库操作数据失败!");
        return NO;
    } else {
        return YES;
    }
}

//从statement获取字符串
- (NSString *)stringWith:(sqlite3_stmt *)statement index:(int)i {
    NSString *text = nil;
    char *str = (char *) sqlite3_column_text(statement, i);
    if (str) {
        text = [NSString stringWithUTF8String:str];
    }
    return text;
}

//处理参数
- (NSString *)handleWhereParame:(NSString *)param {
    param = param ? [param stringByReplacingOccurrencesOfString:@"'" withString:@"''"] : param;
    param = param ? [NSString stringWithFormat:@" = '%@'", param] : @" is null";
    return param;
}

- (NSString *)handleUpdateParame:(NSString *)param {
    param = param ? [param stringByReplacingOccurrencesOfString:@"'" withString:@"''"] : param;
    param = param ? [NSString stringWithFormat:@"'%@'", param] : @"null";
    return param;
}

@end


@implementation LWCategory

- (instancetype)initWithId:(NSUInteger)_id
                      type:(NSString *)type
                      name:(NSString *)name
                   en_name:(NSString *)en_name
                  file_url:(NSString *)file_url
                  http_url:(NSString *)http_url
                    select:(BOOL)select
                     order:(NSUInteger)order; {
    self = [super init];
    if (self) {
        __id = _id;
        _type = type;
        _name = name;
        _en_name = en_name;
        _file_url = file_url;
        _http_url = http_url;
        _select = select;
        _order = order;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LWCategory *copy = (LWCategory *) [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy._id = self._id;
        copy.type = self.type;
        copy.name = self.name;
        copy.en_name = self.en_name;
        copy.file_url = self.file_url;
        copy.http_url = self.http_url;
        copy.select = self.select;
        copy.order = self.order;
    }

    return copy;
}


@end


@implementation LWSymbol

- (instancetype)initWithId:(NSUInteger)_id
                categoryId:(NSUInteger)categoryId
                     title:(NSString *)title
                      text:(NSString *)text
                  file_url:(NSString *)file_url
                  http_url:(NSString *)http_url
                 frequency:(NSUInteger)frequency
                     order:(NSUInteger)order {

    self = [super init];
    if (self) {
        __id = _id;
        _categoryId = categoryId;
        _title = title;
        _text = text;
        _file_url = file_url;
        _http_url = http_url;
        _frequency = frequency;
        _order = order;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    LWSymbol *copy = (LWSymbol *) [[[self class] allocWithZone:zone] init];

    if (copy != nil) {
        copy._id = self._id;
        copy.categoryId = self.categoryId;
        copy.title = self.title;
        copy.text = self.text;
        copy.file_url = self.file_url;
        copy.http_url = self.http_url;
        copy.frequency = self.frequency;
        copy.order = self.order;
    }

    return copy;
}


@end
