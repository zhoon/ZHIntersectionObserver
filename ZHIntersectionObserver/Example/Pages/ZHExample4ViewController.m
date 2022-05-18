//
//  ZHExample4ViewController.m
//  ZHIntersectionObserver
//
//  Created by zhoonchen on 2022/4/23.
//

#import "ZHExample4ViewController.h"
#import "IntersectionObserverHeader.h"

@interface ZHExample4ViewController ()

@property(nonatomic, strong) UIButton *alphaButton;
@property(nonatomic, strong) UIButton *hiddenButton;
@property(nonatomic, strong) UIButton *removeButton;

@property(nonatomic, strong) UIView *view1;
@property(nonatomic, strong) UIView *view2;
@property(nonatomic, strong) UIView *view3;

@property(nonatomic, strong) UILabel *logLabel;

@end

@implementation ZHExample4ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupIntersectionObserver];
    
    _alphaButton = ({
        UIButton *r = [[UIButton alloc] init];
        r.titleLabel.font = [UIFont systemFontOfSize:16];
        r.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [r setTitle:@"alpha" forState:UIControlStateNormal];
        [r setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [r addTarget:self action:@selector(handleChangeAlpha) forControlEvents:UIControlEventTouchUpInside];
        [r sizeToFit];
        [self.view addSubview:r];
        r;
    });
    
    _hiddenButton = ({
        UIButton *r = [[UIButton alloc] init];
        r.titleLabel.font = [UIFont systemFontOfSize:16];
        r.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [r setTitle:@"hidden" forState:UIControlStateNormal];
        [r setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [r addTarget:self action:@selector(handleChangeHidden) forControlEvents:UIControlEventTouchUpInside];
        [r sizeToFit];
        [self.view addSubview:r];
        r;
    });
    
    _removeButton = ({
        UIButton *r = [[UIButton alloc] init];
        r.titleLabel.font = [UIFont systemFontOfSize:16];
        r.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        [r setTitle:@"remove" forState:UIControlStateNormal];
        [r setTitleColor:UIColor.blueColor forState:UIControlStateNormal];
        [r addTarget:self action:@selector(handleChangeRemove) forControlEvents:UIControlEventTouchUpInside];
        [r sizeToFit];
        [self.view addSubview:r];
        r;
    });
    
    _view1 = ({
        UIView *r = [[UIView alloc] init];
        r.backgroundColor = [UIColor orangeColor];
        IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example4" dataKey:@"Example4_Alpha" data:@{@"text": @"alpha change"}];
        r.intersectionObserverTargetOptions = targetOptions;
        [self.view addSubview:r];
        r;
    });
    
    _view2 = ({
        UIView *r = [[UIView alloc] init];
        r.backgroundColor = [UIColor orangeColor];
        IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example4" dataKey:@"Example4_Hidden" data:@{@"text": @"hidden change"}];
        r.intersectionObserverTargetOptions = targetOptions;
        [self.view addSubview:r];
        r;
    });
    
    _view3 = ({
        UIView *r = [[UIView alloc] init];
        r.backgroundColor = [UIColor orangeColor];
        IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example4" dataKey:@"Example4_Remove" data:@{@"text": @"remove change"}];
        r.intersectionObserverTargetOptions = targetOptions;
        [self.view addSubview:r];
        r;
    });
    
    _logLabel = ({
        UILabel *r = [[UILabel alloc] init];
        r.font = [UIFont systemFontOfSize:16];
        r.textColor = [UIColor grayColor];
        r.numberOfLines = 0;
        r.text = @"点击按钮分别设置 view 的 alpha 值、hidden 状态、addSubView 和 removeFromSupperView";
        [r sizeToFit];
        [self.view addSubview:r];
        r;
    });
}

- (void)setupIntersectionObserver {
    
    __weak __typeof(self)weakSelf = self;
    
    IntersectionObserverContainerOptions *containerOptions = [IntersectionObserverContainerOptions initOptionsWithScope:@"Example4" rootMargin:UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0) thresholds:@[@1] intersectionDuration:300 callback:^(NSString * _Nonnull scope, NSArray<IntersectionObserverEntry *> * _Nonnull entries) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        
        for (NSInteger i = 0; i < entries.count; i++) {
            IntersectionObserverEntry *entry = entries[i];
            if (entry.isIntersecting) {
                NSString *text = [NSString stringWithFormat:@"✅ 曝光：%@", [entry.data objectForKey:@"text"]];
                NSString *newText = [NSString stringWithFormat:@"%@\n%@", text, strongSelf.logLabel.text ?: @""];
                strongSelf.logLabel.text = newText;
            } else {
                NSString *text = [NSString stringWithFormat:@"❌ 隐藏：%@", [entry.data objectForKey:@"text"]];
                NSString *newText = [NSString stringWithFormat:@"%@\n%@", text, strongSelf.logLabel.text ?: @""];
                strongSelf.logLabel.text = newText;
            }
        }
        
        [strongSelf.logLabel sizeToFit];
        [strongSelf.view setNeedsLayout];
    }];
    
    self.view.intersectionObserverContainerOptions = containerOptions;
}

- (void)handleChangeAlpha {
    if (self.view1.alpha == 0) {
        self.view1.alpha = 1;
    } else {
        self.view1.alpha = 0;
    }
}

- (void)handleChangeHidden {
    if (self.view2.hidden) {
        self.view2.hidden = NO;
    } else {
        self.view2.hidden = YES;
    }
}

- (void)handleChangeRemove {
    if (self.view3.superview) {
        [self.view3 removeFromSuperview];
    } else {
        [self.view addSubview:self.view3];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat viewSpace = 20;
    CGFloat viewWidth = MIN(120, (CGRectGetWidth(self.view.bounds) - viewSpace * 4) / 3);
    CGFloat left = (CGRectGetWidth(self.view.bounds) - viewWidth * 3 - viewSpace * 2) / 2;
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame) + left;
    self.view1.frame = CGRectMake(left, y, viewWidth, viewWidth);
    self.alphaButton.frame = CGRectMake(CGRectGetMinX(self.view1.frame), CGRectGetMaxY(self.view1.frame) + 6, CGRectGetWidth(self.view1.bounds), CGRectGetHeight(self.alphaButton.bounds));
    self.view2.frame = CGRectMake(left + viewWidth + viewSpace, y, viewWidth, viewWidth);
    self.hiddenButton.frame = CGRectMake(CGRectGetMinX(self.view2.frame), CGRectGetMaxY(self.view2.frame) + 6, CGRectGetWidth(self.view2.bounds), CGRectGetHeight(self.hiddenButton.bounds));
    self.view3.frame = CGRectMake(left + viewWidth * 2 + viewSpace * 2, y, viewWidth, viewWidth);
    self.removeButton.frame = CGRectMake(CGRectGetMinX(self.view3.frame), CGRectGetMaxY(self.view3.frame) + 6, CGRectGetWidth(self.view3.bounds), CGRectGetHeight(self.removeButton.bounds));
    CGFloat labelWidth = CGRectGetWidth(self.view.bounds) - left * 2;
    CGSize labelSize = [self.logLabel sizeThatFits:CGSizeMake(labelWidth, CGFLOAT_MAX)];
    self.logLabel.frame = CGRectMake(left, CGRectGetMaxY(self.alphaButton.frame) + left, labelWidth, labelSize.height);
}

@end
