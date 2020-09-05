//
//  AppDelegate.m
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import "AppDelegate.h"
#import "AppDefines.h"
#import "GenGIFViewController.h"
#import "SearchGIFViewController.h"
#import "LWMyGIFViewController.h"
#import "Categories.h"
#import "OpenShare.h"
#import "OpenShare+QQ.h"
#import "OpenShareHeader.h"
#import "LWWKWebViewController.h"
#import <UMAnalytics/MobClick.h>
#import <UMCommon/UMConfigure.h>
#import <UMPush/UMessage.h>
#import <GoogleMobileAds/GADMobileAds.h>
#import <GoogleMobileAds/GADInterstitial.h>

@interface AppDelegate () <UITabBarControllerDelegate,UNUserNotificationCenterDelegate>


@end


@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    application.applicationIconBadgeNumber = 0;

    //U-Push 配置
    [self configUPush:launchOptions];

    //Google Ads
    [[GADMobileAds sharedInstance] startWithCompletionHandler:nil];
    GADMobileAds.sharedInstance.requestConfiguration.testDeviceIdentifiers = @[kGADSimulatorID];

    //UMeng Anlyitcs
    [UMConfigure initWithAppkey:@"5f53e9183739314483bc403e" channel:@"App Store"];
    //[MobClick setCrashReportEnabled:YES];   // 默认是开启Crash收集的
    [UMConfigure setLogEnabled:YES];
    [MobClick setScenarioType:E_UM_NORMAL];   //支持普通场景
    [MobClick setAutoPageEnabled:YES];  //设置为自动采集页面

    //注册appId,qq和wechat
    [OpenShare connectQQWithAppId:@"1106605943"];
    [OpenShare connectWeixinWithAppId:@"wxb4b64828a439e04b"];

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



#pragma mark - UITabbarControllerDelegate Implements

- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController {
    //给TabBar设置过渡动画
    //set up crossfade transition
    CATransition *transition = [CATransition animation];
    transition.type = kCATransitionFade;
    //apply transition to tab bar controller's view
    [self.window.rootViewController.view.layer addAnimation:transition forKey:nil];
}

#pragma mark - Push

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [UMessage setAutoAlert:NO];
    if([[[UIDevice currentDevice] systemVersion]intValue] < 10){
        [UMessage didReceiveRemoteNotification:userInfo];
    }

    //过滤掉Push的撤销功能，因为PushSDK内部已经调用的completionHandler(UIBackgroundFetchResultNewData)，
    //防止两次调用completionHandler引起崩溃
    if(![userInfo valueForKeyPath:@"aps.recall"]) {
        completionHandler(UIBackgroundFetchResultNewData);
    }
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    if (![deviceToken isKindOfClass:[NSData class]]) return;
    const unsigned *tokenBytes = (const unsigned *) [deviceToken bytes];
    NSString *hexToken = [NSString stringWithFormat:@"%08x%08x%08x%08x%08x%08x%08x%08x",
                    ntohl(tokenBytes[0]), ntohl(tokenBytes[1]), ntohl(tokenBytes[2]),
                    ntohl(tokenBytes[3]), ntohl(tokenBytes[4]), ntohl(tokenBytes[5]),
                    ntohl(tokenBytes[6]), ntohl(tokenBytes[7])];
    Log(@"==== push deviceToken:%@", hexToken);
    //1.2.7版本开始不需要用户再手动注册devicetoken，SDK会自动注册
    //传入的devicetoken是系统回调didRegisterForRemoteNotificationsWithDeviceToken的入参，切记
    //[UMessage registerDeviceToken:deviceToken];
}

