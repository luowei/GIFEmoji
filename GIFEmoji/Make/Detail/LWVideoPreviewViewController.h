//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LWAVPlayerView;


@interface LWVideoPreviewViewController : UIViewController

@property (weak, nonatomic) IBOutlet LWAVPlayerView *videoPlayerView;

+(LWVideoPreviewViewController *)viewControllerWithFileURL:(NSURL *)videoURL;

@end
