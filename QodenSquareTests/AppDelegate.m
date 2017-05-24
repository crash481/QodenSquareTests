//
//  AppDelegate.m
//  QodenSquareTests
//
//  Created by morozov on 19.05.17.
//  Copyright © 2017 morozov. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    UIWindow *window = [[UIWindow alloc] initWithFrame: [[UIScreen mainScreen] bounds]];
    window.rootViewController = [ViewController new];
    [window makeKeyAndVisible];
    self.window = window;
    return YES;
}

@end
