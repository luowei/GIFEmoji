//
// Created by Luo Wei on 2018/1/6.
// Copyright (c) 2018 Luo Wei. All rights reserved.
//

#import "LWHelper.h"


@implementation LWHelper {

}

+(NSString *)getCurrentTimeStampText {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"yyyyMMddHHmmssSSS";
    NSString *timeStampText = [dateFormatter stringFromDate:[NSDate new]];
    return timeStampText;
}

@end