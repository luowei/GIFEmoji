//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWVideoPreviewViewController.h"
#import "LWAVPlayerView.h"
#import "MASConstraintMaker.h"
#import "View+MASAdditions.h"
#import "LWPurchaseHelper.h"
#import "AppDefines.h"
#import <GoogleMobileAds/GADBannerView.h>

@interface LWVideoPreviewViewController ()<GADBannerViewDelegate>
@property(nonatomic, strong) NSURL *videoURL;

@property(nonatomic, strong) GADBannerView *bannerView;
@end

@implementation LWVideoPreviewViewController {

}

+(LWVideoPreviewViewController *)viewControllerWithFileURL:(NSURL *)videoURL {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LWVideoPreviewViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LWVideoPreviewViewController"];
    vc.videoURL = videoURL;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction:)];

    [self.videoPlayerView playVideoWithURL:self.videoURL];

    if(![LWPurchaseHelper isPurchased]){
        //添加谷歌横幅广告
        [self addGADBanner];
    }

}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.videoPlayerView pauseVideo];
}

//右侧的按钮被点击
- (void)rightBarItemAction:(UIBarButtonItem *)rightBarItemAction {

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.videoURL] applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
        if(!activityVC.popoverPresentationController.sourceView){
            activityVC.popoverPresentationController.sourceView = self.view;
            activityVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionRight | UIPopoverArrowDirectionUp;
        }
    }
    [self presentViewController:activityVC animated:TRUE completion:nil];
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

@end
