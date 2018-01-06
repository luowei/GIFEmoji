//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVKit/AVKit.h>


@interface LWAVPlayerView : UIView

@property(nonatomic, strong) AVPlayerViewController *playerViewController;

-(void)playVideoWithURL:(NSURL *)videoFileURL;
-(void)pauseVideo;

@end