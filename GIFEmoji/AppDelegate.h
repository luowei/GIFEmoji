//
//  AppDelegate.h
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>


#define NotificationShowFrom_LWHomeViewController @"NotificationShowFrom_LWHomeViewController"

#define App_Delegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property(nonatomic, strong) UITabBarController *tabBarController;

- (void)setTabBarSelectedIndex:(NSUInteger)index;

@end

