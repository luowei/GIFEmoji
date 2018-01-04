//
//  NSGIF.h
//
//  Created by Sebastian Dobrincu
//

#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>
#import <ImageIO/ImageIO.h>
#import <AVFoundation/AVFoundation.h>

#if __has_feature(objc_arc)
#define toCF (__bridge CFTypeRef)
#define fromCF (__bridge id)
#else
#define toCF (CFTypeRef)
#define fromCF (id)
#endif

//把ImageSource 转存到 imageOut 数组，并输出delayCentisecondsOut， delayCentisecondsOut：每一帧之间的时隙数组
static void createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count]);

//对values中的前count个元素求和
static int sum(size_t const count, int const *const values);

//从 images 数组中取出 count 帧，delayCentiseconds：每一帧之间的时隙数组；totalDurationCentiseconds：总时长
static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds);

static int vectorGCD(size_t const count, int const *const values);

static int pairGCD(int a, int b);

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i);


#if TARGET_OS_IPHONE
    #import <MobileCoreServices/MobileCoreServices.h>
    #import <UIKit/UIKit.h>
#elif TARGET_OS_MAC
    #import <CoreServices/CoreServices.h>
    #import <WebKit/WebKit.h>
#endif


#pragma mark - NSGIF

@interface NSGIF : NSObject

+ (void)optimalGIFfromVideoURL:(NSURL *)videoURL loopCount:(int)loopCount completion:(void(^)(NSURL *GifURL))completionBlock;

+ (void)createGIFfromURL:(NSURL*)videoURL withFrameCount:(int)frameCount delayTime:(int)delayTime loopCount:(int)loopCount completion:(void(^)(NSURL *GifURL))completionBlock;

@end


@interface LWGIFManager : NSObject

//把 Video 转换成 GIF
+ (void)convertVideoToImages:(NSURL *)videoFileURL
             completionBlock:(void(^)(NSArray <UIImage *>*images,float gifDelayTime))completionBlock;

//根据已有的 GIFFrames 导出GIF图片，返回GIF图片地址
+ (NSString *)exportAnimatedGifWithImages:(NSArray <UIImage *>*)imageList gifDelayTime:(float) gifDelayTime;

@end