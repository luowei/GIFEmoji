//
// Created by Luo Wei on 2018/1/11.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDefines.h"

@class LWCategory;

#define ButtonId (sender.tag-Tag_First_Channel)

#define Arr_ChannelNames @[@"常用", @"搞笑", @"明星", @"人物", @"动物"]

//当前频道
#define Key_CurrentChannel @"Key_CurrentChannel"

//第1个Channel的Tag,即首页的Tag
#define Tag_First_Channel 100

//顶部分类滑条高度
#define TopScrollView_H 34.0

//一个屏幕宽度下显示5个标签
#define Num_Btns_InAHomeWidth 5

//顶部标签按钮宽度
#define TopBtn_W (Screen_W / Num_Btns_InAHomeWidth)

//顶部标签阴影图片宽度
#define ShadowImage_W 38.0
//顶部标签阴影图片高度
#define ShadowImage_H 3.0

#define NormalColor [UIColor grayColor]
#define SelectedColor [UIColor blackColor]


@interface LWTopScrollView : UIScrollView

//点击按钮选择名字ID
@property(nonatomic, assign) NSInteger userSelectedChannelID;
//滑动列表选择名字ID
@property(nonatomic, assign) NSInteger scrollViewSelectedChannelID;
//标签数组
@property(nonatomic, strong) NSArray<LWCategory *> *categoryList;

@property (nonatomic, strong) UIImageView *shadowImageView;           //按钮下的下划线


//选择一个标签
- (void)channelBtnTouchUpInside:(UIButton *)sender;

//设置顶行分类滚动条的按钮
-(void)setupSubviewWithCategoryList:(NSArray <LWCategory *>*)nameArray;

//滑动撤销选中按钮
- (void)setButtonUnSelect;

//滑动选中按钮
- (void)setButtonSelect;

//设置下划线的centerX
-(void)setShadowImageCenterX:(CGFloat)x;



@end