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
#import <PhotosUI/PhotosUI.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "NSGIF.h"
#import "SVProgressHUD.h"
#import "View+MASAdditions.h"
#import "YangMingShan.h"
#import "FLAnimatedImageView.h"
#import "LWLivePhotoView.h"
#import "LWAVPlayerView.h"
#import "UIImage+GIF.h"
#import "FLAnimatedImage.h"
#import "Categories.h"
#import "LWVideoPreviewViewController.h"
#import "LWHelper.h"
#import "LWGIFPreviewViewController.h"
#import "LWFramePreviewViewController.h"
#import "LWWKWebViewController.h"
#import "AppDelegate.h"
#import "NSData+ImageContentType.h"

@interface GenGIFViewController () {
}

@property(nonatomic, strong) NSURL *selectedVideoFileURL;

@property(nonatomic, strong) NSURL *livePhotoVideoURL;
@property(nonatomic, strong) NSURL *livePhotoFirstImageURL;

@end

@implementation GenGIFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(showDetailVC:) name:NotificationShowFrom_LWHomeViewController object:nil];

    [self updateUIAppearance];

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

    [self setupDefaultImage];
}

//设置默认的图片
- (void)setupDefaultImage {
    self.liveView.hidden = YES;
    self.videoPlayerView.hidden = YES;

    NSString *defaultGIFPath = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"gif"];
    NSData *gifData = [NSData dataWithContentsOfFile:defaultGIFPath];
    self.exportGIFImageData = gifData;
    [self updateSelectedMode:GIFMode];

    FLAnimatedImage *gifImage = [FLAnimatedImage animatedImageWithGIFData:gifData];
    self.exportGIFImageData = gifData;
    self.imagePreview.animatedImage = gifImage;

}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if(self.selectedMode == StaticPhotosMode && self.exportImageFrames){
        [self setImages:self.exportImageFrames toImageView:self.imagePreview];
    }
}


