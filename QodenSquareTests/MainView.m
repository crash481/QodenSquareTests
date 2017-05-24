#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MainView.h"



@implementation MainView

-(instancetype)init{
    if(self = [super init]){
        self.backgroundColor = [UIColor whiteColor];
        self.imageView = [UIImageView new];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        self.imageView.backgroundColor = [UIColor greenColor];
        self.imageView.userInteractionEnabled = false;
//        [self addSubview:self.imageView];
        
        self.mainPart = [UIView new];
        self.mainPart.backgroundColor = [UIColor greenColor];
//        [self addSubview:self.mainPart];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    self.imageView.frame = self.frame;
}

@end
