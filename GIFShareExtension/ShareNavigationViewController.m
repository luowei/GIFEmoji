//
//  ShareNavigationViewController.m
//  GIFShareExtension
//
//  Created by luowei on 2018/1/26.
//  Copyright © 2018年 Luo Wei. All rights reserved.
//

#import <Photos/Photos.h>
#import "ShareNavigationViewController.h"
#import "FLAnimatedImageView.h"
#import "Masonry.h"
#import "ShareDefines.h"
#import "LWMyUtils.h"
#import "FLAnimatedImage.h"
#import "UIColor+HexValue.h"
#import "ShareCategories.h"

@interface ShareNavigationViewController ()

@end

@implementation ShareNavigationViewController


- (instancetype)init {
    LWShareViewController *vc = [LWShareViewController new];
    self = [super initWithRootViewController:vc];
    if (self) {

    }

    return self;
}

@end



@implementation LWShareViewController

- (void)viewDidLoad {
    [super viewDidLoad];

//    self.navigationController.navigationBar.barStyle = UIBarStyleDefault;
//    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
//            initWithTitle:NSLocalizedString(@"Close", nil) style:UIBarButtonItemStylePlain target:self action:@selector(closeAction)];

    NSDictionary *attributes = @{NSFontAttributeName: [UIFont systemFontOfSize:16], NSForegroundColorAttributeName: [UIColor darkTextColor]};

    //设置NavigationBar为透明，自定义返回按钮
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;

    [self.navigationController.navigationBar setTitleTextAttributes:attributes];
    self.navigationController.navigationBar.tintColor = [UIColor darkTextColor];

    self.navigationController.interactivePopGestureRecognizer.delegate = self;

    //修改箭头图案
    UIImage *backBtnImage = [UIImage imageNamed:@"TitleIcon_Left"];
    [self.navigationController.navigationBar setBackIndicatorImage:backBtnImage];
    [self.navigationController.navigationBar setBackIndicatorTransitionMaskImage:backBtnImage];


    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];

    self.containerView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.containerView];
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.leading.equalTo(self.view.mas_leading).offset(20);
        make.trailing.equalTo(self.view.mas_trailing).offset(-20);
        make.height.mas_equalTo(240);
    }];
    self.containerView.layer.cornerRadius = 3.0f;
    self.containerView.clipsToBounds = YES;
    self.containerView.backgroundColor = [UIColor whiteColor];

    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.containerView addSubview:self.titleLabel];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.text = @"导入Markdown";
    self.titleLabel.font = [UIFont boldSystemFontOfSize:16];
    self.titleLabel.textColor = [UIColor colorWithHexString:@"#7C7C7C"];
    [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView).offset(20);
        make.centerX.equalTo(self.containerView);
    }];

    self.topLine = [[UIView alloc] initWithFrame:CGRectZero];
    [self.containerView addSubview:self.topLine];
    self.topLine.backgroundColor = [[UIColor colorWithHexString:@"#7C7C7C"] colorWithAlphaComponent:0.5];
    [self.topLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.containerView);
        make.top.equalTo(self.containerView).offset(48.5);
        make.height.mas_equalTo(0.5);
    }];

    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    [self.containerView addSubview:self.textView];
    self.textView.editable = NO;
    self.textView.delegate = self;
    self.textView.font = [UIFont systemFontOfSize:16];
    self.textView.textColor = [UIColor colorWithHexString:@"#7C7C7C"];
    self.textView.showsHorizontalScrollIndicator = NO;
    self.textView.contentInset = UIEdgeInsetsMake(6, 10, 6, 10);
    self.textView.contentSize = CGSizeMake(self.textView.frame.size.height - 20, self.textView.contentSize.height);
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView).with.insets(UIEdgeInsetsMake(50, 0, 50, 0));
    }];
    self.textView.text = @"";

    self.imageView = [[FLAnimatedImageView alloc] initWithFrame:CGRectZero];
    [self.containerView addSubview:self.imageView];
    self.imageView.layer.cornerRadius = 5;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.containerView).with.insets(UIEdgeInsetsMake(50, 0, 50, 0));
    }];
    self.imageView.hidden = YES;

    self.bottomLine = [[UIView alloc] initWithFrame:CGRectZero];
    [self.containerView addSubview:self.bottomLine];
    self.bottomLine.backgroundColor = [[UIColor colorWithHexString:@"#7C7C7C"] colorWithAlphaComponent:0.5];
    [self.bottomLine mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.containerView);
        make.bottom.equalTo(self.containerView).offset(-50);
        make.height.mas_equalTo(0.5);
    }];

    self.okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.containerView addSubview:self.okButton];
    [self.okButton setTitle:@"确定" forState:UIControlStateNormal];
    [self.okButton addTarget:self action:@selector(okButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [self.okButton setTitleColor:[UIColor colorWithHexString:@"#4DC7FE"] forState:UIControlStateNormal];
    [self.okButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self.containerView);
        make.top.equalTo(self.bottomLine.mas_bottom).offset(1);
    }];


    //获取数据及内容

    for (NSExtensionItem *eItem in self.extensionContext.inputItems) {

        for (NSItemProvider *itemProvider in eItem.attachments) {

            if (itemProvider) {
                NSArray *registeredTypeIdentifiers = itemProvider.registeredTypeIdentifiers;
                NSLog(@"====registeredTypeIdentifiers: %@ \n first typeIdentifier:%@", registeredTypeIdentifiers, registeredTypeIdentifiers.firstObject);
            }

            //word,pages,numbers,excel等文档
            void (^wordCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item) {
                if ([(NSObject *) item isKindOfClass:[NSURL class]]) {
                    self.imageView.hidden = YES;
                    self.textView.hidden = NO;

                    NSURL *wordFileUrl = (NSURL *) item;
                    NSString *absolutePath = wordFileUrl.path;
                    NSString *fileName = [absolutePath subStringWithRegex:@".*/([^/]*)$" matchIndex:1];
                    self.textView.text = fileName;

                    UIWebView *theWebView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
                    NSURLRequest *request = [NSURLRequest requestWithURL:wordFileUrl];
                    [theWebView loadRequest:request];
                    theWebView.delegate = self;
                    [self.view addSubview:theWebView];

                    self.okButton.enabled = NO;
                    [self.okButton setTitle:@"Loading..." forState:UIControlStateNormal];
                }
            };
            NSArray *wordIdentifers = @[
                    @"public.html",
                    @"com.apple.iwork.pages.sffpages",
                    @"org.openxmlformats.wordprocessingml.document",
                    @"com.microsoft.word.doc",
                    @"public.rtf",
                    @"com.apple.iwork.numbers.sffnumbers",
                    @"org.openxmlformats.spreadsheetml.sheet",
                    @"com.microsoft.excel.xls",
                    @"public.comma-separated-values-text",
                    @"com.apple.iwork.keynote.sffkey",
                    @"org.openxmlformats.presentationml.presentation",
                    @"com.microsoft.powerpoint.ppt"];
            if([self loadItemProvider:itemProvider withIdentifier:wordIdentifers completionBlock:wordCompletionBlock]){
                return;
            }


            //文件 public.file-url
            void (^fileCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                self.imageView.hidden = YES;
                self.textView.hidden = NO;

                if ([(NSObject *) item isKindOfClass:[NSURL class]]) {
                    NSString *absolutePath = ((NSURL *) item).path;
                    NSString *fileName = [absolutePath subStringWithRegex:@".*/([^/]*)$" matchIndex:1];
                    self.textView.text = fileName;

                    NSData *data = [[NSFileManager defaultManager] contentsAtPath:absolutePath];
                    NSString *mimeType = [data mimeType];

                    if ([mimeType isEqualToString:@"text/plain"]) {  //文本
                        //[[UIPasteboard generalPasteboard] setData:data forPasteboardType:@"public.plain-text "];
                        NSString *contents = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                        self.textView.text = [fileName stringByAppendingFormat:@"\n%@", contents];

                    } else if ([mimeType hasPrefix:@"image"]) {
                        self.imageView.hidden = NO;
                        self.textView.hidden = YES;
                        if ([mimeType isEqualToString:@"image/gif"]) {
                            self.imageView.image = nil;
                            self.imageView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                        } else {
                            self.imageView.image = [UIImage imageWithData:data];
                        }
                    } else {
                        self.textView.text = NSLocalizedString(@"Share Data", nil);
                    }
                }
            };
            NSArray *fileIdentifers = @[@"public.file-url"];
            if([self loadItemProvider:itemProvider withIdentifier:fileIdentifers completionBlock:fileCompletionBlock]){
                return;
            }


            //链接
            void (^urlCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                self.imageView.hidden = YES;
                self.textView.hidden = NO;
                if ([(NSObject *) item isKindOfClass:[NSURL class]]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.textView.text = ((NSURL *) item).absoluteString;
                    });
                } else {
                    self.textView.text = NSLocalizedString(@"Share Data", nil);
                }
            };
            NSArray *urlIdentifers = @[@"public.url"];
            if([self loadItemProvider:itemProvider withIdentifier:urlIdentifers completionBlock:urlCompletionBlock]){
                return;
            }


            //文本public.text
            void (^textCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                self.imageView.hidden = YES;
                self.textView.hidden = NO;
                if ([(NSObject *) item isKindOfClass:[NSString class]]) {
                    NSString *text = (NSString *) item;
                    if (text.length > 5000) {
                        text = [[text substringToIndex:5000] stringByAppendingString:@"..."];
                    }
                    self.textView.text = text;
                } else if ([(NSObject *) item isKindOfClass:[NSData class]]) {
                    NSData *data = (NSData *) item;
                    NSString *text = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    if (text.length > 5000) {
                        text = [[text substringToIndex:5000] stringByAppendingString:@"..."];
                    }
                    self.textView.text = text;
                } else {
                    self.textView.text = NSLocalizedString(@"Share Data", nil);
                }
            };
            NSArray *textIdentifers = @[@"public.text"];
            if([self loadItemProvider:itemProvider withIdentifier:textIdentifers completionBlock:textCompletionBlock]){
                return;
            }


            //图片
            void (^imageCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                self.textView.hidden = YES;
                self.imageView.hidden = NO;
                NSData *data = nil;
                if ([(NSObject *) item isKindOfClass:[UIImage class]]) {
                    data = UIImagePNGRepresentation(item);
                } else if ([(NSObject *) item isKindOfClass:[NSData class]]) {
                    data = (NSData *) item;
                } else if ([(NSObject *) item isKindOfClass:[NSURL class]]) {   //路径
                    data = [NSData dataWithContentsOfURL:(NSURL *) item];
                }
                NSString *mimeType = [data mimeType];

                if ([mimeType isEqualToString:@"image/gif"]) {
                    self.imageView.image = nil;
                    self.imageView.animatedImage = [[FLAnimatedImage alloc] initWithAnimatedGIFData:data];
                } else {
                    self.imageView.image = [UIImage imageWithData:data];
                }
            };
            NSArray *imageIdentifers = @[@"public.image"];
            if([self loadItemProvider:itemProvider withIdentifier:imageIdentifers completionBlock:imageCompletionBlock]){
                return;
            }


            //其他 data & content
            void (^otherCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                self.imageView.hidden = YES;
                self.textView.hidden = NO;
                self.textView.text = NSLocalizedString(@"Share Data", nil);
            };
            NSArray *otherIdentifers = @[@"public.data",@"public.content",@"public.item"@"public.database",
                    @"public.calendar-event",@"public.message",@"public.contact",@"public.archive"];
            if([self loadItemProvider:itemProvider withIdentifier:otherIdentifers completionBlock:otherCompletionBlock]){
                return;
            }

        }//第二层for
    }//第一层for

}

