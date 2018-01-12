//
// Created by Luo Wei on 2018/1/12.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LWInputMaskView;


@interface LWTextInputView : UIView

@property (nonatomic, strong) LWInputMaskView *inputMaskView;
@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *okBtn;

+(instancetype)showTextInputViewInView:(UIView *)view;

@end


@interface LWInputMaskView : UIView

@end

