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


#define Item_Spacing 6
#define Default_PageSize 100
//图片搜索
#define URLString_POST_Image @"http://image.baidu.com/search/avatarjson?tn=resultjsonavatarnew&ie=utf-8&z=%@&ic=0&s=0&face=0&st=-1&lm=-1&word=%@&pn=%@&rn=%@"


@interface SearchGIFViewController () <UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property(nonatomic, strong) NSMutableArray <LWImageModel *> *imageList;
@property(nonatomic, assign) NSUInteger startNum;

@end

@implementation SearchGIFViewController {
    NSUInteger _startNum;
    NSString *_searchText;
    dispatch_source_t _source;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchBtn.layer.cornerRadius = 5;

    // Do any additional setup after loading the view, typically from a nib.
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"Cell"];
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;


    //网络请求图片User-Agent要设置为浏览器的
    SDWebImageDownloader *manager = [SDWebImageDownloader sharedDownloader];
    [manager setValue:[LWHelper getiOSUserAgent] forHTTPHeaderField:@"User-Agent"];

    //构建分派源
    _source = dispatch_source_create(DISPATCH_SOURCE_TYPE_DATA_ADD, 0, 0, dispatch_get_main_queue());
//    __weak typeof(self) weakSelf = self;
    dispatch_source_set_event_handler(_source, ^{
        [self reloadImageSearch];
    });
    dispatch_resume(_source);

    [self reloadSearchResult];  //发送发派源Merge信息，调用网络请求
}

#pragma mark - Action

- (IBAction)searchBtnAction:(UIButton *)sender {
    [self reloadImageSearch];
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
    LWImageModel *imageModel = self.imageList[indexPath.row];
    [cell fillWithImageModel:imageModel searchText:self.searchText];

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
    LWImageModel *item = self.imageList[(NSUInteger) indexPath.item];

    LWCollectionViewCell *cell = (LWCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
    [[UIPasteboard generalPasteboard] setString:cell.objURL];

    //todo:用webView打开相应的网址

}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((Screen_W - Item_Spacing * 4) / 3, (Screen_W - Item_Spacing * 4) / 3);
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

    NSString *word = (!searchText || [searchText isBlank]) ? [@"表情" URLEncode] : [searchText URLEncode];
    NSString *pnStr = [NSString stringWithFormat:@"%lu", pn ?: 0];
    NSString *rnStr = [NSString stringWithFormat:@"%lu", rn ?: 49];
//    NSString *URLString = [NSString stringWithFormat:URLString_POST_Image,width,height, word, pnStr, rnStr];

    NSString *size = @"0"; //尺寸（0全部尺寸 9特大 3大 2中 1小）
    NSString *URLString = [NSString stringWithFormat:URLString_POST_Image, size, word, pnStr, rnStr];
    NSURL *url = [NSURL URLWithString:URLString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60.0];
    [request setHTTPMethod:@"POST"];

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
                NSArray *imgs = jsonDictionary[@"imgs"];
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


@end


@implementation LWCollectionViewCell {
    UIImage *_defaultImage;
}

- (void)awakeFromNib {
    [super awakeFromNib];

    self.imageView.layer.borderWidth = 1;
    self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.imageView.layer.cornerRadius = 2;

}

- (IBAction)favoriteBtnTouchUpInside:(UIButton *)btn {
    NSData *data = self.imageView.animatedImage.data;
    if (!data) {
        data = UIImagePNGRepresentation(self.imageView.image);
    }

    SearchGIFViewController *controller = [self superViewWithClass:[SearchGIFViewController class]];
    LWPickerPanel *pickerPanel = [LWPickerPanel showPickerPanelInView:controller.view];

    __weak typeof(self) weakSelf = self;
    pickerPanel.faveritaBlock = ^(NSInteger categoryId, NSString *categoryName) {

        NSString *imgName = [weakSelf.objURL md5];

        BOOL isContains = [weakSelf checkGriphicContainsImgName:imgName];
        if (isContains) {
            return;
        }

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
                return;
            }
        }


        //保存图片表情到相应的分类中
        [[LWSymbolService symbolService] insertSymbolWithCategoryId:(NSUInteger) categoryId title:nil text:imgName file_url:file_url http_url:nil];

        weakSelf.faveritaBtn.selected = YES;
    };
}

