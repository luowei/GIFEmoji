//
//  SearchGIFViewController.m
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import "SearchGIFViewController.h"
#import "LWImageModel.h"
#import "AppDefines.h"
#import "Categories.h"
#import "SDWebImageCompat.h"
#import "YYModel.h"
#import "SDWebImageDownloader.h"
#import "LWHelper.h"
#import "NSData+ImageContentType.h"
#import "FLAnimatedImageView.h"
#import "SDWebImageManager.h"
#import "FLAnimatedImage.h"
#import "LWPickerPanel.h"
#import "FCFileManager.h"
#import "UIView+extensions.h"
#import "LWSymbolService.h"
#import "AppDelegate.h"
#import "GenGIFViewController.h"
#import "LWWKWebViewController.h"
#import "SVProgressHUD.h"
#import "UIColor+HexValue.h"
#import "LWAVPlayerView.h"
#import "LWLivePhotoView.h"
#import "OpenShare.h"
#import "UIImage+Extension.h"
#import "OpenShareHeader.h"
#import "LWUIActivity.h"
#import "LWPurchaseHelper.h"
#import "LWPurchaseViewController.h"
#import <GoogleMobileAds/GADBannerView.h>
#import <GoogleMobileAds/GADInterstitial.h>

#define Item_Spacing 6
#define Default_PageSize 100
//图片搜索
//#define URLString_POST_Image @"http://image.baidu.com/search/avatarjson?tn=resultjsonavatarnew&ie=utf-8&z=%@&ic=0&s=0&face=0&st=-1&lm=-1&word=%@&pn=%@&rn=%@"
#define URLString_POST_Image @"https://image.baidu.com/search/acjson?tn=resultjson_com&ipn=rj&word=%@&width=%i&height=%i&pn=%@&rn=%@"


@interface SearchGIFViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout,UITextFieldDelegate,
                                    GADBannerViewDelegate,GADInterstitialDelegate>

@property(nonatomic, strong) NSMutableArray <LWImageModel *> *imageList;
@property(nonatomic, assign) NSUInteger startNum;

@property(nonatomic, strong) GADBannerView *bannerView;

@end

@implementation SearchGIFViewController {
    NSUInteger _startNum;
    NSString *_searchText;
    dispatch_source_t _source;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchBtn.layer.cornerRadius = 5;
    self.collectionView.backgroundColor = [UIColor colorWithHexString:@"#F6F6F6"];
    self.favoritedDcitionary = @{}.mutableCopy;

    // Do any additional setup after loading the view, typically from a nib.
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

    self.searchTextField.text = [LWHelper isAfterDate:@"2018-02-05"] ? @"GIF" : @"";

    //网络请求图片User-Agent要设置为浏览器的
    SDWebImageDownloader *manager = [SDWebImageDownloader sharedDownloader];
    [manager setValue:[LWHelper getiOSUserAgent] forHTTPHeaderField:@"User-Agent"];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(favoriteChangeNotify:) name:Notification_FavoriteChanged object:nil];



    //构建分派源
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
//    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_source, ^{
        [self reloadImageSearch];
    });
    dispatch_resume(_source);

    [self reloadSearchResult];  //发送发派源Merge信息，调用网络请求

    //创建并加载广告
    self.interstitial = [self createAndLoadInterstitial];
    if(![LWPurchaseHelper isPurchased]){
        //添加谷歌横幅广告
        [self addGADBanner];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadSearchResult];

    id obj = [[NSUserDefaults standardUserDefaults] objectForKey:@"ReportList"];
    if(!obj){
        self.reportList = @[].mutableCopy;
    }else{
        self.reportList = [obj mutableCopy];
    }
}


#pragma mark - Action

- (IBAction)searchBtnAction:(UIButton *)sender {
    [self.searchTextField resignFirstResponder];
    [self reloadImageSearch];
}


