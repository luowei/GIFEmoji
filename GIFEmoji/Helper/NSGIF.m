//
//  NSGIF.m
//  
//  Created by Sebastian Dobrincu
//

#import "NSGIF.h"


#pragma mark - Extracting images from GIF

static void createImagesAndDelays(CGImageSourceRef source, size_t count, CGImageRef imagesOut[count], int delayCentisecondsOut[count]) {
    for (size_t i = 0; i < count; ++i) {
        imagesOut[i] = CGImageSourceCreateImageAtIndex(source, i, NULL);
        delayCentisecondsOut[i] = delayCentisecondsForImageAtIndex(source, i);
    }
}

static int sum(size_t const count, int const *const values) {
    int theSum = 0;
    for (size_t i = 0; i < count; ++i) {
        theSum += values[i];
    }
    return theSum;
}

static NSArray *frameArray(size_t const count, CGImageRef const images[count], int const delayCentiseconds[count], int const totalDurationCentiseconds) {
    int const gcd = vectorGCD(count, delayCentiseconds);
    size_t const frameCount = totalDurationCentiseconds / gcd;
    UIImage *frames[frameCount];
    for (size_t i = 0, f = 0; i < count; ++i) {
        UIImage *const frame = [UIImage imageWithCGImage:images[i]];
        for (size_t j = delayCentiseconds[i] / gcd; j > 0; --j) {
            frames[f++] = frame;
        }
    }
    return [NSArray arrayWithObjects:frames count:frameCount];
}

static int vectorGCD(size_t const count, int const *const values) {
    int gcd = values[0];
    for (size_t i = 1; i < count; ++i) {
        // Note that after I process the first few elements of the vector, `gcd` will probably be smaller than any remaining element.  By passing the smaller value as the second argument to `pairGCD`, I avoid making it swap the arguments.
        gcd = pairGCD(values[i], gcd);
    }
    return gcd;
}

static int pairGCD(int a, int b) {
    if (a < b)
        return pairGCD(b, a);
    while (true) {
        int const r = a % b;
        if (r == 0)
            return b;
        a = b;
        b = r;
    }
}

static int delayCentisecondsForImageAtIndex(CGImageSourceRef const source, size_t const i) {
    int delayCentiseconds = 1;
    CFDictionaryRef const properties = CGImageSourceCopyPropertiesAtIndex(source, i, NULL);
    if (properties) {
        CFDictionaryRef const gifProperties = CFDictionaryGetValue(properties, kCGImagePropertyGIFDictionary);
        if (gifProperties) {
            NSNumber *number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFUnclampedDelayTime);
            if (number == NULL || [number doubleValue] == 0) {
                number = fromCF CFDictionaryGetValue(gifProperties, kCGImagePropertyGIFDelayTime);
            }
            if ([number doubleValue] > 0) {
                // Even though the GIF stores the delay as an integer number of centiseconds, ImageIO “helpfully” converts that to seconds for us.
                delayCentiseconds = (int) lrint([number doubleValue] * 100);
            }
        }
        CFRelease(properties);
    }
    return delayCentiseconds;
}


//对图片进行缩放
CGImageRef ImageWithScale(CGImageRef imageRef, float scale) {

    #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
    CGSize newSize = CGSizeMake(CGImageGetWidth(imageRef)*scale, CGImageGetHeight(imageRef)*scale);
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        return nil;
    }

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGAffineTransform flipVertical = CGAffineTransformMake(1, 0, 0, -1, 0, newSize.height);

    CGContextConcatCTM(context, flipVertical);
    // Draw into the context; this scales the image
    CGContextDrawImage(context, newRect, imageRef);

    //Release old image
    CFRelease(imageRef);
    // Get the resized image from the context and a UIImage
    imageRef = CGBitmapContextCreateImage(context);

    UIGraphicsEndImageContext();
    #endif

    return imageRef;
}

#pragma mark - NSGIF

@implementation NSGIF

// Declare constants
#define timeInterval @(600)
#define tolerance    @(0.01)

typedef NS_ENUM(NSInteger, GIFSize) {
    GIFSizeVeryLow  = 2,
    GIFSizeLow      = 3,
    GIFSizeMedium   = 5,
    GIFSizeHigh     = 7,
    GIFSizeOriginal = 10
};

#pragma mark - Public methods

