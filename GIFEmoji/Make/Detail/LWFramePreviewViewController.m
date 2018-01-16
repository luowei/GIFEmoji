//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWFramePreviewViewController.h"
#import "SRPictureBrowser.h"
#import "SRPictureModel.h"
#import "OpenShare.h"
#import "LWUIActivity.h"


@interface LWFramePreviewViewController ()<SRPictureBrowserDelegate>

@property(nonatomic, strong) NSArray<UIImage *> *images;

@property(nonatomic, strong) SRPictureBrowser *pictureBrowser;
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
    [self presentViewController:activityVC animated:TRUE completion:nil];
}


@end