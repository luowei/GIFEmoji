//
// Created by Luo Wei on 2018/1/11.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LWCategory;


@interface LWContainerScrollView : UIScrollView

@property(nonatomic, assign) NSInteger currentChannel;

//子视图ScrollView的scrollsToTop是否可用
@property(nonatomic) BOOL scrollTopEnable;

@property(nonatomic, strong) NSArray<LWCategory *> *categoryList;

//设置内容子视图
-(void)setupSubviewWithCategoryList:(NSArray <LWCategory *>*)categoryList;

//根据指定的标签Id显示标签内容
-(void)showChannelWithChannelId:(NSInteger)channelId;

//更新contentOffset
- (void)updateContainerContentOffset;

@end