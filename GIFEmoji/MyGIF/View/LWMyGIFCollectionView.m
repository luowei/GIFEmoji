//
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
#import "FCFileManager.h"
#import "LWLivePhotoView.h"
#import "LWAVPlayerView.h"
#import "OpenShare.h"
#import "UIImage+Extension.h"
#import "OpenShareHeader.h"
#import "LWUIActivity.h"
#import "SVProgressHUD.h"
#import "LWPurchaseHelper.h"
#import "LWPurchaseViewController.h"

#define GIFItem_Spacing 6

//小x按钮的宽度与高度
#define Cell_DeleteBtn_W 30.0
#define Cell_DeleteBtn_H 30.0

@implementation LWMyGIFCollectionView {
    UILongPressGestureRecognizer *_longPressGestureRecognizer;
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

        //给CollectionView添加长按手势
        [self addLongPressGestureRecognizers];
    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.superview.frame.size.height);
    self.placeHoldView.frame = self.bounds;
}

- (void)dealloc {
    [self removeLongPressGestureRecognizers];
}

#pragma mark - 长按手势处理

//添加longPress手势
- (void)addLongPressGestureRecognizers {
    self.userInteractionEnabled = YES;

    _longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressGestureRecognizerTriggerd:)];
    _longPressGestureRecognizer.cancelsTouchesInView = NO;
    _longPressGestureRecognizer.minimumPressDuration = 0.8;
    //_longPressGestureRecognizer.delegate = self;

    for (UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
            [gestureRecognizer requireGestureRecognizerToFail:_longPressGestureRecognizer];
        }
    }

    [self addGestureRecognizer:_longPressGestureRecognizer];
}

//移除longPress手势
- (void)removeLongPressGestureRecognizers {
    if (_longPressGestureRecognizer) {
        if (_longPressGestureRecognizer.view) {
            [_longPressGestureRecognizer.view removeGestureRecognizer:_longPressGestureRecognizer];
        }
        _longPressGestureRecognizer = nil;
    }
}

