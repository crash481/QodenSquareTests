#import "ViewController.h"
#import "MainView.h"
#import <RectTest/RectTester.hpp>

#import <CoreGraphics/CoreGraphics.h>
#import <CoreMedia/CoreMedia.h>


@interface ViewController ()

@property MainView *controllerView;

@property NSArray<id<VideoDataSource>>* dataSources;
@property AVSampleBufferDisplayLayer *layer;
@property NSUInteger activeDataSource;

@end

@implementation ViewController{
    UITapGestureRecognizer *_doubleTap, *_singleTap;
}

-(instancetype)init{
    if(self = [super init]){
        self.controllerView = [MainView new];
        _doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(switchToNextDataSource:)];
        _doubleTap.numberOfTapsRequired = 2;
        
        _singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveToNextItemInDataSource:)];
        _singleTap.numberOfTapsRequired = 1;
        [_singleTap requireGestureRecognizerToFail:_doubleTap];

        
        NSMutableArray *_dataSources = [NSMutableArray new];
        
#ifdef DEBUG
        NSString *path = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test_photos"];
//        NSURL *url = [NSURL fileURLWithPath:[path stringByAppendingPathComponent:@"test.mp4"]];
//        FileVideoDataSource *videoFileDS = [[FileVideoDataSource alloc] initWithURL:url];
//        [_dataSources addObject:videoFileDS];
        
        ImageFolderVideoDataSource *imagesDS = [[ImageFolderVideoDataSource alloc] initWithPath: path];
        [_dataSources addObject:imagesDS];
#endif
        
#if !TARGET_IPHONE_SIMULATOR
        [_dataSources addObject:[DeviceVideoDataSource new]];
#endif
        self.dataSources = [_dataSources copy];
        for (id<VideoDataSource> s in _dataSources) {
            s.delegate = self;
        }
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addGestureRecognizer:_doubleTap];
    [self.view addGestureRecognizer:_singleTap];
    
//    NSString *imgPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"test_photos"] stringByAppendingPathComponent:@"test.jpg"];
//    RectTester rectTester = RectTester(string([imgPath UTF8String]));
//    rectTester.getMat();
//
//    cv::Mat matImage = rectTester.getMat();
//    self.controllerView.imageView.image = [self UIImageFromCVMat:matImage];
    
    [self displayActiveDataSource]; 
    return;
}

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                            //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

- (void)displayActiveDataSource {
    [self.layer removeFromSuperlayer];
    self.layer = _dataSources[self.activeDataSource].layer;
    [self.layer setVideoGravity: AVLayerVideoGravityResizeAspect];
    _layer.frame = self.view.frame;
    [self.view.layer insertSublayer:_layer atIndex:0];
    [self.dataSources[self.activeDataSource] start];
}

- (void)videoDataSource:(id<VideoDataSource>)capture capturedBuffer:(CMSampleBufferRef)sampleBuffer {
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageBuffer, kCMAttachmentMode_ShouldPropagate);
//    CIImage *image = [[CIImage alloc] initWithCVPixelBuffer:imageBuffer options:(__bridge NSDictionary *)attachments];
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    
    
    CVPixelBufferLockBaseAddress(imageBuffer, 0);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    unsigned char *pixel = (unsigned char *)CVPixelBufferGetBaseAddress(imageBuffer);
    cv::Mat cv_image((int) height, (int) width, CV_8UC4, pixel, bytesPerRow);
    
    if(!cv_image.empty()){
        RectTester::RecognizeMarkers(cv_image);
        RectTester::RecognizeAnswers(cv_image);
    }
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)switchToNextDataSource:(UITapGestureRecognizer*)r {
    if (_dataSources.count > 1) {
        [_dataSources[_activeDataSource] stop];
        _activeDataSource = (_activeDataSource + 1) % _dataSources.count;
        [self displayActiveDataSource];
    }
}

- (void)moveToNextItemInDataSource:(UITapGestureRecognizer*)r {
    NSObject* ds = _dataSources[_activeDataSource];
    if ([ds respondsToSelector:@selector(next)]) {
        [ds performSelector:@selector(next)];
    }
}

-(void)loadView{
    [super loadView];
    self.controllerView.frame = self.view.frame;
    self.view = self.controllerView;
}


@end