//收藏发生变化
- (void)favoriteChangeNotify:(NSNotification *)notification {
    if([notification.name isEqualToString:@""]){}
    NSDictionary* userInfo = notification.userInfo;
    NSString *objURLString = userInfo[@"objURLString"];
    NSNumber *value = userInfo[@"favoriteValue"];

    self.favoritedDcitionary[objURLString] = value;
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.imageList ? self.imageList.count : 0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LWCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LWCollectionViewCell" forIndexPath:indexPath];
    if (!self.imageList || self.imageList.count <= 0) {
        return [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    }
    LWImageModel *imageModel = self.imageList[(NSUInteger) indexPath.row];
    [cell fillWithImageModel:imageModel searchText:self.searchText favoritedDcit:self.favoritedDcitionary];
    if([self.reportList containsString:imageModel.objURL]){
        cell.imageView.animatedImage = nil;
        cell.imageView.image = [UIImage imageNamed:@"imagehold"];
    }

    //如果滑到了到最后一条记录，则加载下一页
    if (indexPath.row == [self.imageList count] - 1) {
        _startNum = [self.imageList count] + Default_PageSize;
        dispatch_source_merge_data(_source, 1);
    }

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    //LWImageModel *item = self.imageList[(NSUInteger) indexPath.item];
    LWCollectionViewCell *cell = (LWCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];

    if([self.reportList containsString:cell.objURL]){
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Image is been Reporting", nil)];
        [SVProgressHUD dismissWithDelay:0.5];
        return;
    }

    [[UIPasteboard generalPasteboard] setString:cell.objURL];

    cell.imgURLString = cell.thumbnailURL;
    if(![cell.imgURLString hasPrefix:@"http"]){
        cell.imgURLString = cell.middleURL;
    }

    //用webView打开相应的网址
    NSURL *url = [NSURL URLWithString:cell.imgURLString];
    LWWKWebViewController *controller = [LWWKWebViewController wkWebViewControllerWithURL:url];
    controller.isFrom = NSStringFromClass([SearchGIFViewController class]);
    [controller setHidesBottomBarWhenPushed:YES];
    [self.navigationController pushViewController:controller animated:YES];

//    //显示广告
//    [self showAdWithNumRate:30];
//
//    //显示评分按钮
//    if ([LWPurchaseHelper isAfterDate:kAfterDate]) {
//        [LWPurchaseHelper showRating];
//    }
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((Screen_W - Item_Spacing * 4) / 3, (Screen_W - Item_Spacing * 4) / 3);
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    [self reloadImageSearch];
    return NO;
}

- (NSString *)searchText {
    NSString *text = self.searchTextField.text;
    if (![_searchText isEqualToString:text]) {
        self.startNum = 0;
        _searchText = text;
        [self.collectionView setContentOffset:CGPointMake(self.collectionView.contentOffset.x, 0) animated:NO];
    }
    return _searchText;
}


#pragma mark - Networking


#pragma mark - 百度图片搜索

//重新加载
- (void)reloadSearchResult {
    dispatch_source_merge_data(_source, 1);
}

//数据请求(耗时)
- (void)reloadImageSearch {
    //显示loadingView
    self.placehoderView.hidden = NO;
    [self.placehoderView reShowLoading];

    NSString *searchText = [self searchText];

    CGSize imgSize = CGSizeMake((Screen_W - Item_Spacing * 4) / 3, (Screen_W - Item_Spacing * 4) / 3);;
    weakify(self)
    [self loadImageWithSearchText:searchText imgSize:imgSize
                         startNum:_startNum pageSize:Default_PageSize
                     successBlock:^(NSArray<LWImageModel *> *imageList) {
                         strongify(self)
                         if (self.startNum == 0) {
                             self.imageList = [imageList mutableCopy];
                         } else {
                             [self.imageList addObjectsFromArray:imageList];
                         }
                         [self.collectionView reloadData];
                         [self.collectionView.collectionViewLayout invalidateLayout];

                         //隐藏placehoderView
                         if (!self.placehoderView.hidden) {
                             self.placehoderView.hidden = YES;
                         }
                     }
                     failureBlock:^(NSError *error) {
                         strongify(self)
                         [self.placehoderView showFailureView];
                     }];
}


//从网络请求数据
- (void)loadImageWithSearchText:(NSString *)searchText imgSize:(CGSize)imgSize startNum:(NSUInteger)pn pageSize:(NSUInteger)rn
                   successBlock:(void (^)(NSArray<LWImageModel *> *))successBlock
                   failureBlock:(void (^)(NSError *error))failureBlock {

    NSString *defaultWord = [LWHelper isAfterDate:@"2020-09-10"] ? @"表情" : @"flower";
    NSString *word = (!searchText || [searchText isBlank]) ? [defaultWord URLEncode] : [searchText URLEncode];
    NSString *pnStr = [NSString stringWithFormat:@"%lu", pn ?: 0];
    NSString *rnStr = [NSString stringWithFormat:@"%lu", rn ?: 49];
//    NSString *URLString = [NSString stringWithFormat:URLString_POST_Image,width,height, word, pnStr, rnStr];

    NSString *size = @"0"; //尺寸（0全部尺寸 9特大 3大 2中 1小）
    //https://image.baidu.com/search/acjson?tn=resultjson_com&ipn=rj&word=%@&width=%i&height=%i&pn=%@&rn=%@
    NSString *URLString = [NSString stringWithFormat:URLString_POST_Image, word,256,256, pnStr, rnStr];
    NSURL *url = [NSURL URLWithString:URLString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];

    [request setValue:@"http://image.baidu.com/search" forHTTPHeaderField:@"Referer"];
    [request setValue:@"http://app.wodedata.com" forHTTPHeaderField:@"User-Agent"];
    [request setValue:@"http://image.baidu.com" forHTTPHeaderField:@"Origin"];

    weakify(self)
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        strongify(self)
        if (!error) {
            if ([data isKindOfClass:[NSData class]]) {
                //把 NSData 转换成 NSString
                NSString *responseStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                responseStr = [responseStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                Log(@"=====responseStr:%@",responseStr);

                NSData *encodeData = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *jsonDictionary = nil;
                @try {
                    jsonDictionary = [NSJSONSerialization JSONObjectWithData:encodeData options:0 error:nil];
                }
                @catch (NSException *exception) {
                    failureBlock(nil);
                    NSLog(@"Exception occurred: %@, %@", exception, [exception userInfo]);
                }
                NSArray *imgs = jsonDictionary[@"data"];
                NSArray<LWImageModel *> *imageArr = [NSArray yy_modelArrayWithClass:[LWImageModel class] json:[imgs yy_modelToJSONString]];
                dispatch_main_async_safe(^{
                    successBlock(imageArr);     //更新UI
                });

            } else {
                Log(@"=====Error: %@", error);
                failureBlock(error);
            }
        }

    }] resume];
}

