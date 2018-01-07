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

#define Item_Spacing 6

@interface SearchGIFViewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout>

@property (nonatomic, strong) NSArray<LWImageModel *> *dataList;

@end

@implementation SearchGIFViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.searchBtn.layer.cornerRadius = 5;

    // Do any additional setup after loading the view, typically from a nib.
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;

}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView{
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 20;
//    return self.dataList ? self.dataList.count : 0;
}

- (__kindof UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    LWCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"LWCollectionViewCell" forIndexPath:indexPath];

    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    LWImageModel *item = self.dataList[(NSUInteger) indexPath.item];


}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    return CGSizeMake((Screen_W - Item_Spacing * 4)/3  , (Screen_W -  Item_Spacing * 4)/3);
}


@end


@implementation LWCollectionViewCell

- (void)awakeFromNib {
    [super awakeFromNib];

    self.imageView.layer.borderWidth = 1;
    self.imageView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    self.imageView.layer.cornerRadius = 2;

}

-(IBAction)favoriteBtnTouchUpInside:(UIButton *)btn {

}

@end


@implementation LWPlaceHolderView


@end
