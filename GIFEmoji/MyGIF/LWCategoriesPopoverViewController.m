//
// Created by Luo Wei on 2017/9/8.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import "LWCategoriesPopoverViewController.h"
#import "View+MASAdditions.h"
#import "SDWebImageManager.h"
#import "LWHelper.h"
#import "UIImage+Extension.h"
#import "LWCategoriesAlertView.h"
#import "LWWKWebViewController.h"
#import "AppDefines.h"


@interface LWCategoriesPopoverViewController () /*<UIViewControllerTransitioningDelegate>*/

@property(nonatomic, strong) SDWebImageDownloadToken *imageDownloadToken;

@end

@implementation LWCategoriesPopoverViewController {

}

+(LWCategoriesPopoverViewController *)popoverViewControllerWithDelegate:(id<UIPopoverPresentationControllerDelegate>)delegate
                                                             size:(CGSize)size sourceView:(UIView *)sourceView {
    LWCategoriesPopoverViewController *saveVC = [LWCategoriesPopoverViewController new];
    saveVC.modalPresentationStyle = UIModalPresentationPopover; //弹出的样式为popover
    saveVC.preferredContentSize = size; //弹出控制器的尺寸

    //箭头方向
    saveVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;

    //设置popoverPresentationController的sourceRect和sourceView属性
    saveVC.popoverPresentationController.sourceView = sourceView;
    saveVC.popoverPresentationController.sourceRect = sourceView.bounds;

    //设置北景色,包括箭头
    //saveVC.popoverPresentationController.backgroundColor = [UIColor orangeColor];
    saveVC.popoverPresentationController.delegate = delegate;

    return saveVC;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.tableFooterView=[[UIView alloc]init];    //去掉多余的Cell与分隔线

    self.tableView.dataSource = self;
    self.tableView.delegate = self;

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    //添加分类
//    [LWAddCategoryAlertView showTextInputViewInView:self.view];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}



#pragma mark - UITableViewDatasource

-(NSArray *)dataList{
    return @[NSLocalizedString(@"Categories", nil), NSLocalizedString(@"Developer App", nil), NSLocalizedString(@"About", nil)];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = self.dataList[(NSUInteger) indexPath.row];
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    switch (indexPath.row){
        case 0:{    //管理分类
            UIViewController *vc = (UIViewController *)self.popoverPresentationController.delegate;
            [LWCategoriesAlertView showCategoryAlertInView:vc.view];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case 1:{    //开发者App页面
            LWWKWebViewController *webVC = [LWWKWebViewController wkWebViewControllerWithURL:[NSURL URLWithString:Developer_URLString]];
            UIViewController *vc = (UIViewController *)self.popoverPresentationController.delegate;
            [vc.navigationController pushViewController:webVC animated:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        case 2:{ //关于
            LWWKWebViewController *webVC = [LWWKWebViewController wkWebViewControllerWithURL:[NSURL URLWithString:App_URLString]];
            UIViewController *vc = (UIViewController *)self.popoverPresentationController.delegate;
            [vc.navigationController pushViewController:webVC animated:YES];
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
        }
        default:{
            break;
        }
    }

}


@end
