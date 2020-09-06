//
//  SRPictureBrowser.m
//  SRPhotoBrowser
//
//  Created by https://github.com/guowilling on 16/12/24.
//  Copyright © 2016年 SR. All rights reserved.
//

#import "SRPictureBrowser.h"
#import "SRPictureCell.h"
#import "SRPictureView.h"
#import "SRPictureModel.h"
#import "SRPictureManager.h"
#import "SRPictureHUD.h"
#import "View+MASAdditions.h"
#import "UIColor+HexValue.h"
#import "LWFramePreviewViewController.h"
#import "UIView+extensions.h"
#import "OpenShare.h"
#import "NSData+ImageContentType.h"
#import "UIImage+Extension.h"
#import "LWUIActivity.h"

@interface SRPictureBrowser () <UICollectionViewDataSource, UICollectionViewDelegate, UIScrollViewDelegate, UIActionSheetDelegate, SRPictureCellDelegate, SRPictureViewDelegate>

@property (nonatomic, weak) id<SRPictureBrowserDelegate> delegate;

@property (nonatomic, copy) NSArray *pictureModels;

//@property (nonatomic, strong) UIImageView *screenImageView;

@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIPageControl    *pageControl;

@property (nonatomic, strong) SRPictureView *currentPictureView;

@end

@implementation SRPictureBrowser

+ (SRPictureBrowser *)sr_showPictureBrowserWithModels:(NSArray *)pictureModels
                           currentIndex:(NSInteger)currentIndex
                               delegate:(id<SRPictureBrowserDelegate>)delegate
                                 inView:(UIView *)view {
    
    SRPictureBrowser *pictureBrowser = [[self alloc] initWithModels:pictureModels
                                                       currentIndex:currentIndex
                                                           delegate:delegate inView:view];
    [pictureBrowser showInView:view];
    [pictureBrowser mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(view);
    }];
    return pictureBrowser;
}

#pragma mark - Initialize

- (id)initWithModels:(NSArray *)pictureModels
        currentIndex:(NSInteger)currentIndex
            delegate:(id<SRPictureBrowserDelegate>)delegate inView:(UIView *)view{
    
    if (self = [super initWithFrame:[UIScreen mainScreen].bounds]) {
        _pictureModels = pictureModels;
        _currentIndex = currentIndex;
        _delegate = delegate;
        for (SRPictureModel *picModel in _pictureModels) {
            if (picModel.index == _currentIndex) {
                picModel.firstShow = YES;
                break;
            }
        }
        [self setupInView:view];
    }
    return self;
}

- (void)setupInView:(UIView *)view {
    
    self.backgroundColor = [UIColor whiteColor];
    
//    [self addSubview:({
//        UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES, [UIScreen mainScreen].scale);
//        [view.layer renderInContext:UIGraphicsGetCurrentContext()];
//        UIImage *currentScreenImage = UIGraphicsGetImageFromCurrentImageContext();
//        UIGraphicsEndImageContext();
//        _screenImageView = [[UIImageView alloc] initWithFrame:view.bounds];
//        _screenImageView.image = currentScreenImage;
//        _screenImageView.hidden = YES;
//        _screenImageView;
//    })];
    
    [self addSubview:({
        CGFloat flowLayoutWidth = view.bounds.size.width;// + 10;
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(flowLayoutWidth, view.bounds.size.height);
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        flowLayout.minimumLineSpacing = 0.0f;
        flowLayout.sectionInset = UIEdgeInsetsMake(0.0f, 0.0f, 0.0f, 0.0f);
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 0, flowLayoutWidth, view.bounds.size.height-64) collectionViewLayout:flowLayout];
        _collectionView.backgroundColor = [UIColor clearColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        [_collectionView registerClass:[SRPictureCell class] forCellWithReuseIdentifier:pictureViewID];
        [_collectionView setContentOffset:CGPointMake(self.currentIndex * flowLayoutWidth, 0.0f) animated:NO];
        _collectionView;
    })];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.bottom.equalTo(self);
    }];
    
    [self addSubview:({
        _pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, view.bounds.size.height - 64 - 40 - 10, view.bounds.size.width, 40)];
        _pageControl.pageIndicatorTintColor = [UIColor lightGrayColor];
        _pageControl.currentPageIndicatorTintColor = [UIColor darkGrayColor];
        _pageControl.numberOfPages = self.pictureModels.count;
        _pageControl.currentPage = self.currentIndex;
        _pageControl.userInteractionEnabled = NO;
        if (_pictureModels.count == 1) {
            _pageControl.hidden = YES;
        }
        _pageControl;
    })];
    [_pageControl mas_makeConstraints:^(MASConstraintMaker *make) {
       make.left.equalTo(self).offset(10);
       make.right.equalTo(self).offset(-10);
       make.bottom.equalTo(self).offset(-10);
        make.height.mas_equalTo(40);
    }];
}

#pragma mark - Animation

- (void)showInView:(UIView *)view {
    
    [view addSubview:self];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    if ([self.delegate respondsToSelector:@selector(pictureBrowserDidShow:)]) {
        [self.delegate pictureBrowserDidShow:self];
    }
}

