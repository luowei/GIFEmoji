//
// Created by Luo Wei on 2017/10/23.
// Copyright (c) 2017 wodedata. All rights reserved.
//

#import "LWSnapshotMaskView.h"
#import "SDWebImageCompat.h"
#import "UIColor+HexValue.h"
#import "UIView+extensions.h"
#import "LWGIFPreviewViewController.h"
#import "FLAnimatedImageView.h"
#import "FLAnimatedImage.h"
#import "UIImage+GIF.h"
#import "UIImage+Extension.h"

#define Edge_Padding 20
#define Default_HalfLen 80
#define CornerPoint_Dia 6


@implementation LWSnapshotMaskView {
    UIColor *_color;
    UIColor *_bgColor;
    BOOL _btnisHiden;
}

+(LWSnapshotMaskView *)showSnapshotMaskInView:(UIView *)view frame:(CGRect)frame{
    LWSnapshotMaskView *snapshutMask = nil;
    for(UIView *v in view.subviews){
        if([v isKindOfClass:[LWSnapshotMaskView class]]){
            snapshutMask = (LWSnapshotMaskView *)v;
            [view bringSubviewToFront:snapshutMask];
            break;
        }
    }
    if(!snapshutMask){
        snapshutMask = [[LWSnapshotMaskView alloc] initWithFrame:frame];
        [view addSubview:snapshutMask];
        [view bringSubviewToFront:snapshutMask];
    }
    return snapshutMask;
}

+(void)hideSnapshotMaskInView:(UIView *)view{
    for(UIView *v in view.subviews){
        if([v isKindOfClass:[LWSnapshotMaskView class]]){
            [v removeFromSuperview];
            break;
        }
    }

}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:self.cancelBtn];
        self.shareBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:self.shareBtn];
        self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self addSubview:self.fullScreenBtn];

        [self.cancelBtn addTarget:self action:@selector(cancelBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self.shareBtn addTarget:self action:@selector(shareBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [self.fullScreenBtn addTarget:self action:@selector(fullScreenBtnTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];

        [self.cancelBtn setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [self.cancelBtn setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        self.cancelBtn.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.5];
        self.cancelBtn.contentEdgeInsets = UIEdgeInsetsMake(4, 10, 4, 10);
        [self.shareBtn setTitle:NSLocalizedString(@"Share", nil) forState:UIControlStateNormal];
        [self.shareBtn setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        self.shareBtn.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.5];
        self.shareBtn.contentEdgeInsets = UIEdgeInsetsMake(4, 10, 4, 10);
        [self.fullScreenBtn setTitle:NSLocalizedString(@"FullScreen", nil) forState:UIControlStateNormal];
        [self.fullScreenBtn setTitleColor:[UIColor whiteColor]forState:UIControlStateNormal];
        self.fullScreenBtn.backgroundColor = [[UIColor grayColor] colorWithAlphaComponent:0.5];
        self.fullScreenBtn.contentEdgeInsets = UIEdgeInsetsMake(4, 10, 4, 10);

        self.cancelBtn.translatesAutoresizingMaskIntoConstraints = NO;
        self.shareBtn.translatesAutoresizingMaskIntoConstraints = NO;
        self.fullScreenBtn.translatesAutoresizingMaskIntoConstraints = NO;

        NSLayoutConstraint *cancelBtnTop = [NSLayoutConstraint constraintWithItem:self.cancelBtn attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:5];
        NSLayoutConstraint *cancelBtnLeading = [NSLayoutConstraint constraintWithItem:self.cancelBtn attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeLeading multiplier:1.0 constant:CornerPoint_Dia];
        [NSLayoutConstraint activateConstraints:@[cancelBtnTop,cancelBtnLeading]];

        NSLayoutConstraint *shareBtnTop = [NSLayoutConstraint constraintWithItem:self.shareBtn attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:5];
        NSLayoutConstraint *shareBtnLeading = [NSLayoutConstraint constraintWithItem:self.shareBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTrailing multiplier:1.0 constant:-CornerPoint_Dia];
        [NSLayoutConstraint activateConstraints:@[shareBtnTop,shareBtnLeading]];

        NSLayoutConstraint *fullScreenBtnTop = [NSLayoutConstraint constraintWithItem:self.fullScreenBtn attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeTop multiplier:1.0 constant:5];
        NSLayoutConstraint *fullScreenBtnLeading = [NSLayoutConstraint constraintWithItem:self.fullScreenBtn attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self attribute:NSLayoutAttributeCenterX multiplier:1.0 constant:0];
        [NSLayoutConstraint activateConstraints:@[fullScreenBtnTop,fullScreenBtnLeading]];

        _color = [UIColor whiteColor];
        _bgColor = [UIColor colorWithRGBAString:@"0,0,0,191"];
        _btnisHiden = NO;

        //初始化截取范围框
        self.prePoint = CGPointMake(frame.size.width / 2, frame.size.height / 2);
        self.snapshotFrame = CGRectMake(frame.size.width / 2 - Default_HalfLen, frame.size.height / 2 - Default_HalfLen, Default_HalfLen * 2, Default_HalfLen * 2);
        //添加手势
        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onDrag:)];
        [self addGestureRecognizer:panGesture];

        //更新子视图样式
        UIFont *font = [UIFont systemFontOfSize:14];
        self.cancelBtn.titleLabel.font = font;
        self.cancelBtn.layer.cornerRadius = 4;
        self.shareBtn.titleLabel.font = font;
        self.shareBtn.layer.cornerRadius = 4;
        self.fullScreenBtn.titleLabel.font = font;
        self.fullScreenBtn.layer.cornerRadius = 4;

    }

    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    LWGIFPreviewViewController *vc = [self superViewWithClass:[LWGIFPreviewViewController class]];
    self.frame = [vc imageFitFrameInView:vc.imageView];
}

- (void)rotationToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    [super rotationToInterfaceOrientation:orientation];
    [self removeFromSuperview];
}


- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];

    //绘制背景颜色
    UIBezierPath* rectanglePath = [UIBezierPath bezierPathWithRect: self.bounds];
    [_bgColor setFill];
    [rectanglePath fill];

    //绘制一个透明的矩形框
    [self drawRectangleWithFrame:self.snapshotFrame];

}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    if(_btnisHiden){
        self.cancelBtn.hidden = NO;
        self.fullScreenBtn.hidden = NO;
        self.shareBtn.hidden = NO;
    }
    [self.nextResponder touchesBegan:touches withEvent:event];
}


//手势滑动
- (void)onDrag:(UIPanGestureRecognizer *)panGesture {

    switch (panGesture.state){
        case UIGestureRecognizerStateBegan:{
            self.prePoint = [panGesture locationInView:self];
            self.pointLocation = [self locationOfPoint:self.prePoint];
            break;
        }
        case UIGestureRecognizerStateChanged:{
            CGPoint point = [panGesture locationInView:self];
            [self updateSnapshotFrameWithPoint:point];
            [self setNeedsDisplay];
            break;
        }
        case UIGestureRecognizerStateEnded: {
            CGPoint point = [panGesture locationInView:self];
            [self updateSnapshotFrameWithPoint:point];
            self.pointLocation = Outside;
            [self setNeedsDisplay];
            break;
        }
        default:{
            self.pointLocation = Outside;
            break;
        }
    }
}

