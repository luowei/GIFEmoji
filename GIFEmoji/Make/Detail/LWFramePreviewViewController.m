//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWFramePreviewViewController.h"
#import "SRPictureBrowser.h"
#import "SRPictureModel.h"
#import "OpenShare.h"
#import "LWUIActivity.h"
#import "LWPurchaseHelper.h"
#import "AppDefines.h"
#import <GoogleMobileAds/GADBannerView.h>

@interface LWFramePreviewViewController ()<SRPictureBrowserDelegate,GADBannerViewDelegate>

@property(nonatomic, strong) NSArray<UIImage *> *images;

@property(nonatomic, strong) SRPictureBrowser *pictureBrowser;

@property(nonatomic, strong) GADBannerView *bannerView;
@end

@implementation LWFramePreviewViewController {

}

+(instancetype)viewControllerWithImages:(NSArray <UIImage *>*)images {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LWFramePreviewViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LWFramePreviewViewController"];
    vc.images = images;
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction:)];

    NSMutableArray *imageBrowserModels = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.images.count; i++) {
        SRPictureModel *imageBrowserModel = [SRPictureModel
                sr_pictureModelWithPicTure:self.images[i]
                             containerView:self.view
                       positionInContainer:self.view.bounds
                                     index:i];
        [imageBrowserModels addObject:imageBrowserModel];
    }
    self.pictureBrowser = [SRPictureBrowser sr_showPictureBrowserWithModels:imageBrowserModels currentIndex:0 delegate:self inView:self.view];

    if(![LWPurchaseHelper isPurchased]){
        //添加谷歌横幅广告
        [self addGADBanner];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

}

#pragma mark - SRPictureBrowserDelegate

- (void)pictureBrowserDidShow:(SRPictureBrowser *)pictureBrowser {

    NSLog(@"%s", __func__);
}

- (void)pictureBrowserDidDismiss {

    NSLog(@"%s", __func__);
}

//右侧的按钮被点击
- (void)rightBarItemAction:(UIBarButtonItem *)rightBarItemAction {
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:self.images applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        activityVC.popoverPresentationController.sourceView = self.view;
        activityVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        activityVC.popoverPresentationController.sourceRect = CGRectMake(CGRectGetWidth(self.view.frame) - 40, 0, 40, 40);
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
