/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Laurin Brandner
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "UIImage+GIF.h"
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "objc/runtime.h"
#import "NSImage+WebCache.h"
#import "NSData+ImageContentType.h"

@implementation UIImage (GIF)

+ (UIImage *)sd_animatedGIFWithData:(NSData *)data {
    if (!data) {
        return nil;
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);

    size_t count = CGImageSourceGetCount(source);

    UIImage *staticImage;

    if (count <= 1) {
        staticImage = [[UIImage alloc] initWithData:data];
    } else {
        // we will only retrieve the 1st frame. the full GIF support is available via the FLAnimatedImageView category.
        // this here is only code to allow drawing animated images as static ones
#if SD_WATCH
        CGFloat scale = 1;
        scale = [WKInterfaceDevice currentDevice].screenScale;
#elif SD_UIKIT
        CGFloat scale = 1;
        scale = [UIScreen mainScreen].scale;
#endif

        CGImageRef CGImage = CGImageSourceCreateImageAtIndex(source, 0, NULL);
#if SD_UIKIT || SD_WATCH
        UIImage *frameImage = [UIImage imageWithCGImage:CGImage scale:scale orientation:UIImageOrientationUp];
        staticImage = [UIImage animatedImageWithImages:@[frameImage] duration:0.0f];
#elif SD_MAC
        staticImage = [[UIImage alloc] initWithCGImage:CGImage size:NSZeroSize];
#endif
        CGImageRelease(CGImage);
    }

    CFRelease(source);

    return staticImage;
}

- (BOOL)isGIF {
    return (self.images != nil);
}


/*
 * 把一张图片按长宽等比例缩放到适应指定大小
 */
- (UIImage *)scaleKeepAspectToSize:(CGSize)size {
    UIGraphicsBeginImageContext(size);

    CGFloat ws = size.width / self.size.width;
    CGFloat hs = size.height / self.size.height;

    if (ws > hs) {
        ws = hs / ws;
        hs = 1.0;
    } else {
        hs = ws / hs;
        ws = 1.0;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(context, 0.0, size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    CGContextDrawImage(context, CGRectMake(size.width / 2 - (size.width * ws) / 2,
            size.height / 2 - (size.height * hs) / 2, size.width * ws,
            size.height * hs), self.CGImage);

    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return scaledImage;
}


/*
 * 从GIFData中取出每一帧构成图片数组
 */
+ (NSArray <UIImage *> *)imagesFromGIFData:(NSData *)data {
    if (!data) {
        return nil;
    }

    SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:data];
    if (imageFormat != SDImageFormatGIF) {
        return nil;
    }

    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);

    size_t count = CGImageSourceGetCount(source);

    if (count <= 1) {
        UIImage *staticImage = [[UIImage alloc] initWithData:data];
        return @[staticImage];
    } else {
        CGFloat scale = 1;
        scale = [UIScreen mainScreen].scale;

        NSMutableArray <UIImage *> *images = @[].mutableCopy;
        for (NSUInteger i = 0; i < count; i++) {
            @autoreleasepool {
                CGImageRef CGImage = CGImageSourceCreateImageAtIndex(source, i, NULL);
                UIImage *frameImage = [UIImage imageWithCGImage:CGImage scale:scale orientation:UIImageOrientationUp];
                [images addObject:frameImage];
                CGImageRelease(CGImage);
            }
        }
        return images;
    }
}

/*
 * 把图片数组全成为图片数组
 */
