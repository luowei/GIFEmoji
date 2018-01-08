//
// Created by Luo Wei on 2017/5/8.
// Copyright (c) 2017 luowei. All rights reserved.
//

#import <UIKit/UIKit.h>

@class MyWKWebView;

@interface LWWKWebViewController : UIViewController

@property (nonatomic, strong) MyWKWebView *wkWebView;
@property (strong, nonatomic) UIProgressView *webProgress;

@property(nonatomic, strong) NSURL *url;

+ (LWWKWebViewController *)loadURL:(NSURL *)url;

+ (LWWKWebViewController *)wkWebViewControllerWithURL:(NSURL *)url;

+(UINavigationController *)navigationControllerWithURL:(NSURL *)url;

- (void)loadURL:(NSURL *)url;

@end


//参考:http://www.papersizes.org/a-sizes-in-pixels.htm
#define kPaperSizeA3 CGSizeMake(842 , 1191)
#define kPaperSizeA4 CGSizeMake(595 , 842)
#define kPaperSizeA5 CGSizeMake(420 , 595)
#define kPaperSizeA6 CGSizeMake(298 , 420)

UIKIT_EXTERN UIActivityType const UIActivityTypeOpenInSafari;

@interface LWWebViewMoreActivity : UIActivity

@property(nonatomic, strong) NSURL *URL;

@property(nonatomic, strong) UIImage *iphoneImg;
@property(nonatomic, strong) UIImage *ipadImg;

- (instancetype)initWithiphoneImage:(UIImage *)iphoneImg ipadImage:(UIImage *)ipadImg;

@end



UIKIT_EXTERN UIActivityType const UIActivityTypePDFPrintActivity;

@interface LWPDFPrintActivity : UIActivity


@property(nonatomic, strong) UIImage *iphoneImg;
@property(nonatomic, strong) UIImage *ipadImg;

@property(nonatomic, strong) UIView *printView;

@property(nonatomic, copy) NSString *title;

- (instancetype)initWithiphoneImage:(UIImage *)iphoneImg ipadImage:(UIImage *)ipadImg;

@end