- (void)showDetailVC:(NSNotification *)notification {
    NSDictionary *dict = notification.userInfo;
    NSURL *url = dict[@"URL"];

    NSString *scheme = [[url scheme] lowercaseString];
    NSString *host = [url host];
    NSString *hostSufix = [host subStringWithRegex:@".*\\.([\\w_-]*)$" matchIndex:1];
    NSDictionary *queryDict = [url queryDictionary];

    UIViewController *controller = nil;
    if ([scheme isEqualToString:@"gifemoji"]) {

        if([host hasPrefix:@"share"]){    //如果是Share Extension跳来的

            if([hostSufix isEqualToString:@"file"]){    //文件
//                //从app group中获得文件路径
                NSString *absolutePath = [queryDict[@"url"] stringByRemovingPercentEncoding];
                if(!absolutePath || absolutePath.length <= 0){
                    return;
                }
                NSData *data = [[NSFileManager defaultManager] contentsAtPath:absolutePath];
                NSString *mimeType = [data mimeType];

                if(([mimeType hasPrefix:@"video"] && data.length/1024.0f/1024.0f > 100)
                        || ([mimeType hasPrefix:@"image"] && data.length/1024.0f/1024.0f > 10) ){   //大于10M
                    [SVProgressHUD showErrorWithStatus:@"file too big"];    //文件太大
                    return;
                }

                if([mimeType hasPrefix:@"image"]){  //图片
                    //NSString *fileName = [absolutePath subStringWithRegex:@".*/([^/]*)$" matchIndex:1];
                    //判断data类型

                    SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
                    if (imageFormat == SDImageFormatGIF) {
                        [self updateSelectedMode:GIFMode];

                        FLAnimatedImage *gifImage = [FLAnimatedImage animatedImageWithGIFData:data];
                        self.exportGIFImageData = data;
                        self.imagePreview.animatedImage = gifImage;
                    }else{
                        [self updateSelectedMode:StaticPhotosMode];
                        self.exportImageFrames = @[[[UIImage alloc] initWithData:data]];
                        [self setImages:self.exportImageFrames toImageView:self.imagePreview];
                    }
                    [self.navigationController popToRootViewControllerAnimated:YES];
                    return;
                }

                if ([mimeType hasPrefix:@"video"]) {  //视频
                    NSString *videoType = [data videoType];
                    if ([videoType containsString:@"video/quicktime"]
                            || [videoType containsString:@"video/mp4"]
                            || [videoType containsString:@"video/m4v"]
                            || [videoType containsString:@"video/3gpp"]) {

/*
                        AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:absolutePath options:nil];
                        CMTime dur = sourceAsset.duration;

                        if(dur.value < 20){
                            [self updateSelectedMode:VideoMode];

                            NSURL *videoURL = [NSURL fileURLWithPath:absolutePath];

                            NSLog(@"Video at URL %@", videoURL.path);
                            self.selectedVideoFileURL = videoURL;

                            self.videoPlayerView.hidden = NO;
                            [self.videoPlayerView playVideoWithURL:self.selectedVideoFileURL];
                        }
*/

//                        NSString *videoPath = [NSString stringWithFormat:@"%@%@",NSTemporaryDirectory(),[LWHelper getCurrentTimeStampText]];
//                        [LWHelper copyFileSource:absolutePath targetPath:videoPath option:FileExsist_Update];
//
                        [LWHelper getTrimmedVideoForFile:absolutePath
                                               videoType:videoType
                                           withStartTime:0
                                                 endTime:10
                                       completionHandler:^(NSString *outputPath) {
                                           dispatch_async(dispatch_get_main_queue(), ^{
                                               [self updateSelectedMode:VideoMode];

                                               NSURL *videoURL = [NSURL fileURLWithPath:absolutePath];
                                               if (outputPath) {
                                                   videoURL = [NSURL fileURLWithPath:outputPath];
                                               }

                                               NSLog(@"Picked a movie at URL %@", videoURL.path);
                                               self.selectedVideoFileURL = videoURL;
                                               NSLog(@"> %@", [self.selectedVideoFileURL path]);

                                               self.videoPlayerView.hidden = NO;
                                               [self.videoPlayerView playVideoWithURL:self.selectedVideoFileURL];
                                           });
                                       }];
                    }

                    [self.navigationController popToRootViewControllerAnimated:YES];
                    return;
                }

                return;
            }

            if(@available(iOS 9.1,*)){
                if([hostSufix isEqualToString:@"livephoto"]){   //livephoto
                    NSURL *imageURL = [NSURL fileURLWithPath:[queryDict[@"imageURL"] stringByRemovingPercentEncoding]];
                    NSURL *videoURL = [NSURL fileURLWithPath:[queryDict[@"videoURL"] stringByRemovingPercentEncoding]];
                    [PHLivePhoto requestLivePhotoWithResourceFileURLs:@[imageURL,videoURL]
                                                     placeholderImage:[UIImage imageWithContentsOfFile:imageURL.path]
                                                           targetSize:CGSizeZero
                                                          contentMode:PHImageContentModeAspectFit
                                                        resultHandler:^(PHLivePhoto *livePhoto, NSDictionary *info) {

                                                            [self updateSelectedMode:LivePhotoMode];
                                                            self.liveView.hidden = NO;
                                                            self.liveView.livePhoto = livePhoto;
                                                            [self.liveView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];
                                                        }];

//                [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
//                    PHAssetCreationRequest *request = [PHAssetCreationRequest creationRequestForAsset];
//
//                    //These types should be inferred from your files
//
//                    //PHAssetResourceCreationOptions *photoOptions = [[PHAssetResourceCreationOptions alloc] init];
//                    //photoOptions.uniformTypeIdentifier = @"public.jpeg";
//
//                    //PHAssetResourceCreationOptions *videoOptions = [[PHAssetResourceCreationOptions alloc] init];
//                    //videoOptions.uniformTypeIdentifier = @"com.apple.quicktime-movie";
//
//                    [request addResourceWithType:PHAssetResourceTypePhoto fileURL:photoURL options:nil /*photoOptions*/];
//                    [request addResourceWithType:PHAssetResourceTypePairedVideo fileURL:videoURL options:nil /*videoOptions*/];
//
//                } completionHandler:^(BOOL success, NSError * _Nullable error) {
//                    NSLog(@"success? %d, error: %@",success,error);
//                }];

                    [self.navigationController popToRootViewControllerAnimated:YES];
                    return;
                }
            }

            if([hostSufix containsString:@"http"]){ //链接
                NSURL *detailURL = [self getHTTPURLFromQueryDict:queryDict];
                if(!detailURL){
                    return;
                }
                controller = [LWWKWebViewController wkWebViewControllerWithURL:detailURL];
                [self showViewController:controller withQueryDict:queryDict];
                return;
            }


        }else if (([hostSufix containsString:@"http"])) {
            NSURL *detailURL = [self getHTTPURLFromQueryDict:queryDict];
            if(detailURL){
                controller = [LWWKWebViewController wkWebViewControllerWithURL:detailURL];
                [self showViewController:controller withQueryDict:queryDict];
            }
        }

    }

}



