//
//  ZHExample1ViewController.m
//  ZHIntersectionObserver
//
//  Created by zhoonchen on 2021/7/8.
//

#import "ZHExample1ViewController.h"
#import "IntersectionObserverHeader.h"

@interface ZHExample1ViewController ()

@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) UIView *targetView;
@property(nonatomic, strong) UILabel *textlabel;

@property(nonatomic, strong) UILabel *leftToplabel;
@property(nonatomic, strong) UILabel *rightToplabel;
@property(nonatomic, strong) UILabel *leftBottomlabel;
@property(nonatomic, strong) UILabel *rightBottomlabel;

@property(nonatomic, strong) UILabel *thresholdsLabel;

@property(nonatomic, strong) UIPanGestureRecognizer *panGesture;

@property(nonatomic, assign) BOOL changingSize;
@property(nonatomic, assign) NSInteger count;
@property(nonatomic, copy) NSArray *thresholds;
@property(nonatomic, assign) NSInteger thresholdIndex;

@end

@implementation ZHExample1ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.thresholds = @[@[@1], @[@0.4, @0.7, @1], @[@0.4], @[@0.25, @0.5, @0.75, @1], @[@0.8]];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self initSubViews];
    [self initIntersectionObserver];
    [self updateNavigationItem];
}

- (void)updateNavigationItem {
    UIBarButtonItem *item1 = [[UIBarButtonItem alloc] initWithTitle:@"修改临界点" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeThresholds)];
    UIBarButtonItem *item2 = [[UIBarButtonItem alloc] initWithTitle:@"修改容器大小" style:UIBarButtonItemStylePlain target:self action:@selector(handleChangeContainerSize)];
    self.navigationItem.rightBarButtonItems = @[item2, item1];
}

- (void)initSubViews {
    
    self.containerView = [[UIView alloc] init];
    self.containerView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    [self.view addSubview:self.containerView];
    
    self.targetView = [[UIView alloc] init];
    self.targetView.backgroundColor = [UIColor orangeColor];
    self.targetView.clipsToBounds = YES;
    self.targetView.layer.cornerRadius = 8;
    [self.containerView addSubview:self.targetView];
    
    self.textlabel = [[UILabel alloc] init];
    self.textlabel.numberOfLines = 0;
    self.textlabel.font = [UIFont systemFontOfSize:14];
    self.textlabel.textColor = [UIColor whiteColor];
    self.textlabel.textAlignment = NSTextAlignmentCenter;
    [self.targetView addSubview:self.textlabel];
    
    self.leftToplabel = [[UILabel alloc] init];
    self.leftToplabel.font = [UIFont boldSystemFontOfSize:14];
    self.leftToplabel.textColor = [UIColor whiteColor];
    self.leftToplabel.textAlignment = NSTextAlignmentCenter;
    self.leftToplabel.backgroundColor = [UIColor brownColor];
    self.leftToplabel.text = @"100%";
    [self.targetView addSubview:self.leftToplabel];
    
    self.leftBottomlabel = [[UILabel alloc] init];
    self.leftBottomlabel.font = [UIFont boldSystemFontOfSize:14];
    self.leftBottomlabel.textColor = [UIColor whiteColor];
    self.leftBottomlabel.textAlignment = NSTextAlignmentCenter;
    self.leftBottomlabel.backgroundColor = [UIColor brownColor];
    self.leftBottomlabel.text = @"100%";
    [self.targetView addSubview:self.leftBottomlabel];
    
    self.rightToplabel = [[UILabel alloc] init];
    self.rightToplabel.font = [UIFont boldSystemFontOfSize:14];
    self.rightToplabel.textColor = [UIColor whiteColor];
    self.rightToplabel.textAlignment = NSTextAlignmentCenter;
    self.rightToplabel.backgroundColor = [UIColor brownColor];
    self.rightToplabel.text = @"100%";
    [self.targetView addSubview:self.rightToplabel];
    
    self.rightBottomlabel = [[UILabel alloc] init];
    self.rightBottomlabel.font = [UIFont boldSystemFontOfSize:14];
    self.rightBottomlabel.textColor = [UIColor whiteColor];
    self.rightBottomlabel.textAlignment = NSTextAlignmentCenter;
    self.rightBottomlabel.backgroundColor = [UIColor brownColor];
    self.rightBottomlabel.text = @"100%";
    [self.targetView addSubview:self.rightBottomlabel];
    
    self.thresholdsLabel = [[UILabel alloc] init];
    self.thresholdsLabel.font = [UIFont systemFontOfSize:15];
    self.thresholdsLabel.textColor = [UIColor blackColor];
    self.thresholdsLabel.textAlignment = NSTextAlignmentCenter;
    self.thresholdsLabel.numberOfLines = 2;
    self.thresholdsLabel.text = [NSString stringWithFormat:@"当前临界点(thresholds): [%@]", [[self.thresholds[0] valueForKey:@"description"] componentsJoinedByString:@", "]];
    [self.view addSubview:self.thresholdsLabel];
    
    self.panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePanGesture:)];
    [self.targetView addGestureRecognizer:self.panGesture];
}

