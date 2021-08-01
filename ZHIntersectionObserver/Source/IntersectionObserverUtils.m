//
//  IntersectionObserverUtils.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import <objc/runtime.h>
#import "IntersectionObserverUtils.h"
#import "IntersectionObserver.h"
#import "IntersectionObserverEntry.h"
#import "IntersectionObserverOptions.h"
#import "IntersectionObserverManager.h"

@interface IntersectionObserverContainerOptions (Utils)

@property(nonatomic, assign) BOOL previousVisible;

@end


@interface IntersectionObserverTargetOptions (Utils)

@property(nonatomic, assign) CGFloat previousRatio;
@property(nonatomic, assign) BOOL previousInsecting;
@property(nonatomic, assign) BOOL previousVisible;
@property(nonatomic, copy) NSString *previousDataKey;
@property(nonatomic, copy) NSDictionary *previousData;
@property(nonatomic, assign) BOOL previousFixedInsecting;

@end


@interface IntersectionObserverEntry (Utils)

@property(nonatomic, copy) NSString *dataKey;

@end


@implementation IntersectionObserverUtils

+ (void)measureWithObserver:(IntersectionObserver *)observer {
    [self measureWithObserver:observer forTargetView:nil];
}

+ (void)measureWithObserver:(IntersectionObserver *)observer forTargetView:(UIView * __nullable)targetView {
    
    IntersectionObserverContainerOptions *containerOptions = observer.containerOptions;
    NSMapTable *targetOptions = observer.targetOptions;
    if (!targetOptions || targetOptions.count <= 0) {
        return;
    }
    
    UIView *containerView = containerOptions.containerView;
    UIEdgeInsets rootMargin = containerOptions.rootMargin;
    NSMutableArray *entries = [[NSMutableArray alloc] init];
    NSMutableArray *reusedEntries = [[NSMutableArray alloc] init];
    BOOL delayReport = containerOptions.intersectionDuration > 0;

    for (UIView *target in targetOptions.keyEnumerator) {
        
        IntersectionObserverTargetOptions *options = [targetOptions objectForKey:target];
        if (targetView && targetView != options.targetView) {
            continue;
        }
        
        UIView *curTargetView = options.targetView;
        NSDictionary *calcResult = [self calcRatioWithTargetView:curTargetView containerView:containerView rootMargin:rootMargin];
        CGFloat ratio = [[calcResult objectForKey:@"ratio"] doubleValue];
        CGRect viewportTargetRect = [[calcResult objectForKey:@"viewportTargetRect"] CGRectValue];
        CGRect intersectionRect = [[calcResult objectForKey:@"intersectionRect"] CGRectValue];
        if (ratio < 0) {
            continue;
        }
        
        BOOL isInsecting = [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:options];
        BOOL needReport = [self needReportWithRatio:ratio containerOptions:containerOptions targetOptions:options];
        
        // 复用 view，发送复用前数据的 isInsecting = NO 事件
        if (options.dataKey && options.dataKey.length > 0 && ![options.dataKey isEqualToString:options.previousDataKey] && options.previousFixedInsecting) {
            IntersectionObserverEntry *entry = [IntersectionObserverEntry initEntryWithTarget:curTargetView
                                                                                         data:options.previousData
                                                                           boundingClientRect:viewportTargetRect
                                                                            intersectionRatio:ratio
                                                                             intersectionRect:intersectionRect
                                                                                  isInsecting:NO
                                                                                   rootBounds:containerView.bounds
                                                                                         time:floor([NSDate date].timeIntervalSince1970 * 1000)];
            options.previousFixedInsecting = NO;
            [reusedEntries addObject:entry];
        }
        
        if (needReport) {
            IntersectionObserverEntry *entry = [IntersectionObserverEntry initEntryWithTarget:curTargetView
                                                                                         data:options.data
                                                                           boundingClientRect:viewportTargetRect
                                                                            intersectionRatio:ratio
                                                                             intersectionRect:intersectionRect
                                                                                  isInsecting:isInsecting
                                                                                   rootBounds:containerView.bounds
                                                                                         time:floor([NSDate date].timeIntervalSince1970 * 1000)];
            entry.dataKey = options.dataKey;
            if (!delayReport) {
                options.previousInsecting = isInsecting;
                options.previousFixedInsecting = isInsecting;
                options.previousDataKey = options.dataKey;
                options.previousData = options.data;
                if (containerOptions.measureWhenVisibilityChanged) {
                    options.previousVisible = [self isTargetViewVisible:curTargetView inContainerView:containerView];
                }
            }
            [entries addObject:entry];
        }
        
        if (!delayReport) {
            options.previousRatio = ratio;
        }
    }
    
    if (!delayReport) {
        if (containerOptions.measureWhenVisibilityChanged) {
            containerOptions.previousVisible = [self isContainerViewVisible:containerView];
        }
    }
    
    if (reusedEntries.count > 0) {
        if (containerOptions.callback) {
            containerOptions.callback(containerOptions.scope, reusedEntries);
        } else {
            NSAssert(NO, @"no callback");
        }
    }
    
    if (entries.count > 0) {
        if (delayReport) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(containerOptions.intersectionDuration / 1000.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self delayMeasureWithObserver:observer entries:entries];
            });
        } else {
            if (containerOptions.callback) {
                containerOptions.callback(containerOptions.scope, entries);
            } else {
                NSAssert(NO, @"no callback");
            }
        }
    }
}

