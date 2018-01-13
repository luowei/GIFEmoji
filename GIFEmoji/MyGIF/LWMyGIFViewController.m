//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWMyGIFViewController.h"
#import "LWTopScrollView.h"
#import "LWSymbolService.h"
#import "LWSavePopoverViewController.h"
#import "UIColor+HexValue.h"

@interface LWMyGIFViewController() <UIPopoverPresentationControllerDelegate>

@property(nonatomic, strong) UIButton *addBtn;
@end

@implementation LWMyGIFViewController {

}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray <LWCategory *>*categoryList = [[LWSymbolService symbolService] categoriesList];
    [self.topScrollView setupSubviewWithCategoryList:categoryList];

//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction)];
    
    self.addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addBtn.frame = CGRectMake(0, 0, 40, 40);
    [self.addBtn setImage:[UIImage imageNamed:@"add"] forState:UIControlStateNormal];
    [self.addBtn addTarget:self action:@selector(rightBarItemAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:self.addBtn];
    [barItem setTintColor:[UIColor colorWithHexString:ButtonTextColor]];
    self.navigationItem.rightBarButtonItem = barItem;
}

//右侧的按钮被点击
- (void)rightBarItemAction {
    LWSavePopoverViewController *saveVC = [LWSavePopoverViewController popoverViewControllerWithDelegate:self size:CGSizeMake(150, 100) sourceView:self.addBtn];
    [self presentViewController:saveVC animated: YES completion: nil];
}

//实现该代理方法,返回UIModalPresentationNone值,可以在iPhone设备实现popover效果
-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller{
    return UIModalPresentationNone;//不适配(不区分ipad或iPhone)
}


//更新顶部导航条
- (void)updateTopScrollView {
    [self.topScrollView updateCategoryList];
}

@end


