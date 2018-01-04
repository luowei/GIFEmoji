//
//  GenGIFViewController.h
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "YMSPhotoPickerViewController.h"

@class PHLivePhotoView;

@interface GenGIFViewController : UIViewController<UIImagePickerControllerDelegate,UINavigationControllerDelegate,YMSPhotoPickerViewControllerDelegate>

@property (nonatomic, weak) IBOutlet UIButton *selectLivePhotoBtn;
@property (nonatomic, weak) IBOutlet UIButton *selectStaticPhotoBtn;
@property (nonatomic, weak) IBOutlet UIButton *selectVideoBtn;


@property (nonatomic, weak) IBOutlet UIImageView *imagePreview;


@property (nonatomic, weak) IBOutlet UIButton *exportVideoBtn;
@property (nonatomic, weak) IBOutlet UIButton *exportGIFBtn;
@property (nonatomic, weak) IBOutlet UIButton *exportFrameBtn;


@end

