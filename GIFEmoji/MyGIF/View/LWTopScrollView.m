//
// Created by Luo Wei on 2018/1/11.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWTopScrollView.h"
#import "UIImage+RCColor.h"
#import "AppDefines.h"
#import "LWContainerScrollView.h"
#import "LWMyGIFViewController.h"
#import "UIView+extensions.h"
#import "UIColor+CrossFade.h"
#import "LWSymbolService.h"
#import "UIColor+HexValue.h"
#import "Categories.h"


@implementation LWTopScrollView {

}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.userSelectedChannelID = Tag_First_Channel;
    self.scrollViewSelectedChannelID = Tag_First_Channel;

    self.pagingEnabled = NO;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;
    self.scrollsToTop = NO;
    self.contentSize = CGSizeMake(Screen_W, TopScrollView_H);

}

//设置顶行分类滚动条的按钮
-(void)setupSubviewWithCategoryList:(NSArray <LWCategory *>*)categoryList {
    self.categoryList = categoryList;

    [self updateButtonItems];   //更新ScrollView底的子Button项

    CGFloat shadowImageWidth = [self getShadowWidthWithIdx:0];
    //标签阴影下划线
    if (!self.shadowImageView) {
        self.shadowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, (self.frame.size.height - ShadowImage_H)/2, shadowImageWidth, ShadowImage_H)];
        self.shadowImageView.layer.cornerRadius = ShadowImage_H/2;
        self.shadowImageView.clipsToBounds = YES;
        [self.shadowImageView setImage:[UIImage imageWithColor:[UIColor colorWithHexString:ButtonTextColor] size:self.shadowImageView.frame.size]];
        [self addSubview:self.shadowImageView];
    }
    self.shadowImageView.center = CGPointMake(TopBtn_W / 2, self.frame.size.height/2);
    self.shadowImageView.bounds = CGRectMake(0, 0, shadowImageWidth, ShadowImage_H);
    [self sendSubviewToBack:self.shadowImageView];
}

//根据index获取相应的宽度
- (CGFloat)getShadowWidthWithIdx:(NSInteger)index {
    if(self.categoryList && self.categoryList.count > index){
        LWCategory *category = self.categoryList[index];
        CGFloat width = [category.name widthWithFont:[UIFont systemFontOfSize:17.0]] + 10;
        return width;
    }else{
        return 40;
    }
}

//更新数据列表
- (void)updateCategoryList {
    self.categoryList = [[LWSymbolService symbolService] categoriesList];

    [self updateButtonItems];   //更新ScrollView底的子Button项
}


//更新ScrollView底的子Button项
- (void)updateButtonItems {
    NSInteger currentChannel = [[NSUserDefaults standardUserDefaults] integerForKey:@"Key_CurrentChannel"];
    self.contentSize = CGSizeMake(TopBtn_W * self.categoryList.count, TopScrollView_H);
    self.scrollViewSelectedChannelID = (NSInteger) (currentChannel + Tag_First_Channel);

    for(UIView *view in self.subviews){
        if([view isKindOfClass:[UIButton class]]){
            [view removeFromSuperview];
        }
    }

    //设置标签
    for (int i = 0; i < [self.categoryList count]; i++) {

        UIButton *button = (UIButton *) [self viewWithTag:i + Tag_First_Channel];
        if (!button) {
            button = [UIButton buttonWithType:UIButtonTypeCustom];
            [button addTarget:self action:@selector(channelBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:button];
            [button setTag:i + Tag_First_Channel];
        }
        [button setFrame:CGRectMake(TopBtn_W * i, 0, TopBtn_W, self.frame.size.height)];
        NSString *title = self.categoryList[i].name;
        [button setTitle:[NSString stringWithFormat:@"%@", title] forState:UIControlStateNormal];
        if (i == _scrollViewSelectedChannelID - Tag_First_Channel) {
            button.selected = YES;
        }

        //设置标签外观
        button.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [button setTitleColor:NormalColor forState:UIControlStateNormal];
        [button setTitleColor:SelectedColor forState:UIControlStateSelected];

        [self updateButtonSelect];
    }
}


//选择一个标签
- (void)channelBtnTouchUpInside:(UIButton *)sender {
    if(!sender){
        return;
    }


    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];

    //当处于编辑状态时，即containerScrollView的scrollEnable为No时,不能被选中
    if (!vc.containerScrollView.scrollEnabled) {
        return;
    }

    [self adjustScrollViewContentX:sender];

    //如果更换按钮
    if (sender.tag != _userSelectedChannelID) {
        //取之前的按钮
        UIButton *lastButton = (UIButton *) [self viewWithTag:_userSelectedChannelID];
        lastButton.selected = NO;
        //赋值按钮ID
        _userSelectedChannelID = sender.tag;
    }

    //按钮选中状态
    if (!sender.selected) {
        sender.selected = YES;

        //赋值滑动列表选择标签Id
        _scrollViewSelectedChannelID = sender.tag;

        //设置内容页出现
        [vc.containerScrollView showChannelWithChannelId:_scrollViewSelectedChannelID-Tag_First_Channel];
        //[vc.containerScrollView setContentOffset:CGPointMake(ButtonId * Screen_W, 0) animated:YES];
    }

    [self updateButtonSelect];
}

