//
//  GenGIFViewController.m
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//
// 3个可用的PhotoPicker:
/*
 * CTAssetsPickerController: https://github.com/chiunam/CTAssetsPickerController
 * YangMingShan: https://github.com/yahoo/YangMingShan
 * BSImagePicker: https://github.com/mikaoj/BSImagePicker
 */

#import "GenGIFViewController.h"
#import <Photos/Photos.h>
#import <PhotosUI/PhotosUI.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "NSGIF.h"
#import "SVProgressHUD.h"
#import "View+MASAdditions.h"
#import "YangMingShan.h"
#import "YMSPhotoPickerViewController.h"
#import "UIViewController+YMSPhotoHelper.h"
#import "FLAnimatedImageView.h"
#import "LWLivePhotoView.h"
#import "LWAVPlayerView.h"
#import "AppDefines.h"
#import "UIImage+GIF.h"
#import "FLAnimatedImage.h"
#import "Categories.h"
#import "LWVideoPreviewViewController.h"
#import "LWHelper.h"

@interface GenGIFViewController () {
    float _exportGIFDelayTime;
}

@property(nonatomic, strong) LWLivePhotoView *liveView;
@property(nonatomic, strong) LWAVPlayerView *videoPlayerView;

@property(nonatomic) SelectedMode selectedMode;

@property(nonatomic, strong) NSURL *selectedVideoFileURL;
@property(nonatomic, strong) NSData *selectedGIFImageData;

@property(nonatomic, strong) NSURL *exportedGIFURL;
@property(nonatomic, strong) NSArray <UIImage *>*exportImageFrames;
@property(nonatomic, strong) NSURL *livePhotoVideoURL;
@property(nonatomic, strong) NSURL *livePhotoFirstImageURL;




@end

@implementation GenGIFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self updateUIAppearance];

    _exportGIFDelayTime = 0.1;


    //LiveView视图
    self.liveView = [[LWLivePhotoView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.liveView];

    [self.liveView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.imagePreview);
    }];
    self.liveView.hidden = YES;

    //视频播放视图
    self.videoPlayerView = [[LWAVPlayerView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.videoPlayerView];

    [self.videoPlayerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self.imagePreview);
    }];
    self.videoPlayerView.hidden = YES;

}

//更新外观
- (void)updateUIAppearance {
    self.selectLivePhotoBtn.layer.cornerRadius = 6;
    self.selectStaticPhotoBtn.layer.cornerRadius = 6;
    self.selectVideoBtn.layer.cornerRadius = 6;
    self.exportVideoBtn.layer.cornerRadius = 6;
    self.exportGIFBtn.layer.cornerRadius = 6;
    self.exportFrameBtn.layer.cornerRadius = 6;
}


#pragma mark - UIImagePickerController Delegate method

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {

    [self dismissViewControllerAnimated:YES completion:nil];
    self.liveView.hidden = YES;
    self.videoPlayerView.hidden = YES;


    //处理视频
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.movie"]) {

        NSLog(@"Picked a movie at URL %@", info[UIImagePickerControllerMediaURL]);
        self.selectedVideoFileURL = info[UIImagePickerControllerMediaURL];
        NSLog(@"> %@", [self.selectedVideoFileURL absoluteString]);

        self.videoPlayerView.hidden = NO;
        [self.videoPlayerView playVideoWithURL:self.selectedVideoFileURL];

        self.selectedMode = VideoMode;

        self.exportedGIFURL = nil;
        self.exportImageFrames = nil;
        self.livePhotoFirstImageURL = nil;
        self.livePhotoVideoURL = nil;
        return;
    }


    //处理LivePhoto
    PHLivePhoto *livePhoto = nil;

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.1")) {
        livePhoto = info[UIImagePickerControllerLivePhoto];
    }
    if (livePhoto) {
        self.liveView.hidden = NO;
        self.liveView.livePhoto = livePhoto;
        [self.liveView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];

        self.selectedMode = LivePhotoMode;

        self.exportedGIFURL = nil;
        self.exportImageFrames = nil;
        self.livePhotoFirstImageURL = nil;
        self.livePhotoVideoURL = nil;
        return;

    } else {
        //处理其他照片
        BOOL isGIF = [self isGIFWithPickerInfo:info];
        if (isGIF) {    //是GIF图片
            self.selectedMode = GIFMode;

            self.exportedGIFURL = nil;
            self.exportImageFrames = nil;
            self.livePhotoFirstImageURL = nil;
            self.livePhotoVideoURL = nil;

            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"The Photo is GIF Image", nil)];
            [SVProgressHUD dismissWithDelay:0.5];

            FLAnimatedImage *gifImage = [FLAnimatedImage animatedImageWithGIFData:self.selectedGIFImageData];
            self.imagePreview.animatedImage = gifImage;

        } else {    //其他情况就让用户重新选择
            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Not a Live Photo", nil)];
            [SVProgressHUD dismissWithDelay:0.5];

            [self selectLivePhotoAction:nil];   //选择LivePhoto
        }

    }

}

