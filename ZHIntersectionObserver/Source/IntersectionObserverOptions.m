//
//  IntersectionObserverOptions.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import "IntersectionObserverOptions.h"
#import "IntersectionObserverManager.h"
#import "IntersectionObserverMeasure.h"
#import "IntersectionObserverReuseManager.h"

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

// 这类 options 在 dealloc 的时候不要清理 IntersectionObserverReuseManager 相关数据
@property(nonatomic, strong) NSNumber *notCleanWhenDealloc;

@end

@implementation IntersectionObserverContainerOptions

+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                            callback:(IntersectionObserverCallback)callback {
    return [self initOptionsWithScope:scope
                           rootMargin:rootMargin
                           thresholds:@[@1]
                             throttle:100
           measureWhenAppStateChanged:YES
         measureWhenVisibilityChanged:YES
                 intersectionDuration:600
                             callback:callback];
}

+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                          thresholds:(NSArray <NSNumber *> *)thresholds
                intersectionDuration:(NSTimeInterval)intersectionDuration
                            callback:(IntersectionObserverCallback)callback {
    return [self initOptionsWithScope:scope
                           rootMargin:rootMargin
                           thresholds:thresholds
                             throttle:100
           measureWhenAppStateChanged:YES
         measureWhenVisibilityChanged:YES
                 intersectionDuration:intersectionDuration
                             callback:callback];
}

+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                          thresholds:(NSArray <NSNumber *> *)thresholds
                            throttle:(NSTimeInterval)throttle
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
    if (!callback) {
        NSAssert(NO, @"no callback");
    }
    IntersectionObserverContainerOptions *options = [[IntersectionObserverContainerOptions alloc] init];
    options.scope = scope;
    options.rootMargin = rootMargin;
    options.thresholds = thresholds;
    options.throttle = throttle;
    options.callback = callback;
    options.intersectionDuration = intersectionDuration;
    options.measureWhenAppStateChanged = measureWhenAppStateChanged;
    options.measureWhenVisibilityChanged = measureWhenVisibilityChanged;
    return options;
}

- (BOOL)isEqual:(id)object {
    if (!object || ![object isKindOfClass:[IntersectionObserverContainerOptions class]]) {
        return NO;
    }
    IntersectionObserverContainerOptions *options = (IntersectionObserverContainerOptions *)object;
    if (self == options) {
        return YES;
    }
    if (self && options) {
        if ([self.scope isEqualToString:options.scope] &&
            [self.thresholds isEqualToArray:options.thresholds] &&
            self.containerView == options.containerView &&
            self.throttle == options.throttle &&
            self.intersectionDuration == options.intersectionDuration &&
            self.measureWhenAppStateChanged == options.measureWhenAppStateChanged &&
            self.measureWhenVisibilityChanged == options.measureWhenVisibilityChanged &&
            UIEdgeInsetsEqualToEdgeInsets(self.rootMargin, options.rootMargin)) {
            return YES;
        }
        return NO;
    }
    return NO;
}

- (void)updateRootMargin:(UIEdgeInsets)rootMargin {
    if (UIEdgeInsetsEqualToEdgeInsets(rootMargin, self.rootMargin)) {
        return;
    }
    self.rootMargin = rootMargin;
    if (self.containerView) {
        if (self.scope && self.scope.length > 0) {
            [[IntersectionObserverManager shareInstance] emitObserverEventWithScope:self.scope];
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
            [[IntersectionObserverManager shareInstance] emitObserverEventWithScope:self.scope];
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
            [[IntersectionObserverManager shareInstance] emitObserverEventWithScope:self.scope];
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
                             dataKey:(NSString * __nullable)dataKey {
    return [self initOptionsWithScope:scope dataKey:dataKey data:nil];
}

+ (instancetype)initOptionsWithScope:(NSString *)scope
                             dataKey:(NSString * __nullable)dataKey
                                data:(NSDictionary * __nullable)data {
    if (!scope || scope.length <= 0) {
        NSAssert(NO, @"no scope");
    }
    IntersectionObserverTargetOptions *options = [[IntersectionObserverTargetOptions alloc] init];
    options.scope = scope;
    options.dataKey = dataKey;
    options.data = data;
    return options;
}

- (BOOL)isEqual:(id)object {
    if (!object || ![object isKindOfClass:[IntersectionObserverTargetOptions class]]) {
        return NO;
    }
    IntersectionObserverTargetOptions *options = (IntersectionObserverTargetOptions *)object;
    if (self && options) {
        if ([self.scope isEqualToString:options.scope] &&
            self.dataKey == options.dataKey &&
            self.targetView == options.targetView) {
            return YES;
        }
        return NO;
    }
    return NO;
}

- (void)updateDataKey:(NSString *)dataKey data:(id)data {
    /* 复用场景的情况下可能会复用跟之前同一个 cell，导致这里被返回了
    if ([dataKey isEqualToString:self.dataKey]) {
        return;
    } */
    if (!dataKey || !data) {
        NSAssert(NO, @"no dataKey or data");
        return;
    }
    self.dataKey = dataKey;
    self.data = data;
    if (self.targetView) {
        if (self.scope && self.scope.length > 0) {
            // NSLog(@"updateDataKey: view = %p, dataKey = %@", self.targetView, self.dataKey);
            [[IntersectionObserverManager shareInstance] emitObserverEventWithScope:self.scope forTargetView:self.targetView];
        }
    } else {
        NSAssert(NO, @"no targetView");
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@, %p>: scope = %@, dataKey = %@, data = %@, targetView = %@", self.class, self, _scope, _dataKey, _data, _targetView];
}

- (void)dealloc {
    if (!_notCleanWhenDealloc) {
        if (_dataKey && _dataKey.length > 0 && _scope && _scope.length > 0) {
            [[IntersectionObserverReuseManager shareInstance] removeReuseDataKey:_dataKey fromScope:_scope];
            [[IntersectionObserverReuseManager shareInstance] removeVisibleDataKey:_dataKey fromScope:_scope];
            [[IntersectionObserverReuseManager shareInstance] removeRatioFromDataKey:_dataKey fromScope:_scope];
        }
    }
    NSLog(@"target dealloc");
}

@end
