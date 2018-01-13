//
// Created by Luo Wei on 2018/1/11.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWMyGIFCollectionView.h"
#import "FLAnimatedImageView.h"
#import "View+MASAdditions.h"
#import "LWSymbolService.h"
#import "LWHelper.h"
#import "NSData+ImageContentType.h"
#import "FLAnimatedImage.h"
#import "LWMyGIFViewController.h"
#import "UIView+extensions.h"
#import "AppDelegate.h"
#import "AppDefines.h"
#import "GenGIFViewController.h"
#import "UIColor+HexValue.h"

#define GIFItem_Spacing 6

@implementation LWMyGIFCollectionView {

}

- (instancetype)initWithFrame:(CGRect)frame category:(LWCategory *)category {
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumLineSpacing = GIFItem_Spacing;
    layout.minimumInteritemSpacing = GIFItem_Spacing;
    layout.scrollDirection = UICollectionViewScrollDirectionVertical;
    
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        self.backgroundColor = [UIColor colorWithHexString:@"#F6F6F6"];
        self.contentInset = UIEdgeInsetsMake(GIFItem_Spacing, GIFItem_Spacing, GIFItem_Spacing, GIFItem_Spacing);
        [self registerClass:[LWMyGIFCollectionCell class] forCellWithReuseIdentifier:@"Cell"];
        self.dataSource = self;
        self.delegate = self;
        self.category = category;
        
        self.placeHoldView = [[LWCollectionPlaceHoldView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];
        [self addSubview:self.placeHoldView];
        self.placeHoldView.hidden = YES;
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.placeHoldView.frame = self.bounds;
}


#pragma mark - UICollectionViewDataSource

//刷新数据
-(void)reloadWithCategory:(LWCategory *)category {
    if(category){
        self.category = category;
    }

    NSArray <LWSymbol *>*list = [[LWSymbolService symbolService] symbolsWithCategoryId:self.category._id];
    self.dataList = list;

    [self reloadData];
}

- (void)reloadData {
    if(!self.dataList || self.dataList.count < 1){
        self.placeHoldView.hidden = NO;
    }else{
        self.placeHoldView.hidden = YES;
    }
    [super reloadData];
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.dataList.count;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LWMyGIFCollectionCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"Cell" forIndexPath:indexPath];
    LWSymbol *item = self.dataList[(NSUInteger) indexPath.row];
    [cell fillWithData:item];
    return cell;
}



#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    LWSymbol *item = self.dataList[(NSUInteger) indexPath.row];

    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:item.file_url];

    //从指定路径读取图片
    NSData *imageData = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        imageData = [NSData dataWithContentsOfFile:filePath];
    }

    LWMyGIFViewController *controller = [self superViewWithClass:[LWMyGIFViewController class]];
    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[imageData] applicationActivities:nil];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    [controller presentViewController:activityVC animated:TRUE completion:nil];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((Screen_W - GIFItem_Spacing * 4) / 3, (Screen_W - GIFItem_Spacing * 4) / 3);
}

@end


@implementation LWMyGIFCollectionCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.layer.cornerRadius = 4;
        self.layer.borderWidth = 0.5;
        self.layer.borderColor = [UIColor lightGrayColor].CGColor;
        self.layer.shadowRadius = 2;
        self.layer.shadowOffset = CGSizeMake(1, 1);
        self.layer.shadowOpacity = 0.25;

        self.imageView = [[FLAnimatedImageView alloc] initWithFrame:frame];
        [self addSubview:self.imageView];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;

        [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self).with.insets(UIEdgeInsetsMake(0, 0, 0, 0));
        }];
        
//        self.shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
//        [self.shareBtn setImage:[UIImage imageNamed:@"share"] forState:UIControlStateNormal];
//        [self.shareBtn addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
//        [self addSubview:self.shareBtn];
//        [self.shareBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.right.bottom.equalTo(self);
//            make.width.height.mas_equalTo(30);
//        }];
        
        self.linkBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.linkBtn setImage:[UIImage imageNamed:@"search_link"] forState:UIControlStateNormal];
        [self.linkBtn addTarget:self action:@selector(linkAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.linkBtn];
        [self.linkBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.bottom.equalTo(self);
            make.width.height.mas_equalTo(30);
        }];
    }

    return self;
}

//- (void)shareAction:(UIButton *)shareBtn {
//    NSData *data = self.imageView.animatedImage.data;
//    if (!data) {
//        data = UIImagePNGRepresentation(self.imageView.image);
//    }
//
//    LWMyGIFViewController *controller = [self superViewWithClass:[LWMyGIFViewController class]];
//    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[data] applicationActivities:nil];
//    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
//    [controller presentViewController:activityVC animated:TRUE completion:nil];
//}

- (void)linkAction:(UIButton *)linkBtn {
    [App_Delegate setTabBarSelectedIndex:0];
    [self performSelector:@selector(linkGenGIFVC) withObject:nil afterDelay:0.3];
}


- (void)fillWithData:(LWSymbol *)symbol {
    self.symbol = symbol;
    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:symbol.file_url];

    //从指定路径读取图片
    NSData *imageData = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        imageData = [NSData dataWithContentsOfFile:filePath];
    }

    SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:imageData];
    if(imageFormat == SDImageFormatGIF){
        [self.imageView setAnimatedImage:[FLAnimatedImage animatedImageWithGIFData:imageData]];
    }else{
        [self.imageView setImage:[UIImage imageWithData:imageData]];
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


@end


@implementation LWCollectionPlaceHoldView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        [self addSubview:self.titleLabel];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:30];
        self.titleLabel.text = NSLocalizedString(@"No Data", nil);
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
        }];

        self.refreshBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:self.refreshBtn];
        [self.refreshBtn setTitle:NSLocalizedString(@"Refresh", nil) forState:UIControlStateNormal];
        [self.refreshBtn setTitleColor:[UIColor colorWithHexString:ButtonTextColor] forState:UIControlStateNormal];
        [self.refreshBtn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [self.refreshBtn addTarget:self action:@selector(refreshAction) forControlEvents:UIControlEventTouchUpInside];
        self.refreshBtn.layer.borderWidth = 0.5;
        self.refreshBtn.layer.borderColor = [UIColor colorWithHexString:ButtonTextColor].CGColor;
        self.refreshBtn.layer.cornerRadius = 4;
        [self.refreshBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.centerX.equalTo(self.titleLabel);
            make.top.equalTo(self.titleLabel.mas_bottom).offset(20);
            make.width.mas_greaterThanOrEqualTo(60);
            make.height.mas_equalTo(36);
        }];
    }

    return self;
}

- (void)refreshAction {
    LWMyGIFCollectionView *collectionView = [self superViewWithClass:[LWMyGIFCollectionView class]];
    [collectionView reloadData];
}


@end