-(void)setSelectedMode:(SelectedMode)selectedMode {
    _selectedMode = selectedMode;
    [self updateExportBtnWithSelectedMode:_selectedMode];
}

//更新导出按钮的样式及
- (void)updateExportBtnWithSelectedMode:(SelectedMode)mode {
    switch (mode){
        case LivePhotoMode:{
            self.exportFrameBtn.hidden = NO;
            self.exportGIFBtn.hidden = NO;
            self.exportVideoBtn.hidden = NO;
            break;
        }
        case StaticPhotosMode:{
            self.exportFrameBtn.hidden = NO;
            self.exportGIFBtn.hidden = NO;
            self.exportVideoBtn.hidden = YES;
            break;
        }
        case VideoMode:{
            self.exportFrameBtn.hidden = NO;
            self.exportGIFBtn.hidden = NO;
            self.exportVideoBtn.hidden = NO;
            break;
        }
        case GIFMode:{
            self.exportFrameBtn.hidden = NO;
            self.exportGIFBtn.hidden = NO;
            self.exportVideoBtn.hidden = YES;
            break;
        }
        default:
            break;
    }
}

//判断是否是GIF图片
- (BOOL)isGIFWithPickerInfo:(NSDictionary *)info {
    __block BOOL isGIF = NO;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
        PHAsset *phAsset = info[UIImagePickerControllerPHAsset];
//        NSArray *resourceList = [PHAssetResource assetResourcesForAsset:phAsset];
//        [resourceList enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
//            PHAssetResource *resource = obj;
//            if ([resource.uniformTypeIdentifier isEqualToString:@"com.compuserve.gif"]) {
//                isGIF = YES;
//            }
//        }];


        PHImageRequestOptions *options = [PHImageRequestOptions new];
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.synchronous = YES;

        weakify(self)
        PHCachingImageManager *imageManager = [[PHCachingImageManager alloc] init];
        [imageManager requestImageDataForAsset:phAsset
                                       options:options
                                 resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                                     strongify(self)
                                     Log(@"dataUTI:%@",dataUTI);

                                     //gif 图片
                                     if ([dataUTI isEqualToString:(__bridge NSString *)kUTTypeGIF]) {
                                         //这里获取gif图片的NSData数据
                                         BOOL downloadFinined = (![info[PHImageCancelledKey] boolValue] && !info[PHImageErrorKey]);
                                         if (downloadFinined && imageData) {
                                             isGIF = YES;
                                             self.selectedGIFImageData = imageData;

                                             //根据 PHAsset 设置GIFURL
                                             [self fillGIFURLWithAsset:phAsset];
                                         }
                                     }
                                 }];


    } else {

        weakify(self)
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        //使用信号量解决 assetForURL 同步问题
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [library assetForURL:[info valueForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
                        strongify(self)
//                        ALAssetRepresentation *repr = [asset defaultRepresentation];
//                        if ([[repr UTI] isEqualToString:@"com.compuserve.gif"]) {
//                            isGIF = YES;
//                        }

                ALAssetRepresentation *re = [asset representationForUTI:(__bridge NSString *)kUTTypeGIF];
                        if(re){
                            isGIF = YES;

                            //获取GIF数据
                            size_t size = (size_t) re.size;
                            uint8_t *buffer = malloc(size);
                            NSError *error;
                            NSUInteger bytes = [re getBytes:buffer fromOffset:0 length:size error:&error];
                            self.selectedGIFImageData = [NSData dataWithBytes:buffer length:bytes];
                            free(buffer);

                            self.exportedGIFURL = re.url;
                        }

                        dispatch_semaphore_signal(sema);
                    }
                    failureBlock:^(NSError *error) {
                        NSLog(@"Error getting asset! %@", error);
                        dispatch_semaphore_signal(sema);
                    }];
        });
        dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
    }
    return isGIF;
}