//根据 point 更新的 SnapshotFrame
-(void)updateSnapshotFrameWithPoint:(CGPoint)point{

    switch (self.pointLocation){
        case InControl:{
            CGSize size = self.snapshotFrame.size;
            CGFloat detaX = point.x - self.prePoint.x;
            CGFloat detaY = point.y - self.prePoint.y;
            self.snapshotFrame = CGRectMake(self.snapshotFrame.origin.x + detaX, self.snapshotFrame.origin.y + detaY, size.width, size.height);
            self.prePoint = point;
            break;
        }
        case OnLeftEdge:{
            CGFloat width = self.snapshotFrame.size.width + (self.snapshotFrame.origin.x - point.x);
            CGSize size = CGSizeMake(width > 30 ? width : 30, self.snapshotFrame.size.height);
            self.snapshotFrame = CGRectMake(point.x, self.snapshotFrame.origin.y, size.width, size.height);
            break;
        }
        case OnRightEdge:{
            CGFloat width = self.snapshotFrame.size.width - ((self.snapshotFrame.origin.x + self.snapshotFrame.size.width) - point.x);
            CGSize size = CGSizeMake(width > 30 ? width : 30, self.snapshotFrame.size.height);
            self.snapshotFrame = CGRectMake(self.snapshotFrame.origin.x, self.snapshotFrame.origin.y, size.width, size.height);
            break;
        }
        case OnTopEdge:{
            CGFloat height = self.snapshotFrame.size.height + (self.snapshotFrame.origin.y - point.y);
            CGSize size = CGSizeMake(self.snapshotFrame.size.width, height > 30 ? height : 30);
            self.snapshotFrame = CGRectMake(self.snapshotFrame.origin.x, point.y, size.width, size.height);
            break;
        }
        case OnBottomEdge:{
            CGFloat height = self.snapshotFrame.size.height - ((self.snapshotFrame.origin.y + self.snapshotFrame.size.height) - point.y);
            CGSize size = CGSizeMake(self.snapshotFrame.size.width, height > 30 ? height : 30);
            self.snapshotFrame = CGRectMake(self.snapshotFrame.origin.x, self.snapshotFrame.origin.y, size.width, size.height);
            break;
        }
        case OnLeftTopCorner:{
            CGFloat width = self.snapshotFrame.size.width + (self.snapshotFrame.origin.x - point.x);
            CGFloat height = self.snapshotFrame.size.height + (self.snapshotFrame.origin.y - point.y);
            CGSize size = CGSizeMake(width > 30 ? width : 30, height > 30 ? height : 30);
            self.snapshotFrame = CGRectMake(point.x, point.y, size.width, size.height);
            break;
        }
        case OnRightTopCorner:{
            CGFloat width = self.snapshotFrame.size.width - ((self.snapshotFrame.origin.x + self.snapshotFrame.size.width) - point.x);
            CGFloat height = self.snapshotFrame.size.height + (self.snapshotFrame.origin.y - point.y);
            CGSize size = CGSizeMake(width > 30 ? width : 30, height > 30 ? height : 30);
            self.snapshotFrame = CGRectMake(self.snapshotFrame.origin.x, point.y, size.width, size.height);
            break;
        }
        case OnLeftBottomCorner:{
            CGFloat width = self.snapshotFrame.size.width + (self.snapshotFrame.origin.x - point.x);
            CGFloat height = self.snapshotFrame.size.height - ((self.snapshotFrame.origin.y + self.snapshotFrame.size.height) - point.y);
            CGSize size = CGSizeMake(width > 30 ? width : 30, height > 30 ? height : 30);
            self.snapshotFrame = CGRectMake(point.x, self.snapshotFrame.origin.y, size.width, size.height);
            break;
        }
        case OnRightBottomCorner:{
            CGFloat width = self.snapshotFrame.size.width - ((self.snapshotFrame.origin.x + self.snapshotFrame.size.width) - point.x);
            CGFloat height = self.snapshotFrame.size.height - ((self.snapshotFrame.origin.y + self.snapshotFrame.size.height) - point.y);
            CGSize size = CGSizeMake(width > 30 ? width : 30, height > 30 ? height : 30);
            self.snapshotFrame = CGRectMake(self.snapshotFrame.origin.x, self.snapshotFrame.origin.y, size.width, size.height);
            break;
        }
        default:{
            break;
        }
    }

    //吸附距离为2
    CGFloat minX = CGRectGetMinX(self.snapshotFrame) > 2 ? CGRectGetMinX(self.snapshotFrame) : 0;
    CGFloat minY = CGRectGetMinY(self.snapshotFrame) > 2 ? CGRectGetMinY(self.snapshotFrame) : 0;
    CGFloat maxX = CGRectGetMaxX(self.snapshotFrame) < self.bounds.size.width - 2 ? CGRectGetMaxX(self.snapshotFrame) : self.bounds.size.width;
    CGFloat maxY = CGRectGetMaxY(self.snapshotFrame) < self.bounds.size.height - 2 ? CGRectGetMaxY(self.snapshotFrame) : self.bounds.size.height;
    self.snapshotFrame = CGRectMake(minX, minY, maxX - minX, maxY - minY);
}