/*
#pragma mark - 百度图片搜索

-(void)loadImageWithSearchText:(NSString *)searchText imgSize:(CGSize)imgSize startNum:(NSUInteger)pn pageSize:(NSUInteger)rn
                  successBlock:(void (^)(NSArray<LWImageModel *> *))successBlock
                  failureBlock:(void (^)(NSError *error))failureBlock{

    __block NSString *translation = @"";
    //检查网络
    if (self.networkReachabilityStatus == AFNetworkReachabilityStatusNotReachable) {
        translation = NSLocalizedString(@"Check Network Connection", nil);
    }

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.HTTPAdditionalHeaders = @{
            @"Referer": @"http://image.baidu.com/search",
            @"User-Agent": [LWDataConfig getiOSUserAgent],
            @"Origin":@"http://image.baidu.com"
    };

    AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
    //response序列化，以接收 text/html 类型
    manager.responseSerializer = [AFHTTPResponseSerializer serializer];

//    CGFloat scale = [UIScreen mainScreen].scale;
//    NSString *width = [NSString stringWithFormat:@"%.f",imgSize.width * scale];
//    NSString *height = [NSString stringWithFormat:@"%.f",imgSize.height * scale];
    NSString *word = (!searchText || [searchText isBlank]) ? [@"表情" URLEncode] : [searchText URLEncode];
    NSString *pnStr = [NSString stringWithFormat:@"%lu",pn ?: 0];
    NSString *rnStr = [NSString stringWithFormat:@"%lu",rn ?: 49];
//    NSString *URLString = [NSString stringWithFormat:URLString_POST_Image,width,height, word, pnStr, rnStr];

    NSString *size = @"0"; //尺寸（0全部尺寸 9特大 3大 2中 1小）
    NSString *URLString = [NSString stringWithFormat:URLString_POST_Image,word,100,100,pnStr,rnStr];
    NSURL *URL = [NSURL URLWithString:URLString];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    [request setHTTPMethod:@"GET"];

    NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:request completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
        if (error) {
            LWLog(@"=====Error: %@", error);
            failureBlock(error);
        } else {
            if ([responseObject isKindOfClass:[NSData class]]) {
                //把 NSData 转换成 NSString
                NSString *responseStr = [[NSString alloc] initWithData:responseObject encoding:NSUTF8StringEncoding];
                responseStr = [responseStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//                Log(@"=====responseStr:%@",responseStr);

                NSData *encodeData = [responseStr dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *data=nil;
                @try {
                    data = [NSJSONSerialization JSONObjectWithData:encodeData options:0 error:nil];
                }
                @catch (NSException *exception) {
                    failureBlock(nil);
                    Log(@"Exception occurred: %@, %@", exception, [exception userInfo]);
                }
                NSArray *imgs = data[@"data"];
                NSArray<LWImageModel *> *imageArr = [NSArray yy_modelArrayWithClass:[LWImageModel class] json:[imgs yy_modelToJSONString] ];
                dispatch_main_async_safe(^{
                    successBlock(imageArr);     //更新UI
                });
            }
        }
    }];
    [dataTask resume];

}
*/


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

