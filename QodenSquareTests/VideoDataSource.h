#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>

@protocol VideoDataSourceDelegate;

@protocol VideoDataSource<NSObject>

@property (nonatomic, strong) AVSampleBufferDisplayLayer *layer;
@property (nonatomic, weak) id<VideoDataSourceDelegate> delegate;
@property (nonatomic, readonly) float focalLengthX;
@property (nonatomic, readonly) float focalLengthY;

- (void)start;
- (void)stop;

@end

@protocol VideoDataSourceDelegate
- (void)videoDataSource:(id<VideoDataSource>)capture capturedBuffer:(CMSampleBufferRef)sampleBuffer;
@end


@interface DeviceVideoDataSource : NSObject<VideoDataSource>

@property (nonatomic, readonly) float hfov;
@property (nonatomic, readonly) float vfov;
@property (nonatomic, readonly) float aspect;
@property (nonatomic, readonly) float focalLengthX;
@property (nonatomic, readonly) float focalLengthY;

@property (nonatomic) AVCaptureVideoOrientation videoOrientation;

@end

@interface FileVideoDataSource : NSObject<VideoDataSource>

-(instancetype)initWithURL:(NSURL*)url;

@property (readonly, strong) NSURL *url;

@end

@interface ImageFolderVideoDataSource : NSObject<VideoDataSource>

-(instancetype)initWithPath:(NSString*)path;

@end
