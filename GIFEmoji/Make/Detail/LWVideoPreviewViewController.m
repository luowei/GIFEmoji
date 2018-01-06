//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWVideoPreviewViewController.h"
#import "LWAVPlayerView.h"
#import "MASConstraintMaker.h"
#import "View+MASAdditions.h"


@interface LWVideoPreviewViewController ()
@property(nonatomic, strong) NSURL *videoURL;
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
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.videoPlayerView pauseVideo];
}

//右侧的按钮被点击
- (void)rightBarItemAction:(UIBarButtonItem *)rightBarItemAction {

}


@end