#pragma mark - Google Ads

//创建GADInterstitial，谷歌广告
- (GADInterstitial *)createAndLoadInterstitial {
    GADInterstitial *interstitial = [[GADInterstitial alloc] initWithAdUnitID:@"ca-app-pub-8760692904992206/1789995794"];
    interstitial.delegate = self;
    [interstitial loadRequest:[GADRequest request]];
    return interstitial;
}

//展示广告
- (BOOL)showAdWithNumRate:(NSUInteger) numRate {
    NSString *key = [NSString stringWithFormat:@"%@_InterstitialAd_Counter", NSStringFromClass(self.class)];
    NSInteger toolOpenCount = [[NSUserDefaults standardUserDefaults] integerForKey:key];
    if (self.interstitial.isReady && toolOpenCount >= numRate && ![LWPurchaseHelper isPurchased]) {  //判断是否弹出广告
        [self.interstitial presentFromRootViewController:self];
        [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:key];
        return YES;

    } else {
        [[NSUserDefaults standardUserDefaults] setInteger:toolOpenCount + 1 forKey:key];
        [[NSUserDefaults standardUserDefaults] synchronize];
        if(self.afterAdShowBlock){
            self.afterAdShowBlock();
            self.afterAdShowBlock=nil;
        }
        return NO;
    }
}

//创建一个新的 GADInterstitial 对象
- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitial = [self createAndLoadInterstitial];
    //广告关闭后，继续做该做的事
    if(self.afterAdShowBlock){
        self.afterAdShowBlock();
        self.afterAdShowBlock=nil;
    }
}

@end


@implementation LWCollectionViewCell {
    UIImage *_defaultImage;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor whiteColor];

    self.layer.cornerRadius = 4;
    self.layer.borderWidth = 0.5;
    self.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.layer.shadowRadius = 1;
    self.layer.shadowOffset = CGSizeMake(1, 1);
    self.layer.shadowOpacity = 0.25;

    _defaultImage = [UIImage imageNamed:@"imagehold"];
}