+ (void)optimalGIFfromVideoURL:(NSURL *)videoURL
                exportedGIFURL:(NSURL *)exportedGIFURL
                frameDelayTime:(float)frameDelayTime
                     loopCount:(int)loopCount
                    completion:(void (^)(NSURL *GifURL))completionBlock {

//    int delayTime = frameDelayTime;
    
    // Create properties dictionaries
    NSDictionary *fileProperties = [self filePropertiesWithLoopCount:loopCount];
    NSDictionary *frameProperties = [self framePropertiesWithDelayTime:frameDelayTime];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];
    
    float videoWidth = [[asset tracksWithMediaType:AVMediaTypeVideo][0] naturalSize].width;
    float videoHeight = [[asset tracksWithMediaType:AVMediaTypeVideo][0] naturalSize].height;
    
    GIFSize optimalSize = GIFSizeMedium;
    if (videoWidth >= 1200 || videoHeight >= 1200)
        optimalSize = GIFSizeVeryLow;
    else if (videoWidth >= 800 || videoHeight >= 800)
        optimalSize = GIFSizeLow;
    else if (videoWidth >= 400 || videoHeight >= 400)
        optimalSize = GIFSizeMedium;
    else if (videoWidth < 400|| videoHeight < 400)
        optimalSize = GIFSizeHigh;
    
    // Get the length of the video in seconds
    float videoLength = (float)asset.duration.value/asset.duration.timescale;
    int framesPerSecond = 4;
    int frameCount = (int) (videoLength*framesPerSecond);
    
    // How far along the video track we want to move, in seconds.
    float increment = (float)videoLength/frameCount;
    
    // Add frames to the buffer
    NSMutableArray *timePoints = [NSMutableArray array];
    for (int currentFrame = 0; currentFrame<frameCount; ++currentFrame) {
        float seconds = (float)increment * currentFrame;
        CMTime time = CMTimeMakeWithSeconds(seconds, [timeInterval intValue]);
        [timePoints addObject:[NSValue valueWithCMTime:time]];
    }
    
    // Prepare group for firing completion block
    dispatch_group_t gifQueue = dispatch_group_create();
    dispatch_group_enter(gifQueue);
    
    __block NSURL *gifURL;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        gifURL = [self createGIFforTimePoints:timePoints
                                      fromURL:videoURL
                               exportedGIFURL:exportedGIFURL
                               fileProperties:fileProperties
                              frameProperties:frameProperties
                                   frameCount:frameCount
                                      gifSize:optimalSize];
        
        dispatch_group_leave(gifQueue);
    });
    
    dispatch_group_notify(gifQueue, dispatch_get_main_queue(), ^{
        // Return GIF URL
        completionBlock(gifURL);
    });

}

+ (void)createGIFfromURL:(NSURL*)videoURL
        exportedGIFURL:(NSURL *)exportedGIFURL
          withFrameCount:(int)frameCount
               delayTime:(int)delayTime
               loopCount:(int)loopCount
              completion:(void(^)(NSURL *GifURL))completionBlock {
    
    // Convert the video at the given URL to a GIF, and return the GIF's URL if it was created.
    // The frames are spaced evenly over the video, and each has the same duration.
    // delayTime is the amount of time for each frame in the GIF.
    // loopCount is the number of times the GIF will repeat. Defaults to 0, which means repeat infinitely.
    
    // Create properties dictionaries
    NSDictionary *fileProperties = [self filePropertiesWithLoopCount:loopCount];
    NSDictionary *frameProperties = [self framePropertiesWithDelayTime:delayTime];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:videoURL];

    // Get the length of the video in seconds
    float videoLength = (float)asset.duration.value/asset.duration.timescale;
    
    // How far along the video track we want to move, in seconds.
    float increment = (float)videoLength/frameCount;
    
    // Add frames to the buffer
    NSMutableArray *timePoints = [NSMutableArray array];
    for (int currentFrame = 0; currentFrame<frameCount; ++currentFrame) {
        float seconds = (float)increment * currentFrame;
        CMTime time = CMTimeMakeWithSeconds(seconds, [timeInterval intValue]);
        [timePoints addObject:[NSValue valueWithCMTime:time]];
    }

    // Prepare group for firing completion block
    dispatch_group_t gifQueue = dispatch_group_create();
    dispatch_group_enter(gifQueue);
    
    __block NSURL *gifURL;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

        gifURL = [self createGIFforTimePoints:timePoints
                                      fromURL:videoURL
                               exportedGIFURL:exportedGIFURL
                               fileProperties:fileProperties
                              frameProperties:frameProperties
                                   frameCount:frameCount
                                      gifSize:GIFSizeMedium];

        dispatch_group_leave(gifQueue);
    });
    
    dispatch_group_notify(gifQueue, dispatch_get_main_queue(), ^{
        // Return GIF URL
        completionBlock(gifURL);
    });
    
}

#pragma mark - Base methods

