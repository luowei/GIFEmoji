//
// Created by luowei on 2018/1/31.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface ReportViewController : UIViewController<UITableViewDataSource,UITableViewDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property(nonatomic, copy) NSString *urlString;
@property(nonatomic, strong) NSMutableArray <NSString *>*reportList;
@end
