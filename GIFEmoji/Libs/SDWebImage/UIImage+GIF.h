/*
 * This file is part of the SDWebImage package.
 * (c) Olivier Poitrey <rs@dailymotion.com>
 * (c) Laurin Brandner
 *
 * For the full copyright and license information, please view the LICENSE
 * file that was distributed with this source code.
 */

#import "SDWebImageCompat.h"

@interface UIImage (GIF)

/**
 *  Compatibility method - creates an animated UIImage from an NSData, it will only contain the 1st frame image
 */
+ (UIImage *)sd_animatedGIFWithData:(NSData *)data;

/**
 *  Checks if an UIImage instance is a GIF. Will use the `images` array
 */
- (BOOL)isGIF;



/*
 * 从GIFData中取出每一帧构成图片数组
 */
+(NSArray <UIImage *>*)imagesFromGIFData:(NSData *)data;

/*
 * 把图片数组全成为图片数组
 */
+(NSData *)createGIFWithImages:(NSArray <UIImage *>*)images
                          size:(CGSize)imageSize
                     loopCount:(NSUInteger)loopCount
                     delayTime:(float)delayTime
                  gifCachePath:(NSString *)gifCachePath;

/*
 * 把图片数组合成为GIF第2种方法
 */
+(NSData *)createGIFWithImages2:(NSArray <UIImage *>*)images
                           size:(CGSize)imageSize
                      loopCount:(NSUInteger)loopCount
                      delayTime:(float)delayTime
                   gifCachePath:(NSString *)gifCachePath;


@end