//根据 PHAsset 设置GIFURL
- (void)fillGIFURLWithAsset:(PHAsset *)phAsset {
    NSArray *assetResources = [PHAssetResource assetResourcesForAsset:phAsset];
    PHAssetResource *resource;
    for (PHAssetResource *assetRes in assetResources) {
        if (assetRes.type == PHAssetResourceTypePhoto ||
                assetRes.type == PHAssetResourceTypeAdjustmentData) {
            resource = assetRes;
        }
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *gifFileName = [dateFormatter stringFromDate:[NSDate new]];
    if (resource.originalFilename) {
        gifFileName = resource.originalFilename;
    }

    NSString *temporaryFile = [NSTemporaryDirectory() stringByAppendingString:gifFileName];
    self.exportedGIFURL = [NSURL fileURLWithPath:temporaryFile];

    [[PHAssetResourceManager defaultManager]
            writeDataForAssetResource:resource
                               toFile:self.exportedGIFURL
                              options:nil
                    completionHandler:^(NSError *_Nullable error) {
                        if (error) {
                            self.exportedGIFURL = nil;
                        }
                    }];
}

//根据FileURL处理Video
- (void)handleVideoWithFileURL:(NSURL *)videoFileURL {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD showWithStatus:@"Loading..."];

    NSString *gifFileName = [videoFileURL.absoluteString md5];
    NSString *temporaryFile = [NSTemporaryDirectory() stringByAppendingString:gifFileName];
    self.exportedGIFURL = [NSURL fileURLWithPath:temporaryFile];

    _exportGIFDelayTime = 0.1;
    [LWGIFManager convertVideoToImages:videoFileURL
                        exportedGIFURL:self.exportedGIFURL
                        frameDelayTime:_exportGIFDelayTime
                       completionBlock:^(NSArray<UIImage *> *images) {
                           [SVProgressHUD dismiss];
                           self.exportImageFrames = images;
                       }];

    [SVProgressHUD dismiss];
}