//判断 point 在 snapshotFrame 的哪个位置
- (PointLocation)locationOfPoint:(CGPoint)point {
    //判断这个点是否在snapshotFrame的范围内
    BOOL isInControl = CGRectContainsPoint(CGRectInset(self.snapshotFrame,Edge_Padding,Edge_Padding), point);
    //BOOL isOnControl = CGRectContainsPoint(CGRectInset(self.snapshotFrame,-Edge_Padding,-Edge_Padding), point) && !isInControl;
    BOOL isOnTopEdge = (point.y > self.snapshotFrame.origin.y - Edge_Padding) && (point.y < self.snapshotFrame.origin.y + Edge_Padding);
    BOOL isOnBottomEdge = (point.y > self.snapshotFrame.origin.y + self.snapshotFrame.size.height - Edge_Padding) && (point.y < self.snapshotFrame.origin.y + self.snapshotFrame.size.height + Edge_Padding);
    BOOL isOnLeftEdge = (point.x > self.snapshotFrame.origin.x - Edge_Padding) && (point.x < self.snapshotFrame.origin.x + Edge_Padding);
    BOOL isOnRightEdge = (point.x > self.snapshotFrame.origin.x + self.snapshotFrame.size.width - Edge_Padding) && (point.x < self.snapshotFrame.origin.x + self.snapshotFrame.size.width + Edge_Padding);
    BOOL isOnLeftTopCorner = isOnLeftEdge && isOnTopEdge;
    BOOL isOnRightTopCorner = isOnRightEdge && isOnTopEdge;
    BOOL isOnLeftBottomCorner = isOnLeftEdge && isOnBottomEdge;
    BOOL isOnRightBottomCorner = isOnRightEdge && isOnBottomEdge;

    PointLocation pointLocation = Outside;
    if (isInControl) {    //内部
        pointLocation = InControl;
    } else if (isOnLeftTopCorner) {    //左上角
        pointLocation = OnLeftTopCorner;
    } else if (isOnRightTopCorner) {   //右上角
        pointLocation = OnRightTopCorner;
    } else if (isOnLeftBottomCorner) { //左下角
        pointLocation = OnLeftBottomCorner;
    } else if (isOnRightBottomCorner) {    //右下角
        pointLocation = OnRightBottomCorner;
    } else if (isOnTopEdge) { //顶边
        pointLocation = OnTopEdge;
    } else if (isOnLeftEdge) { //左边
        pointLocation = OnLeftEdge;
    } else if (isOnBottomEdge) {   //底边
        pointLocation = OnBottomEdge;
    } else if (isOnRightEdge) {    //右边
        pointLocation = OnRightEdge;
    }
    return pointLocation;
}


