//
//  ZHExample3ViewController.m
//  ZHIntersectionObserver
//
//  Created by zhoonchen on 2021/7/11.
//

#import "ZHExample3ViewController.h"
#import "IntersectionObserverHeader.h"


@interface ItemView : UIView

@property(nonatomic, copy) NSString *text;

@property(nonatomic, strong) UIView *card;
@property(nonatomic, strong) UILabel *cardLabel;

@end

@implementation ItemView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        
        self.card = [[UIView alloc] init];
        self.card.layer.cornerRadius = 8;
        self.card.backgroundColor = [UIColor orangeColor];
        [self addSubview:self.card];
        
        self.cardLabel = [[UILabel alloc] init];
        self.cardLabel.font = [UIFont systemFontOfSize:50];
        self.cardLabel.textColor = [UIColor whiteColor];
        [self.card addSubview:self.cardLabel];
    }
    return self;
}


- (void)setText:(NSString *)text {
    _text = text;
    self.cardLabel.text = text;
    [self.cardLabel sizeToFit];
    if (self.intersectionObserverTargetOptions) {
        [self.intersectionObserverTargetOptions updateDataKey:text data:@{@"text": text}];
    } else {
        IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example3" dataKey:text data:@{@"text": text} targetView:self];
        self.intersectionObserverTargetOptions = targetOptions;
    }
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.card.frame = self.bounds;
    self.cardLabel.center = CGPointMake(CGRectGetWidth(self.card.bounds) / 2, CGRectGetHeight(self.card.bounds) / 2);
}

@end

@interface ZHExample3ViewController ()

@property(nonatomic, strong) ItemView *view1;
@property(nonatomic, strong) ItemView *view2;
@property(nonatomic, strong) ItemView *view3;
@property(nonatomic, strong) ItemView *view4;
@property(nonatomic, strong) ItemView *view5;
@property(nonatomic, strong) ItemView *view6;

@property(nonatomic, strong) UILabel *logLabel;

@property(nonatomic, strong) UIButton *button;
@property(nonatomic, assign) NSInteger dataCount;

@end

@implementation ZHExample3ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.dataCount = 0;
    
    [self setupIntersectionObserver];
    
    self.view1 = [[ItemView alloc] init];
    [self.view addSubview:self.view1];
    
    self.view2 = [[ItemView alloc] init];
    [self.view addSubview:self.view2];
    
    self.view3 = [[ItemView alloc] init];
    [self.view addSubview:self.view3];
    
    self.view4 = [[ItemView alloc] init];
    [self.view addSubview:self.view4];
    
    self.view5 = [[ItemView alloc] init];
    [self.view addSubview:self.view5];
    
    self.view6 = [[ItemView alloc] init];
    [self.view addSubview:self.view6];
    
    self.button = [[UIButton alloc] init];
    self.button.backgroundColor = [UIColor lightGrayColor];
    self.button.titleLabel.font = [UIFont systemFontOfSize:16];
    self.button.layer.cornerRadius = 8;
    [self.button setTitle:@"换一批" forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(handleChange) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.button];
    
    self.logLabel = [[UILabel alloc] init];
    self.logLabel.font = [UIFont systemFontOfSize:14];
    self.logLabel.textColor = [UIColor grayColor];
    self.logLabel.numberOfLines = 0;
    self.logLabel.text = @"进入界面 0.5 秒后切换数据，曝光时间要求 0.6 秒\n停留时间短（第一批数据）的数据将不会被曝光";
    [self.logLabel sizeToFit];
    [self.view addSubview:self.logLabel];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self setupData];
}