- (void)showViewController:(UIViewController *)controller withQueryDict:(NSDictionary *)queryDict {
    if (controller) {
        NSString *title = [queryDict[@"title"] stringByRemovingPercentEncoding];
        controller.navigationItem.title = title;
        [controller setHidesBottomBarWhenPushed:YES];

        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (NSURL *)getHTTPURLFromQueryDict:(NSDictionary *)queryDict {
    NSString *urlString = [queryDict[@"url"] stringByRemovingPercentEncoding];
//    urlString = (NSString *) CFBridgingRelease(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (__bridge CFStringRef) urlString, (CFStringRef) @"!NULL,'()*+,-./:;=?@_~%#[]", NULL, kCFStringEncodingUTF8));
    NSURL *detailURL = [NSURL URLWithString:urlString];
    return detailURL;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

        self.selectedVideoFileURL = info[UIImagePickerControllerMediaURL];
        NSString *videoPath = self.selectedVideoFileURL.path;
        [LWHelper getTrimmedVideoForFile:self.selectedVideoFileURL.path
                               videoType:nil
                           withStartTime:0
                                 endTime:10
                       completionHandler:^(NSString *outputPath) {
                           dispatch_async(dispatch_get_main_queue(), ^{
                               [self updateSelectedMode:VideoMode];

                               NSURL *videoURL = [NSURL fileURLWithPath:videoPath];
                               if (outputPath) {
                                   videoURL = [NSURL fileURLWithPath:outputPath];
                               }

                               NSLog(@"Picked a movie at URL %@", videoURL.path);
                               self.selectedVideoFileURL = videoURL;

                               self.videoPlayerView.hidden = NO;
                               [self.videoPlayerView playVideoWithURL:self.selectedVideoFileURL];
                           });
                       }];


//        [self updateSelectedMode:VideoMode];
//
//        NSLog(@"Picked a movie at URL %@", info[UIImagePickerControllerMediaURL]);
//        self.selectedVideoFileURL = info[UIImagePickerControllerMediaURL];
//        NSLog(@"> %@", [self.selectedVideoFileURL path]);
//
//        self.videoPlayerView.hidden = NO;
//        [self.videoPlayerView playVideoWithURL:self.selectedVideoFileURL];

        return;
    }


    //处理LivePhoto
    PHLivePhoto *livePhoto = nil;

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.1")) {
        livePhoto = info[UIImagePickerControllerLivePhoto];
    }
    if (livePhoto) {
        [self updateSelectedMode:LivePhotoMode];

        self.liveView.hidden = NO;
        self.liveView.livePhoto = livePhoto;
        [self.liveView startPlaybackWithStyle:PHLivePhotoViewPlaybackStyleFull];

        return;

    } else {
        //处理其他照片
        BOOL isGIF = [self isGIFWithPickerInfo:info];
        if (isGIF) {    //是GIF图片
            NSData *gifData = self.exportGIFImageData;
            [self updateSelectedMode:GIFMode];
            
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"The Photo is GIF Image", nil)];
            [SVProgressHUD dismissWithDelay:0.5];

            FLAnimatedImage *gifImage = [FLAnimatedImage animatedImageWithGIFData:gifData];
            self.exportGIFImageData = gifData;
            self.imagePreview.animatedImage = gifImage;

        } else {    //其他情况就让用户重新选择
            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Not a Live Photo", nil)];
            [SVProgressHUD dismissWithDelay:0.5];

            [self selectLivePhotoAction:nil];   //选择LivePhoto
        }

    }

}