- (IBAction)favoriteBtnTouchUpInside:(UIButton *)btn {
    if(btn.selected){
        [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Been Favorited", nil)];
        [SVProgressHUD dismissWithDelay:0.5];
        return;
    }
    NSData *data = self.imageView.animatedImage.data;
    if (!data) {
        data = UIImagePNGRepresentation(self.imageView.image);
    }

    SearchGIFViewController *controller = [self superViewWithClass:[SearchGIFViewController class]];
    LWPickerPanel *pickerPanel = [LWPickerPanel showPickerPanelInView:controller.view];

    __weak typeof(self) weakSelf = self;
    pickerPanel.faveritaBlock = ^(NSInteger categoryId, NSString *categoryName) {
        __strong typeof(weakSelf) strongSelf = weakSelf;

        NSString *imgName = [weakSelf.objURL md5];

        NSNumber *value = controller.favoritedDcitionary[self.objURL];
        BOOL isContains = [value boolValue];
        if(value == nil){
            isContains = [strongSelf checkFavoritesContainsURLString:strongSelf.objURL];
            controller.favoritedDcitionary[self.objURL] = @(isContains);
        }

        if (isContains) {
            controller.favoritedDcitionary[self.objURL] = @(YES);
            btn.selected = YES;
            [SVProgressHUD showInfoWithStatus:NSLocalizedString(@"Exist The Image", nil)];
            [SVProgressHUD dismissWithDelay:1.5];
            return;
        }

        [SVProgressHUD showWithStatus:@"Loading..."];

        //保存data到文件中
        NSString *docPath = [NSString stringWithFormat:@"%@/%@", AnimojiDirectory, categoryName];
        NSString *file_url = [docPath stringByAppendingPathComponent:imgName];

        //如果不存在文件夹，则创建文件夹
        NSString *imgDirectoryPath = [LWHelper createIfNotExistsDirectory:docPath];
        NSString *filePath = [imgDirectoryPath stringByAppendingPathComponent:imgName];
        Log(@"============filePath:%@", filePath);

        //保存到文件
        if (![FCFileManager existsItemAtPath:filePath]) {
            NSError *error;
            [data writeToFile:filePath options:NSDataWritingWithoutOverwriting error:&error];
            if (error) {
                Log(@"====writeToFile:%@ , %@", filePath, error.localizedFailureReason);
                [SVProgressHUD showErrorWithStatus:@"Save Image File Faild"];
                [SVProgressHUD dismissWithDelay:1.5];
                return;
            }
        }

        //保存图片表情到相应的分类中
        BOOL isSuccess = [[LWSymbolService symbolService] insertSymbolWithCategoryId:(NSUInteger) categoryId title:nil text:imgName file_url:file_url http_url:weakSelf.objURL];
        if(isSuccess){
            [SVProgressHUD showSuccessWithStatus:NSLocalizedString(@"Operate Success", nil)];
            [SVProgressHUD dismissWithDelay:0.5];
        }else{
            [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Operate Faild", nil)];
            [SVProgressHUD dismissWithDelay:1.5];
        }

        weakSelf.faveritaBtn.selected = YES;
        controller.favoritedDcitionary[self.objURL] = @(YES);
    };
}

- (IBAction)shareBtnTouchUpInside:(UIButton *)sender {
    SearchGIFViewController *controller = [self superViewWithClass:[SearchGIFViewController class]];

    NSData *data = self.imageView.animatedImage.data;
    if (!data) {
        data = UIImagePNGRepresentation(self.imageView.image);
    }

    OSMessage *msg = [self getShareMessage];

    LWWechatActivity *wechatActivity = [[LWWechatActivity alloc] initWithiphoneImage:[UIImage imageNamed:@"Wechat50"] ipadImage:[UIImage imageNamed:@"Wechat53"]];
    wechatActivity.msg = msg;
    wechatActivity.fromView = controller.view;

    LWQQActivity *qqActivity = [[LWQQActivity alloc] initWithiphoneImage:[UIImage imageNamed:@"QQ50"] ipadImage:[UIImage imageNamed:@"QQ53"]];
    qqActivity.msg = msg;
    qqActivity.fromView = controller.view;

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[data] applicationActivities:@[wechatActivity,qqActivity]];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    [controller presentViewController:activityVC animated:TRUE completion:nil];
}

- (OSMessage *)getShareMessage {
    //构建消息
    OSMessage *msg = [[OSMessage alloc] init];
    msg.title = NSLocalizedString(@"Share Image", nil);
    msg.desc = NSLocalizedString(@"Share Image", nil);

    UIImage *thumbnailImg = [self.imageView.image scaleToWXThumbnailSizeKeepAspect:CGSizeMake(200, 200)];
    NSData *data = self.imageView.animatedImage.data;
    if (data) {
        SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
        if (imageFormat == SDImageFormatGIF) {
            msg.messageType = Msg_ImageGif;
            thumbnailImg = self.imageView.animatedImage.posterImage;
            NSData *thumbnailData = [thumbnailImg compressWithInMaxFileSize:32 * 1024];
            msg.thumbnail = thumbnailData;
        } else {
            msg.messageType = Msg_Image;

            NSData *thumbnailData = [thumbnailImg compressWithInMaxFileSize:32 * 1024];
            msg.thumbnail = thumbnailData;
        }

    } else {
        msg.messageType = Msg_Image;
        NSData *thumbnailData = [thumbnailImg compressWithInMaxFileSize:32 * 1024];
        msg.thumbnail = thumbnailData;
        data = UIImagePNGRepresentation(self.imageView.image);
    }
    msg.image = data;
    msg.file = data;
    return msg;
}


- (IBAction)linkBtnTouchUpInside:(UIButton *)sender {
    [App_Delegate setTabBarSelectedIndex:0];
    [self performSelector:@selector(linkGenGIFVC) withObject:nil afterDelay:0.3];
}

-(IBAction)wechatBtnTouchUpInside:(UIButton *)sender {
    SearchGIFViewController *controller = [self superViewWithClass:[SearchGIFViewController class]];

    __weak typeof(self) weakSelf = self;
    controller.afterAdShowBlock = ^{
        OSMessage *msg = [weakSelf getShareMessage];    //获取分享的消息数据
        [OpenShare shareToWeixinSession:msg fromView:controller.view Success:^(OSMessage *message){
            Log(@"分享到微信成功");
        } Fail:^(OSMessage *message,NSError *error){
            Log(@"分享到微信失败");
        }];
    };

    //显示广告
    [controller showAdWithNumRate:3];

    //显示评分按钮
    if ([LWPurchaseHelper isAfterDate:kAfterDate]) {
        [LWPurchaseHelper showRating];
    }
}

- (void)linkGenGIFVC {
    NSData *gifData = self.imageView.animatedImage.data;
    UIImage *image = self.imageView.image;
    UINavigationController *navVC = (UINavigationController *) App_Delegate.tabBarController.viewControllers.firstObject;
    GenGIFViewController *vc = navVC.viewControllers.firstObject;
    if(!vc){
        return;
    }

    vc.liveView.hidden = YES;
    vc.videoPlayerView.hidden = YES;

    if(gifData){
        [vc updateSelectedMode:GIFMode];
        vc.exportGIFImageData = gifData;
        vc.imagePreview.animatedImage = [FLAnimatedImage animatedImageWithGIFData:gifData];

    }else if(image){
        [vc updateSelectedMode:StaticPhotosMode];
        vc.exportImageFrames = @[image];
        [vc setImages:vc.exportImageFrames toImageView:vc.imagePreview];
    }
}

- (void)fillWithImageModel:(LWImageModel *)model searchText:(NSString *)text favoritedDcit:(NSMutableDictionary *)favoritedDcit {
    self.thumbnailURL = model.thumbURL;
    self.middleURL = model.middleURL;
    self.objURL = model.objURL;
    self.fromURL = model.fromURL;
    
    self.imgURLString = self.thumbnailURL;
    if([self.objURL hasPrefix:@"http"]){
        self.imgURLString = self.objURL;
    }else if([self.middleURL hasPrefix:@"http"]){
        self.imgURLString = self.middleURL;
    }

    NSURL *imageURL = nil;
    if([self.imgURLString hasPrefix:@"http"]){
        imageURL = [[NSURL alloc] initWithString:self.imgURLString];
    }

    if(!imageURL){
        [self updateFavoriteBtnWithDict:favoritedDcit];    //更新favoriteBtn状态
        return;
    }

//    NSString *urlStr = [[NSBundle mainBundle]pathForResource:@"aaa" ofType:@"gif"];
//    NSURL *url = [NSURL fileURLWithPath:urlStr];
//    Log(@"===gifURL:%@",imageURL.absoluteString);

    //
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:imageURL];
    NSData *iData = [[SDImageCache sharedImageCache] diskImageDataBySearchingAllPathsForKey:key];

    if (iData) {    //从缓存中获取
        SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:iData];
        if (imageFormat != SDImageFormatGIF) {
            UIImage *img = [UIImage imageWithData:iData];
            self.imageView.image = img ?: _defaultImage;

            [self updateFavoriteBtnWithDict:favoritedDcit];    //更新favoriteBtn状态
            return;
        }
        FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:iData];
        self.imageView.animatedImage = animatedImage;

    } else {    //请求网络
        self.imageView.image = _defaultImage;
        weakify(self)
        if (self.downloadToken) {
            [[SDWebImageDownloader sharedDownloader] cancel:self.downloadToken];
            self.downloadToken = nil;
        }
        self.downloadToken = [self sdDownloadWithURL:imageURL completedBlock:^(UIImage *image, NSData *data) {
            strongify(self)
            if (!data) {
                self.imageView.image = _defaultImage;
                return;
            }

            //NSURL *imgURL = [[NSURL alloc] initWithString:self.objURL];
            NSString *imageKey = [[SDWebImageManager sharedManager] cacheKeyForURL:imageURL];

            SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
            if (imageFormat != SDImageFormatGIF) {
                [[SDImageCache sharedImageCache] storeImage:image forKey:imageKey toDisk:YES completion:^{
                    UIImage *img = [[SDImageCache sharedImageCache] imageFromDiskCacheForKey:imageKey];
                    self.imageView.image = img ?: _defaultImage;
                }];
                return;
            }

            [[SDImageCache sharedImageCache] storeImageDataToDisk:data forKey:imageKey];    //保存GIF图片数据


            NSData *imgData = [[SDImageCache sharedImageCache] diskImageDataBySearchingAllPathsForKey:imageKey];
            if (imgData) {
                FLAnimatedImage *animatedImage = [FLAnimatedImage animatedImageWithGIFData:imgData];
                self.imageView.animatedImage = animatedImage;
            } else {
                self.imageView.image = _defaultImage;
            }
        }];
    }
    //[self.imageView sd_setImageWithURL:imageURL placeholderImage:_defaultImage];
    [self updateFavoriteBtnWithDict:favoritedDcit];    //更新favoriteBtn状态
}

