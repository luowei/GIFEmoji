//
// Created by Luo Wei on 2017/10/23.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, PointLocation) {
    Outside = 1 << 0,                   //外部
    InControl = 1 << 1,                 //内部
    OnControl = 1 << 2,                 //框上
    OnTopEdge = (1 << 3) | OnControl,       //顶边上
    OnBottomEdge = (1 << 4) | OnControl,    //底边上
    OnLeftEdge = (1 << 5) | OnControl,      //左边上
    OnRightEdge = (1 << 6) | OnControl,     //右边上
    OnLeftTopCorner = (1 << 7) | OnControl,      //左上角
    OnRightTopCorner = (1 << 8) | OnControl,     //右上角
    OnLeftBottomCorner = (1 << 9) | OnControl,   //左下角
    OnRightBottomCorner = (1 << 10) | OnControl,  //右下角
};


@interface LWSnapshotMaskView : UIView

@property (nonatomic, strong) UIView *selectRegion;

@property(nonatomic, strong) UIButton *cancelBtn;

@property(nonatomic, strong) UIButton *shareBtn;

@property(nonatomic) CGRect snapshotFrame;

//@property(nonatomic, strong) UIView *snapshotView;

@property(nonatomic) enum PointLocation pointLocation;

@property(nonatomic) CGPoint prePoint;

@property(nonatomic, strong) UIButton *fullScreenBtn;

@property(nonatomic, copy) void (^closeBlock)();

+(LWSnapshotMaskView *)showSnapshotMaskInView:(UIView *)view;
+(void)hideSnapshotMaskInView:(UIView *)view;


//判断 point 在 snapshotFrame 的哪个位置
- (PointLocation)locationOfPoint:(CGPoint)point;


@end