+ (NSURL *)createGIFforTimePoints:(NSArray *)timePoints
                          fromURL:(NSURL *)vedioURL
                   exportedGIFURL:(NSURL *)exportedGIFURL
                   fileProperties:(NSDictionary *)fileProperties
                  frameProperties:(NSDictionary *)frameProperties
                       frameCount:(int)frameCount
                          gifSize:(GIFSize)gifSize{
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef)exportedGIFURL, kUTTypeGIF , (size_t) frameCount, NULL);
    
    if (exportedGIFURL == nil)
        return nil;

    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:vedioURL options:nil];
    AVAssetImageGenerator *generator = [AVAssetImageGenerator assetImageGeneratorWithAsset:asset];
    generator.appliesPreferredTrackTransform = YES;
    
    CMTime tol = CMTimeMakeWithSeconds([tolerance floatValue], [timeInterval intValue]);
    generator.requestedTimeToleranceBefore = tol;
    generator.requestedTimeToleranceAfter = tol;
    
    NSError *error = nil;
   CGImageRef previousImageRefCopy = nil;
    for (NSValue *time in timePoints) {
        CGImageRef imageRef;
        
        #if TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR
            if((float)gifSize/10 != 1){ //对图片进行缩放
                imageRef = ImageWithScale([generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error], (float)gifSize/10);
            } else{
                imageRef = [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
            }
        #elif TARGET_OS_MAC
            imageRef = [generator copyCGImageAtTime:[time CMTimeValue] actualTime:nil error:&error];
        #endif
        
        if (error) {
            NSLog(@"Error copying image: %@", error);
        }
        if (imageRef) {
            CGImageRelease(previousImageRefCopy);
            previousImageRefCopy = CGImageCreateCopy(imageRef);
        } else if (previousImageRefCopy) {
            imageRef = CGImageCreateCopy(previousImageRefCopy);
        } else {
            NSLog(@"Error copying image and no previous frames to duplicate");
            return nil;
        }
        CGImageDestinationAddImage(destination, imageRef, (__bridge CFDictionaryRef)frameProperties);
        CGImageRelease(imageRef);
    }
    CGImageRelease(previousImageRefCopy);
    
    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef)fileProperties);
    // Finalize the GIF
    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to finalize GIF destination: %@", error);
        return nil;
    }
    CFRelease(destination);
    
    return exportedGIFURL;
}

#pragma mark - Helpers

#pragma mark - Properties

+ (NSDictionary *)filePropertiesWithLoopCount:(int)loopCount {
    return @{(NSString *)kCGImagePropertyGIFDictionary:
                @{(NSString *)kCGImagePropertyGIFLoopCount: @(loopCount)}
             };
}

+ (NSDictionary *)framePropertiesWithDelayTime:(float)delayTime {

    return @{(NSString *)kCGImagePropertyGIFDictionary:
                @{(NSString *)kCGImagePropertyGIFDelayTime: @(delayTime)},
                (NSString *)kCGImagePropertyColorModel:(NSString *)kCGImagePropertyColorModelRGB
            };
}


@end


@implementation LWGIFManager{
}


//把 Video 转换成 GIF
+ (void)convertVideoToImages:(NSURL *)videoFileURL
        exportedGIFURL:(NSURL *)exportedGIFURL
              frameDelayTime:(float)frameDelayTime
                             completionBlock:(void(^)(NSArray <UIImage *>*images))completionBlock {

    [NSGIF optimalGIFfromVideoURL:videoFileURL
            exportedGIFURL:exportedGIFURL
                   frameDelayTime:frameDelayTime
                        loopCount:0
                       completion:^(NSURL *GifURL) {

        NSLog(@"Finished generating GIF: %@", GifURL);
        NSData *imageData = [NSData dataWithContentsOfURL:GifURL];

        CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) imageData, NULL);
        size_t const count = CGImageSourceGetCount(source);
        CGImageRef images[count];
        int delayCentiseconds[count]; // in centiseconds

        createImagesAndDelays(source, count, images, delayCentiseconds);
        float const totalDurationCentiseconds = sum(count, delayCentiseconds);

        //float gifDelayTime = (float) (totalDurationCentiseconds / (count * 100));
        NSArray <UIImage *> *imageFrames = frameArray(count, images, delayCentiseconds, (const int) totalDurationCentiseconds);
        if (completionBlock) {
            //隐藏提示弹窗,把images设置到ImageView
            completionBlock(imageFrames);
        }
    }];
}


//根据已有的 GIFFrames 导出GIF图片，返回GIF图片地址
+ (NSString *)exportAnimatedGifWithImages:(NSArray <UIImage *>*)imageList gifDelayTime:(float) gifDelayTime {
    NSString *path = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:@"animated.gif"];

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL((__bridge CFURLRef) [NSURL fileURLWithPath:path],
            kUTTypeGIF,
            [imageList count],
            NULL);

    NSDictionary *frameProperties = @{
            (NSString *) kCGImagePropertyGIFDictionary: @{(NSString *) kCGImagePropertyGIFDelayTime: @(gifDelayTime)}
    };

    NSDictionary *gifProperties = @{
            (NSString *) kCGImagePropertyGIFDictionary: @{(NSString *) kCGImagePropertyGIFLoopCount: @0}
    };

    for (int i = 0; i < [imageList count]; i++) {
        UIImage *bgImage = imageList[i];

        UIGraphicsBeginImageContextWithOptions(bgImage.size, FALSE, 0.0);
        [bgImage drawInRect:CGRectMake(0, 0, bgImage.size.width, bgImage.size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        CGImageDestinationAddImage(destination, newImage.CGImage, (__bridge CFDictionaryRef) frameProperties);

    }

    CGImageDestinationSetProperties(destination, (__bridge CFDictionaryRef) gifProperties);
    CGImageDestinationFinalize(destination);
    CFRelease(destination);


    NSLog(@"animated GIF file created at %@", path);

    return path;
}


@end