+ (void)delayMeasureWithObserver:(IntersectionObserver *)observer entries:(NSArray<IntersectionObserverEntry *> *)entries {
    
    IntersectionObserverContainerOptions *containerOptions = observer.containerOptions;
    NSMapTable *targetOptions = observer.targetOptions;
    if (!targetOptions || targetOptions.count <= 0 || entries.count <= 0) {
        return;
    }
    
    UIView *containerView = containerOptions.containerView;
    UIEdgeInsets rootMargin = containerOptions.rootMargin;
    NSMutableArray *filterEntries = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < entries.count; i++) {
        IntersectionObserverEntry *oldEntry = entries[i];
        
        // 这里不要判断 target 是否 visible
        if (!oldEntry || !oldEntry.target) {
            continue;
        }
        
        IntersectionObserverTargetOptions *options = [targetOptions objectForKey:oldEntry.target];
        if (!options) {
            continue;
        }
        
        UIView *targetView = options.targetView;
        NSDictionary *calcResult = [self calcRatioWithTargetView:targetView containerView:containerView rootMargin:rootMargin];
        CGFloat ratio = [[calcResult objectForKey:@"ratio"] doubleValue];
        CGRect viewportTargetRect = [[calcResult objectForKey:@"viewportTargetRect"] CGRectValue];
        CGRect intersectionRect = [[calcResult objectForKey:@"intersectionRect"] CGRectValue];
        if (ratio < 0) {
            continue;
        }
        
        BOOL isInsecting = [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:options];
        BOOL isInsectingChanged = isInsecting == oldEntry.isInsecting && isInsecting != options.previousInsecting;
        BOOL needReportDelay = [oldEntry.dataKey isEqualToString:options.dataKey] && isInsectingChanged;
        
        if (!needReportDelay) {
            if (needReportDelay) {
                IntersectionObserverEntry *entry = [IntersectionObserverEntry initEntryWithTarget:targetView
                                                                                             data:oldEntry.data
                                                                               boundingClientRect:viewportTargetRect
                                                                                intersectionRatio:ratio
                                                                                 intersectionRect:intersectionRect
                                                                                      isInsecting:NO
                                                                                       rootBounds:containerView.bounds
                                                                                             time:floor([NSDate date].timeIntervalSince1970 * 1000)];
                [filterEntries addObject:entry];
            }
            continue;
        }
        
        IntersectionObserverEntry *entry = [IntersectionObserverEntry initEntryWithTarget:targetView
                                                                                     data:oldEntry.data
                                                                       boundingClientRect:viewportTargetRect
                                                                        intersectionRatio:ratio
                                                                         intersectionRect:intersectionRect
                                                                              isInsecting:isInsecting
                                                                               rootBounds:containerView.bounds
                                                                                     time:floor([NSDate date].timeIntervalSince1970 * 1000)];
        [filterEntries addObject:entry];
        
        options.previousInsecting = isInsecting;
        options.previousFixedInsecting = isInsecting;
        options.previousDataKey = options.dataKey;
        options.previousData = options.data;
        
        if (containerOptions.measureWhenVisibilityChanged) {
            options.previousVisible = [self isTargetViewVisible:targetView inContainerView:containerView];
        }
        
        options.previousRatio = ratio;
    }
    
    if (containerOptions.measureWhenVisibilityChanged) {
        containerOptions.previousVisible = [self isContainerViewVisible:containerView];
    }
    
    if (filterEntries.count > 0) {
        if (containerOptions.callback) {
            containerOptions.callback(containerOptions.scope, filterEntries);
        } else {
            NSAssert(NO, @"no callback");
        }
    }
}