- (void)setupIntersectionObserver {
    
    __weak __typeof(self)weakSelf = self;
    
    IntersectionObserverContainerOptions *containerOptions = [IntersectionObserverContainerOptions initOptionsWithScope:@"Example3" rootMargin:UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0) thresholds:@[@1] containerView:self.view intersectionDuration:600 callback:^(NSString * _Nonnull scope, NSArray<IntersectionObserverEntry *> * _Nonnull entries) {
        
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        NSLog(@"Example3: entries = %@", entries);
        
        for (NSInteger i = 0; i < entries.count; i++) {
            IntersectionObserverEntry *entry = entries[i];
            if (entry.isInsecting) {
                NSString *text = [NSString stringWithFormat:@"曝光: %@ ✓", [entry.data objectForKey:@"text"]];
                NSLog(@"%@", text);
                strongSelf.logLabel.text = [NSString stringWithFormat:@"%@\n%@", text, strongSelf.logLabel.text ?: @""];
            } else {
                NSString *text = [NSString stringWithFormat:@"隐藏: %@ ✕", [entry.data objectForKey:@"text"]];
                NSLog(@"%@", text);
                strongSelf.logLabel.text = [NSString stringWithFormat:@"%@\n%@", text, strongSelf.logLabel.text ?: @""];
            }
        }
        
        [strongSelf.logLabel sizeToFit];
        [strongSelf.view setNeedsLayout];
    }];
    
    self.view.intersectionObserverContainerOptions = containerOptions;
}

- (void)setupData {
    [self handleChange];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self handleChange];
    });
}

- (void)handleChange {
    NSInteger count = 6;
    if (self.isRandom) {
        NSArray *values = [self noRepeatRandomArrayWithMinNum:1 maxNum:20 count:count];
        self.view1.text = [NSString stringWithFormat:@"%@", values[0]];
        self.view2.text = [NSString stringWithFormat:@"%@", values[1]];
        self.view3.text = [NSString stringWithFormat:@"%@", values[2]];
        self.view4.text = [NSString stringWithFormat:@"%@", values[3]];
        self.view5.text = [NSString stringWithFormat:@"%@", values[4]];
        self.view6.text = [NSString stringWithFormat:@"%@", values[5]];
    } else {
        self.view1.text = [NSString stringWithFormat:@"%@", @(self.dataCount * count + 1)];
        self.view2.text = [NSString stringWithFormat:@"%@", @(self.dataCount * count + 2)];
        self.view3.text = [NSString stringWithFormat:@"%@", @(self.dataCount * count + 3)];
        self.view4.text = [NSString stringWithFormat:@"%@", @(self.dataCount * count + 4)];
        self.view5.text = [NSString stringWithFormat:@"%@", @(self.dataCount * count + 5)];
        self.view6.text = [NSString stringWithFormat:@"%@", @(self.dataCount * count + 6)];
        self.dataCount++;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    CGFloat viewSpace = 20;
    CGFloat viewWidth = MIN(120, (CGRectGetWidth(self.view.bounds) - viewSpace * 4) / 3);
    CGFloat left = (CGRectGetWidth(self.view.bounds) - viewWidth * 3 - viewSpace * 2) / 2;
    CGFloat y = CGRectGetMaxY(self.navigationController.navigationBar.frame) + left;
    self.view1.frame = CGRectMake(left, y, viewWidth, viewWidth);
    self.view2.frame = CGRectMake(left + viewWidth + viewSpace, y, viewWidth, viewWidth);
    self.view3.frame = CGRectMake(left + viewWidth * 2 + viewSpace * 2, y, viewWidth, viewWidth);
    y = CGRectGetMaxY(self.view3.frame) + 20;
    self.view4.frame = CGRectMake(left, y, viewWidth, viewWidth);
    self.view5.frame = CGRectMake(left + viewWidth + viewSpace, y, viewWidth, viewWidth);
    self.view6.frame = CGRectMake(left + viewWidth * 2 + viewSpace * 2, y, viewWidth, viewWidth);
    self.button.frame = CGRectMake(left, CGRectGetMaxY(self.view6.frame) + left, CGRectGetWidth(self.view.bounds) - left * 2, 42);
    self.logLabel.frame = CGRectMake(left, CGRectGetMaxY(self.button.frame) + left, CGRectGetWidth(self.view.bounds) - left * 2, CGRectGetHeight(self.logLabel.bounds));
}

// 生成一组不重复的随机数 （随机数的个数为 最大数-最小数）
- (NSArray *)noRepeatRandomArrayWithMinNum:(NSInteger)min maxNum:(NSInteger )max count:(NSInteger)count {
    NSMutableSet *values = [NSMutableSet setWithCapacity:count];
    while (values.count < count) {
        NSInteger value = arc4random() % (max - min + 1) + min;
        [values addObject:[NSNumber numberWithInteger:value]];
    }
    return values.allObjects;
}

@end
