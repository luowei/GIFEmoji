//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWMyGIFViewController.h"
#import "LWTopScrollView.h"
#import "LWSymbolService.h"


@implementation LWMyGIFViewController {

}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray <LWCategory *>*categoryList = [[LWSymbolService symbolService] categoriesList];
    [self.topScrollView setupSubviewWithCategoryList:categoryList];
}


@end