+ (NSDictionary *)calcRatioWithTargetView:(UIView *)targetView
                  containerView:(UIView *)containerView
                     rootMargin:(UIEdgeInsets)rootMargin {
    
    CGFloat ratio = -1;
    
    CGRect convertTargetRect = [targetView convertRect:targetView.bounds toView:containerView];
    CGRect viewportTargetRect = CGRectMake(CGRectGetMinX(convertTargetRect) - containerView.bounds.origin.x, CGRectGetMinY(convertTargetRect) - floor(containerView.bounds.origin.y), CGRectGetWidth(convertTargetRect), CGRectGetHeight(convertTargetRect)); // 没加 floor 有些场景 intersectionRect 会错误，高度少了那么一点点
    
    if (![self isCGRectValidated:viewportTargetRect]) {
        return @{@"ratio": @(ratio)};
    }
    
    CGFloat targetViewSize = CGRectGetWidth(convertTargetRect) * CGRectGetHeight(convertTargetRect);
    if (targetViewSize <= 0) {
        return @{@"ratio": @(ratio)};
    }
    
    CGRect containerViewInsetRect = UIEdgeInsetsInsetRect(CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds)), rootMargin);
    if (![self isCGRectValidated:containerViewInsetRect]) {
        return @{@"ratio": @(ratio)};
    }
    
    CGRect intersectionRect = CGRectIntersection(containerViewInsetRect, viewportTargetRect);
    if (![self isCGRectValidated:intersectionRect]) {
        intersectionRect = CGRectZero;
    }
    
    CGFloat intersectionSize = CGRectGetWidth(intersectionRect) * CGRectGetHeight(intersectionRect);
    ratio = intersectionSize > 0 ? ceil(intersectionSize / targetViewSize * 100) / 100 : 0;
    
    return @{@"ratio": @(ratio), @"viewportTargetRect": @(viewportTargetRect), @"intersectionRect": @(intersectionRect)};
}

