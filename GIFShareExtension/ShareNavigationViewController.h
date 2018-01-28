//
//  ShareNavigationViewController.h
//  GIFShareExtension
//
//  Created by luowei on 2018/1/26.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Social/Social.h>

@class FLAnimatedImageView;

@interface ShareNavigationViewController : UINavigationController

@end


@interface LWShareViewController : UIViewController<UIGestureRecognizerDelegate,UITextViewDelegate,
        UIWebViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property(nonatomic, strong) UIView *containerView;

@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIView *topLine;
@property(nonatomic, strong) UITextView *textView;
@property(nonatomic, strong) UIView *bottomLine;
@property(nonatomic, strong) UIButton *okButton;

@property(nonatomic, strong) FLAnimatedImageView *imageView;

@property(nonatomic, strong) PHLivePhotoView *liveView;
@property(nonatomic, strong) NSData *imageData;
@property(nonatomic) BOOL isPickerImage;
@property(nonatomic, strong) UIButton *livePhotoBtn;
@property(nonatomic) BOOL isLivePhoto;
@property(nonatomic, strong) PHLivePhoto *livePhoto;
@end