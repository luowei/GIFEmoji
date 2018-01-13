//
// Created by Luo Wei on 2018/1/11.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FLAnimatedImageView;
@class LWSymbol;
@class LWCategory;
@class LWCollectionPlaceHoldView;


@interface LWMyGIFCollectionView : UICollectionView<UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>


@property(nonatomic, strong) NSArray <LWSymbol *>*dataList;
@property(nonatomic, strong) LWCategory *category;

@property(nonatomic, strong) LWCollectionPlaceHoldView *placeHoldView;

@property(nonatomic, assign) BOOL editing;

- (instancetype)initWithFrame:(CGRect)frame category:(LWCategory *)category;

//刷新数据
-(void)reloadWithCategory:(LWCategory *)category;

@end


@interface LWMyGIFCollectionCell : UICollectionViewCell


@property(nonatomic, strong) FLAnimatedImageView *imageView;
@property(nonatomic, strong) UIButton *shareBtn;
@property(nonatomic, strong) UIButton *linkBtn;
@property(nonatomic, strong) UIButton *deleteButton;

@property(nonatomic, assign) BOOL editing;

@property(nonatomic, strong) LWSymbol *symbol;

- (void)fillWithData:(LWSymbol *)symbol;

@end


@interface LWCollectionPlaceHoldView : UIView

@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIButton *refreshBtn;

@end