+ (NSData *)createGIFWithImages:(NSArray <UIImage *> *)images
                           size:(CGSize)imageSize
                      loopCount:(NSUInteger)loopCount
                      delayTime:(float)delayTime
                   gifCachePath:(NSString *)gifCachePath {

    if (!images || images.count < 1) {
        return nil;
    }
    if (images.count == 1) {
        return UIImagePNGRepresentation(images.firstObject);
    }

    @autoreleasepool {
        NSDictionary *fileProperties = @{
                (__bridge id) kCGImagePropertyGIFDictionary: @{
                        (__bridge id) kCGImagePropertyGIFLoopCount: @(loopCount), // 0 means loop forever
                }
        };

        NSDictionary *frameProperties = @{
                (__bridge id) kCGImagePropertyGIFDictionary: @{
                        (__bridge id) kCGImagePropertyGIFDelayTime: @(delayTime < 0.001f ? 0.01f : delayTime), // a float (not double!) in seconds, rounded to centiseconds in the GIF data
                }
        };

        NSURL *fileURL = [NSURL fileURLWithPath:gifCachePath];

        CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef) fileURL, kUTTypeGIF, images.count, NULL);
        CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef) fileProperties);

        for (NSUInteger i = 0; i < images.count; i++) {
            UIImage *image = [images[i] scaleKeepAspectToSize:imageSize];
            //image = [image convertImageRGB];
            CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef) frameProperties);
        }

        if (destination) {
            BOOL isFinalize=NO;
            @try {
                isFinalize = CGImageDestinationFinalize(destination);
            }
            @catch (NSException *exception) {
                NSLog(@"Exception occurred: %@, %@", exception, [exception userInfo]);
            }
            if (!isFinalize) {
                NSLog(@"failed to finalize image destination");
            }
            CFRelease(destination);
        }
        NSLog(@"url=%@", fileURL);  //GIF图片地址为fileURL
    }
    NSData *gifData = [NSData dataWithContentsOfFile:gifCachePath];
    return gifData;
}

- (UIImage *)convertImageRGB {
    UIGraphicsBeginImageContext(self.size);
    [self drawInRect:CGRectMake(0, 0, self.size.width, self.size.height)];

    UIImage *targetImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return targetImage;
}

/*
 * 把图片数组合成为GIF第2种方法
 */
+ (NSData *)createGIFWithImages2:(NSArray <UIImage *> *)images
                            size:(CGSize)imageSize
                       loopCount:(NSUInteger)loopCount
                       delayTime:(float)delayTime
                    gifCachePath:(NSString *)gifCachePath {
    if (!images || images.count < 1) {
        return nil;
    }
    if (images.count == 1) {
        return UIImagePNGRepresentation(images.firstObject);
    }

    //图像目标
    CGImageDestinationRef destination;


    //创建CFURL对象
    /*
    CFURLCreateWithFileSystemPath(CFAllocatorRef allocator, CFStringRef filePath, CFURLPathStyle pathStyle, Boolean isDirectory)
    allocator : 分配器,通常使用kCFAllocatorDefault
    filePath : 路径
    pathStyle : 路径风格,我们就填写kCFURLPOSIXPathStyle 更多请打问号自己进去帮助看
    isDirectory : 一个布尔值,用于指定是否filePath被当作一个目录路径解决时相对路径组件
    */
    CFURLRef url = CFURLCreateWithFileSystemPath(kCFAllocatorDefault, (__bridge CFStringRef) gifCachePath, kCFURLPOSIXPathStyle, false);

    //通过一个url返回图像目标
    destination = CGImageDestinationCreateWithURL(url, kUTTypeGIF, images.count, NULL);

    //设置gif信息
    NSDictionary *gifProperties = @{
            (NSString *) kCGImagePropertyGIFDictionary: @{
                    (NSString *) kCGImagePropertyGIFHasGlobalColorMap: @YES,
                    (NSString *) kCGImagePropertyColorModel: (NSString *) kCGImagePropertyColorModelRGB,
                    (NSString *) kCGImagePropertyDepth: @16.0F,
                    (NSString *) kCGImagePropertyGIFLoopCount: @(delayTime),
            }.mutableCopy
    };

    //设置gif的信息,播放间隔时间,基本数据,和delay时间
    NSDictionary *frameProperties = @{
            (NSString *) kCGImagePropertyGIFDictionary: [@{(NSString *) kCGImagePropertyGIFDelayTime: @(delayTime)} mutableCopy]
    };

    //合成gif
    for (UIImage *dImg in images) {
        UIImage *image = [dImg scaleKeepAspectToSize:imageSize];
        CGImageDestinationAddImage(destination, image.CGImage, (__bridge CFDictionaryRef) frameProperties);
    }
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef) gifProperties);
    CGImageDestinationFinalize(destination);

    NSData *gifData = [NSData dataWithContentsOfFile:gifCachePath];

    SDImageFormat imageFormat = [NSData sd_imageFormatForImageData:gifData];

    return gifData;
}


@end
