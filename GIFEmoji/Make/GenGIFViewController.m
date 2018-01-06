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
#import "LWLivePhotoView.h"
#import "LWAVPlayerView.h"
#import "AppDefines.h"
#import "UIImage+GIF.h"

@interface GenGIFViewController () {
    NSArray *_aryGifframes;
    float _floatGifTime;
    NSURL *_videoURL;
    NSURL *_photoURL;
}

@property(nonatomic, strong) LWLivePhotoView *liveView;
@property(nonatomic, strong) LWAVPlayerView *videoPlayerView;
@property(nonatomic, strong) NSURL *selectedVideoFileURL;

@property(nonatomic) SelectedMode selectedMode;

@end

@implementation GenGIFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [self updateUIAppearance];

    _floatGifTime = 0.1;


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

//        //处理Video
//        [self handleVideoWithFileURL:videoFileURL];

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
        return;
    } else {
        //处理其他照片

//        //是否为GIF图片
//        weakify(self)
//        [self checkGIFWithPickerInfo:info resultBlock:^(BOOL isGIF) {
//            strongify(self)
//            Log(@"===========is GIF:%@", isGIF ? @"YES" : @"NO");
//
//            if (isGIF) {
//                [SVProgressHUD showWithStatus:@"GIF....."];
//                [SVProgressHUD dismissWithDelay:2.0];
//            } else {
//                [SVProgressHUD setBackgroundColor:[UIColor lightGrayColor]];
//                [SVProgressHUD showInfoWithStatus:@"Not a Live Photo"];
//                [SVProgressHUD dismissWithDelay:2.0];
//
//                [self selectLivePhotoAction:nil];   //选择LivePhoto
//            }
//        }];

        BOOL isGIF = [self isGIFWithPickerInfo:info];
        if (isGIF) {
            [SVProgressHUD showWithStatus:@"GIF....."];
            [SVProgressHUD dismissWithDelay:2.0];
        } else {
            [SVProgressHUD setBackgroundColor:[UIColor lightGrayColor]];
            [SVProgressHUD showInfoWithStatus:@"Not a Live Photo"];
            [SVProgressHUD dismissWithDelay:2.0];

            [self selectLivePhotoAction:nil];   //选择LivePhoto
        }

    }


}

//判断是否是GIF图片
- (BOOL)isGIFWithPickerInfo:(NSDictionary *)info {
    __block BOOL isGIF = NO;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
        PHAsset *phAsset = info[UIImagePickerControllerPHAsset];
        NSArray *resourceList = [PHAssetResource assetResourcesForAsset:phAsset];
        [resourceList enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            PHAssetResource *resource = obj;
            if ([resource.uniformTypeIdentifier isEqualToString:@"com.compuserve.gif"]) {
                isGIF = YES;
            }
        }];

    } else {
        dispatch_semaphore_t sema = dispatch_semaphore_create(0);
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        //使用信号量解决 assetForURL 同步问题
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [library assetForURL:[info valueForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
                        ALAssetRepresentation *repr = [asset defaultRepresentation];
                        if ([[repr UTI] isEqualToString:@"com.compuserve.gif"]) {
                            isGIF = YES;
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


//判断是否是GIF图片
- (void)checkGIFWithPickerInfo:(NSDictionary *)info resultBlock:(void (^)(BOOL isGIF))resultBlock {
    __block BOOL isGIF = NO;
    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"11.0")) {
        PHAsset *phAsset = info[UIImagePickerControllerPHAsset];
        NSArray *resourceList = [PHAssetResource assetResourcesForAsset:phAsset];
        [resourceList enumerateObjectsUsingBlock:^(id _Nonnull obj, NSUInteger idx, BOOL *_Nonnull stop) {
            PHAssetResource *resource = obj;
            if ([resource.uniformTypeIdentifier isEqualToString:@"com.compuserve.gif"]) {
                isGIF = YES;
                if (resultBlock) {
                    resultBlock(isGIF);
                }
            }
        }];

    } else {
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library assetForURL:[info valueForKey:UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
            ALAssetRepresentation *repr = [asset defaultRepresentation];
            if ([[repr UTI] isEqualToString:@"com.compuserve.gif"]) {
                isGIF = YES;
                if (resultBlock) {
                    resultBlock(isGIF);
                }
            }
        }       failureBlock:^(NSError *error) {
            NSLog(@"Error getting asset! %@", error);
        }];
    }
}

//根据FileURL处理Video
- (void)handleVideoWithFileURL:(NSURL *)videoFileURL {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD showWithStatus:@"Loading..."];

    [LWGIFManager convertVideoToImages:videoFileURL completionBlock:^(NSArray<UIImage *> *images, float gifDelayTime) {
        [SVProgressHUD dismiss];
        _aryGifframes = images;
        _floatGifTime = gifDelayTime;
        [self setImages:images toImageView:self.imagePreview];
    }];

    [SVProgressHUD dismiss];
}

