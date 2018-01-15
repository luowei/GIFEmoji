//
// Created by Luo Wei on 2018/1/13.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWCategoriesAlertView.h"
#import "MASConstraintMaker.h"
#import "View+MASAdditions.h"
#import "LWMyGIFViewController.h"
#import "SVProgressHUD.h"
#import "UIView+extensions.h"
#import "LWSymbolService.h"
#import "AppDefines.h"
#import "UIColor+HexValue.h"


@interface LWCategoriesAlertView ()
@property(nonatomic, strong) UIButton *addBtn;
@end

@implementation LWCategoriesAlertView {

}

+(instancetype)showCategoryAlertInView:(UIView *)view {

    LWCategoriesAlertView *textInputView = nil;
    for(UIView *v in view.subviews){
        if([v isKindOfClass:[LWCategoriesAlertView class]]){
            textInputView = (LWCategoriesAlertView *) v;
        }
    }
    if(!textInputView){
        textInputView = [[LWCategoriesAlertView alloc] initWithFrame:view.bounds];
        [view addSubview:textInputView];
        [view bringSubviewToFront:textInputView];
        [textInputView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(view).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
    }

    return textInputView;
}

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.inputMaskView = [[LWInputMaskView alloc] initWithFrame:frame];
        [self addSubview:self.inputMaskView];
        self.inputMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];

        [self.inputMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];

        self.containerView = [[UITableView alloc] initWithFrame:CGRectZero];
        [self.inputMaskView addSubview:self.containerView];
        self.containerView.backgroundColor = [UIColor whiteColor];
        self.containerView.showsVerticalScrollIndicator = NO;
        self.containerView.separatorInset = UIEdgeInsetsMake(0, 0, 0, 0);
        self.containerView.layer.cornerRadius = 4;
        self.containerView.dataSource = self;
        self.containerView.delegate = self;
        [self.containerView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.inputMaskView);
            make.centerY.equalTo(self.inputMaskView);
            make.width.mas_equalTo(240);
            make.height.mas_equalTo(Screen_H / 2);
        }];

        self.dataList = [[LWSymbolService symbolService] categoriesList];
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

- (void)cancelBtnTouchUpInside:(UIButton *)btn {
    [self removeFromSuperview];
}


#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    LWCategory *category = self.dataList[(NSUInteger) indexPath.row];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    cell.textLabel.text = category.name;
    cell.textLabel.textAlignment = NSTextAlignmentCenter;
    return cell;
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 44;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 44;
}


- (nullable UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 40)];
    headerView.backgroundColor = [UIColor whiteColor];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.font = [UIFont boldSystemFontOfSize:18];
    titleLabel.text = NSLocalizedString(@"Category List", nil);
    [headerView addSubview:titleLabel];
    [titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(headerView);
    }];

    UIView *bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
    [headerView addSubview:bottomLine];
    bottomLine.backgroundColor = [UIColor colorWithHexString:ButtonTextColor];
    [bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(headerView);
        make.height.mas_equalTo(0.5);
    }];

    return headerView;
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 44)];
    footerView.backgroundColor = [UIColor whiteColor];

    self.addBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [footerView addSubview:self.addBtn];
    [self.addBtn setTitleColor:[UIColor colorWithHexString:ButtonTextColor] forState:UIControlStateNormal];
    self.addBtn.titleLabel.font = [UIFont systemFontOfSize:16];
    [self.addBtn setTitle:NSLocalizedString(@"Add Category", nil) forState:UIControlStateNormal];
    [self.addBtn addTarget:self action:@selector(addBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.addBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(footerView);
        make.width.mas_greaterThanOrEqualTo(120);
        make.height.mas_equalTo(40);
    }];

    UIView *topLine = [[UIView alloc] initWithFrame:CGRectZero];
    [footerView addSubview:topLine];
    topLine.backgroundColor = [UIColor colorWithHexString:ButtonTextColor];
    [topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(footerView);
        make.height.mas_equalTo(0.5);
    }];

    return footerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    LWCategory *category = self.dataList[(NSUInteger) indexPath.row];

    //弹出重名命弹窗
    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    [LWAddCategoryAlertView showTextInputViewInView:vc.view category:category updateBlock:^{
        self.dataList = [[LWSymbolService symbolService] categoriesList];
        [self.containerView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:Notification_CategoryChanged object:nil];
    }];
}

// Edit Cell

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return indexPath.row < self.dataList.count;
}

- (NSArray<UITableViewRowAction *> *)tableView:(UITableView *)tableView editActionsForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewRowAction *deleteAction = [UITableViewRowAction
            rowActionWithStyle:UITableViewRowActionStyleDefault
                         title:NSLocalizedString(@"Delete", nil)
                       handler:^(UITableViewRowAction *action, NSIndexPath *idxPath) {
                           //删除一个Cell
                           LWCategory *item = self.dataList[(NSUInteger) indexPath.row];
                           [[LWSymbolService symbolService] deleteCategoryWithId:item._id];
                           [[NSNotificationCenter defaultCenter] postNotificationName:Notification_CategoryChanged object:nil];
                           self.dataList = [[LWSymbolService symbolService] categoriesList];
                           [self.containerView reloadData];
                       }];
    deleteAction.backgroundColor = [UIColor colorWithHexString:@"#FC3C30"];

    return @[deleteAction];
}



