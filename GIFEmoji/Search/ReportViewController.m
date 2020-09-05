//
// Created by luowei on 2018/1/31.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "ReportViewController.h"
#import "SearchGIFViewController.h"
#import "SVProgressHUD.h"
#import "AppDefines.h"
#import "NSImage+WebCache.h"
#import "LWPurchaseHelper.h"


@implementation ReportViewController {

}

-(NSArray <NSString *>*)dataList{
    return @[
            NSLocalizedString(@"Lewd or harassing content", nil),
            NSLocalizedString(@"Bad Content", nil),
            NSLocalizedString(@"There is infringement", nil)
    ];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Report", nil);
    self.tableView.tableFooterView = [UIView new];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReportList"];
    if(!obj){
        self.reportList = @[].mutableCopy;
    }else{
        self.reportList = [obj mutableCopy];
    }

    if(![LWPurchaseHelper isPurchased]){
        //添加谷歌横幅广告
        [self addGADBanner];
    }
}


//选择投诉原因

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    cell.textLabel.text = self.dataList[(NSUInteger) indexPath.row];
    return cell;
}

- (nullable NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return @"选择投诉原因";
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"=======selected row");
    [self.reportList addObject:self.urlString];
    [[NSUserDefaults standardUserDefaults] setObject:self.reportList forKey:@"ReportList"];

    //请求网络
    NSURL *url = [NSURL URLWithString:@"http://wodedata.com/MyResource/GIFEmoji/res_report"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"http://wodedata.com" forHTTPHeaderField:@"Referer"];
    weakify(self)
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        strongify(self)
        if (error) {
            Log(@"Error:%@",error.localizedDescription);
        }
//            if ([data isKindOfClass:[NSData class]]) {
//                //把 NSData 转换成 NSString
//                NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//            }

        dispatch_main_async_safe(^{
            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Received Report", nil)];
            [SVProgressHUD dismissWithDelay:2.5];

            for(UIViewController *item in self.navigationController.viewControllers){
                if([item isKindOfClass:[SearchGIFViewController class]]){
                    [self.navigationController popToViewController:item animated:YES];
                    return;
                }
            }
            [self.navigationController popViewControllerAnimated:YES];
        });

    }] resume];
}

#pragma mark - GAD Banner

//添加谷歌横幅广告
- (void)addGADBanner {
    GADAdSize size = GADAdSizeFromCGSize(CGSizeMake(Screen_W, 50));
    self.bannerView = [[GADBannerView alloc] initWithAdSize:size];
    self.bannerView.adUnitID = @"ca-app-pub-8760692904992206/9036563441";
    self.bannerView.rootViewController = self;
    self.bannerView.delegate = self;

    self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.bannerView];
    [self.view addConstraints:@[
            [NSLayoutConstraint constraintWithItem:self.bannerView
                                         attribute:NSLayoutAttributeBottom
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.bottomLayoutGuide
                                         attribute:NSLayoutAttributeTop
                                        multiplier:1
                                          constant:-6],
            [NSLayoutConstraint constraintWithItem:self.bannerView
                                         attribute:NSLayoutAttributeCenterX
                                         relatedBy:NSLayoutRelationEqual
                                            toItem:self.view
                                         attribute:NSLayoutAttributeCenterX
                                        multiplier:1
                                          constant:0]
    ]];

    //加载广告
    [self.bannerView loadRequest:[GADRequest request]];
}


@end