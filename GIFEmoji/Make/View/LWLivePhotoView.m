//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWLivePhotoView.h"


@implementation LWLivePhotoView {

}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
    }

    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesBegan:touches withEvent:event];

//    UITouch *touch = [touches anyObject];
//
//    CGFloat maximumPossibleForce = touch.maximumPossibleForce;
//    CGFloat force = touch.force;
//    CGFloat normalizedForce = force/maximumPossibleForce;
//
//    if(normalizedForce > 0.8){
//        [self startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleUndefined];
//    }
}


@end