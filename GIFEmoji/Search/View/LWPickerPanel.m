//
// Created by Luo Wei on 2017/4/17.
// Copyright (c) 2017 luowei. All rights reserved.
//

#import "LWPickerPanel.h"
#import "AppDefines.h"
#import "UIView+extensions.h"
#import "LWSymbolService.h"
#import "View+MASAdditions.h"


@implementation LWPickerPanel {
    NSMutableArray <LWCategory *>*_graphicCategroyArr;
    NSInteger _selectCategoryId;
    NSString *_selectCategoryName;
}

+(instancetype)showPickerPanelInView:(UIView *)view{
    LWPickerPanel *pickerPanel = [[NSBundle mainBundle] loadNibNamed:@"LWPickerPanel" owner:self options:nil][0];
    [view addSubview:pickerPanel];
    [pickerPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(view);
        make.bottom.equalTo(view);
        make.height.mas_equalTo(200);
    }];

    return pickerPanel;
}


- (void)awakeFromNib {
    [super awakeFromNib];

    self.layer.shadowColor = [UIColor blackColor].CGColor;
    self.layer.shadowOffset = CGSizeMake(0, -2);
    self.layer.shadowOpacity = 0.8;
    self.layer.shadowRadius = 4;

    //初始化数据源
   _graphicCategroyArr = [[LWSymbolService symbolService] categoriesList];
    if(_graphicCategroyArr.count > 0){
        _selectCategoryId = _graphicCategroyArr.count - 1;
        LWCategory *category = _graphicCategroyArr[(NSUInteger) _selectCategoryId];
        _selectCategoryName = category.name;
        [self.pickerView selectRow:_selectCategoryId inComponent:0 animated:NO];
    }

    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;

    //更新子视图
    UIFont *font = [UIFont systemFontOfSize:16];
    self.okBtn.titleLabel.font = font;
    self.cancelBtn.titleLabel.font = font;
}

- (void)layoutSubviews {
    [super layoutSubviews];
}


#pragma mark - UIPickerViewDataSource Implemetation

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return _graphicCategroyArr.count;
}

#pragma mark - UIPickerViewDelegate Implemetation

- (CGFloat)pickerView:(UIPickerView *)pickerView widthForComponent:(NSInteger)component {
    return self.pickerView.bounds.size.width;
}

- (CGFloat)pickerView:(UIPickerView *)pickerView rowHeightForComponent:(NSInteger)component {
    CGFloat height = self.pickerView.bounds.size.height;
    return (CGFloat) (height / rint(height / 30.0));
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(nullable UIView *)view {
    LWCategory *category = _graphicCategroyArr[(NSUInteger) row];
    NSString *text = category.name;

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.pickerView.bounds.size.width, self.pickerView.bounds.size.height)];
    titleLabel.textAlignment = NSTextAlignmentCenter;
    titleLabel.font = [UIFont systemFontOfSize:16];
    titleLabel.text = NSLocalizedString(text, nil);
    [titleLabel sizeToFit];
    return titleLabel;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if(!_graphicCategroyArr || _graphicCategroyArr.count <= 0){
        return;
    }
    LWCategory *category = _graphicCategroyArr[(NSUInteger) row];
    _selectCategoryId = category._id;
    _selectCategoryName = category.name;
}


-(IBAction)okAction{
    if(self.faveritaBlock){
        self.faveritaBlock(_selectCategoryId,_selectCategoryName);
    }
    [self removeFromSuperview];
}

-(IBAction)cancelAction{
    [self removeFromSuperview];
}


@end