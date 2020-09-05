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
#import "LWPurchaseHelper.h"
#import "LWPurchaseViewController.h"
#import <GoogleMobileAds/GADBannerView.h>
#import <GoogleMobileAds/GADInterstitial.h>

@interface LWMyGIFViewController() <UIPopoverPresentationControllerDelegate,GADBannerViewDelegate,GADInterstitialDelegate>

@property(nonatomic, strong) UIButton *addBtn;
@property(nonatomic, strong) UIButton *purchaseBtn;

@property(nonatomic, strong) GADBannerView *bannerView;

@end

@implementation LWMyGIFViewController {

}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSArray <LWCategory *>*categoryList = [[LWSymbolService symbolService] categoriesList];
    [self.topScrollView setupSubviewWithCategoryList:categoryList];
    [self.containerScrollView setupSubviewWithCategoryList:categoryList];

//    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction)];

    self.purchaseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.purchaseBtn.frame = CGRectMake(0, 0, 40, 40);
    UIImage *purchaseImg = [[UIImage imageNamed:@"purchase"] imageWithOverlayColor:[UIColor colorWithHexString:ButtonTextColor]];
    [self.purchaseBtn setImage:purchaseImg forState:UIControlStateNormal];
    [self.purchaseBtn addTarget:self action:@selector(leftBarItemAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *leftBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.purchaseBtn];
    self.navigationItem.leftBarButtonItem = leftBarItem;

    self.addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.addBtn.frame = CGRectMake(0, 0, 40, 40);
    UIImage *addImg = [[UIImage imageNamed:@"add"] imageWithOverlayColor:[UIColor colorWithHexString:ButtonTextColor]];
    [self.addBtn setImage:addImg forState:UIControlStateNormal];
    [self.addBtn addTarget:self action:@selector(rightBarItemAction) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightBarItem = [[UIBarButtonItem alloc] initWithCustomView:self.addBtn];
    self.navigationItem.rightBarButtonItem = rightBarItem;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(categoryChangedNotifyAction) name:Notification_CategoryChanged object:nil];

    //创建并加载广告
    self.interstitial = [self createAndLoadInterstitial];
    if(![LWPurchaseHelper isPurchased]){
        //添加谷歌横幅广告
        [self addGADBanner];
    }
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
- (void)leftBarItemAction {
    //购买
    UINavigationController *nvc = [LWPurchaseViewController navigationViewController];
    nvc.modalPresentationStyle = UIModalPresentationFullScreen;
    LWPurchaseViewController *vc = nvc.viewControllers.firstObject;
//    vc.needPrePurchase = YES;
    vc.title = NSLocalizedString(@"In-App Purchase No Ad", nil);
    [self presentViewController:nvc animated:YES completion:nil];
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


#pragma mark - GAD Banner

//添加谷歌横幅广告
- (void)addGADBanner {
    GADAdSize size = GADAdSizeFromCGSize(CGSizeMake(Screen_W, 50));
    self.bannerView = [[GADBannerView alloc] initWithAdSize:size];
    self.bannerView.adUnitID = @"ca-app-pub-8760692904992206/9036563441";
    self.bannerView.rootViewController = self;
    self.bannerView.delegate = self;

    self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bannerView];
    [self.view addConstraints:@[
            [NSLayoutConstraint constraintWithItem:self.bannerView
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.bottomLayoutGuide
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1
                                          constant:-6],
            [NSLayoutConstraint constraintWithItem:self.bannerView
                                         attribute:NSLayoutAttributeCenterX
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeCenterX
                                        multiplier:1
                                          constant:0]
    ]];

    //加载广告
    [self.bannerView loadRequest:[GADRequest request]];
}

#pragma mark - Google Ads

//创建GADInterstitial，谷歌广告
- (GADInterstitial *)createAndLoadInterstitial {
    GADInterstitial *interstitial = [[GADInterstitial alloc] initWithAdUnitID:@"ca-app-pub-8760692904992206/1789995794"];
    interstitial.delegate = self;
    [interstitial loadRequest:[GADRequest request]];
    return interstitial;
}

//展示广告
- (BOOL)showAdWithNumRate:(NSUInteger) numRate {
    NSString *key = [NSString stringWithFormat:@"%@_InterstitialAd_Counter", NSStringFromClass(self.class)];
    NSInteger toolOpenCount = [[NSUserDefaults standardUserDefaults] integerForKey:key];
    if (self.interstitial.isReady && toolOpenCount >= numRate && ![LWPurchaseHelper isPurchased]) {  //判断是否弹出广告
        [self.interstitial presentFromRootViewController:self];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:key];
        return YES;

    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:toolOpenCount + 1 forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if(self.afterAdShowBlock){
            self.afterAdShowBlock();
            self.afterAdShowBlock=nil;
        }
        return NO;
    }
}

//创建一个新的 GADInterstitial 对象
- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitial = [self createAndLoadInterstitial];
    //广告关闭后，继续做该做的事
    if(self.afterAdShowBlock){
        self.afterAdShowBlock();
        self.afterAdShowBlock=nil;
    }
}


@end