- (void)addBtnTouchUpInside:(UIButton *)btn {
    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    [LWAddCategoryAlertView showTextInputViewInView:vc.view category:nil updateBlock:^{
        self.dataList = [[LWSymbolService symbolService] categoriesList];
        [self.containerView reloadData];
        [[NSNotificationCenter defaultCenter] postNotificationName:Notification_CategoryChanged object:nil];
    }];
}


@end



#pragma mark - LWAddCategoryAlertView

@implementation LWAddCategoryAlertView


+ (instancetype)showTextInputViewInView:(UIView *)view category:(LWCategory *)category 
                            updateBlock:(void (^)())updateBlock {
    LWAddCategoryAlertView *textInputView = nil;
    for(UIView *v in view.subviews){
        if([v isKindOfClass:[LWAddCategoryAlertView class]]){
            textInputView = (LWAddCategoryAlertView *) v;
        }
    }
    if(!textInputView){
        textInputView = [[LWAddCategoryAlertView alloc] initWithFrame:view.bounds category:category];
        [view addSubview:textInputView];
        [view bringSubviewToFront:textInputView];
        [textInputView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(view).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
    }
    textInputView.updateBlock = updateBlock;

    return textInputView;
}

- (instancetype)initWithFrame:(CGRect)frame category:(LWCategory *)category {
    self = [super initWithFrame:frame];
    if (self) {
        self.category = category;
        
        self.backgroundColor = [UIColor clearColor];
        self.inputMaskView = [[LWInputMaskView alloc] initWithFrame:frame];
        [self addSubview:self.inputMaskView];
        self.inputMaskView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];

        [self.inputMaskView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];

        self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
        [self.inputMaskView addSubview:self.containerView];
        self.containerView.backgroundColor = [UIColor whiteColor];
        self.containerView.layer.cornerRadius = 4;

        [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self.inputMaskView).offset(20);
            make.right.equalTo(self.inputMaskView).offset(-20);
            make.centerX.equalTo(self.inputMaskView);
            make.centerY.equalTo(self.inputMaskView).offset(-80);
        }];

        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self.containerView addSubview:self.titleLabel];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        self.titleLabel.text = category ? NSLocalizedString(@"Rename Category", nil) : NSLocalizedString(@"Add Favorite Category", nil);

        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.containerView);
            make.top.equalTo(self.containerView).offset(20);
            make.height.mas_equalTo(30);
        }];

        self.textField = [[UITextField alloc] initWithFrame:CGRectZero];
        [self.containerView addSubview:self.textField];
        self.textField.placeholder = NSLocalizedString(@"Input Category Name", nil);
        self.textField.borderStyle = UITextBorderStyleRoundedRect;
        self.textField.text = category ? category.name : @"";

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
        [self.okBtn setTitleColor:[UIColor colorWithHexString:ButtonTextColor] forState:UIControlStateNormal];
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
        [self.cancelBtn setTitleColor:[UIColor colorWithHexString:ButtonTextColor] forState:UIControlStateNormal];
        [self.cancelBtn addTarget:self action:@selector(cancelBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

        [self.cancelBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(bottomLine.mas_bottom);
            make.right.equalTo(self.containerView);
            make.left.equalTo(centerBtnLine.mas_right);
            make.bottom.equalTo(self.containerView);
            make.height.mas_equalTo(50);
        }];

        [self.textField becomeFirstResponder];

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
    NSString *name = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if(name.length <= 0 ){
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Text Empty", nil)];
        [SVProgressHUD dismissWithDelay:1.5];
        return;
    }

    NSArray <LWCategory *>*list = [[LWSymbolService symbolService] categoriesList];
    for(LWCategory *category in list){
        if([category.name isEqualToString:name]){
            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Exist The Category", nil)];
            [SVProgressHUD dismissWithDelay:1.5];
            return;
        }
    }

    BOOL isSuccess = NO;
    if(self.category){
        isSuccess = [[LWSymbolService symbolService] updateCategoryName:name byId:self.category._id];
    }else{
        isSuccess = [[LWSymbolService symbolService] insertCategoryWithType:@"My" name:name en_name:nil file_url:nil http_url:nil];
    }

    if(isSuccess){
        [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Operate Success", nil)];
        [SVProgressHUD dismissWithDelay:0.5];
    }else{
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Operate Faild", nil)];
        [SVProgressHUD dismissWithDelay:1.5];
    }

    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    [vc updateTopScrollView];   //更新顶部导航条

    if(self.updateBlock){
        self.updateBlock();
    }

    [self removeFromSuperview];
}

- (void)cancelBtnTouchUpInside:(UIButton *)btn {
    [self removeFromSuperview];
}

@end


#pragma mark - LWInputMaskView

@implementation LWInputMaskView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    [self.nextResponder touchesBegan:touches withEvent:event];
}


@end