//从ItemProvider中取数据
- (BOOL)loadItemProvider:(NSItemProvider *)itemProvider
          withIdentifier:(NSArray <NSString *>*)identifiers
         completionBlock:(void (^)(id <NSSecureCoding> item))completionBlock {

    for(NSString *identifier in identifiers){

//        if ([itemProvider hasItemConformingToTypeIdentifier:@"com.apple.live-photo"]){
//            [itemProvider loadItemForTypeIdentifier:identifier options:nil completionHandler:^(id <NSSecureCoding> item, NSError *error) {
//                dispatch_async(dispatch_get_main_queue(), ^{
//                    if(completionBlock){
//                        completionBlock(item);
//                    }
//                });
//            }];
//            return YES;
//        }

        if ([itemProvider hasItemConformingToTypeIdentifier:identifier]){
            [itemProvider loadItemForTypeIdentifier:identifier options:nil completionHandler:^(id <NSSecureCoding> item, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if(completionBlock){
                        completionBlock(item);
                    }
                });
            }];
            return YES;
        }
    }
    return NO;
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    /* GET TEXT FROM WEB VIEW */
    NSString *text = [webView stringByEvaluatingJavaScriptFromString:@"document.documentElement.innerText"];
    self.textView.text = text;
    self.okButton.enabled = YES;
    [self.okButton setTitle:NSLocalizedString(@"Ok", nil) forState:UIControlStateNormal];

    [UIView animateWithDuration:0.1 animations:^{} completion:^(BOOL finished) {
        [self.containerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self.view);
            make.leading.equalTo(self.view.mas_leading).offset(20);
            make.trailing.equalTo(self.view.mas_trailing).offset(-20);
            make.top.equalTo(self.view).offset(40);
            make.bottom.equalTo(self.view).offset(-40);
        }];
    }];

    //保存数据到App Group
    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:Share_Group];
    [userDefaults setValue:text forKey:Key_SharedText];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    [scrollView setContentOffset:CGPointMake(0.0, scrollView.contentOffset.y)];
}