//长按手势响应处理
- (void)longPressGestureRecognizerTriggerd:(UILongPressGestureRecognizer *)longPress {

    //LWSkinGridView *gridView = (LWSkinGridView *) longPress.view;
    switch (longPress.state) {
        case UIGestureRecognizerStateBegan: {
            //如果不是处于编辑状态，设置成编辑状态
            if (!self.editing) {
                self.editing = YES;
            }
            //[self.collectionViewLayout invalidateLayout];
            [self reloadData];
        }
            break;
        default:
            break;
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    LWMyGIFCollectionCell *cell = (LWMyGIFCollectionCell *) [self cellForItemAtIndexPath:[self indexPathForItemAtPoint:point]];

    if (self.editing) {
        if (!cell) {
            self.editing = NO;
            [self reloadData];
            return [super hitTest:point withEvent:event];
        }

        CGPoint tPoint = [self convertPoint:point toView:cell];
        CGRect cancelFrame = UIEdgeInsetsInsetRect(cell.bounds, UIEdgeInsetsMake(30, 30, 30, 30));
//        Log(@"=====tPoint:(%f,%f) , cancelFrame:(%f,%f,%f,%f)",tPoint.x,tPoint.y,
//                cancelFrame.origin.x,cancelFrame.origin.y,cancelFrame.size.width,cancelFrame.size.height);
        if (CGRectContainsPoint(cancelFrame, tPoint)) {
            self.editing = NO;
            [self reloadData];
        }
    }
    return [super hitTest:point withEvent:event];
}

//设置编辑状态
- (void)setEditing:(BOOL)editing {
    _editing = editing;
    for (UICollectionViewCell *cel in self.visibleCells) {
        LWMyGIFCollectionCell *cell = (LWMyGIFCollectionCell *) cel;
        cell.editing = editing;
    }
}


#pragma mark - UICollectionViewDataSource

//刷新数据
- (void)reloadWithCategory:(LWCategory *)category {
    if (category) {
        self.category = category;
    }
    [self reloadData];
}

- (void)reloadData {
    self.dataList = [[LWSymbolService symbolService] symbolsWithCategoryId:self.category._id];

    if (!self.dataList || self.dataList.count < 1) {
        self.placeHoldView.hidden = NO;
    } else {
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

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return !self.editing;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    LWMyGIFViewController *controller = [self superViewWithClass:[LWMyGIFViewController class]];
    LWMyGIFCollectionCell *cell = (LWMyGIFCollectionCell *) [collectionView cellForItemAtIndexPath:indexPath];

    LWSymbol *item = self.dataList[(NSUInteger) indexPath.row];

    NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *filePath = [documentsDirectory stringByAppendingPathComponent:item.file_url];

    //从指定路径读取图片
    NSData *imageData = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath]) {
        imageData = [NSData dataWithContentsOfFile:filePath];
    }

    if(!imageData){
        [SVProgressHUD showErrorWithStatus:NSLocalizedString(@"Data Empty", nil)];
        [SVProgressHUD dismissWithDelay:0.5];
        return;
    }

    OSMessage *msg = [self getShareMessageWithCell:cell];

    LWWechatActivity *wechatActivity = [[LWWechatActivity alloc] initWithiphoneImage:[UIImage imageNamed:@"Wechat50"] ipadImage:[UIImage imageNamed:@"Wechat53"]];
    wechatActivity.msg = msg;
    wechatActivity.fromView = controller.view;

    LWQQActivity *qqActivity = [[LWQQActivity alloc] initWithiphoneImage:[UIImage imageNamed:@"QQ50"] ipadImage:[UIImage imageNamed:@"QQ53"]];
    qqActivity.msg = msg;
    qqActivity.fromView = controller.view;

    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[imageData] applicationActivities:@[wechatActivity, qqActivity]];
    activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];
    if ([activityVC respondsToSelector:@selector(popoverPresentationController)]) {
        if(!activityVC.popoverPresentationController.sourceView){
            activityVC.popoverPresentationController.sourceView = controller.view;
            activityVC.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionRight | UIPopoverArrowDirectionUp;
        }
    }
    [controller presentViewController:activityVC animated:TRUE completion:nil];
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake((Screen_W - GIFItem_Spacing * 4) / 3, (Screen_W - GIFItem_Spacing * 4) / 3);
}

- (OSMessage *)getShareMessageWithCell:(LWMyGIFCollectionCell *)cell {
    //构建消息
    OSMessage *msg = [[OSMessage alloc] init];
    msg.title = NSLocalizedString(@"Share Image", nil);
    msg.desc = NSLocalizedString(@"Share Image", nil);

    UIImage *thumbnailImg = [cell.imageView.image scaleToWXThumbnailSizeKeepAspect:CGSizeMake(200, 200)];
    NSData *data = cell.imageView.animatedImage.data;
    if (data) {
        SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
        if (imageFormat == SDImageFormatGIF) {
            msg.messageType = Msg_ImageGif;
            thumbnailImg = cell.imageView.animatedImage.posterImage;
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
        data = UIImagePNGRepresentation(cell.imageView.image);
    }
    msg.image = data;
    msg.file = data;
    return msg;
}


@end


@implementation LWMyGIFCollectionCell {
}

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

        self.wechatBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.wechatBtn setImage:[UIImage imageNamed:@"wechat"] forState:UIControlStateNormal];
        [self.wechatBtn addTarget:self action:@selector(wechatAction:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.wechatBtn];
        [self.wechatBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.bottom.equalTo(self);
            make.width.height.mas_equalTo(30);
        }];


        //删除小叉叉
        self.deleteButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.deleteButton setImage:[UIImage imageNamed:@"deleteIcon"] forState:UIControlStateNormal];
        [self addSubview:self.deleteButton];
        self.deleteButton.hidden = YES;
        self.deleteButton.frame = CGRectMake(-Cell_DeleteBtn_W / 2, -Cell_DeleteBtn_H / 2, Cell_DeleteBtn_W, Cell_DeleteBtn_H);
        [self.deleteButton setHitTestEdgeInsets:UIEdgeInsetsMake(-4, -20, -20, -4)];
        [self bringSubviewToFront:self.deleteButton];
        [self.deleteButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self);
            make.right.equalTo(self);
            make.width.mas_equalTo(Cell_DeleteBtn_W);
            make.height.mas_equalTo(Cell_DeleteBtn_H);
        }];
        //给删除按钮添加响应事件
        [self.deleteButton addTarget:self action:@selector(deleteButtonClicked:) forControlEvents:UIControlEventTouchDown];

    }

    return self;
}

