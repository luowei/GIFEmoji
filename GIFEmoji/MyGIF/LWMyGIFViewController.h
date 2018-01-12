//
// Created by Luo Wei on 2018/1/3.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LWTopScrollView;
@class LWContainerScrollView;
@class LWInputMaskView;


@interface LWMyGIFViewController : UIViewController

@property (nonatomic, weak) IBOutlet LWTopScrollView *topScrollView;
@property (nonatomic, weak) IBOutlet LWContainerScrollView *containerScrollView;

//更新顶部导航条
- (void)updateTopScrollView;

@end


