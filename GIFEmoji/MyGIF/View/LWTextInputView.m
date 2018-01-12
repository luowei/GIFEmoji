//
// Created by Luo Wei on 2018/1/12.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWTextInputView.h"
#import "View+MASAdditions.h"
#import "UIColor+HexValue.h"
#import "UIView+Frame.h"
#import "UIView+extensions.h"
#import "SVProgressHUD.h"
#import "LWSymbolService.h"
#import "LWMyGIFViewController.h"


@implementation LWTextInputView

+(instancetype)showTextInputViewInView:(UIView *)view {

    LWTextInputView *textInputView = nil;
    for(UIView *v in view.subviews){
        if([v isKindOfClass:[LWTextInputView class]]){
            textInputView = (LWTextInputView *) v;
        }
    }
    if(!textInputView){
        textInputView = [[LWTextInputView alloc] initWithFrame:view.bounds inView:view];
        [view addSubview:textInputView];
        [view bringSubviewToFront:textInputView];
        [textInputView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(view).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
    }

    return textInputView;
}

- (instancetype)initWithFrame:(CGRect)frame inView:(UIView *)view {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.inputMaskView = [[LWInputMaskView alloc] initWithFrame:frame];
        [view addSubview:self.inputMaskView];
        self.inputMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];

        [self.inputMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(view).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];

        self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.inputMaskView addSubview:self.containerView];
        self.containerView.backgroundColor = [UIColor whiteColor];
        self.containerView.layer.cornerRadius = 4;

        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(view).offset(20);
            make.right.equalTo(view).offset(-20);
            make.centerX.equalTo(view);
            make.centerY.equalTo(view).offset(-50);
        }];

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.containerView addSubview:self.titleLabel];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        self.titleLabel.text = NSLocalizedString(@"Add Favorite Category", nil);

        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.containerView);
            make.top.equalTo(self.containerView).offset(20);
            make.height.mas_equalTo(30);
        }];

        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        [self.containerView addSubview:self.textField];
        self.textField.placeholder = NSLocalizedString(@"Input Category Name", nil);
        self.textField.borderStyle = UITextBorderStyleRoundedRect;

        [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.containerView);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
            make.left.equalTo(self.containerView).offset(20);
            make.right.equalTo(self.containerView).offset(-20);
            make.height.mas_equalTo(40);
        }];

        UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
        [self.containerView addSubview:bottomLine];
        bottomLine.backgroundColor = [UIColor lightGrayColor];

        [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.equalTo(self.containerView);
            make.height.mas_equalTo(0.5);
            make.top.equalTo(self.textField.mas_bottom).offset(20);
        }];

        UIView *centerBtnLine = [[UIView alloc] initWithFrame:CGRectZero];
        [self.containerView addSubview:centerBtnLine];
        centerBtnLine.backgroundColor = [UIColor lightGrayColor];

        [centerBtnLine mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bottomLine.mas_bottom).offset(0);
            make.bottom.equalTo(self.containerView);
            make.centerX.equalTo(self.containerView);
            make.width.mas_equalTo(0.5);
        }];


        self.okBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.containerView addSubview:self.okBtn];
        self.okBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        [self.okBtn setTitle:NSLocalizedString(@"Ok", nil) forState:UIControlStateNormal];
        [self.okBtn setTitleColor:[UIColor colorWithHexString:@"28862C"] forState:UIControlStateNormal];
        [self.okBtn addTarget:self action:@selector(okBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

        [self.okBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bottomLine.mas_bottom);
            make.left.equalTo(self.containerView);
            make.right.equalTo(centerBtnLine.mas_left);
            make.bottom.equalTo(self.containerView);
            make.height.mas_equalTo(50);
        }];


        self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.containerView addSubview:self.cancelBtn];
        self.cancelBtn.titleLabel.font = [UIFont systemFontOfSize:16];
        [self.cancelBtn setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [self.cancelBtn setTitleColor:[UIColor colorWithHexString:@"28862C"] forState:UIControlStateNormal];
        [self.cancelBtn addTarget:self action:@selector(cancelBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

        [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bottomLine.mas_bottom);
            make.right.equalTo(self.containerView);
            make.left.equalTo(centerBtnLine.mas_right);
            make.bottom.equalTo(self.containerView);
            make.height.mas_equalTo(50);
        }];

    }

    return self;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    CGPoint touchPoint = [touches.anyObject locationInView:self.inputMaskView];
    if(!CGRectContainsPoint(self.containerView.frame, touchPoint)){
        [self removeFromSuperview];
    }
}


- (void)okBtnTouchUpInside:(UIButton *)btn {
    NSString *name = self.textField.text;
    BOOL isSuccess = [[LWSymbolService symbolService] insertCategoryWithType:@"My" name:name en_name:nil file_url:nil http_url:nil];
    if(isSuccess){
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Add Success", nil)];
        [SVProgressHUD dismissWithDelay:1.5];
    }else{
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Add Faild", nil)];
        [SVProgressHUD dismissWithDelay:1.5];
    }

    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    [vc updateTopScrollView];   //更新顶部导航条

    [self removeFromSuperview];
}

- (void)cancelBtnTouchUpInside:(UIButton *)btn {
    [self removeFromSuperview];
}

@end

@implementation LWInputMaskView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.nextResponder touchesBegan:touches withEvent:event];
}


@end
