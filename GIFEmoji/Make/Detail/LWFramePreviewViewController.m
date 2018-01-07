//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWFramePreviewViewController.h"
#import "SRPictureBrowser.h"
#import "SRPictureModel.h"


@interface LWFramePreviewViewController ()<SRPictureBrowserDelegate>

@property(nonatomic, strong) NSArray<UIImage *> *images;

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

    NSMutableArray *imageBrowserModels = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.images.count; i++) {
        SRPictureModel *imageBrowserModel = [SRPictureModel
                sr_pictureModelWithPicTure:self.images[i]
                             containerView:self.view
                       positionInContainer:self.view.bounds
                                     index:i];
        [imageBrowserModels addObject:imageBrowserModel];
    }
    [SRPictureBrowser sr_showPictureBrowserWithModels:imageBrowserModels currentIndex:0 delegate:self inView:self.view];

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



@end