- (void)setEditing:(BOOL)editing {
    _deleteButton.hidden = !editing;
    _editing = editing;
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

//执行删除Cell的操作
- (void)deleteButtonClicked:(UIButton *)btn {
    BOOL isSuccess = [[LWSymbolService symbolService] deleteSymbolWithId:self.symbol._id];
    if (isSuccess) {
        //删除文件
        NSString *documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *filePath = [documentsDirectory stringByAppendingPathComponent:self.symbol.file_url];
        [FCFileManager removeItemAtPath:filePath];

        LWMyGIFCollectionView *collectionView = [self superViewWithClass:[LWMyGIFCollectionView class]];
        [collectionView reloadData];

        NSDictionary *userInfo = @{@"objURLString":self.symbol.http_url,@"favoriteValue":@(0)};
        [[NSNotificationCenter defaultCenter] postNotificationName:Notification_FavoriteChanged object:nil userInfo:userInfo];
    }
}

- (void)linkAction:(UIButton *)linkBtn {
    [App_Delegate setTabBarSelectedIndex:0];
    [self performSelector:@selector(linkGenGIFVC) withObject:nil afterDelay:0.3];
}

- (void)wechatAction:(UIButton *)wechatBtn {

    LWMyGIFViewController *vc = [self superViewWithClass:[LWMyGIFViewController class]];
    __weak typeof(self) weakSelf = self;
    vc.afterAdShowBlock = ^{
        //构建消息
        OSMessage *msg = [[OSMessage alloc] init];
        msg.title = NSLocalizedString(@"Share Image", nil);
        msg.desc = NSLocalizedString(@"Share Image", nil);

        UIImage *thumbnailImg = [weakSelf.imageView.image scaleToWXThumbnailSizeKeepAspect:CGSizeMake(200, 200)];
        NSData *data = weakSelf.imageView.animatedImage.data;
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
            data = UIImagePNGRepresentation(weakSelf.imageView.image);
        }
        msg.image = data;
        msg.file = data;

        LWMyGIFViewController *controller = [weakSelf superViewWithClass:[LWMyGIFViewController class]];
        [OpenShare shareToWeixinSession:msg fromView:controller.view Success:^(OSMessage *message) {
            Log(@"分享到微信成功");
        }                          Fail:^(OSMessage *message, NSError *error) {
            Log(@"分享到微信失败");
        }];

    };

    //显示广告
    [vc showAdWithNumRate:3];

    //显示评分按钮
    if ([LWPurchaseHelper isAfterDate:kAfterDate]) {
        [LWPurchaseHelper showRating];
    }
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

    if(!imageData){
        return;
    }

    SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:imageData];
    if (imageFormat == SDImageFormatGIF) {
        [self.imageView setAnimatedImage:[FLAnimatedImage animatedImageWithGIFData:imageData]];
    } else {
        [self.imageView setImage:[UIImage imageWithData:imageData]];
    }
    [self bringSubviewToFront:self.deleteButton];
}

- (void)linkGenGIFVC {
    NSData *gifData = self.imageView.animatedImage.data;
    UIImage *image = self.imageView.image;
    UINavigationController *navVC = (UINavigationController *) App_Delegate.tabBarController.viewControllers.firstObject;
    GenGIFViewController *vc = navVC.viewControllers.firstObject;
    if (!vc) {
        return;
    }

    vc.liveView.hidden = YES;
    vc.videoPlayerView.hidden = YES;

    if (gifData) {

        [vc updateSelectedMode:GIFMode];
        vc.exportGIFImageData = gifData;
        vc.imagePreview.animatedImage = [FLAnimatedImage animatedImageWithGIFData:gifData];

    } else if (image) {
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
        [self.refreshBtn setContentEdgeInsets:UIEdgeInsetsMake(6, 10, 6, 10)];
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


