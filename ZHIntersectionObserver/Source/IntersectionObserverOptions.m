//
//  IntersectionObserverOptions.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import "IntersectionObserverOptions.h"
#import "IntersectionObserverManager.h"
#import "IntersectionObserverUtils.h"

@interface IntersectionObserverContainerOptions ()

@property(nonatomic, copy ,readwrite) NSString *scope;
@property(nonatomic, weak, readwrite) UIView *containerView;

@property(nonatomic, assign ,readwrite) UIEdgeInsets rootMargin;
@property(nonatomic, copy ,readwrite, nullable) NSArray <NSNumber *> *thresholds;
@property(nonatomic, assign ,readwrite) NSTimeInterval throttle;
@property(nonatomic, assign, readwrite) BOOL measureWhenAppStateChanged;
@property(nonatomic, assign, readwrite) BOOL measureWhenVisibilityChanged;
@property(nonatomic, assign, readwrite) NSTimeInterval intersectionDuration;
@property(nonatomic, copy ,readwrite) IntersectionObserverCallback callback;

@end

@interface IntersectionObserverTargetOptions ()

@property(nonatomic, copy ,readwrite) NSString *scope;
@property(nonatomic, weak, readwrite) UIView *targetView;

@property(nonatomic, copy ,readwrite, nullable) NSDictionary *data;
@property(nonatomic, copy ,readwrite, nullable) NSString *dataKey;

@end

@implementation IntersectionObserverContainerOptions

+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                       containerView:(UIView *)containerView
                            callback:(IntersectionObserverCallback)callback {
    return [self initOptionsWithScope:scope
                           rootMargin:rootMargin
                           thresholds:@[@1]
                             throttle:100
                        containerView:containerView
           measureWhenAppStateChanged:YES
         measureWhenVisibilityChanged:YES
                 intersectionDuration:600
                             callback:callback];
}

+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                          thresholds:(NSArray <NSNumber *> *)thresholds
                       containerView:(UIView *)containerView
                intersectionDuration:(NSTimeInterval)intersectionDuration
                            callback:(IntersectionObserverCallback)callback {
    return [self initOptionsWithScope:scope
                           rootMargin:rootMargin
                           thresholds:thresholds
                             throttle:100
                        containerView:containerView
           measureWhenAppStateChanged:YES
         measureWhenVisibilityChanged:YES
                 intersectionDuration:intersectionDuration
                             callback:callback];
}

+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                          thresholds:(NSArray <NSNumber *> *)thresholds
                            throttle:(NSTimeInterval)throttle
                       containerView:(UIView *)containerView
          measureWhenAppStateChanged:(BOOL)measureWhenAppStateChanged
        measureWhenVisibilityChanged:(BOOL)measureWhenVisibilityChanged
                intersectionDuration:(NSTimeInterval)intersectionDuration
                            callback:(IntersectionObserverCallback)callback {
    if (!scope || scope.length <= 0) {
        NSAssert(NO, @"no scope");
    }
    if (!thresholds || thresholds.count <= 0) {
        NSAssert(NO, @"no threstholds");
    }
    if (!containerView || !callback) {
        NSAssert(NO, @"no containerView or callback");
    }
    IntersectionObserverContainerOptions *options = [[IntersectionObserverContainerOptions alloc] init];
    options.scope = scope;
    options.rootMargin = rootMargin;
    options.thresholds = thresholds;
    options.throttle = throttle;
    options.containerView = containerView;
    options.callback = callback;
    options.intersectionDuration = intersectionDuration;
    options.measureWhenAppStateChanged = measureWhenAppStateChanged;
    options.measureWhenVisibilityChanged = measureWhenVisibilityChanged;
    return options;
}

- (void)updateRootMargin:(UIEdgeInsets)rootMargin {
    if (UIEdgeInsetsEqualToEdgeInsets(rootMargin, self.rootMargin)) {
        return;
    }
    self.rootMargin = rootMargin;
    if (self.containerView) {
        if (self.scope && self.scope.length > 0) {
            [[IntersectionObserverManager shareInstance] emitObserverEvent:self.scope];
        }
    } else {
        NSAssert(NO, @"no containerView");
    }
}

