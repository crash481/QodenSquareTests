#import "VideoDataSource.h"
#import <Accelerate/Accelerate.h>
#import <CoreImage/CoreImage.h>

@interface DeviceVideoDataSource () <AVCaptureVideoDataOutputSampleBufferDelegate>
@end

@implementation DeviceVideoDataSource {
    AVCaptureSession *session;
    dispatch_queue_t sampleQueue;
    AVCaptureVideoDataOutput *output;
    AVCaptureDeviceInput *input;
    AVCaptureDevice *device;
    CGSize dimensions;
}
@synthesize layer = _layer;
@synthesize delegate;

- (instancetype)init
{
    self = [super init];
    if (self) {
        session = [AVCaptureSession new];
        _layer = [AVSampleBufferDisplayLayer new];
        sampleQueue = dispatch_queue_create("ru.studiomobile.dlibsample.sampleQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)start
{
    for (AVCaptureDevice *someDevice in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (someDevice.position == AVCaptureDevicePositionBack) {
            device = someDevice;
            break;
        }
    }
    NSAssert(device, @"Must have camera");

    NSError *error;
    input = [[AVCaptureDeviceInput alloc] initWithDevice:device error:&error];
    if (error) {
        NSLog(@"AVCaptureDeviceInput init error: %@", error);
        return;
    }

    output = [AVCaptureVideoDataOutput new];
    [output setSampleBufferDelegate:self queue:sampleQueue];
    output.alwaysDiscardsLateVideoFrames = YES;

    [session beginConfiguration];

    if ([session canAddInput:input]) {
        [session addInput:input];
    }
    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }

    [session commitConfiguration];

    output.videoSettings = @{(NSString *) kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA)};

    self.videoOrientation = AVCaptureVideoOrientationPortrait;

    [session startRunning];
}

-(void)stop {
    [session stopRunning];
}

- (void)setVideoOrientation:(AVCaptureVideoOrientation)videoOrientation
{
    [output connectionWithMediaType:AVMediaTypeVideo].videoOrientation = videoOrientation;
    [output connectionWithMediaType:AVMediaTypeVideo].videoMirrored = NO;
}

- (AVCaptureVideoOrientation)videoOrientation
{
    return [output connectionWithMediaType:AVMediaTypeVideo].videoOrientation;
}

- (float)hfov
{
    return device.activeFormat.videoFieldOfView;
}

- (float)aspect {
    float cx = (float)(dimensions.width) / 2.0f;
    float cy = (float)(dimensions.height) / 2.0f;
    return cy/cx;
}

- (float)vfov {    
    float HFOV = device.activeFormat.videoFieldOfView;
    return HFOV * self.aspect;
}

- (float)focalLengthX {
    return fabsf(((float)dimensions.width) / (2 * tanf(self.hfov / 180 * ((float)M_PI) / 2)));
}

- (float)focalLengthY {
    return fabsf(((float)dimensions.height) / (2 * tanf(self.vfov / 180 * ((float)M_PI) / 2)));
}

#pragma mark - AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    if(self.layer.status == AVQueuedSampleBufferRenderingStatusFailed){
        [self.layer flush];
        return;
    }
    dimensions = CMVideoFormatDescriptionGetPresentationDimensions(device.activeFormat.formatDescription, true, true);
    [self.delegate videoDataSource:self capturedBuffer:sampleBuffer];
    [self.layer enqueueSampleBuffer:sampleBuffer];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didDropSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
}

@end


const float FOCAL_LENGTH_X = 1143.27026;
const float FOCAL_LENGTH_Y = 1219.44165;

@interface FileVideoDataSource ()

@property (readwrite, strong) NSURL *url;

@end

@implementation FileVideoDataSource {
    dispatch_queue_t assetQueue;
    AVAssetReader *_movieReader;
}

@synthesize layer = _layer;
@synthesize delegate;