//iOS10新增：处理前台收到通知的代理方法
-(void)userNotificationCenter:(UNUserNotificationCenter *)center willPresentNotification:(UNNotification *)notification withCompletionHandler:(void (^)(UNNotificationPresentationOptions))completionHandler{
    NSDictionary * userInfo = notification.request.content.userInfo;
    if([notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //[UMessage setAutoAlert:NO];
        //应用处于前台时的远程推送接受,必须加这句代码
        [UMessage didReceiveRemoteNotification:userInfo];
    }else{
        //应用处于前台时的本地推送接受
    }
    completionHandler(UNNotificationPresentationOptionSound|UNNotificationPresentationOptionBadge|UNNotificationPresentationOptionAlert);
}
//iOS10新增：处理后台点击通知的代理方法
-(void)userNotificationCenter:(UNUserNotificationCenter *)center didReceiveNotificationResponse:(UNNotificationResponse *)response withCompletionHandler:(void (^)())completionHandler {
    NSDictionary *userInfo = response.notification.request.content.userInfo;
    if ([response.notification.request.trigger isKindOfClass:[UNPushNotificationTrigger class]]) {
        //应用处于后台时的远程推送接受,必须加这句代码
        [UMessage didReceiveRemoteNotification:userInfo];
    } else {
        //应用处于后台时的本地推送接受
    }
}


@end


//API_AVAILABLE(ios(10))
@implementation AppDelegate(UPush)

//配置UPush

- (void)configUPush:(NSDictionary *)launchOptions /*API_AVAILABLE(ios(10))*/ {
    // Push组件基本功能配置
    UMessageRegisterEntity * entity = [[UMessageRegisterEntity alloc] init];
    //type是对推送的几个参数的选择，可以选择一个或者多个。默认是三个全部打开，即：声音，弹窗，角标
    entity.types = UMessageAuthorizationOptionBadge|UMessageAuthorizationOptionSound|UMessageAuthorizationOptionAlert;

    // Push功能配置
    //如果你期望使用交互式(只有iOS 8.0及以上有)的通知，请参考下面注释部分的初始化代码
    if (([[[UIDevice currentDevice] systemVersion]intValue]>=8)&&([[[UIDevice currentDevice] systemVersion]intValue]<10)) {
        UIMutableUserNotificationAction *action1 = [[UIMutableUserNotificationAction alloc] init];
        action1.identifier = @"action1_identifier";
        action1.title=@"打开";
        action1.activationMode = UIUserNotificationActivationModeForeground;//当点击的时候启动程序

        UIMutableUserNotificationAction *action2 = [[UIMutableUserNotificationAction alloc] init];  //第二按钮
        action2.identifier = @"action2_identifier";
        action2.title=@"忽略";
        action2.activationMode = UIUserNotificationActivationModeBackground;//当点击的时候不启动程序，在后台处理
        action2.authenticationRequired = YES;//需要解锁才能处理，如果action.activationMode = UIUserNotificationActivationModeForeground;则这个属性被忽略；
        action2.destructive = YES;
        UIMutableUserNotificationCategory *actionCategory1 = [[UIMutableUserNotificationCategory alloc] init];
        actionCategory1.identifier = @"category1";//这组动作的唯一标示
        [actionCategory1 setActions:@[action1,action2] forContext:(UIUserNotificationActionContextDefault)];
        NSSet *categories = [NSSet setWithObjects:actionCategory1, nil];
        entity.categories=categories;
    }
    //如果要在iOS10显示交互式的通知，必须注意实现以下代码
    if ([[[UIDevice currentDevice] systemVersion]intValue]>=10) {
        UNNotificationAction *action1_ios10 = [UNNotificationAction actionWithIdentifier:@"action1_identifier" title:@"打开" options:UNNotificationActionOptionForeground];
        UNNotificationAction *action2_ios10 = [UNNotificationAction actionWithIdentifier:@"action2_identifier" title:@"忽略" options:UNNotificationActionOptionForeground];

        //UNNotificationCategoryOptionNone
        //UNNotificationCategoryOptionCustomDismissAction  清除通知被触发会走通知的代理方法
        //UNNotificationCategoryOptionAllowInCarPlay       适用于行车模式
        UNNotificationCategory *category1_ios10 = [UNNotificationCategory categoryWithIdentifier:@"category1" actions:@[action1_ios10,action2_ios10]   intentIdentifiers:@[] options:UNNotificationCategoryOptionCustomDismissAction];
        NSSet *categories = [NSSet setWithObjects:category1_ios10, nil];
        entity.categories=categories;

        [UNUserNotificationCenter currentNotificationCenter].delegate=self;
    }

    //[UNUserNotificationCenter currentNotificationCenter].delegate=self;
    [UMessage registerForRemoteNotificationsWithLaunchOptions:launchOptions Entity:entity completionHandler:^(BOOL granted, NSError * _Nullable error) {
        if (granted) {
            Log(@"===UMessage 注册成功");
        }else{
        }
    }];

//    [UMessage setBadgeClear:NO]; //默认为YES
//    [UMessage setAutoAlert:NO];

    [UMessage setWebViewClassString:NSStringFromClass(LWWKWebViewController.class)];  //自定义跳转WebView
    //[UMessage addCardMessageWithLabel:@"消息"]; //插屏消息
    //自定义插屏消息
    [UMessage addCustomCardMessageWithPortraitSize:CGSizeMake(300, 500) LandscapeSize:CGSizeMake(500, 300) CloseBtn:nil Label:@"消息" umCustomCloseButtonDisplayMode:NO];
    //文本插屏消息
    [UMessage addPlainTextCardMessageWithTitleFont:[UIFont systemFontOfSize:16] ContentFont:[UIFont systemFontOfSize:14] buttonFont:[UIFont systemFontOfSize:17] Label:@"消息"];
}

@end
