//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LWAVPlayerView.h"


@interface LWAVPlayerView ()

@end

@implementation LWAVPlayerView {

}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.playerViewController = [AVPlayerViewController new];
        [self addSubview:self.playerViewController.view];

    }

    return self;
}


-(void)playVideoWithURL:(NSURL *)videoFileURL {
    AVPlayer *player = [AVPlayer playerWithURL:videoFileURL];
    self.playerViewController.player = player;
    [player pause];
    [player play];
}


@end