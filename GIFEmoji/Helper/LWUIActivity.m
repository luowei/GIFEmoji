//
// Created by Luo Wei on 2018/1/17.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWUIActivity.h"


#import "AppDefines.h"
#import "OpenShare.h"
#import "OpenShareHeader.h"


#pragma mark - LWWechatActivity

NSString *const UIActivityTypeShareToWechat = @"ShareToWechat";

@implementation LWWechatActivity

- (instancetype)initWithiphoneImage:(UIImage *)iphoneImg ipadImage:(UIImage *)ipadImg {
    self = [super init];
    if (self) {
        self.iphoneImg = iphoneImg;
        self.ipadImg = ipadImg;
    }

    return self;
}


- (UIActivityType)activityType {
    return UIActivityTypeShareToWechat;
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Share Wechat", nil);
}

- (UIImage *)activityImage {
    // Note: These images need to have a transparent background and I recommend these sizes:
    // iPadShare@2x should be 126 px, iPadShare should be 53 px, iPhoneShare@2x should be 100
    // px, and iPhoneShare should be 50 px. I found these sizes to work for what I was making.

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return self.ipadImg;
    } else {
        return self.iphoneImg;
    }
}

+ (UIActivityCategory)activityCategory {
    NSLog(@"--------%d:%s \n\n", __LINE__, __func__);
    //return [super activityCategory];
    return UIActivityCategoryShare;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    NSLog(@"--------%d:%s \n\n", __LINE__, __func__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSLog(@"--------%d:%s \n\n", __LINE__, __func__);
    [super prepareWithActivityItems:activityItems];
}

- (void)performActivity {
    [OpenShare shareToWeixinSession:self.msg fromView:self.fromView Success:^(OSMessage *message){
        Log(@"分享到微信成功");
    } Fail:^(OSMessage *message,NSError *error){
        Log(@"分享到微信失败");
    }];
    [self activityDidFinish:YES];
}

@end


#pragma mark - LWQQActivity

NSString *const UIActivityTypeShareToQQ = @"ShareToQQ";

@implementation LWQQActivity

- (instancetype)initWithiphoneImage:(UIImage *)iphoneImg ipadImage:(UIImage *)ipadImg {
    self = [super init];
    if (self) {
        self.iphoneImg = iphoneImg;
        self.ipadImg = ipadImg;
    }

    return self;
}


- (UIActivityType)activityType {
    return UIActivityTypeShareToQQ;
}

- (NSString *)activityTitle {
    return NSLocalizedString(@"Share QQ", nil);
}

- (UIImage *)activityImage {
    // Note: These images need to have a transparent background and I recommend these sizes:
    // iPadShare@2x should be 126 px, iPadShare should be 53 px, iPhoneShare@2x should be 100
    // px, and iPhoneShare should be 50 px. I found these sizes to work for what I was making.

    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        return self.ipadImg;
    } else {
        return self.iphoneImg;
    }
}

+ (UIActivityCategory)activityCategory {
    NSLog(@"--------%d:%s \n\n", __LINE__, __func__);
    //return [super activityCategory];
    return UIActivityCategoryShare;
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems {
    NSLog(@"--------%d:%s \n\n", __LINE__, __func__);
    return YES;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems {
    NSLog(@"--------%d:%s \n\n", __LINE__, __func__);
    [super prepareWithActivityItems:activityItems];
}

- (void)performActivity {
    //qq分享
    [OpenShare shareToQQFriends:self.msg fromView:self.fromView Success:^(OSMessage *message){
        Log(@"分享到qq成功");
    } Fail:^(OSMessage *message, NSError *error){
        Log(@"分享到qq失败");
    }];
    [self activityDidFinish:YES];
}

@end