- (void)initIntersectionObserver {
    
    __weak __typeof(self)weakSelf = self;
    
    IntersectionObserverContainerOptions *containerOptions = [IntersectionObserverContainerOptions initOptionsWithScope:@"Example1" rootMargin:UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0) thresholds:self.thresholds[0] intersectionDuration:0 callback:^(NSString * _Nonnull scope, NSArray<IntersectionObserverEntry *> * _Nonnull entries) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        for (NSInteger i = 0; i < entries.count; i++) {
            strongSelf.count++;
            IntersectionObserverEntry *entry = entries[i];
            entry.targetView.backgroundColor = entry.isIntersecting ? [UIColor orangeColor] : [UIColor redColor];
            NSLog(@"Example1: isIntersecting = %@", @(entry.isIntersecting));
            strongSelf.leftToplabel.text = strongSelf.rightToplabel.text = strongSelf.leftBottomlabel.text = strongSelf.rightBottomlabel.text = [NSString stringWithFormat:@"%@%@", @(ceil(entry.intersectionRatio * 100)), @"%"];
            [strongSelf updateLabelText:[NSString stringWithFormat:@"可拖动 \n isIntersecting = %@ \n changeCount = %@", @(entry.isIntersecting), @(strongSelf.count)]];
        }
    }];
    self.containerView.intersectionObserverContainerOptions = containerOptions;

    IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example1" dataKey:@"Example1"];
    self.targetView.intersectionObserverTargetOptions = targetOptions;
}

- (void)handlePanGesture:(UIPanGestureRecognizer *)recognizer {
    if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint location = [recognizer locationInView:self.view];
        if (location.y < 0 || location.y > CGRectGetHeight(self.view.bounds)) {
            return;
        }
        CGPoint translation = [recognizer translationInView:self.view];
        self.targetView.center = CGPointMake(recognizer.view.center.x + translation.x, recognizer.view.center.y + translation.y);
        [recognizer setTranslation:CGPointZero inView:self.view];
    }
}

- (void)updateLabelText:(NSString *)text {
    self.textlabel.text = text;
}

- (void)handleChangeContainerSize {
    self.changingSize = YES;
    [UIView animateWithDuration:0.25 animations:^{
        if (CGRectGetWidth(self.containerView.bounds) < 200) {
            self.containerView.frame = self.view.bounds;
            [self.containerView.intersectionObserverContainerOptions updateRootMargin:UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0)];
        } else {
            if (CGRectGetMinY(self.containerView.frame) == 0) {
                self.containerView.frame = CGRectMake(CGRectGetMinX(self.containerView.frame) + 16, CGRectGetMaxY(self.navigationController.navigationBar.frame) + 30, CGRectGetWidth(self.containerView.bounds) - 32, CGRectGetHeight(self.containerView.bounds) - CGRectGetMaxY(self.navigationController.navigationBar.frame) - 60);
                if (self.containerView.intersectionObserverContainerOptions) {
                    [self.containerView.intersectionObserverContainerOptions updateRootMargin:UIEdgeInsetsZero];
                }
            } else {
                self.containerView.frame = CGRectMake(CGRectGetMinX(self.containerView.frame) + 16, CGRectGetMinY(self.containerView.frame) + 30, CGRectGetWidth(self.containerView.bounds) - 32, CGRectGetHeight(self.containerView.bounds) - 60);
                [self.containerView.intersectionObserverContainerOptions updateRootMargin:UIEdgeInsetsZero];
            }
        }
    } completion:^(BOOL finished) {
        self.changingSize = NO;
    }];
}

- (void)handleChangeThresholds {
    if (self.thresholdIndex == self.thresholds.count - 1) {
        self.thresholdIndex = 0;
    } else {
        self.thresholdIndex++;
    }
    self.thresholdsLabel.text = [NSString stringWithFormat:@"当前临界点(thresholds): [%@]", [[self.thresholds[self.thresholdIndex] valueForKey:@"description"] componentsJoinedByString:@", "]];
    if (self.containerView.intersectionObserverContainerOptions) {
        [self.containerView.intersectionObserverContainerOptions updateThresholds:self.thresholds[self.thresholdIndex]];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (self.changingSize) {
        return;
    }
    if (UIApplication.sharedApplication.applicationState != UIApplicationStateActive) {
        return;
    }
    self.containerView.frame = self.view.bounds;
    self.targetView.frame = CGRectMake(0, 0, 250, 250);
    self.targetView.center = self.containerView.center;
    self.textlabel.frame = self.targetView.bounds;
    self.leftToplabel.frame = CGRectMake(0, 0, 60, 40);
    self.leftBottomlabel.frame = CGRectMake(0, 210, 60, 40);
    self.rightToplabel.frame = CGRectMake(190, 0, 60, 40);
    self.rightBottomlabel.frame = CGRectMake(190, 210, 60, 40);
    self.thresholdsLabel.frame = CGRectMake(0, CGRectGetMaxY(self.navigationController.navigationBar.frame) + 20, CGRectGetWidth(self.view.bounds), 30);
}

- (void)dealloc {
    NSLog(@"example 2 dealloc");
}

@end
