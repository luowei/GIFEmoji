//
// Created by Luo Wei on 2018/1/11.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWContainerScrollView.h"
#import "LWTopScrollView.h"
#import "LWMyGIFViewController.h"
#import "UIView+extensions.h"
#import "LWMyGIFCollectionView.h"
#import "LWSymbolService.h"


@interface LWContainerScrollView () <UIScrollViewDelegate,UIGestureRecognizerDelegate>

//@property(nonatomic, strong) NSMutableArray <UICollectionView *>*collectionList;
@end


@implementation LWContainerScrollView {
    CGFloat _userContentOffsetX;
    BOOL _isLeftScroll;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor whiteColor];
    self.contentMode = UIViewContentModeTopRight;
    self.clipsToBounds = NO;
    self.delegate = self;

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.showsHorizontalScrollIndicator = NO;
    self.showsVerticalScrollIndicator = NO;

    self.pagingEnabled = YES;
    self.userInteractionEnabled = YES;
    self.bounces = NO;
    self.scrollsToTop = NO;

    _userContentOffsetX = 0;

}

//接收屏幕发生旋转消息
- (void)rotationToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    //屏幕发生旋转修改contentOffset
    [self updateContainerContentOffset];
}

//更新contentOffset
- (void)updateContainerContentOffset {
    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    NSUInteger selIdx = (NSUInteger) (vc.topScrollView.scrollViewSelectedChannelID - Tag_First_Channel);
    self.contentOffset = CGPointMake(selIdx * Screen_W, 0);
}

//设置内容子视图
-(void)setupSubviewWithCategoryList:(NSArray <LWCategory *>*)categoryList{
    self.categoryList = categoryList;
    //设置contenSize
    self.contentSize = CGSizeMake(Screen_W * self.categoryList.count, self.frame.size.height);

    for (int i = 0; i < [self.categoryList count]; i++) {
        CGRect contentFrame = CGRectMake(0 + Screen_W * i, 0, Screen_W, self.frame.size.height);

        LWCategory *category = self.categoryList[i];
        LWMyGIFCollectionView *collectionView = [[LWMyGIFCollectionView alloc] initWithFrame:contentFrame category:category];
        collectionView.tag = Tag_First_Channel + i;
        [self addSubview:collectionView];
    }

    //这里要调set方法
    //如果设置的Channel与当前显示的不同，显示设置的
    if (_currentChannel != 0) {

        LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];

        //做选中一个标签的操作
        vc.topScrollView.scrollViewSelectedChannelID = (NSInteger) (0 + Tag_First_Channel);
        UIButton *button = (UIButton *) [vc.topScrollView viewWithTag:(NSInteger) (0 + Tag_First_Channel)];
        if(!button){
            return;
        }
        [vc.topScrollView channelBtnTouchUpInside:button];

        //适配TopScrollView的位置
        [self adjustTopScrollView:self];
    }

    [self updateCurrentChannel:0];
}

//滑动内容顶部滑动标签跟随滑动
- (void)adjustTopScrollViewButton:(UIScrollView *)scrollView {
    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];

    NSInteger positionId = (NSInteger) (scrollView.contentOffset.x/Screen_W);
    [vc.topScrollView updateButtonUnSelect];
    vc.topScrollView.scrollViewSelectedChannelID = (NSInteger) (positionId + Tag_First_Channel);;
    [vc.topScrollView updateButtonSelect];
}


#pragma mark - UIScrollViewDelegate 的实现

//开发滑动
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    _userContentOffsetX = scrollView.contentOffset.x;
}

//当滑动时
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {

    //如果是上下滚动
    CGPoint offset = scrollView.contentOffset;
    if (fabs(offset.x) < fabs(offset.y)) {
        return;
    }

    _isLeftScroll = _userContentOffsetX < scrollView.contentOffset.x;

    //设置TopScrollView下划线的centerX
    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    [vc.topScrollView setShadowImageCenterX:(TopBtn_W / 2 + scrollView.contentOffset.x * (TopBtn_W / self.frame.size.width))];

}

//当滑动结束减速
- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {

    NSInteger i = (NSUInteger) roundf(scrollView.contentOffset.x / Screen_W);
    [self updateCurrentChannel:i];

    //调整顶部滑条按钮状态
    [self adjustTopScrollViewButton:scrollView];

    [self adjustTopScrollView:scrollView];
}

//适应TopScrollView
- (void)adjustTopScrollView:(UIScrollView *)scrollView {
    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    //左滑
    if (_isLeftScroll) {
        if (scrollView.contentOffset.x <= Screen_W * (Num_Btns_InAHomeWidth - 1)) {
            [vc.topScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        } else {
            CGFloat topOffsetX = (vc.topScrollView.contentOffset.x + TopBtn_W) > (self.categoryList.count - Num_Btns_InAHomeWidth) * TopBtn_W ?
                    vc.topScrollView.contentOffset.x : vc.topScrollView.contentOffset.x + TopBtn_W;
            [vc.topScrollView setContentOffset:CGPointMake(topOffsetX, 0) animated:YES];
        }

    }
        //右滑
    else {
        if (scrollView.contentOffset.x >= Screen_W * Num_Btns_InAHomeWidth) {
            CGFloat topOffsetX = vc.topScrollView.contentOffset.x - TopBtn_W;
            [vc.topScrollView setContentOffset:CGPointMake(topOffsetX, 0) animated:YES];
        }
        else {
            [vc.topScrollView setContentOffset:CGPointMake(0, 0) animated:YES];
        }
    }
}


#pragma mark - 显示标签内容

//根据指定的标签Id显示标签内容
-(void)showChannelWithChannelId:(NSInteger)channelId{

    //设置TopScrollView下划线的centerX
    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    [vc.topScrollView setShadowImageCenterX:(TopBtn_W / 2 + channelId * Screen_W * (TopBtn_W / self.frame.size.width))];

    [self updateCurrentChannel:channelId];
    [self setContentOffset:CGPointMake(channelId * Screen_W,0) animated:NO];
}

//设置当前选中栏目
- (void)updateCurrentChannel:(NSInteger)channelId {
    //设置_currentChannel
    _currentChannel = channelId < 0 ? 0 : channelId;

    //滑动时创建内容详情页面
    CGRect contentFrame = CGRectMake(0 + Screen_W * channelId, 0, Screen_W, self.frame.size.height);

    //更子视图的scrollsToTop
    [self updateScrollsToTopWithChannelId:channelId];

    LWCategory *category = self.categoryList[(NSUInteger) channelId];

    //更新当前CollectionView数据源，并更新scrollTopEnable
    LWMyGIFCollectionView *collectionView = [self viewWithTag:Tag_First_Channel + channelId];
    if(!collectionView){
        collectionView = [[LWMyGIFCollectionView alloc] initWithFrame:contentFrame category:category];
        collectionView.tag = Tag_First_Channel + channelId;
        [self addSubview:collectionView];
    }
    [collectionView reloadWithCategory:category];   //刷新CollectionView的数据

    //保存
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setInteger:channelId forKey:Key_CurrentChannel];
    [userDefaults synchronize];
}

//更新subview的scrollsToTop
- (void)updateScrollsToTopWithChannelId:(NSInteger) channelId {

    for(LWMyGIFCollectionView *colView in self.subviews){
        colView.scrollsToTop = NO;
    }
    LWMyGIFCollectionView *collectionView = [self viewWithTag:Tag_First_Channel + channelId];
    collectionView.scrollsToTop = YES;

}


@end