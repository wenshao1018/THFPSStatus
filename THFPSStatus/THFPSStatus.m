//
//  THFPSStatus.m
//  Westore
//
//  Created by WenQing on 2017/8/1.
//  Copyright © 2017年 Rainbow Department Store Co., Ltd. All rights reserved.
//

#import "THFPSStatus.h"
#import <UIKit/UIKit.h>

@interface THFPSStatus()

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, assign) NSTimeInterval lastTime;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) UILabel *fpsLabel;

@end


@implementation THFPSStatus

static THFPSStatus *_shareInstance = nil;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.displayLink.paused = YES;
    [self.displayLink removeFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.displayLink invalidate];
    self.displayLink = nil;
}

+ (void)load
{
    @autoreleasepool {
        [self shareInstance];
    }
}

+ (THFPSStatus *)shareInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [[THFPSStatus alloc] init];
    });
    return _shareInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _shareInstance = [super allocWithZone:zone];
    });
    return _shareInstance;
}

- (instancetype)init
{
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActiveNotification) name:UIApplicationDidBecomeActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActiveNotification) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidFinishLaunchingNotification) name:UIApplicationDidFinishLaunchingNotification object:nil];
        
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTimeFired:)];
        self.displayLink.paused = YES;
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        self.fpsLabel = [[UILabel alloc] init];
        self.fpsLabel.frame = CGRectMake(0, 0, 45, 20);
        self.fpsLabel.center = CGPointMake([UIScreen mainScreen].bounds.size.width/2.0+50, 10);
        self.fpsLabel.font = [UIFont boldSystemFontOfSize:12];
        self.fpsLabel.textColor = [UIColor blueColor];
        self.fpsLabel.textAlignment = NSTextAlignmentRight;
        self.fpsLabel.backgroundColor = [UIColor clearColor];
    }
    return self;
}

- (void)displayLinkTimeFired:(CADisplayLink *)displayLink
{
    if (self.lastTime == 0) {
        self.lastTime = displayLink.timestamp;
        return;
    }
    self.count++;
    NSTimeInterval interval = displayLink.timestamp - self.lastTime;
    if (interval < 1.0) {
        return;
    }
    self.lastTime = displayLink.timestamp;
    NSTimeInterval fps = self.count/interval;
    NSInteger fpsInteger = (NSInteger)round(fps);
    self.fpsLabel.text = [NSString stringWithFormat:@"%@ FPS", @(fpsInteger)];
    if (fpsInteger >= 45) {
        self.fpsLabel.textColor = [UIColor blueColor];
    }else {
        self.fpsLabel.textColor = [UIColor redColor];
    }
    self.count = 0;
}

- (void)start
{
#if !DEBUG
    return ;
#endif

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    
    if (!self.window) {
        self.window = [[UIWindow alloc] init];
        self.window.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, 20);
        self.window.windowLevel = UIWindowLevelStatusBar+1.0;
        self.window.backgroundColor = [UIColor clearColor];
        self.window.tag = 1000;
        self.window.hidden = NO;
        self.window.userInteractionEnabled = NO;
    }
    
    [self.window addSubview:self.fpsLabel];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] < 9.0) {
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
    if (!self.displayLink) {
        self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkTimeFired:)];
        [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    self.displayLink.paused = NO;
    
#pragma clang diagnostic pop
}

#pragma mark - Notifications
- (void)applicationDidBecomeActiveNotification
{
    if (self.displayLink) {
        self.displayLink.paused = NO;
    }
}

- (void)applicationWillResignActiveNotification
{
    if (self.displayLink) {
        self.displayLink.paused = YES;
        self.lastTime = 0;
        self.count = 0;
    }
}

- (void)applicationDidFinishLaunchingNotification
{
    __weak typeof(self) weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [weakSelf start];
    });
}

@end
