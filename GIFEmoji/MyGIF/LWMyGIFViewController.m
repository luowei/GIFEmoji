//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWMyGIFViewController.h"
#import "LWTopScrollView.h"
#import "LWSymbolService.h"
#import "LWTextInputView.h"


@implementation LWMyGIFViewController {

}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray <LWCategory *>*categoryList = [[LWSymbolService symbolService] categoriesList];
    [self.topScrollView setupSubviewWithCategoryList:categoryList];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction:)];

}

//右侧的按钮被点击
- (void)rightBarItemAction:(UIBarButtonItem *)rightBarItemAction {
    //添加分类
    [LWTextInputView showTextInputViewInView:self.view];
}

//更新顶部导航条
- (void)updateTopScrollView {
    [self.topScrollView updateCategoryList];
}

@end