//处理LivePhoto
- (void)handleLivePhoto:(PHLivePhoto *)livePhoto {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD showWithStatus:@"Loading..."];

    NSArray *resourceArray = [PHAssetResource assetResourcesForLivePhoto:livePhoto];
    PHAssetResourceManager *assetResourceManager = [PHAssetResourceManager defaultManager];

    NSError *error;

    //保存livePhoto中的图片
    PHAssetResource *livePhotoImageAsset = resourceArray[0];
    // Create path.

    NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg",[LWHelper getCurrentTimeStampText]];
    NSString *imageFilePath = [NSTemporaryDirectory() stringByAppendingString:imageFileName];
    self.livePhotoFirstImageURL = [NSURL fileURLWithPath:imageFilePath];
    [[NSFileManager defaultManager] removeItemAtPath:imageFilePath error:&error];

    [assetResourceManager writeDataForAssetResource:livePhotoImageAsset toFile:self.livePhotoFirstImageURL options:nil completionHandler:^(NSError *_Nullable error) {
        NSLog(@"error: %@", error);
    }];


    //保存livePhoto中的短视频
    PHAssetResource *livePhotoVideoAsset = resourceArray[1];
    // Create path.
    NSString *videoFileName = [NSString stringWithFormat:@"%@.mov",[LWHelper getCurrentTimeStampText]];
    NSString *videoFilePath = [NSTemporaryDirectory() stringByAppendingString:videoFileName];
    self.livePhotoVideoURL = [[NSURL alloc] initFileURLWithPath:videoFilePath];
    [[NSFileManager defaultManager] removeItemAtPath:videoFilePath error:&error];

    [assetResourceManager writeDataForAssetResource:livePhotoVideoAsset toFile:self.livePhotoVideoURL options:nil completionHandler:^(NSError *_Nullable error) {
        NSLog(@"videoURL: %@", self.livePhotoVideoURL);
        NSLog(@"error: %@", error);

        NSString *gifFileName = [self.livePhotoVideoURL.absoluteString md5];
        NSString *temporaryFile = [NSTemporaryDirectory() stringByAppendingString:gifFileName];
        self.exportedGIFURL = [NSURL fileURLWithPath:temporaryFile];

        _exportGIFDelayTime = 0.1;
        [LWGIFManager convertVideoToImages:self.livePhotoVideoURL
                            exportedGIFURL:self.exportedGIFURL
                            frameDelayTime:_exportGIFDelayTime
                           completionBlock:^(NSArray<UIImage *> *images) {
                               [SVProgressHUD dismiss];
                               self.exportImageFrames = images;
                           }];
    }];

    [SVProgressHUD dismiss];
}


#pragma mark - YMSPhotoPickerViewControllerDelegate

- (void)photoPickerViewControllerDidReceivePhotoAlbumAccessDenied:(YMSPhotoPickerViewController *)picker {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Allow photo album access?", nil) message:NSLocalizedString(@"Need your permission to access photo albumbs", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    [alertController addAction:dismissAction];
    [alertController addAction:settingsAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)photoPickerViewControllerDidReceiveCameraAccessDenied:(YMSPhotoPickerViewController *)picker {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Allow camera access?", nil) message:NSLocalizedString(@"Need your permission to take a photo", nil) preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *dismissAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    UIAlertAction *settingsAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Settings", nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }];
    [alertController addAction:dismissAction];
    [alertController addAction:settingsAction];

    // The access denied of camera is always happened on picker, present alert on it to follow the view hierarchy
    [picker presentViewController:alertController animated:YES completion:nil];
}

//选择了单图片
- (void)photoPickerViewController:(YMSPhotoPickerViewController *)picker didFinishPickingImage:(UIImage *)image {
    self.liveView.hidden = YES;
    self.videoPlayerView.hidden = YES;

    self.selectedMode = StaticPhotosMode;

    [picker dismissViewControllerAnimated:YES completion:^() {
        self.exportImageFrames = @[image];
        [self setImages:self.exportImageFrames toImageView:self.imagePreview];
    }];
}

//选择了多张图片
- (void)photoPickerViewController:(YMSPhotoPickerViewController *)picker didFinishPickingImages:(NSArray *)photoAssets {
    self.liveView.hidden = YES;
    self.videoPlayerView.hidden = YES;

    self.selectedMode = StaticPhotosMode;

    [picker dismissViewControllerAnimated:YES completion:^() {

        PHImageManager *imageManager = [[PHImageManager alloc] init];

        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
        options.networkAccessAllowed = YES;
        options.resizeMode = PHImageRequestOptionsResizeModeExact;
        options.synchronous = YES;

        NSMutableArray *mutableImages = [NSMutableArray array];

        for (PHAsset *asset in photoAssets) {
            CGSize targetSize = CGSizeMake((CGRectGetWidth(self.imagePreview.bounds) - 20 * 2) * [UIScreen mainScreen].scale, (CGRectGetHeight(self.imagePreview.bounds) - 20 * 2) * [UIScreen mainScreen].scale);
            [imageManager requestImageForAsset:asset targetSize:targetSize contentMode:PHImageContentModeAspectFill options:options resultHandler:^(UIImage *image, NSDictionary *info) {
                [mutableImages addObject:image];
            }];
        }
        self.exportImageFrames = [mutableImages copy];
        [self setImages:self.exportImageFrames toImageView:self.imagePreview];
    }];
}


