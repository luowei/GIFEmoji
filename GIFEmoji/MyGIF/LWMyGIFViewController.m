//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWMyGIFViewController.h"
#import "LWTopScrollView.h"
#import "LWSymbolService.h"
#import "LWCategoriesPopoverViewController.h"
#import "UIColor+HexValue.h"
#import "UIImage+Extension.h"
#import "LWContainerScrollView.h"
#import "UIView+Frame.h"

@interface LWMyGIFViewController() <UIPopoverPresentationControllerDelegate>

@property(nonatomic, strong) UIButton *addBtn;
@end

@implementation LWMyGIFViewController {

}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray <LWCategory *>*categoryList = [[LWSymbolService symbolService] categoriesList];
    [self.topScrollView setupSubviewWithCategoryList:categoryList];
    [self.containerScrollView setupSubviewWithCategoryList:categoryList];

//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction)];
    
    self.addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addBtn.frame = CGRectMake(0, 0, 40, 40);
    UIImage *addImg = [[UIImage imageNamed:@"add"] imageWithOverlayColor:[UIColor colorWithHexString:ButtonTextColor]];
    [self.addBtn setImage:addImg forState:UIControlStateNormal];
    [self.addBtn addTarget:self action:@selector(rightBarItemAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *barItem = [[UIBarButtonItem alloc] initWithCustomView:self.addBtn];
    self.navigationItem.rightBarButtonItem = barItem;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoryChangedNotifyAction) name:Notification_CategoryChanged object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)categoryChangedNotifyAction {
    NSArray <LWCategory *>*categoryList = [[LWSymbolService symbolService] categoriesList];
    [self.topScrollView setupSubviewWithCategoryList:categoryList];
    [self.containerScrollView setupSubviewWithCategoryList:categoryList];
//    [self updateTopScrollView];
//    [self updateContainerScrollView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateTopScrollView];
    [self updateContainerScrollView];
}


//右侧的按钮被点击
- (void)rightBarItemAction {
    LWCategoriesPopoverViewController *saveVC = [LWCategoriesPopoverViewController popoverViewControllerWithDelegate:self size:CGSizeMake(150, 145) sourceView:self.addBtn];
    if ([saveVC respondsToSelector:@selector(popoverPresentationController)]) {
        if(!saveVC.popoverPresentationController.sourceView){
            saveVC.popoverPresentationController.sourceView = self.view;
            saveVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionRight | UIPopoverArrowDirectionUp;
        }
    }
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

//更新Container数据
-(void)updateContainerScrollView {
    [self.containerScrollView showChannelWithChannelId:self.containerScrollView.currentChannel];
}

@end