- (void)dismiss {
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
//    _screenImageView.hidden = NO;
    _pageControl.hidden = YES;
    
    if (self.currentPictureView.zoomScale != 1.0) {
        self.currentPictureView.zoomScale = 1.0;
    }
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        self.currentPictureView.imageView.frame = self.currentPictureView.pictureModel.originPosition;
    } completion:^(BOOL finished) {
        if ([self.delegate respondsToSelector:@selector(pictureBrowserDidDismiss)]) {
            [self.delegate pictureBrowserDidDismiss];
        }
//        [self removeFromSuperview];
    }];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    
    return self.pictureModels.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    SRPictureCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:pictureViewID forIndexPath:indexPath];
    cell.delegate = self;
    cell.pictureView.pictureViewDelegate = self;
    cell.pictureModel = self.pictureModels[indexPath.row];
    if (!_currentPictureView) {
        _currentPictureView = cell.pictureView;
    }
    return cell;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    
    NSInteger index = scrollView.contentOffset.x / [UIScreen mainScreen].bounds.size.width;
    self.currentIndex = index;
    self.pageControl.currentPage = index;
    
    NSArray *cells = [self.collectionView visibleCells];
    if (cells.count == 0) {
        return;
    }
    SRPictureCell *cell = [cells objectAtIndex:0];
    if (self.currentPictureView == cell.pictureView) {
        return;
    }
    self.currentPictureView = cell.pictureView;
    
    if (self.currentIndex + 1 < self.pictureModels.count) {
        SRPictureModel *nextModel = self.pictureModels[self.currentIndex + 1];
        if(!nextModel.picture){
            [SRPictureManager prefetchDownloadPicture:nextModel.picURLString success:^(UIImage *picture) {
                nextModel.picture = picture;
            }];
        }
    }
    if (self.currentIndex - 1 >= 0) {
        SRPictureModel *preModel = self.pictureModels[self.currentIndex - 1];
        if(!preModel.picture){
            [SRPictureManager prefetchDownloadPicture:preModel.picURLString success:^(UIImage *picture) {
                preModel.picture = picture;
            }];
        }
    }
}

#pragma mark - SRPictureCellDelegate

- (void)pictureCellDidPanToAlpha:(CGFloat)alpha {
    
//    self.backgroundColor = [UIColor colorWithWhite:0 alpha:alpha];
//    self.pageControl.alpha = alpha;
}

- (void)pictureCellDidPanToDismiss {
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    if ([self.delegate respondsToSelector:@selector(pictureBrowserDidDismiss)]) {
        [self.delegate pictureBrowserDidDismiss];
    }
//    [self removeFromSuperview];
}

#pragma mark - SRPictureViewDelegate

- (void)pictureViewDidTapToDismissPictureBrowser {
    
    [self dismiss];
}

- (void)pictureViewDidLongPress {

    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle: nil
                                                             delegate: self
                                                    cancelButtonTitle: nil
                                               destructiveButtonTitle: nil
                                                    otherButtonTitles: nil];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Save", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Share", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    [actionSheet setCancelButtonIndex: 2];

    [actionSheet showInView:self];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (buttonIndex == 0) {
        UIImageWriteToSavedPhotosAlbum(self.currentPictureView.imageView.image, self, @selector(image:didFinishSavingWithError:contextInfo:), NULL);
    }else if(buttonIndex == 1){
        LWFramePreviewViewController *vc = [self superViewWithClass:[LWFramePreviewViewController class]];

        OSMessage *msg = [self getShareMessage];

        LWWechatActivity *wechatActivity = [[LWWechatActivity alloc] initWithiphoneImage:[UIImage imageNamed:@"Wechat50"] ipadImage:[UIImage imageNamed:@"Wechat53"]];
        wechatActivity.msg = msg;
        wechatActivity.fromView = vc.view;

        LWQQActivity *qqActivity = [[LWQQActivity alloc] initWithiphoneImage:[UIImage imageNamed:@"QQ50"] ipadImage:[UIImage imageNamed:@"QQ53"]];
        qqActivity.msg = msg;
        qqActivity.fromView = vc.view;

        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[self.currentPictureView.imageView.image] applicationActivities:@[wechatActivity,qqActivity]];
        activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePrint];

        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
            UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityVC];
            CGRect rect = [[UIScreen mainScreen] bounds];
            [popoverController presentPopoverFromRect:rect inView:self permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }else{
            [vc presentViewController:activityVC animated:TRUE completion:nil];
        }

    }
}

- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo {
    
    if (error) {
        [SRPictureHUD showHUDInView:self withMessage:@"Save Picture Failure!"];
    } else {
        [SRPictureHUD showHUDInView:self withMessage:@"Save Picture Success!"];
    }
}

- (OSMessage *)getShareMessage {
    //构建消息
    OSMessage *msg = [[OSMessage alloc] init];
    msg.title = NSLocalizedString(@"Share Image", nil);
    msg.desc = NSLocalizedString(@"Share Image", nil);

    UIImage *image = self.currentPictureView.imageView.image;

    msg.messageType = Msg_Image;

    UIImage *thumbnailImg = [image scaleToWXThumbnailSizeKeepAspect:CGSizeMake(200, 200)];
    NSData *thumbnailData = [thumbnailImg compressWithInMaxFileSize:32 * 1024];
    msg.thumbnail = thumbnailData;

    NSData *data = UIImagePNGRepresentation(image);

    msg.image = data;
    msg.file = data;
    return msg;
}


@end
