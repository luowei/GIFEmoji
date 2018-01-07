//
// Created by Luo Wei on 2018/1/8.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface LWImageModel : NSObject

@property (nonatomic, strong) NSString *thumbURL;
@property (nonatomic, strong) NSString *middleURL;
@property (nonatomic, strong) NSString *objURL;
@property (nonatomic, strong) NSString *fromURL;
@property (nonatomic, assign) CGFloat width;
@property (nonatomic, assign) CGFloat height;

@end