+ (BOOL)needReportWithRatio:(CGFloat)ratio
           containerOptions:(IntersectionObserverContainerOptions *)containerOptions
              targetOptions:(IntersectionObserverTargetOptions *)targetOptions {
    
    // 生命周期发生变化
    if (containerOptions.measureWhenAppStateChanged) {
        UIApplicationState prevApplicationState = [IntersectionObserverManager shareInstance].previousApplicationState;
        if (prevApplicationState != UIApplicationStateActive &&
            UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            return targetOptions.previousInsecting != [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:targetOptions];
        }
        if (prevApplicationState != UIApplicationStateBackground &&
            UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            return targetOptions.previousInsecting != [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:targetOptions];
        }
    }
    
    // 可视状态发生变化
    if (containerOptions.measureWhenVisibilityChanged) {
        BOOL targetViewVisible = [self isTargetViewVisible:targetOptions.targetView inContainerView:containerOptions.containerView];
        BOOL containerViewVisible = [self isContainerViewVisible:containerOptions.containerView];
        if (targetViewVisible != targetOptions.previousVisible || containerViewVisible != containerOptions.previousVisible) {
            return targetOptions.previousInsecting != [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:targetOptions];
        }
    }
    
    // 数据发生变化
    if (targetOptions.dataKey && targetOptions.dataKey.length > 0 && targetOptions.previousDataKey && targetOptions.previousDataKey.length > 0 &&
        ![targetOptions.dataKey isEqualToString:targetOptions.previousDataKey]) {
        return YES;
    }
    
    // 前后 ratio 变化
    if ([self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:targetOptions] !=
        [self isInsectingWithRatio:targetOptions.previousRatio containerOptions:containerOptions targetOptions:targetOptions]) {
        return YES;
    }
    
    // 是否达到某个 ratio
    return [self lastMatchThreshold:containerOptions.thresholds ratio:ratio] != [self lastMatchThreshold:containerOptions.thresholds ratio:targetOptions.previousRatio];
}

+ (BOOL)isContainerViewVisible:(UIView *)containerView {
    if (containerView.hidden || containerView.alpha <= 0 || !containerView.window) {
        return NO;
    }
    return YES;
}

+ (BOOL)isTargetViewVisible:(UIView *)targetView inContainerView:(UIView *)containerView {
    if (targetView.hidden || targetView.alpha <= 0 || !targetView.window) {
        return NO;
    }
    BOOL visible = YES;
    while (targetView.superview && targetView.superview != containerView) {
        targetView = targetView.superview;
        if (targetView.hidden || targetView.alpha <= 0 || !targetView.window) {
            visible = NO;
            break;
        }
    }
    return visible;
}

+ (BOOL)isInsectingWithRatio:(CGFloat)ratio
            containerOptions:(IntersectionObserverContainerOptions *)containerOptions
               targetOptions:(IntersectionObserverTargetOptions *)targetOptions {
    if (containerOptions.measureWhenAppStateChanged &&
        UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
        return NO;
    }
    UIView *containerView = containerOptions.containerView;
    UIView *targetView = targetOptions.targetView;
    if (containerOptions.measureWhenVisibilityChanged && ![self isTargetViewVisible:targetView inContainerView:containerView]) {
        return NO;
    }
    if (containerOptions.measureWhenVisibilityChanged && ![self isContainerViewVisible:containerView]) {
        return NO;
    }
    NSArray<NSNumber *> *sortedThresholds = [containerOptions.thresholds sortedArrayUsingSelector:@selector(compare:)];
    CGFloat minThresholds = [sortedThresholds[0] doubleValue];
    return ratio >= minThresholds;
}

+ (CGFloat)lastMatchThreshold:(NSArray<NSNumber *> *)thresholds ratio:(CGFloat)ratio {
    NSArray<NSNumber *> *sortedThresholds = [thresholds sortedArrayUsingSelector:@selector(compare:)];
    CGFloat matchedThreshold = 0;
    for (NSInteger i = 0; i < sortedThresholds.count; i++) {
        CGFloat threshold = [sortedThresholds[i] doubleValue];
        if (ratio >= threshold) {
            matchedThreshold = threshold;
        }
    }
    return matchedThreshold;
}