- (void)updateSelectedMode:(SelectedMode)selectedMode {
    _selectedMode = selectedMode;

    self.selectedVideoFileURL = nil;
    self.exportGIFImageData = nil;
    self.exportImageFrames = nil;
    self.livePhotoFirstImageURL = nil;
    self.livePhotoVideoURL = nil;

    [self updateExportBtnWithSelectedMode:_selectedMode];
}

//更新导出按钮的样式及
- (void)updateExportBtnWithSelectedMode:(SelectedMode)mode {
    switch (mode) {
        case LivePhotoMode: {
            [self.imagePreview stopAnimating];
            self.imagePreview.animatedImage = nil;
            self.imagePreview.image = nil;

            self.exportFrameBtn.hidden = NO;
            self.exportGIFBtn.hidden = NO;
            self.exportVideoBtn.hidden = NO;
            break;
        }
        case StaticPhotosMode: {
            self.exportFrameBtn.hidden = NO;
            self.exportGIFBtn.hidden = NO;
            self.exportVideoBtn.hidden = YES;
            break;
        }
        case VideoMode: {
            [self.imagePreview stopAnimating];
            self.imagePreview.animatedImage = nil;
            self.imagePreview.image = nil;

            self.exportFrameBtn.hidden = NO;
            self.exportGIFBtn.hidden = NO;
            self.exportVideoBtn.hidden = NO;
            break;
        }
        case GIFMode: {
            [self.imagePreview stopAnimating];
            self.imagePreview.animatedImage = nil;
            self.imagePreview.image = nil;

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
                                 resultHandler:^(NSData *_Nullable imageData, NSString *_Nullable dataUTI, UIImageOrientation orientation, NSDictionary *_Nullable info) {
                                     strongify(self)
                                     Log(@"dataUTI:%@", dataUTI);

                                     //gif 图片
                                     if ([dataUTI isEqualToString:(__bridge NSString *) kUTTypeGIF]) {
                                         //这里获取gif图片的NSData数据
                                         BOOL downloadFinined = (![info[PHImageCancelledKey] boolValue] && !info[PHImageErrorKey]);
                                         if (downloadFinined && imageData) {
                                             isGIF = YES;
                                             self.exportGIFImageData = imageData;
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

                        ALAssetRepresentation *re = [asset representationForUTI:(__bridge NSString *) kUTTypeGIF];
                        if (re) {
                            isGIF = YES;

                            //获取GIF数据
                            size_t size = (size_t) re.size;
                            uint8_t *buffer = malloc(size);
                            NSError *error;
                            NSUInteger bytes = [re getBytes:buffer fromOffset:0 length:size error:&error];
                            self.exportGIFImageData = [NSData dataWithBytes:buffer length:bytes];
                            free(buffer);
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


//根据FileURL处理Video
- (void)handleVideoWithFileURL:(NSURL *)videoFileURL completionBlock:(void (^)(NSArray<UIImage *> *images, NSData *gifData))completionBlock {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD showWithStatus:@"Loading..."];

    NSString *gifFileName = [NSString stringWithFormat:@"%@.gif", [self.livePhotoVideoURL.absoluteString md5]];
    NSString *gifFilePath = [NSTemporaryDirectory() stringByAppendingString:gifFileName];

    [LWGIFManager convertVideoToImages:videoFileURL
                       exportedGIFPath:gifFilePath
                        frameDelayTime:0.1
                       completionBlock:^(NSArray<UIImage *> *images, NSData *gifData) {
                           [SVProgressHUD dismiss];
                           if (completionBlock) {
                               completionBlock(images, gifData);
                           }
                       }];

    [SVProgressHUD dismiss];
}

//处理LivePhoto
- (void)handleLivePhoto:(PHLivePhoto *)livePhoto completionBlock:(void (^)(NSArray<UIImage *> *images, NSData *gifData))completionBlock {
    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeGradient];
    [SVProgressHUD showWithStatus:@"Loading..."];

    NSArray *resourceArray = [PHAssetResource assetResourcesForLivePhoto:livePhoto];
    PHAssetResourceManager *assetResourceManager = [PHAssetResourceManager defaultManager];

    NSError *error;

    //保存livePhoto中的图片
    PHAssetResource *livePhotoImageAsset = resourceArray[0];
    // Create path.

//    NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    NSString *imageFileName = [NSString stringWithFormat:@"%@.jpg", [LWHelper getCurrentTimeStampText]];
    NSString *imageFilePath = [NSTemporaryDirectory() stringByAppendingString:imageFileName];
    self.livePhotoFirstImageURL = [NSURL fileURLWithPath:imageFilePath];
    [[NSFileManager defaultManager] removeItemAtPath:imageFilePath error:&error];

    [assetResourceManager writeDataForAssetResource:livePhotoImageAsset toFile:self.livePhotoFirstImageURL options:nil completionHandler:^(NSError *_Nullable error) {
        [SVProgressHUD dismiss];
        NSLog(@"error: %@", error);
    }];


    //保存livePhoto中的短视频
    PHAssetResource *livePhotoVideoAsset = resourceArray[1];
    // Create path.
    NSString *videoFileName = [NSString stringWithFormat:@"%@.mov", [LWHelper getCurrentTimeStampText]];
    NSString *videoFilePath = [NSTemporaryDirectory() stringByAppendingString:videoFileName];
    self.livePhotoVideoURL = [[NSURL alloc] initFileURLWithPath:videoFilePath];
    [[NSFileManager defaultManager] removeItemAtPath:videoFilePath error:&error];

    [assetResourceManager writeDataForAssetResource:livePhotoVideoAsset toFile:self.livePhotoVideoURL options:nil completionHandler:^(NSError *_Nullable error) {
        NSLog(@"videoURL: %@", self.livePhotoVideoURL);
        NSLog(@"error: %@", error);

        NSString *gifFileName = [NSString stringWithFormat:@"%@.gif", [self.livePhotoVideoURL.absoluteString md5]];
        NSString *gifFilePath = [NSTemporaryDirectory() stringByAppendingString:gifFileName];

        [LWGIFManager convertVideoToImages:self.livePhotoVideoURL
                           exportedGIFPath:gifFilePath
                            frameDelayTime:0.1
                           completionBlock:^(NSArray<UIImage *> *images, NSData *gifData) {
                               [SVProgressHUD dismiss];
                               if (completionBlock) {
                                   completionBlock(images, gifData);
                               }
                           }];
    }];
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

    [self updateSelectedMode:StaticPhotosMode];


    [picker dismissViewControllerAnimated:YES completion:^() {
        self.exportImageFrames = @[image];
        [self setImages:self.exportImageFrames toImageView:self.imagePreview];
    }];
}

//选择了多张图片
- (void)photoPickerViewController:(YMSPhotoPickerViewController *)picker didFinishPickingImages:(NSArray *)photoAssets {
    self.liveView.hidden = YES;
    self.videoPlayerView.hidden = YES;

    [self updateSelectedMode:StaticPhotosMode];

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
        self.exportImageFrames = mutableImages;
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
        if (!self.livePhotoVideoURL) {
            //处理LivePhoto
            [self handleLivePhoto:self.liveView.livePhoto completionBlock:nil];
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

    if (self.exportGIFImageData) {
        [self showGIFPreviewVCWithGIFData:self.exportGIFImageData];
//        //合成图片帧集为GIF,并跳转到GIF预览页面
//        LWGIFPreviewViewController *vc = [LWGIFPreviewViewController viewControllerWithGIFData:self.exportGIFImageData];
//        [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    switch (self.selectedMode) {
        case LivePhotoMode: {
            //处理LivePhoto
            weakify(self)
            [self handleLivePhoto:self.liveView.livePhoto completionBlock:^(NSArray<UIImage *> *images, NSData *gifData) {
                strongify(self)
                self.exportImageFrames = images;
                [self showGIFPreviewVCWithGIFData:gifData];
            }];
            return;
        }
        case VideoMode: {
            [self.videoPlayerView pauseVideo];  //暂停播放
            //处理视频
            weakify(self)
            [self handleVideoWithFileURL:self.selectedVideoFileURL completionBlock:^(NSArray<UIImage *> *images, NSData *gifData) {
                strongify(self)
                self.exportImageFrames = images;
                [self showGIFPreviewVCWithGIFData:gifData];
            }];
            return;
        }
        case StaticPhotosMode: {
            if (!self.exportImageFrames || self.exportImageFrames.count <= 0) {
                break;
            }
            CGSize imageSize = self.exportImageFrames.firstObject.size;
            NSString *gifFileName = [NSString stringWithFormat:@"%@.gif", [LWHelper getCurrentTimeStampText]];
            NSString *gifFilePath = [NSTemporaryDirectory() stringByAppendingString:gifFileName];
            NSData *gifData = [UIImage createGIFWithImages:self.exportImageFrames size:imageSize loopCount:0 delayTime:0.1 gifCachePath:gifFilePath];
            [self showGIFPreviewVCWithGIFData:gifData];
            break;
        }
        default: {
            if (!self.exportGIFImageData) {
                [SVProgressHUD showWithStatus:NSLocalizedString(@"Export GIF Faild", nil)];
                [SVProgressHUD dismissWithDelay:1.0];
            }
            break;
        }
    }

}

- (IBAction)exportFrameAction:(UIButton *)sender {
    //跳转到图片集预览页面
    if (self.exportImageFrames) {
        LWFramePreviewViewController *vc = [LWFramePreviewViewController viewControllerWithImages:self.exportImageFrames];
        [self.navigationController pushViewController:vc animated:YES];
        return;
    }

    switch (self.selectedMode) {
        case LivePhotoMode: {
            //处理LivePhoto
            weakify(self)
            [self handleLivePhoto:self.liveView.livePhoto completionBlock:^(NSArray<UIImage *> *images, NSData *gifData) {
                strongify(self)
                self.exportGIFImageData = gifData;
                [self showFramePreviewVCWithImages:images];
            }];
            return;
        }
        case VideoMode: {
            [self.videoPlayerView pauseVideo];  //暂停播放
            //处理视频
            weakify(self)
            [self handleVideoWithFileURL:self.selectedVideoFileURL completionBlock:^(NSArray<UIImage *> *images, NSData *gifData) {
                strongify(self)
                self.exportGIFImageData = gifData;
                [self showFramePreviewVCWithImages:images];
            }];
            return;
        }
        case GIFMode: {
            NSArray <UIImage *>*images = [UIImage imagesFromGIFData:self.exportGIFImageData];
            [self showFramePreviewVCWithImages:images];
            break;
        }
        default: {
            if(!self.exportImageFrames){
                [SVProgressHUD showWithStatus:NSLocalizedString(@"Export Frames Faild", nil)];
                [SVProgressHUD dismissWithDelay:1.0];
            }
            break;
        }
    }

    return;

}


#pragma mark - Private Method

- (void)showGIFPreviewVCWithGIFData:(NSData *)gifData {
    self.exportGIFImageData = gifData;

    if([LWGIFManager frameCountWithGIFData:self.exportGIFImageData] <= 1){
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Only One Frame", nil)];
        [SVProgressHUD dismissWithDelay:1.0];
        return;
    }

    if (self.exportGIFImageData) {
        LWGIFPreviewViewController *vc = [LWGIFPreviewViewController viewControllerWithGIFData:self.exportGIFImageData];
        [self.navigationController pushViewController:vc animated:YES];

    } else {
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Export GIF Faild", nil)];
        [SVProgressHUD dismissWithDelay:1.0];
    }
}


- (void)showFramePreviewVCWithImages:(NSArray <UIImage *>*)images {
    self.exportImageFrames = images;
    if (self.exportImageFrames && self.exportImageFrames.count > 0) {
        LWFramePreviewViewController *vc = [LWFramePreviewViewController viewControllerWithImages:self.exportImageFrames];
        [self.navigationController pushViewController:vc animated:YES];

    } else {
        [SVProgressHUD showWithStatus:NSLocalizedString(@"Export Frames Faild", nil)];
        [SVProgressHUD dismissWithDelay:1.0];
    }
}


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
    imageView.animationDuration = 0.1 * [imageList count];
    imageView.animationRepeatCount = 0;
    [imageView startAnimating];

}


@end