- (void)okButtonAction {
    for (NSExtensionItem *eItem in self.extensionContext.inputItems) {

        for (NSItemProvider *itemProvider in eItem.attachments) {

            //word,pages,numbers,excel等文档
            void (^wordCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item) {
                if ([(NSObject *) item isKindOfClass:[NSURL class]]) {
                    NSString *urlString = [NSString stringWithFormat:@"%@://share.text?from=native&textKey=%@", Share_Scheme, Key_SharedText];
                    [self openURLWithString:urlString];

                    //执行分享内容处理
                    [self.extensionContext completeRequestReturningItems:@[eItem] completionHandler:nil];
                }
            };
            NSArray *wordIdentifers = @[
                    @"public.html",
                    @"com.apple.iwork.pages.sffpages",
                    @"org.openxmlformats.wordprocessingml.document",
                    @"com.microsoft.word.doc",
                    @"public.rtf",
                    @"com.apple.iwork.numbers.sffnumbers",
                    @"org.openxmlformats.spreadsheetml.sheet",
                    @"com.microsoft.excel.xls",
                    @"public.comma-separated-values-text",
                    @"com.apple.iwork.keynote.sffkey",
                    @"org.openxmlformats.presentationml.presentation",
                    @"com.microsoft.powerpoint.ppt"];
            if([self loadItemProvider:itemProvider withIdentifier:wordIdentifers completionBlock:wordCompletionBlock]){
                return;
            }


            //文件 public.file-url
            void (^fileCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                if ([(NSObject *) item isKindOfClass:[NSURL class]]) {
                    NSString *absolutePath = ((NSURL *) item).path;

                    NSData *data = [[NSFileManager defaultManager] contentsAtPath:absolutePath];
                    NSURL *groupPathURL = [LWMyUtils URLWithGroupName:Share_Group];
                    NSString *fileName = [absolutePath subStringWithRegex:@".*/([^/]*)$" matchIndex:1];
                    NSURL *groupFileURL = [groupPathURL URLByAppendingPathComponent:fileName];

                    BOOL isSuccess = [data writeToURL:groupFileURL atomically:YES];

//                  NSString *str = [NSString stringWithContentsOfURL:groupFileURL encoding:NSUTF8StringEncoding error:nil];    //读取文件
//                  NSLog(@"write group:%@, str = %@",isSuccess?@"YES":@"NO", str);

                    //打开宿主App
                    NSString *subURLString = groupFileURL.path;
                    NSString *subURLText = [subURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    NSString *urlString = [NSString stringWithFormat:@"%@://share.file?from=native&url=%@", Share_Scheme, subURLText];
                    [self openURLWithString:urlString];

                    //执行分享内容处理
                    [self.extensionContext completeRequestReturningItems:@[eItem] completionHandler:nil];
                }
            };
            NSArray *fileIdentifers = @[@"public.file-url"];
            if([self loadItemProvider:itemProvider withIdentifier:fileIdentifers completionBlock:fileCompletionBlock]){
                return;
            }


            //链接
            void (^urlCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item) {
                if ([(NSObject *) item isKindOfClass:[NSURL class]]) {
                    NSURL *url = ((NSURL *) item);
                    //NSCharacterSet *cSet = [NSCharacterSet characterSetWithCharactersInString:@"'();:@&=+$,/?%#[]"];
                    NSString *subURLText = [url.absoluteString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
                    NSString *urlString = [NSString stringWithFormat:@"%@://share.http?from=native&url=%@", Share_Scheme, subURLText];
                    [self openURLWithString:urlString];

                    //执行分享内容处理
                    [self.extensionContext completeRequestReturningItems:@[eItem] completionHandler:nil];
                }
            };
            NSArray *urlIdentifers = @[@"public.url"];
            if([self loadItemProvider:itemProvider withIdentifier:urlIdentifers completionBlock:urlCompletionBlock]){
                return;
            }


            //文本public.text
            void (^textCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                if ([(NSObject *) item isKindOfClass:[NSString class]]) {
                    NSString *text = (NSString *) item;
                    NSUserDefaults *userDefaults = [[NSUserDefaults alloc] initWithSuiteName:Share_Group];
                    [userDefaults setValue:text forKey:Key_SharedText];

                    NSString *urlString = [NSString stringWithFormat:@"%@://share.text?from=native&textKey=%@", Share_Scheme, Key_SharedText];
                    [self openURLWithString:urlString];

                    //执行分享内容处理
                    [self.extensionContext completeRequestReturningItems:@[eItem] completionHandler:nil];

                } else if ([(NSObject *) item isKindOfClass:[NSData class]]) {
                    NSData *data = (NSData *) item;

                    [self handleData:data eItem:eItem]; //处理NSData
                    //执行分享内容处理
                    [self.extensionContext completeRequestReturningItems:@[eItem] completionHandler:nil];
                }
            };
            NSArray *textIdentifers = @[@"public.text"];
            if([self loadItemProvider:itemProvider withIdentifier:textIdentifers completionBlock:textCompletionBlock]){
                return;
            }


            //图片
            void (^imageCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                NSData *data = nil;
                if ([(NSObject *) item isKindOfClass:[UIImage class]]) {
                    data = UIImagePNGRepresentation(item);
                } else if ([(NSObject *) item isKindOfClass:[NSData class]]) {
                    data = (NSData *) item;
                } else if ([(NSObject *) item isKindOfClass:[NSURL class]]) {   //路径
                    data = [NSData dataWithContentsOfURL:(NSURL *) item];
                }

                [self handleData:data eItem:eItem]; //处理NSData

                //执行分享内容处理
                [self.extensionContext completeRequestReturningItems:@[eItem] completionHandler:nil];
            };
            NSArray *imageIdentifers = @[@"public.image"];
            if([self loadItemProvider:itemProvider withIdentifier:imageIdentifers completionBlock:imageCompletionBlock]){
                return;
            }


            //其他 data & content
            void (^otherCompletionBlock)(id <NSSecureCoding>) = ^(id <NSSecureCoding> item){
                NSData *data = nil;
                if ([(NSObject *) item isKindOfClass:[NSData class]]) {
                    data = (NSData *) item;
                } else if ([(NSObject *) item isKindOfClass:[NSURL class]]) {   //路径
                    data = [NSData dataWithContentsOfURL:(NSURL *) item];
                }

                [self handleData:data eItem:eItem]; //处理NSData
                //执行分享内容处理
                [self.extensionContext completeRequestReturningItems:@[eItem] completionHandler:nil];
            };
            NSArray *otherIdentifers = @[@"public.data",@"public.content",@"public.item"@"public.database",
                    @"public.calendar-event",@"public.message",@"public.contact",@"public.archive"];
            if([self loadItemProvider:itemProvider withIdentifier:otherIdentifers completionBlock:otherCompletionBlock]){
                return;
            }


        }//第二层for

        //执行分享内容处理
        [self.extensionContext completeRequestReturningItems:@[eItem] completionHandler:nil];
        return;

    }//第一层for

    [self dismissViewControllerAnimated:YES completion:nil];
}

//处理NSData
- (void)handleData:(NSData *)data eItem:(NSExtensionItem *)eItem {
    NSURL *groupPathURL = [LWMyUtils URLWithGroupName:Share_Group];
    NSString *title = eItem.attributedTitle ? eItem.attributedTitle.string : [LWMyUtils getCurrentTimeStampText];
    NSString *fileName = [title subStringWithRegex:@".*/([^/]*)$" matchIndex:1] ?: title;
    NSURL *groupFileURL = [groupPathURL URLByAppendingPathComponent:fileName];

    BOOL isSuccess = [data writeToURL:groupFileURL atomically:YES];

    NSString *subURLString = groupFileURL.path;
    NSString *subURLText = [subURLString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSString *urlString = [NSString stringWithFormat:@"%@://share.file?from=native&url=%@", Share_Scheme, subURLText];
    [self openURLWithString:urlString];
}


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    CGPoint point = [touches.anyObject locationInView:self.view];
    if (!CGRectContainsPoint(self.containerView.frame, point)) {
        [self.extensionContext cancelRequestWithError:[NSError errorWithDomain:@"CustomShareError" code:NSUserCancelledError userInfo:nil]];
        return;
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