//更新favoriteBtn状态
- (void)updateFavoriteBtnWithDict:(NSMutableDictionary *)favoritedDcit {
    //判断是否已添加收藏
    if(![self.imgURLString hasPrefix:@"http"]){
        return;
    }
    NSNumber *value = favoritedDcit[self.imgURLString];
    BOOL isContains = [value boolValue];
    if (value == nil) {
        isContains = [self checkFavoritesContainsURLString:self.imgURLString];    //如果数据库中存在
        favoritedDcit[self.imgURLString] = @(isContains);
    }
    if(isContains){
        self.faveritaBtn.selected = YES;
    }
    self.faveritaBtn.selected = isContains;
}

//检查数据库中是否包含 imgName
- (BOOL)checkFavoritesContainsURLString:(NSString *)urlstring {
    BOOL isExsit = [[LWSymbolService symbolService] exsitSymbolWithHttpURL:urlstring];
    return isExsit;
}

//SDWebImage库下载图片
- (SDWebImageDownloadToken *)sdDownloadWithURL:(NSURL *)imageURL completedBlock:(void (^)(UIImage *image, NSData *data))completedBlock {
    if (!imageURL) {
        return nil;
    }
    SDWebImageDownloader *manager = [SDWebImageDownloader sharedDownloader];
    [manager setValue:[LWHelper getiOSUserAgent] forHTTPHeaderField:@"User-Agent"];
    SDWebImageDownloadToken *downloadToken = [manager
            downloadImageWithURL:imageURL options:SDWebImageDownloaderHighPriority | SDWebImageDownloaderUseNSURLCache
                        progress:nil completed:^(UIImage *image, NSData *data, NSError *error, BOOL finished) {
                dispatch_main_async_safe(^{
                    if (error) {
                        Log(@"=====error:%@ \n %@", error.localizedFailureReason, error.localizedDescription);
                        return;
                    }
                });

                if (!finished) {
                    return;
                }
                //清除内存缓存
                [[SDImageCache sharedImageCache] setValue:nil forKey:@"memCache"];
                //处理下载的图片
                dispatch_main_async_safe(^{
                    completedBlock(image, data);
                });
            }];
    return downloadToken;
}

@end


@implementation LWPlacehoderView

- (void)awakeFromNib {
    [super awakeFromNib];
    self.activityIndicatorView.layer.cornerRadius = 4;

    self.imageView.hidden = YES;
    self.settingsBtn.hidden = YES;
    self.refreshBtn.hidden = YES;
}


-(IBAction)settingsBtnTouchUpInside:(UIButton *)btn {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
}

-(IBAction)refreshBtnTouchUpInside:(UIButton *)btn {
    SearchGIFViewController *vc = [self superViewWithClass:[SearchGIFViewController class]];
    [vc reloadSearchResult];
}

- (void)setHidden:(BOOL)hidden {
    [super setHidden:hidden];

    self.activityIndicatorView.hidden = hidden;
}


//显示加载失败视图
- (void)showFailureView {
    [self.activityIndicatorView stopAnimating];
    self.activityIndicatorView.hidden = YES;
    self.settingsBtn.hidden = NO;
    self.refreshBtn.hidden = NO;
    self.imageView.hidden = NO;
}

- (void)reShowLoading {
    self.imageView.hidden = YES;
    self.settingsBtn.hidden = YES;
    self.refreshBtn.hidden = YES;
    [self.activityIndicatorView startAnimating];
}


@end
