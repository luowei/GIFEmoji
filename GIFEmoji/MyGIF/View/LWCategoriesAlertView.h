//
// Created by Luo Wei on 2018/1/13.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LWInputMaskView;
@class LWCategory;


@interface LWCategoriesAlertView : UIView<UITableViewDataSource,UITableViewDelegate>

@property (nonatomic, strong) LWInputMaskView *inputMaskView;
@property (nonatomic, strong) UITableView *containerView;

@property (nonatomic, strong) NSArray <LWCategory *>* dataList;

+(instancetype)showCategoryAlertInView:(UIView *)view;

@end


@interface LWAddCategoryAlertView : UIView

@property (nonatomic, strong) LWInputMaskView *inputMaskView;
@property (nonatomic, strong) UIView *containerView;

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *okBtn;

@property(nonatomic, strong) LWCategory *category;

@property(nonatomic, copy) void (^updateBlock)();

+ (instancetype)showTextInputViewInView:(UIView *)view category:(LWCategory *)category updateBlock:(void (^)())updateBlock;
@end


@interface LWInputMaskView : UIView

@end

