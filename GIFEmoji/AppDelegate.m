//
//  AppDelegate.m
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import "AppDelegate.h"
#import "LWPushManager.h"
#import "AppDefines.h"
#import "XGPush.h"
#import "GenGIFViewController.h"
#import "SearchGIFViewController.h"
#import "LWMyGIFViewController.h"
#import "Categories.h"

@interface AppDelegate () <UITabBarControllerDelegate>


@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    application.applicationIconBadgeNumber = 0;

    //程序启动时处理推送
    [[LWPushManager shareManager] handPushInApplicationDidFinishLaunchingWithOptions:launchOptions];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.tabBarController = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateInitialViewController];
    self.tabBarController.delegate = self;
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark - 处理URL handURL

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url {
    // Do something with the url here
    return true;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation {
    NSString *from = [url queryDictionary][@"from"];
    NSTimeInterval duration = [from isEqualToString:@"native"] ? .05 : .15;
    [self performSelector:@selector(handNavigateControllerWithURL:) withObject:url afterDelay:duration];
    return YES;
}

- (void)handNavigateControllerWithURL:(NSURL *)url {
    NSString *host = [url host];
    NSString *hostPrefix = [host subStringWithRegex:@"^([\\w_-]*)\\..*" matchIndex:1];

    [self setTabBarSelectedIndex:0];
    NSString *NotificationName = NotificationShowFrom_LWHomeViewController;
//    if ([hostPrefix isEqualToString:@"other"]) {
//        [self setTabBarSelectedIndex:1];
//        NotificationName = NotificationShowFrom_LWOtherViewController;
//    }

    NSString *from = [url queryDictionary][@"from"];
    NSTimeInterval duration = [from isEqualToString:@"native"] ? .05 : .15;
    NSDictionary *dict = @{@"NotificationName": NotificationName, @"URL": url};
    [self performSelector:@selector(postNotification:) withObject:dict afterDelay:duration];
}

- (void)postNotification:(NSDictionary *)dict {
    NSString *NotificationName = dict[@"NotificationName"];
    [[NSNotificationCenter defaultCenter] postNotificationName:NotificationName object:nil userInfo:dict];
}

- (void)setTabBarSelectedIndex:(NSUInteger)index {
    UIViewController *rootVC = self.window.rootViewController;
    if (![self.window.rootViewController isKindOfClass:[UITabBarController class]]) {
        return;
    }
    UITabBarController *tabBarController = (UITabBarController *) self.window.rootViewController;

    //先把 NavigationController 全部 Pop
    if ([tabBarController.selectedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navigationController = tabBarController.selectedViewController;
        [navigationController popToRootViewControllerAnimated:NO];
    }

    UIViewController *presentedViewController = tabBarController.presentedViewController;
    if ([presentedViewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *presentedNav = (UINavigationController *) presentedViewController;

        if (presentedNav.viewControllers.count > 0) { //关闭其他的Presented NavigationVC
            if (![presentedNav.viewControllers[0] isKindOfClass:[GenGIFViewController class]]
                    && ![presentedNav.viewControllers[0] isKindOfClass:[SearchGIFViewController class]]
                    && ![presentedNav.viewControllers[0] isKindOfClass:[LWMyGIFViewController class]]) {
                [presentedNav dismissViewControllerAnimated:NO completion:nil];
            }

        }

    } else {  //不是NavigationController,直接关闭即可
        [presentedViewController dismissViewControllerAnimated:NO completion:nil];
    }

    tabBarController.selectedIndex = index;
}

#pragma mark - 处理推送

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {

}

//远程通知 Remote Notification
- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    //向信息注册设备号
    NSString *deviceTokenStr = [XGPush registerDevice:deviceToken account:nil successCallback:^{
        Log(@"XGPush registerDevice:%@ account:%@  Success", deviceToken, nil);
    }                                   errorCallback:^{
        Log(@"XGPush registerDevice:%@ account:%@  Faild", deviceToken, nil);
    }];
    NSLog(@"[MyInputMethod] device token is %@", deviceTokenStr);
}

//收到静默推送的回调
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult result))completionHandler {
    //清除角标
    application.applicationIconBadgeNumber = 0;

    //处理推送消息
    [[LWPushManager shareManager] handRemotePushNotificationWithUserInfo:userInfo];

    //推送反馈XG
    [XGPush handleReceiveNotification:userInfo successCallback:nil errorCallback:nil];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error {
    if (error.code == 3010) {
        Log(@"iOS Simulator 不支持远程推送消息");
    } else {
        Log(@"application:didFailToRegisterForRemoteNotificationsWithError:%@", error.localizedFailureReason);
    }
}


//handleAction
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {

}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forRemoteNotification:(NSDictionary *)userInfo completionHandler:(void (^)())completionHandler {

}

//本地通知 Local Notification
- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification completionHandler:(void (^)())completionHandler {

}

- (void)application:(UIApplication *)application handleActionWithIdentifier:(NSString *)identifier forLocalNotification:(UILocalNotification *)notification withResponseInfo:(NSDictionary *)responseInfo completionHandler:(void (^)())completionHandler {

}

//收到远程通知的回调,iOS10 废弃的方法 Deprecated Message
- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo {
    Log(@"--------%d:%s \n\n", __LINE__, __func__);
    //清除角标
    application.applicationIconBadgeNumber = 0;

    //处理推送消息
    [[LWPushManager shareManager] handRemotePushNotificationWithUserInfo:userInfo];

    //推送反馈XG
    [XGPush handleReceiveNotification:userInfo successCallback:nil errorCallback:nil];
}

//收到本地通知的回调
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    Log(@"--------%d:%s \n\n", __LINE__, __func__);
    //清除角标
    application.applicationIconBadgeNumber = 0;
}


#pragma mark - UITabbarControllerDelegate Implements

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    //给TabBar设置过渡动画
    //set up crossfade transition
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    //apply transition to tab bar controller's view
    [self.window.rootViewController.view.layer addAnimation:transition forKey:nil];
}

@end