//绘制一个透明的矩形框
- (void)drawRectangleWithFrame:(CGRect)frame {
    CGContextRef context = UIGraphicsGetCurrentContext();

    UIBezierPath *snapshotPath = [UIBezierPath bezierPathWithRect:frame];

    //设置清除颜色模式,以透明的方式填充
    CGContextSetBlendMode(context, kCGBlendModeClear);
    [_color setFill];
    [snapshotPath fill];

    if(_btnisHiden){
        return;
    }

    //设置为虚线类型
    CGContextSetBlendMode(context, kCGBlendModeNormal);
    [snapshotPath setLineDash: (CGFloat[]){8,5}  count: 2 phase: 0];
    [_color setStroke];
    snapshotPath.lineWidth = 1.0;
    [snapshotPath stroke];

    //绘制4个小圆点
    CGRect oval1Rect = CGRectMake(CGRectGetMinX(self.snapshotFrame) - CornerPoint_Dia/2, CGRectGetMinY(self.snapshotFrame) - CornerPoint_Dia/2, CornerPoint_Dia, CornerPoint_Dia);
    UIBezierPath* oval1Path = [UIBezierPath bezierPathWithOvalInRect: oval1Rect];
    [_color setFill];
    [oval1Path fill];

    CGRect oval2Rect = CGRectMake(CGRectGetMaxX(self.snapshotFrame) - CornerPoint_Dia/2, CGRectGetMinY(self.snapshotFrame) - CornerPoint_Dia/2, CornerPoint_Dia, CornerPoint_Dia);
    UIBezierPath* oval2Path = [UIBezierPath bezierPathWithOvalInRect: oval2Rect];
    [_color setFill];
    [oval2Path fill];

    CGRect oval3Rect = CGRectMake(CGRectGetMinX(self.snapshotFrame) - CornerPoint_Dia/2, CGRectGetMaxY(self.snapshotFrame) - CornerPoint_Dia/2, CornerPoint_Dia, CornerPoint_Dia);
    UIBezierPath* oval3Path = [UIBezierPath bezierPathWithOvalInRect: oval3Rect];
    [_color setFill];
    [oval3Path fill];

    CGRect oval4Rect = CGRectMake(CGRectGetMaxX(self.snapshotFrame) - CornerPoint_Dia/2, CGRectGetMaxY(self.snapshotFrame) - CornerPoint_Dia/2, CornerPoint_Dia, CornerPoint_Dia);
    UIBezierPath* oval4Path = [UIBezierPath bezierPathWithOvalInRect: oval4Rect];
    [_color setFill];
    [oval4Path fill];
}


#pragma mark - Btn Action

//取消按钮按下
- (void)cancelBtnTouchUpInside:(UIButton *)btn {
    if(self.closeBlock){
        self.closeBlock();
    }
    [self removeFromSuperview];
}

//全屏按钮按下
- (void)fullScreenBtnTouchUpInside:(UIButton *)btn {
    self.snapshotFrame = self.bounds;
    [self setNeedsDisplay];
}

//分享按钮按下
- (void)shareBtnTouchUpInside:(UIButton *)btn {
    LWGIFPreviewViewController *vc = [self superViewWithClass:[LWGIFPreviewViewController class]];

    NSLog(@"======分享图片======");
    //UIImage *image = [self.superview snapshotImageInRect:self.snapshotFrame];

    NSData *cutGIFData = vc.gifData;

    CGSize imageSize = vc.imageView.intrinsicContentSize;
    CGFloat wScale = imageSize.width / self.bounds.size.width;
    CGFloat hScale = imageSize.height / self.bounds.size.height;

    if(fabs(wScale-1.0) > 0.01 || fabs(hScale-1.0) > 0.01){

        CGRect cutRect = CGRectMake(self.snapshotFrame.origin.x * wScale, self.snapshotFrame.origin.y * hScale,
                self.snapshotFrame.size.width * wScale, self.snapshotFrame.size.height * hScale);
        CGSize cutSize = CGSizeMake(self.snapshotFrame.size.width * wScale, self.snapshotFrame.size.height * hScale);

        NSMutableArray <UIImage *>* imageList = @[].mutableCopy;
        NSArray <UIImage *>*images = [UIImage imagesFromGIFData:vc.gifData];

        for(UIImage *image in images){
            UIImage *img = [image cutImageWithRect:cutRect];
            [imageList addObject:img];
        }

        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyyMMddHHmmssSSS";
        NSString *gifFileName = [NSString stringWithFormat:@"%@.gif",[dateFormatter stringFromDate:[NSDate new]]];
        NSString *gifFilePath = [NSTemporaryDirectory() stringByAppendingString:gifFileName];

        CGFloat screenScale = [UIScreen mainScreen].scale;
        imageSize = CGSizeMake(cutSize.width * screenScale, cutSize.height * screenScale);
        float delayTime = (float) (1.0/(float)vc.fpsSlider.value);

        cutGIFData = [UIImage createGIFWithImages:imageList size:imageSize loopCount:0 delayTime:delayTime gifCachePath:gifFilePath];
    }


    UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[cutGIFData] applicationActivities:nil];
    //显示弹出层
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:activityVC];
        CGRect rect = [[UIScreen mainScreen] bounds];
        [popoverController presentPopoverFromRect:rect inView:vc.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [vc presentViewController:activityVC animated:YES completion:nil];
    }

    [self removeFromSuperview];

}

@end