- (IBAction)shareBtnTouchUpInside:(UIButton *)sender {
    NSData *data = self.imageView.animatedImage.data;
    if (!data) {
        data = UIImagePNGRepresentation(self.imageView.image);
    }

    SearchGIFViewController *controller = [self superViewWithClass:[SearchGIFViewController class]];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[data] applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    [controller presentViewController:activityVC animated:TRUE completion:nil];
}

- (IBAction)linkBtnTouchUpInside:(UIButton *)sender {
    [App_Delegate setTabBarSelectedIndex:0];
    [self performSelector:@selector(linkGenGIFVC) withObject:nil afterDelay:0.3];
}

- (void)linkGenGIFVC {
    NSData *gifData = self.imageView.animatedImage.data;
    UIImage *image = self.imageView.image;
    UINavigationController *navVC = (UINavigationController *) App_Delegate.tabBarController.viewControllers.firstObject;
    GenGIFViewController *vc = navVC.viewControllers.firstObject;
    if(!vc){
        return;
    }
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

- (void)fillWithImageModel:(LWImageModel *)model searchText:(NSString *)text {
    self.thumbnailURL = model.thumbURL;
    self.objURL = model.objURL;
    self.fromURL = model.fromURL;
    NSURL *imageURL = [[NSURL alloc] initWithString:self.objURL];

//    NSString *urlStr = [[NSBundle mainBundle]pathForResource:@"aaa" ofType:@"gif"];
//    NSURL *url = [NSURL fileURLWithPath:urlStr];
//    Log(@"===gifURL:%@",imageURL.absoluteString);

    //此处要优化gif文件大小
    NSString *key = [[SDWebImageManager sharedManager] cacheKeyForURL:imageURL];
    NSData *iData = [[SDImageCache sharedImageCache] diskImageDataBySearchingAllPathsForKey:key];

    if (iData) {    //从缓存中获取
        SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:iData];
        if (imageFormat != SDImageFormatGIF) {
            UIImage *img = [UIImage imageWithData:iData];
            self.imageView.image = img ?: _defaultImage;
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

            NSURL *imgURL = [[NSURL alloc] initWithString:self.objURL];
            NSString *imageKey = [[SDWebImageManager sharedManager] cacheKeyForURL:imgURL];

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

    //判断_graphicDictArr 中是否存在 imgName
    NSString *imgName = [self.objURL md5];
    BOOL isContains = [self checkGriphicContainsImgName:imgName];
    self.faveritaBtn.selected = isContains;
}

//检查数据中是否包含 imgName
- (BOOL)checkGriphicContainsImgName:(NSString *)imgName {
//    BOOL exsit = [LWDataConfig  exsitGraphicWithImgName:imgName];
//    return exsit;
    return NO;
}

//SDWebImage库下载图片
- (SDWebImageDownloadToken *)sdDownloadWithURL:(NSURL *)imageURL completedBlock:(void (^)(UIImage *image, NSData *data))completedBlock {
    if (!imageURL) {
        return nil;
    }
    SDWebImageDownloader *manager = [SDWebImageDownloader sharedDownloader];
    [manager setValue:[LWHelper getiOSUserAgent] forHTTPHeaderField:@"User-Agent"];
    SDWebImageDownloadToken *downloadToken = [manager downloadImageWithURL:imageURL options:SDWebImageDownloaderHighPriority | SDWebImageDownloaderUseNSURLCache
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


//显示加载失败视图
- (void)showFailureView {
//    self.loadingView.hidden = YES;
//    self.settingBtn.hidden = NO;
//    self.reloadBtn.hidden = NO;
//    self.msgTip.hidden = NO;
}

- (void)reShowLoading {
//    self.msgTip.hidden = YES;
//    self.settingBtn.hidden = YES;
//    self.reloadBtn.hidden = YES;
}


@end
