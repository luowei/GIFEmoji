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
#import "NSGIF.h"
#import "LWSymbolService.h"
#import "FCFileManager.h"
#import "LWHelper.h"
#import "LWPickerPanel.h"


@interface LWGIFPreviewViewController ()<UITextFieldDelegate,UIGestureRecognizerDelegate>

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

    float frameDuration = [LWGIFManager frameDurationAtIndex:1 gifData:self.gifData];
    frameDuration = (float) (frameDuration < 0.011 ? 0.1 : frameDuration);
    CGFloat fps = (CGFloat) (1.0 / frameDuration);
    [self.fpsSlider setValue:fps animated:YES];
    NSString *fpsText = [NSString stringWithFormat:@"%d", (int) round(fps)];
    [self updateSliderThumbImageWithText:fpsText]; //更新sliderThumbImage

    [self updateGIFImageView];  //更新GIFImageView
}

- (void)viewWillAppear:(BOOL)animated {
    self.navigationController.interactivePopGestureRecognizer.delegate = self;
}

- (void)viewWillDisappear:(BOOL)animated {
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.delegate = nil;
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return gestureRecognizer != self.navigationController.interactivePopGestureRecognizer;
    // add whatever logic you would otherwise have
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

//收藏
-(IBAction)favoriteBtnTouchUpInside:(UIButton *)btn {
    if(btn.selected){
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Been Favorited", nil)];
        [SVProgressHUD dismissWithDelay:0.5];
        return;
    }
    NSData *data = self.imageView.animatedImage.data;
    if (!data) {
        data = UIImagePNGRepresentation(self.imageView.image);
    }

    LWPickerPanel *pickerPanel = [LWPickerPanel showPickerPanelInView:self.view];

    pickerPanel.faveritaBlock = ^(NSInteger categoryId, NSString *categoryName) {

        NSString *imgName = [NSString stringWithFormat:@"%@.gif",[LWHelper getCurrentTimeStampText]];

        [SVProgressHUD showWithStatus:@"Loading..."];

        //保存data到文件中
        NSString *docPath = [NSString stringWithFormat:@"%@/%@", AnimojiDirectory, categoryName];
        NSString *file_url = [docPath stringByAppendingPathComponent:imgName];

        //如果不存在文件夹，则创建文件夹
        NSString *imgDirectoryPath = [LWHelper createIfNotExistsDirectory:docPath];
        NSString *filePath = [imgDirectoryPath stringByAppendingPathComponent:imgName];
        Log(@"============filePath:%@", filePath);

        //保存到文件
        if (![FCFileManager existsItemAtPath:filePath]) {
            NSError *error;
            [data writeToFile:filePath options:NSDataWritingWithoutOverwriting error:&error];
            if (error) {
                Log(@"====writeToFile:%@ , %@", filePath, error.localizedFailureReason);
                [SVProgressHUD showErrorWithStatus:@"Save Image File Faild"];
                [SVProgressHUD dismissWithDelay:1.5];
                return;
            }
        }

        //保存图片表情到相应的分类中
        BOOL isSuccess = [[LWSymbolService symbolService] insertSymbolWithCategoryId:(NSUInteger) categoryId title:nil text:imgName file_url:file_url http_url:nil];
        if(isSuccess){
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Operate Success", nil)];
            [SVProgressHUD dismissWithDelay:1.5];
        }else{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Operate Faild", nil)];
            [SVProgressHUD dismissWithDelay:1.5];
        }

        btn.selected = YES;
    };
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

    NSString *gifFileName = [NSString stringWithFormat:@"%@.gif",[LWHelper getCurrentTimeStampText]];
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
