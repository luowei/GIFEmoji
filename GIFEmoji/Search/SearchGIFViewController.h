//
//  SearchGIFViewController.h
//  GIFEmoji
//
//  Created by Luo Wei on 2018/1/3.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SearchGIFViewController : UIViewController

@property (nonatomic, weak) IBOutlet UITextField *searchTextField;
@property (nonatomic, weak) IBOutlet UIButton *searchBtn;

@property (nonatomic, weak) IBOutlet UICollectionView *collectionView;

@end

