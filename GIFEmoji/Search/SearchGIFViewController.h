//
//  SearchGIFViewController.h
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LWImageModel;
@class FLAnimatedImageView;
@class SDWebImageDownloadToken;


@interface LWPlacehoderView : UIView

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIButton *settingsBtn;
@property (weak, nonatomic) IBOutlet UIButton *refreshBtn;


//显示加载失败视图
- (void)showFailureView;

- (void)reShowLoading;
@end

@interface LWCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet FLAnimatedImageView *imageView;
@property (nonatomic, weak) IBOutlet UIButton *faveritaBtn;
@property (weak, nonatomic) IBOutlet UIButton *shareBtn;
@property (weak, nonatomic) IBOutlet UIButton *linkBtn;
@property (weak, nonatomic) IBOutlet UIButton *wechatBtn;

@property(nonatomic, copy) NSString *thumbnailURL;
@property(nonatomic, copy) NSString *middleURL;
@property(nonatomic, copy) NSString *objURL;
@property(nonatomic, copy) NSString *fromURL;

@property(nonatomic, strong) SDWebImageDownloadToken *downloadToken;

- (void)fillWithImageModel:(LWImageModel *)model searchText:(NSString *)text;

@end


@interface SearchGIFViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextField *searchTextField;
@property (nonatomic, weak) IBOutlet UIButton *searchBtn;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet LWPlacehoderView *placehoderView;

@property (strong, nonatomic) NSMutableDictionary <NSString*,NSNumber*>* favoritedDcitionary;
@property(nonatomic, strong) NSMutableArray <NSString *>*reportList;;


- (IBAction)searchBtnAction:(UIButton *)sender;

@end





