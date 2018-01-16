//
// Created by Luo Wei on 2018/1/17.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class OSMessage;


#pragma mark - LWWechatActivity

UIKIT_EXTERN UIActivityType const UIActivityTypeShareToWechat;

@interface LWWechatActivity : UIActivity

@property(nonatomic, strong) NSURL *URL;

@property(nonatomic, strong) UIImage *iphoneImg;
@property(nonatomic, strong) UIImage *ipadImg;

@property(nonatomic, strong) OSMessage *msg;
@property(nonatomic, strong) UIView *fromView;



- (instancetype)initWithiphoneImage:(UIImage *)iphoneImg ipadImage:(UIImage *)ipadImg;

@end


#pragma mark - LWQQActivity

UIKIT_EXTERN UIActivityType const UIActivityTypeShareToQQ;

@interface LWQQActivity : UIActivity

@property(nonatomic, strong) NSURL *URL;

@property(nonatomic, strong) UIImage *iphoneImg;
@property(nonatomic, strong) UIImage *ipadImg;

@property(nonatomic, strong) OSMessage *msg;
@property(nonatomic, strong) UIView *fromView;



- (instancetype)initWithiphoneImage:(UIImage *)iphoneImg ipadImage:(UIImage *)ipadImg;

@end