- (void)updateThresholds:(NSArray<NSNumber *> *)thresholds {
    // 新旧 thresholds 简单比较下
    NSString *newThresholdsString = [[thresholds valueForKey:@"description"] componentsJoinedByString:@","];
    NSString *oldThresholdsString = [[self.thresholds valueForKey:@"description"] componentsJoinedByString:@","];
    if ([newThresholdsString isEqualToString:oldThresholdsString]) {
        return;
    }
    self.thresholds = thresholds;
    if (self.containerView) {
        if (self.scope && self.scope.length > 0) {
            [[IntersectionObserverManager shareInstance] emitObserverEvent:self.scope];
        }
    } else {
        NSAssert(NO, @"no containerView");
    }
}

- (void)updateIntersectionDuration:(NSTimeInterval)intersectionDuration {
    if (intersectionDuration == self.intersectionDuration) {
        return;
    }
    self.intersectionDuration = intersectionDuration;
    if (self.containerView) {
        if (self.scope && self.scope.length > 0) {
            [[IntersectionObserverManager shareInstance] emitObserverEvent:self.scope];
        }
    } else {
        NSAssert(NO, @"no containerView");
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@, %p>: scope = %@, rootMargin = %@, thresholds = %@, throttle = %@, containerView = %@, measureWhenAppStateChanged = %@, measureWhenVisibilityChanged = %@, intersectionDuration = %@", self.class, self, _scope, @(_rootMargin), _thresholds, @(_throttle), _containerView, @(_measureWhenAppStateChanged), @(_measureWhenVisibilityChanged), @(_intersectionDuration)];
}

- (void)dealloc {
    NSLog(@"container dealloc");
}

@end

@implementation IntersectionObserverTargetOptions

+ (instancetype)initOptionsWithScope:(NSString *)scope
                          targetView:(UIView *)targetView {
    return [self initOptionsWithScope:scope dataKey:nil data:nil targetView:targetView];
}

+ (instancetype)initOptionsWithScope:(NSString *)scope
                             dataKey:(NSString * __nullable)dataKey
                          targetView:(UIView *)targetView {
    return [self initOptionsWithScope:scope dataKey:dataKey data:nil targetView:targetView];
}

+ (instancetype)initOptionsWithScope:(NSString *)scope
                             dataKey:(NSString * __nullable)dataKey
                                data:(NSDictionary * __nullable)data
                          targetView:(UIView *)targetView {
    if (!scope || scope.length <= 0) {
        NSAssert(NO, @"no scope");
    }
    if (!targetView) {
        NSAssert(NO, @"no targetView");
    }
    IntersectionObserverTargetOptions *options = [[IntersectionObserverTargetOptions alloc] init];
    options.scope = scope;
    options.dataKey = dataKey;
    options.data = data;
    options.targetView = targetView;
    return options;
}

- (void)updateDataKey:(NSString *)dataKey data:(id)data {
    if ([dataKey isEqualToString:self.dataKey]) {
        return;
    }
    self.dataKey = dataKey;
    self.data = data;
    // resetTargetOptions 改为其他地方调用
    // [IntersectionObserverUtils resetTargetOptions:self];
    if (self.targetView) {
        if (self.scope && self.scope.length > 0) {
            NSLog(@"updateDataKey: targetView = %p, dataKey = %@, data = %@", self.targetView, self.dataKey, self.data);
            [[IntersectionObserverManager shareInstance] emitObserverEvent:self.scope forTargetView:self.targetView];
        }
    } else {
        NSAssert(NO, @"no targetView");
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@, %p>: scope = %@, dataKey = %@, data = %@, targetView = %@", self.class, self, _scope, _dataKey, _data, _targetView];
}

- (void)dealloc {
    NSLog(@"target dealloc");
}

@end
