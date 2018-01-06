//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "LWAVPlayerView.h"
#import "View+MASAdditions.h"


@interface LWAVPlayerView ()

@end

@implementation LWAVPlayerView {

}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.playerViewController = [AVPlayerViewController new];
        [self addSubview:self.playerViewController.view];

        [self.playerViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.bottom.equalTo(self);
        }];
    }

    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.playerViewController = [AVPlayerViewController new];
    [self addSubview:self.playerViewController.view];

    [self.playerViewController.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
}


-(void)playVideoWithURL:(NSURL *)videoFileURL {
    if(videoFileURL){
        AVPlayer *player = [AVPlayer playerWithURL:videoFileURL];
        self.playerViewController.player = player;
        [player pause];
        [player play];
    }
}

-(void)pauseVideo {
    [self.playerViewController.player pause];
}


@end