#pragma mark - Action

#pragma mark - 选择照片

- (IBAction)selectLivePhotoAction:(UIButton *)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = NO;

    NSArray *mediaTypes = @[(NSString *) kUTTypeImage, (NSString *) kUTTypeGIF];
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_9_1
    mediaTypes = @[(NSString *) kUTTypeImage, (NSString *) kUTTypeLivePhoto, (NSString *) kUTTypeGIF];
#endif
    imagePicker.mediaTypes = mediaTypes;

    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)selectStaticPhotoAction:(UIButton *)sender {
    YMSPhotoPickerViewController *pickerViewController = [[YMSPhotoPickerViewController alloc] init];
    pickerViewController.numberOfPhotoToSelect = 0;
    [self yms_presentCustomAlbumPhotoView:pickerViewController delegate:self];
}

- (IBAction)selectVideoAction:(UIButton *)sender {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.allowsEditing = NO;

    NSArray *mediaTypes = @[(NSString *) kUTTypeMovie];
    imagePicker.mediaTypes = mediaTypes;
    [self presentViewController:imagePicker animated:YES completion:nil];
}


#pragma mark - 导出图片

- (IBAction)exportVideoAction:(UIButton *)sender {
    if (self.selectedMode == LivePhotoMode) {
        if(!self.livePhotoVideoURL){
            //处理LivePhoto
            [self handleLivePhoto:self.liveView.livePhoto];
        }
        LWVideoPreviewViewController *vc = [LWVideoPreviewViewController viewControllerWithFileURL:self.livePhotoVideoURL];
        [self.navigationController pushViewController:vc animated:YES];

    } else if (self.selectedMode == VideoMode) {
        [self.videoPlayerView pauseVideo];  //暂停播放
        LWVideoPreviewViewController *vc = [LWVideoPreviewViewController viewControllerWithFileURL:self.selectedVideoFileURL];
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (IBAction)exportGIFAction:(UIButton *)sender {

    if (self.selectedMode == LivePhotoMode) {
        if(self.exportedGIFURL){

        }else{
            //处理LivePhoto
            [self handleLivePhoto:self.liveView.livePhoto];
        }


    } else if (self.selectedMode == VideoMode) {
        if(self.exportedGIFURL){

        }else{
            //处理视频
            [self handleVideoWithFileURL:self.selectedVideoFileURL];
        }
    }

    //todo:合成图片帧集为GIF,并跳转到GIF预览页面


}

- (IBAction)exportFrameAction:(UIButton *)sender {
    //todo:跳转到图片集预览页面
}

#pragma mark - Private Method

//把一个images数组设置到ImageView
- (void)setImages:(NSArray <UIImage *> *)imageList toImageView:(FLAnimatedImageView *)imageView {

    NSMutableArray *images = [[NSMutableArray alloc] init];

    for (int i = 1; i <= [imageList count]; i++) {
        UIImage *image = imageList[i - 1];
        [images addObject:image];
    }


    [imageView stopAnimating];
    imageView.animatedImage = nil;
    imageView.image = nil;
    imageView.animationImages = [NSArray arrayWithArray:images];
    imageView.animationDuration = _exportGIFDelayTime * [imageList count];
    imageView.animationRepeatCount = 0;
    [imageView startAnimating];

    //todo:隐藏弹窗
}


@end
