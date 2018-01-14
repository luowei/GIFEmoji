//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWGIFPreviewViewController.h"
#import "FLAnimatedImageView.h"
#import "FLAnimatedImage.h"
#import "UIImage+GIF.h"
#import "UIImage+Extension.h"
#import "UIColor+HexValue.h"
#import "AppDefines.h"
#import "SVProgressHUD.h"
#import "LWSnapshotMaskView.h"


@interface LWGIFPreviewViewController ()<UITextFieldDelegate>

@property(nonatomic, strong) NSData *gifData;

@property(nonatomic, copy) NSString *originGIFFilePath;
@end

@implementation LWGIFPreviewViewController {
    NSString *_scaleText;
}

+(instancetype)viewControllerWithGIFData:(NSData *)gifData {
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
    LWGIFPreviewViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"LWGIFPreviewViewController"];
    vc.gifData = gifData;

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *gifFileName = [NSString stringWithFormat:@"%@.gif",[dateFormatter stringFromDate:[NSDate new]]];
    NSString *gifFilePath = [NSTemporaryDirectory() stringByAppendingString:gifFileName];
    
    BOOL isOK = [vc.gifData writeToFile:gifFilePath options:NSDataWritingWithoutOverwriting error:nil];
    if(isOK){
        vc.originGIFFilePath = gifFilePath;
    }
    
    return vc;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"share"] style:UIBarButtonItemStylePlain target:self action:@selector(rightBarItemAction:)];

    [self.scaleTextField addTarget:self action:@selector(textFieldEditingDidBegin:) forControlEvents:UIControlEventEditingDidBegin];
    [self.scaleTextField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];

    //手势截图
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] init];
    longPressGesture.numberOfTouchesRequired = 2;
    [longPressGesture addTarget:self action:@selector(longPressGestureAction:)];
    [self.imageView addGestureRecognizer:longPressGesture];
    self.imageView.userInteractionEnabled = YES;

    [self updateSliderThumbImageWithText:@"10"]; //更新sliderThumbImage

    [self updateGIFImageView];  //更新GIFImageView
}

//手势截图分享
- (void)longPressGestureAction:(UILongPressGestureRecognizer *)gesture {
    Log(@"--------: 识别到手势截图");

    if(gesture.state == UIGestureRecognizerStateBegan ){
        CGRect scaleFrame = [self imageFitFrameInView:self.imageView];
        LWSnapshotMaskView *snapshotMaskView = [LWSnapshotMaskView showSnapshotMaskInView:self.imageView frame:scaleFrame];
        snapshotMaskView.snapshotFrame = CGRectMake(0, 0, scaleFrame.size.width, scaleFrame.size.height);
    }

}

//获取UIImageView中自适应的Image Frame
- (CGRect)imageFitFrameInView:(UIImageView *)imageView {
    CGSize imageSize = imageView.intrinsicContentSize;
    CGSize viewSize = imageView.frame.size;

    CGSize scaleSize = CGSizeMake(viewSize.width, viewSize.width *imageSize.height / imageSize.width);
    if(imageSize.width/imageSize.height < viewSize.width/viewSize.height){
            scaleSize = CGSizeMake(viewSize.height * imageSize.width / imageSize.height, viewSize.height);
        }
    CGRect scaleFrame = CGRectMake((viewSize.width-scaleSize.width)/2.0, (viewSize.height-scaleSize.height)/2.0, scaleSize.width, scaleSize.height);
    return scaleFrame;
}


- (void)updateGIFImageView {
    FLAnimatedImage *animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:self.gifData];
    self.imageView.animatedImage = animatedImage;
}

- (void)updateSliderThumbImageWithText:(NSString *)text {
    UIImage *thumbImg = [UIImage imageNamed:@"slider_thumnail"];
    UIImage *thumbImage = [UIImage drawImage:thumbImg voerlayText:text
                                   textColor:[UIColor colorWithHexString:@"#FC4D2B"]
                                     atPoint:CGPointMake(thumbImg.size.width/2, thumbImg.size.height/2)];
    [self.fpsSlider setThumbImage:thumbImage forState:UIControlStateNormal];
}


- (IBAction)fpsSliderAction:(UISlider *)slider forEvent:(UIEvent*)event{
    float fpsValue = (float)slider.value;

    UITouch *touchEvent = [[event allTouches] anyObject];
    switch (touchEvent.phase) {
        case UITouchPhaseBegan:
            // handle drag began
            break;
        case UITouchPhaseMoved:{
            [self updateSliderThumbImageWithText:[NSString stringWithFormat:@"%.f",fpsValue]];
            break;
        }
        case UITouchPhaseEnded:{
            Log(@"=========Slider Touch End");

            [self updateGIFDataWithFPSValue:fpsValue];  //根据帧率更新gifData
            [self updateGIFImageView];  //更新视图动画
            break;
        }
        default:
            break;
    }

}

- (void)updateGIFDataWithFPSValue:(float)fpsValue {
    float delayTime = (float) (1/fpsValue);
    CGSize imageSize = self.imageView.animatedImage.size;

    NSArray <UIImage *>*images = nil;
    if(self.originGIFFilePath && [[NSFileManager defaultManager] fileExistsAtPath:self.originGIFFilePath]){
        NSData *originGIFData = [NSData dataWithContentsOfFile:self.originGIFFilePath];
        images = [UIImage imagesFromGIFData:originGIFData];
    }else{
        images = [UIImage imagesFromGIFData:self.gifData];
    }

    if(images && images.count > 0){
        imageSize = images.firstObject.size;
    }

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *gifFileName = [NSString stringWithFormat:@"%@.gif",[dateFormatter stringFromDate:[NSDate new]]];
    NSString *gifFilePath = [NSTemporaryDirectory() stringByAppendingString:gifFileName];

    CGFloat screenScale = [UIScreen mainScreen].scale;
    float scaleSize = (float) ([self.scaleTextField.text floatValue] ?: 1.0);
    imageSize = CGSizeMake(imageSize.width * scaleSize * screenScale, imageSize.height * scaleSize * screenScale);
    self.gifData = [UIImage createGIFWithImages:images size:imageSize loopCount:0 delayTime:delayTime gifCachePath:gifFilePath];
}

- (void)textFieldEditingDidBegin:(UITextField *)textField {
    _scaleText  = textField.text;
}
- (void)textFieldEditingChanged:(UITextField *)textField {
    NSString *text = textField.text;
    if([text rangeOfString:@"^\\d{0,2}\\.?\\d{0,2}$" options:NSRegularExpressionSearch].location == NSNotFound){
        textField.text = _scaleText ?: [NSString stringWithFormat:@"%.1f",1.0];
    }else{
        _scaleText = textField.text;
    }
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField{
    float fpsValue = [self.fpsSlider value];
    [self updateGIFDataWithFPSValue:fpsValue];  //根据帧率更新gifData
    [self updateGIFImageView];  //更新视图动画
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.view endEditing:YES];
}


//右侧的按钮被点击
- (void)rightBarItemAction:(UIBarButtonItem *)rightBarItemAction {

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.gifData] applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    [self presentViewController:activityVC animated:TRUE completion:nil];
}

@end
