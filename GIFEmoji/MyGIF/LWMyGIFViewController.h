//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LWTopScrollView;
@class LWContainerScrollView;
@class LWInputMaskView;
@class GADInterstitial;


@interface LWMyGIFViewController : UIViewController

@property (nonatomic, weak) IBOutlet LWTopScrollView *topScrollView;
@property (nonatomic, weak) IBOutlet LWContainerScrollView *containerScrollView;

@property(nonatomic, strong) GADInterstitial *interstitial;
@property(nonatomic, copy) void (^afterAdShowBlock)();

//更新顶部导航条
- (void)updateTopScrollView;

//更新Container数据
-(void)updateContainerScrollView;

//展示广告
- (BOOL)showAdWithNumRate:(NSUInteger) numRate;

@end


