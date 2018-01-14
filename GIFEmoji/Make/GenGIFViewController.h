//
//  GenGIFViewController.h
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMSPhotoPickerViewController.h"
#import "AppDefines.h"

@class PHLivePhotoView;
@class LWAVPlayerView;
@class FLAnimatedImageView;
@class LWLivePhotoView;

@interface GenGIFViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,YMSPhotoPickerViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *selectLivePhotoBtn;
@property (nonatomic, weak) IBOutlet UIButton *selectStaticPhotoBtn;
@property (nonatomic, weak) IBOutlet UIButton *selectVideoBtn;


@property (nonatomic, weak) IBOutlet FLAnimatedImageView *imagePreview;

@property(nonatomic, strong) LWLivePhotoView *liveView;
@property(nonatomic, strong) LWAVPlayerView *videoPlayerView;


@property (nonatomic, weak) IBOutlet UIButton *exportVideoBtn;
@property (nonatomic, weak) IBOutlet UIButton *exportGIFBtn;
@property (nonatomic, weak) IBOutlet UIButton *exportFrameBtn;


@property(nonatomic, readonly) SelectedMode selectedMode;

@property(nonatomic, strong) NSData *exportGIFImageData;
@property(nonatomic, strong) NSArray <UIImage *> *exportImageFrames;

- (void)updateSelectedMode:(SelectedMode)selectedMode;

//把一个images数组设置到ImageView
- (void)setImages:(NSArray <UIImage *> *)imageList toImageView:(FLAnimatedImageView *)imageView;

@end