+ (BOOL)isContainerOptions:(IntersectionObserverContainerOptions *)options1 sameWithOptions:(IntersectionObserverContainerOptions *)options2 {
    if (!options1 && !options2) {
        return YES;
    }
    if (options1 && options2) {
        BOOL isSameScope = [options1.scope isEqualToString:options2.scope];
        BOOL isSameContainerView = options1.containerView == options2.containerView;
        BOOL isSameThrottle = options1.throttle == options2.throttle;
        BOOL isSameRootMargin = UIEdgeInsetsEqualToEdgeInsets(options1.rootMargin, options2.rootMargin);
        BOOL isSameThresholds = [options1.thresholds isEqualToArray:options2.thresholds];
        return isSameScope && isSameContainerView && isSameThrottle && isSameRootMargin && isSameThresholds;
    }
    return NO;
}

+ (BOOL)isTargetOptions:(IntersectionObserverTargetOptions *)options1 sameWithOptions:(IntersectionObserverTargetOptions *)options2 {
    if (!options1 && !options2) {
        return YES;
    }
    if (options1 && options2) {
        BOOL isSameScope = [options1.scope isEqualToString:options2.scope];
        BOOL isSameTarget = options1.targetView == options2.targetView;
        BOOL isSameDataKey = [options1.dataKey isEqualToString:options2.dataKey];
        return isSameScope && isSameTarget && isSameDataKey;
    }
    return NO;
}

+ (void)resetTargetOptions:(IntersectionObserverTargetOptions *)targetOptions {
    if (targetOptions) {
        targetOptions.previousRatio = 0;
        targetOptions.previousVisible = NO;
        targetOptions.previousDataKey = nil;
        targetOptions.previousInsecting = NO;
    }
}

+ (BOOL)isCGRectValidated:(CGRect)rect {
    BOOL isCGRectNaN = isnan(rect.origin.x) || isnan(rect.origin.y) || isnan(rect.size.width) || isnan(rect.size.height);
    BOOL isCGRectInf = isinf(rect.origin.x) || isinf(rect.origin.y) || isinf(rect.size.width) || isinf(rect.size.height);
    return !CGRectIsNull(rect) && !CGRectIsInfinite(rect) && !isCGRectNaN && !isCGRectInf;
}

@end


static char kAssociatedObjectKey_UtilsPreviousRatio;
static char kAssociatedObjectKey_UtilsPreviousInsecting;
static char kAssociatedObjectKey_UtilsPreviousFixedInsecting;
static char kAssociatedObjectKey_UtilsPreviousVisible;
static char kAssociatedObjectKey_UtilsContainerPreviousVisible;
static char kAssociatedObjectKey_UtilsDataKey;
static char kAssociatedObjectKey_UtilsPreviousDataKey;
static char kAssociatedObjectKey_UtilsPreviousData;

@implementation IntersectionObserverContainerOptions (Utils)

- (void)setPreviousVisible:(BOOL)previousVisible {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsContainerPreviousVisible, @(previousVisible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)previousVisible {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsContainerPreviousVisible) boolValue];
}

@end


@implementation IntersectionObserverTargetOptions (Utils)

- (void)setPreviousRatio:(CGFloat)previousRatio {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousRatio, @(previousRatio), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)previousRatio {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousRatio) doubleValue];
}

- (void)setPreviousInsecting:(BOOL)previousInsecting {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousInsecting, @(previousInsecting), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)previousInsecting {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousInsecting) boolValue];
}

- (void)setPreviousFixedInsecting:(BOOL)previousFixedInsecting {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousFixedInsecting, @(previousFixedInsecting), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)previousFixedInsecting {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousFixedInsecting) boolValue];
}

- (void)setPreviousVisible:(BOOL)previousVisible {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousVisible, @(previousVisible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)previousVisible {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousVisible) boolValue];
}

- (void)setPreviousDataKey:(NSString *)previousDataKey {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousDataKey, previousDataKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)previousDataKey {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousDataKey);
}

- (void)setPreviousData:(NSDictionary *)previousData {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousData, previousData, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)previousData {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreviousData);
}

@end


@implementation IntersectionObserverEntry (Utils)

- (void)setDataKey:(NSString *)dataKey {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsDataKey, dataKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)dataKey {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsDataKey);
}

@end