//滑动标签以适应选择项,让选择项完全显示出来
- (void)adjustScrollViewContentX:(UIButton *)sender {
    if (sender.frame.origin.x - self.contentOffset.x > Screen_W - TopBtn_W) {
        //4:表示显示五个标签
        [self setContentOffset:CGPointMake((ButtonId - Num_Btns_InAHomeWidth) * TopBtn_W, 0) animated:YES];
    }

    if (sender.frame.origin.x - self.contentOffset.x < 0) {
        [self setContentOffset:CGPointMake(ButtonId * TopBtn_W, 0) animated:YES];
    }
}


//滑动撤销选中按钮
- (void)updateButtonUnSelect {
    UIButton *lastButton = (UIButton *) [self viewWithTag:_scrollViewSelectedChannelID];
    lastButton.selected = NO;
}

//滑动选中按钮
- (void)updateButtonSelect {
    UIButton *button = (UIButton *) [self viewWithTag:_scrollViewSelectedChannelID];
    button.selected = YES;
    _userSelectedChannelID = button.tag;
    CGFloat shadowImageWidth = [self getShadowWidthWithIdx:_userSelectedChannelID - Tag_First_Channel];

    [UIView animateWithDuration:0.25 animations:^{
        self.shadowImageView.center = CGPointMake(button.frame.origin.x + TopBtn_W / 2, self.frame.size.height/2);
        self.shadowImageView.bounds = CGRectMake(0, 0, shadowImageWidth, ShadowImage_H);
    }];

}

//设置下划线的centerX
- (void)setShadowImageCenterX:(CGFloat)x {
    [UIView animateWithDuration:0.1 animations:^{
        self.shadowImageView.center = CGPointMake(x, self.frame.size.height/2);
    } completion:^(BOOL finished) {
        if(finished){
            CGFloat shadowCenterX = self.shadowImageView.center.x;

            //给按钮设置过渡颜色
            for (int i = 0; i < [self.categoryList count]; i++) {
                UIButton *btn = (UIButton *) [self viewWithTag:i + Tag_First_Channel];
                if(!btn){
                    continue;
                }

                CGFloat btnCenterX = btn.center.x;
                CGFloat detaX = shadowCenterX-btnCenterX;
                CGFloat crossRatio = fabs(detaX/TopBtn_W);
                //下划线在按钮右边，还不到两个标签按钮中间时 或者 下划线在按钮左边，还不到两个标签按钮中间时
                if( (detaX > 0 && detaX < TopBtn_W) || (detaX > -TopBtn_W && detaX < 0) ){
                    btn.titleLabel.textColor = [UIColor colorForFadeBetweenFirstColor:SelectedColor secondColor:NormalColor atRatio:crossRatio];
                }
            }

        }
    }];

}


@end