-(instancetype)initWithURL:(NSURL*)url {
    self = [super init];
    if (self) {
        self.url = url;
        _layer = [AVSampleBufferDisplayLayer new];
        CMTimebaseRef controlTimebase;
        CMTimebaseCreateWithMasterClock( CFAllocatorGetDefault(), CMClockGetHostTimeClock(), &controlTimebase );
        
        _layer.controlTimebase = controlTimebase;
        
        // Set the timebase to the initial pts here
        CMTimebaseSetTime(_layer.controlTimebase, kCMTimeZero);
        CMTimebaseSetRate(_layer.controlTimebase, 1.0);
        assetQueue = dispatch_queue_create("ru.studiomobile.assetQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}


- (void)start {
    if (_movieReader) {
        NSLog(@"Already playing");
        return;
    }
    
    AVURLAsset * asset = [AVURLAsset URLAssetWithURL:self.url options:nil];
    NSError * error = nil;
    _movieReader = [[AVAssetReader alloc] initWithAsset:asset error:&error];
    if (error) {
        NSLog(@"%@", error.localizedDescription);
        return;
    }
    
    [asset loadValuesAsynchronouslyForKeys:@[@"tracks"] completionHandler: ^{
        NSArray* tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
        if (tracks.count > 0) {
            AVAssetTrack* videoTrack = tracks[0];
            
            NSDictionary* videoSettings = @{(NSString*)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA)};
            AVAssetReaderTrackOutput *output = [AVAssetReaderTrackOutput assetReaderTrackOutputWithTrack:videoTrack
                                                                                          outputSettings:videoSettings];
            [_movieReader addOutput:output];
            if([_movieReader startReading]) {
                [self.layer requestMediaDataWhenReadyOnQueue: assetQueue usingBlock: ^{
                    [self readAndEnqueueVideo];
                }];
            }
        }
    }];
}

- (void)readAndEnqueueVideo{
    AVAssetReaderTrackOutput * output = (AVAssetReaderTrackOutput*)[_movieReader.outputs objectAtIndex:0];
    while([self.layer isReadyForMoreMediaData]) {
        if (_movieReader.status == AVAssetReaderStatusReading) {
            __block CMSampleBufferRef buffer = [output copyNextSampleBuffer];
            if (buffer) {
                CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(buffer, YES);
                CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
                CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanFalse);
                
                [self.delegate videoDataSource:self capturedBuffer:buffer];
                [self.layer enqueueSampleBuffer:buffer];
                CFRelease(buffer);
//                [NSThread sleepForTimeInterval:1/24.0f];
            }
        }
    }
}

- (void)stop {
    [self.layer stopRequestingMediaData];
    dispatch_async(assetQueue, ^{
        [_movieReader cancelReading];
        _movieReader = nil;
    });
}

- (float)focalLengthX {
    return FOCAL_LENGTH_X;
}

- (float)focalLengthY {
    return FOCAL_LENGTH_Y;
}

@end

#import <UIKit/UIKit.h>

@interface ImageFolderVideoDataSource()
@property (readwrite, strong) NSString *path;
@end

@implementation ImageFolderVideoDataSource {
    NSString *_path;
    NSArray *_images;
    NSUInteger _idx;
}

@synthesize layer = _layer;
@synthesize delegate;

-(instancetype)initWithPath:(NSString*)path {
    self = [super init];
    if (self) {
        _path = path;
        _layer = [AVSampleBufferDisplayLayer new];
        _idx = 0;
    }
    return self;
}

- (void)start {
    _images = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:self.path error:NULL];
    _idx = -1;
    [self next];
}

- (void)stop {
    
}

- (void)next {
    if (_images.count == 0) return;
    _idx = (_idx + 1) % _images.count;
    UIImage *image = [UIImage imageWithContentsOfFile:[self.path stringByAppendingPathComponent:_images[_idx]]];
    
    CVPixelBufferRef pixelBuffer = [self pixelBufferFromImage:image.CGImage];
    CMSampleBufferRef sampleBuffer = NULL;
    CMSampleTimingInfo timimgInfo = kCMTimingInfoInvalid;
    CMVideoFormatDescriptionRef videoInfo = NULL;
    CMVideoFormatDescriptionCreateForImageBuffer(NULL, pixelBuffer, &videoInfo);
    CMSampleBufferCreateForImageBuffer(kCFAllocatorDefault,
                                       pixelBuffer,
                                       true,
                                       NULL,
                                       NULL,
                                       videoInfo,
                                       &timimgInfo,
                                       &sampleBuffer);
    
    if (sampleBuffer) {
        [self.delegate videoDataSource:self capturedBuffer:sampleBuffer];
        CFArrayRef attachments = CMSampleBufferGetSampleAttachmentsArray(sampleBuffer, YES);
        CFMutableDictionaryRef dict = (CFMutableDictionaryRef)CFArrayGetValueAtIndex(attachments, 0);
        CFDictionarySetValue(dict, kCMSampleAttachmentKey_DisplayImmediately, kCFBooleanTrue);
        [self.layer enqueueSampleBuffer:sampleBuffer];
    }
}

-(CVPixelBufferRef)pixelBufferFromImage:(CGImageRef)image {
    CGSize frameSize = CGSizeMake(CGImageGetWidth(image),
                                  CGImageGetHeight(image));
    NSDictionary *options = @{
                              (NSString*)kCVPixelBufferCGImageCompatibilityKey : @YES,
                              (NSString*)kCVPixelBufferCGBitmapContextCompatibilityKey: @YES
                              };
    CVPixelBufferRef pxbuffer = NULL;
    
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault,
                        frameSize.width,
                        frameSize.height,
                        kCVPixelFormatType_32BGRA,
                        (__bridge CFDictionaryRef)options,
                        &pxbuffer);
    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);
    
    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata,
                                                 frameSize.width,
                                                 frameSize.height,
                                                 8,
                                                 CVPixelBufferGetBytesPerRow(pxbuffer),
                                                 rgbColorSpace,
                                                 (CGBitmapInfo)kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst);
    
    CGContextDrawImage(context,
                       CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)),
                       image);
    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);
    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    return pxbuffer;
}

- (float)focalLengthX {
    return FOCAL_LENGTH_X;
}

- (float)focalLengthY {
    return FOCAL_LENGTH_Y;
}

@end
