//
// Created by Luo Wei on 2017/4/17.
// Copyright (c) 2017 luowei. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LWBackMaskView : UIView

@end


@interface LWPickerPanel : UIView <UIPickerViewDataSource, UIPickerViewDelegate>

@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UIView *toolBar;
@property (nonatomic, weak) IBOutlet UIView *topLine;
@property (nonatomic, weak) IBOutlet UIView *bottomLine;
@property (nonatomic, weak) IBOutlet UIButton *okBtn;
@property (nonatomic, weak) IBOutlet UIButton *cancelBtn;

@property(nonatomic, copy) void (^faveritaBlock)(NSInteger, NSString *);

+(instancetype)showPickerPanelInView:(UIView *)view;

@end
