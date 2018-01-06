//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLAnimatedImageView;


@interface LWGIFPreviewViewController : UIViewController

@property (weak, nonatomic) IBOutlet UISlider *fpsSlider;
@property (weak, nonatomic) IBOutlet UITextField *scaleTextField;

@property (weak, nonatomic) IBOutlet FLAnimatedImageView *imageView;

+(instancetype)viewControllerWithGIFData:(NSData *)gifData;

- (IBAction)fpsSliderAction:(UISlider *)sender forEvent:(UIEvent*)event;

@end
