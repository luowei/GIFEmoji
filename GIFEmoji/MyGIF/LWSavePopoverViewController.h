//
// Created by Luo Wei on 2017/9/8.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LWSavePopoverViewController : UITableViewController <UITableViewDataSource,UITableViewDelegate>

+(LWSavePopoverViewController *)popoverViewControllerWithDelegate:(id<UIPopoverPresentationControllerDelegate>)delegate
                                                             size:(CGSize)size sourceView:(UIView *)sourceView;

@end