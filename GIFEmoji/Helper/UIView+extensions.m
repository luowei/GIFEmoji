//
// Created by Luo Wei on 2017/5/9.
// Copyright (c) 2017 luowei. All rights reserved.
//

#import <objc/runtime.h>
#import "UIView+extensions.h"


@implementation UIView (extensions)
@end


@implementation UIView (Snapshot)

- (UIImage *)snapshotImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, [UIScreen mainScreen].scale);
    [self drawViewHierarchyInRect:self.bounds afterScreenUpdates:YES];
    // old style [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}


//截取 UIView 指定 rect 的图像
- (UIImage *)snapshotImageInRect:(CGRect)rect {
    UIGraphicsBeginImageContextWithOptions(rect.size, NO, [UIScreen mainScreen].scale);
    [self drawViewHierarchyInRect:CGRectMake(-rect.origin.x, -rect.origin.y, self.bounds.size.width, self.bounds.size.height) afterScreenUpdates:YES];
    // old style [self.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)snapshotImageRenderInContext {
    UIImage *snapShot = nil;
//    UIGraphicsBeginImageContext(size);
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, self.opaque, 0.0);
    {
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        snapShot = UIGraphicsGetImageFromCurrentImageContext();
    }

    UIGraphicsEndImageContext();
    return snapShot;

}

@end



@implementation UIView (Copy)

-(id)copyView{
    return [NSKeyedUnarchiver unarchiveObjectWithData:[NSKeyedArchiver archivedDataWithRootObject:self]];
}

@end


@implementation UIView (SuperRecurse)

- (UIViewController *)responderViewController {
    UIResponder *responder = self;
    while (![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
        if (nil == responder) {
            break;
        }
    }
    return (UIViewController *) responder;
}

//获得指class类型的父视图
- (id)superViewWithClass:(Class)clazz {
    UIResponder *responder = self;
    while (![responder isKindOfClass:clazz]) {
        responder = [responder nextResponder];
        if (nil == responder) {
            break;
        }
    }
    return responder;
}

@end

@implementation UIView (Resign)

- (UIView *)resignSubviewsFirstResponder {
    if ([self isFirstResponder]) {
        [self resignFirstResponder];
        return self;
    }
    for (UIView *subview in self.subviews) {
        UIView *result = [subview resignSubviewsFirstResponder];
        if (result) return result;
    }
    return nil;
}

-(UIView*)getSubviewsFirstResponder {
    UIView* requestedView = nil;
    for (UIView *view in self.subviews) {
        if (view.isFirstResponder) {
            return view;
        } else if (view.subviews.count > 0) {
            requestedView = [view getSubviewsFirstResponder];
        }
        if (requestedView != nil) {
            return requestedView;
        }
    }
    return nil;
}

@end

@implementation UIView (Rotation)

//递归的向子视图发送屏幕发生旋转了的消息
- (void)rotationToInterfaceOrientation:(UIInterfaceOrientation)orientation {
    for (UIView *v in self.subviews) {
        [v rotationToInterfaceOrientation:orientation];
    }
}

@end

@implementation UIView (NoScrollToTop)

- (void)subViewNOScrollToTopExcludeClass:(Class)clazz {

    for (UIView *v in self.subviews) {
        if ([v isKindOfClass:[UIScrollView class]]) {
            UIScrollView *scrollView = (UIScrollView *) v;
            scrollView.scrollsToTop = clazz == nil ? NO : [v isKindOfClass:clazz];
        }
        [v subViewNOScrollToTopExcludeClass:clazz];
    }
}

@end

@implementation UIView (updateAppearance)

- (void)updateAppearance {

    for (UIView *v in self.subviews) {
        [v updateAppearance];
    }

}

@end

@implementation UIView (CallCycle)

-(void)applicationDidEnterBackground{
//    for (UIView *v in self.subviews) {
//        [v applicationDidEnterBackground];
//    }
}
-(void)applicationDidBecomeActive{
//    for (UIView *v in self.subviews) {
//        [v applicationDidBecomeActive];
//    }
}
-(void)applicationWillTerminate{

}

-(void)applicationWillResignActive{

}
-(void)applicationWillEnterForeground{

}

-(void)willAppear{
    for (UIView *v in self.subviews) {
        [v willAppear];
    }
}
-(void)willDisappear{
    for (UIView *v in self.subviews) {
        [v willDisappear];
    }
}

@end

@implementation UIView (ScaleSize)

- (CGSize)scaleSize{
    CGFloat  scale = [UIScreen mainScreen].scale;
    return CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
}

-(CGSize)size{
    return CGSizeMake(self.bounds.size.width, self.bounds.size.height);
}

-(CGPoint)origin{
    return CGPointMake(self.frame.origin.x, self.frame.origin.y);
}

@end


@implementation UIButton (Extension)

@dynamic hitTestEdgeInsets;

static const NSString *KEY_HIT_TEST_EDGE_INSETS = @"HitTestEdgeInsets";

- (void)setHitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets {
    NSValue *value = [NSValue value:&hitTestEdgeInsets withObjCType:@encode(UIEdgeInsets)];
    objc_setAssociatedObject(self, &KEY_HIT_TEST_EDGE_INSETS, value, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIEdgeInsets)hitTestEdgeInsets {
    NSValue *value = objc_getAssociatedObject(self, &KEY_HIT_TEST_EDGE_INSETS);
    if (value) {
        UIEdgeInsets edgeInsets;
        [value getValue:&edgeInsets];
        return edgeInsets;
    } else {
        return UIEdgeInsetsZero;
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    if (UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden) {
        return [super pointInside:point withEvent:event];
    }

    CGRect relativeFrame = self.bounds;
    CGRect hitFrame = UIEdgeInsetsInsetRect(relativeFrame, self.hitTestEdgeInsets);

    return CGRectContainsPoint(hitFrame, point);
}

@end