//处理LivePhoto
- (void)handleLivePhoto:(PHLivePhoto *)livePhoto {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD showWithStatus:@"Loading..."];

    NSArray *resourceArray = [PHAssetResource assetResourcesForLivePhoto:livePhoto];
    PHAssetResourceManager *assetResourceManager = [PHAssetResourceManager defaultManager];

    NSString *documentPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSError *error;

    //保存livePhoto中的图片
    PHAssetResource *livePhotoImageAsset = resourceArray[0];
    // Create path.
    NSString *filePath = [documentPath stringByAppendingPathComponent:@"Image.jpg"];
    _photoURL = [[NSURL alloc] initFileURLWithPath:filePath];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];

    [assetResourceManager writeDataForAssetResource:livePhotoImageAsset toFile:_photoURL options:nil completionHandler:^(NSError *_Nullable error) {
        NSLog(@"error: %@", error);
    }];


    //保存livePhoto中的短视频
    PHAssetResource *livePhotoVideoAsset = resourceArray[1];
    // Create path.
    filePath = [documentPath stringByAppendingPathComponent:@"Image.mov"];
    _videoURL = [[NSURL alloc] initFileURLWithPath:filePath];
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];

    [assetResourceManager writeDataForAssetResource:livePhotoVideoAsset toFile:_videoURL options:nil completionHandler:^(NSError *_Nullable error) {
        NSLog(@"videoURL: %@", _videoURL);
        NSLog(@"error: %@", error);

        [LWGIFManager convertVideoToImages:_videoURL completionBlock:^(NSArray<UIImage *> *images, float gifDelayTime) {
            [SVProgressHUD dismiss];
            _aryGifframes = images;
            _floatGifTime = gifDelayTime;
            [self setImages:images toImageView:self.imagePreview];
        }];
    }];

    [SVProgressHUD dismiss];
}


#pragma mark - YMSPhotoPickerViewControllerDelegate

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
        _aryGifframes = @[image];
        [self setImages:_aryGifframes toImageView:self.imagePreview];
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
        _aryGifframes = [mutableImages copy];
        [self setImages:_aryGifframes toImageView:self.imagePreview];
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
        //处理LivePhoto
        [self handleLivePhoto:self.liveView.livePhoto];

    } else if (self.selectedMode == VideoMode) {
        //处理视频
        [self handleVideoWithFileURL:self.selectedVideoFileURL];
    }

    //todo:跳转到视频预览页面
}

- (IBAction)exportGIFAction:(UIButton *)sender {

    if (self.selectedMode == LivePhotoMode) {
        //处理LivePhoto
        [self handleLivePhoto:self.liveView.livePhoto];

    } else if (self.selectedMode == VideoMode) {
        //处理视频
        [self handleVideoWithFileURL:self.selectedVideoFileURL];
    }

    //todo:合成图片帧集为GIF,并跳转到GIF预览页面


}

- (IBAction)exportFrameAction:(UIButton *)sender {
    //todo:跳转到图片集预览页面
}

#pragma mark - Private Method

//把一个images数组设置到ImageView
- (void)setImages:(NSArray <UIImage *> *)gifImages toImageView:(UIImageView *)imageView {
    UIImage *newImage1 = gifImages[0];

    NSMutableArray *images = [[NSMutableArray alloc] init];

    for (int i = 1; i <= [gifImages count]; i++) {
        UIImage *image = gifImages[i - 1];
        [images addObject:image];
    }

    imageView.image = nil;
    imageView.animationImages = [NSArray arrayWithArray:images];
    imageView.animationDuration = _floatGifTime * [gifImages count];
    imageView.animationRepeatCount = 0;
    [imageView startAnimating];

    //todo:隐藏弹窗
}


@end
