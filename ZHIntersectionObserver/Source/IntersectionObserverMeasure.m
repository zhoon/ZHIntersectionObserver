//
//  IntersectionObserverMeasure.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import <objc/runtime.h>
#import "IntersectionObserverMeasure.h"
#import "IntersectionObserver.h"
#import "IntersectionObserverEntry.h"
#import "IntersectionObserverOptions.h"
#import "IntersectionObserverManager.h"
#import "IntersectionObserverReuseManager.h"
#import "UIView+IntersectionObserver.h"

@interface IntersectionObserverContainerOptions (Utils)

@property(nonatomic, assign) BOOL preVisible;

@end


@interface IntersectionObserverTargetOptions (Utils)

@property(nonatomic, assign) CGFloat preRatio;
@property(nonatomic, assign) BOOL preInsecting;
@property(nonatomic, assign) BOOL preVisible;
@property(nonatomic, copy) NSString *preDataKey;
@property(nonatomic, copy) NSDictionary *preData;
@property(nonatomic, assign) BOOL preReuseInsecting;

@end


@implementation IntersectionObserverMeasure

+ (void)measureWithObserver:(IntersectionObserver *)observer {
    [self measureWithObserver:observer forTargetView:nil];
}

+ (void)measureWithObserver:(IntersectionObserver *)observer forTargetView:(UIView * __nullable)targetView {
    // updateDataKey 调用后马上开始重新计算，但是这个时候如果是复用的 view 例如 cell，如果复用前和复用后位置不一样，那么在计算 isInsecting 的时候可能会错误。例如被复用的 view 在复用前是在屏幕外，那么复用的时候计算出来的 isInsecting 就是在屏幕外的，所以需要等待 view 重新布局之后再计算，通过 dispatch_async 使得计算再下个 runloop 再触发
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // 判断是否有 containerOptions
        IntersectionObserverContainerOptions *containerOptions = observer.containerOptions;
        NSString *scope = containerOptions.scope;
        NSMapTable *targetOptions = observer.targetOptions;
        if (!targetOptions || targetOptions.count <= 0) {
            return;
        }
        
        // 获取配置参数值  
        UIView *containerView = containerOptions.containerView;
        UIEdgeInsets rootMargin = containerOptions.rootMargin;
        BOOL delayReport = containerOptions.intersectionDuration > 0;
        
        // 初始化数组
        NSMutableArray *entries = [[NSMutableArray alloc] init];
        NSMutableArray *reusedEntries = [[NSMutableArray alloc] init];
        NSMutableArray *hideEntries = [[NSMutableArray alloc] init];

        for (UIView *target in targetOptions.keyEnumerator) {
            
            // 获取 targetOptions 和 targetView
            IntersectionObserverTargetOptions *options = [targetOptions objectForKey:target];
            UIView *curTargetView = options.targetView;
            
            // targetView 参数有值意味着只需要更新 targetView 对应的曝光状态就好了，其他忽略
            if (targetView && targetView != curTargetView) {
                continue;
            }
            
            // 计算 ratio 和可视区域
            NSDictionary *calcResult = [self calcRatioWithTargetView:curTargetView containerView:containerView rootMargin:rootMargin];
            CGFloat ratio = [[calcResult objectForKey:@"ratio"] doubleValue];
            CGRect viewportTargetRect = [[calcResult objectForKey:@"viewportTargetRect"] CGRectValue];
            CGRect intersectionRect = [[calcResult objectForKey:@"intersectionRect"] CGRectValue];
            
            if (ratio < 0) {
                continue;
            }
            
            // preReuseInsecting 是为了结局一个 view 被复用很多次都没有曝光的情况下，会一直发送 isInsecting = NO 的事件，例如 delayReport 并且快速滚动的时候
            if (options.dataKey && options.dataKey.length > 0 &&
                ![options.dataKey isEqualToString:options.preDataKey] &&
                options.preInsecting &&
                options.preReuseInsecting) {
                IntersectionObserverEntry *entry =
                    [IntersectionObserverEntry initEntryWithTargetView:curTargetView
                                                               dataKey:options.preDataKey
                                                                  data:options.preData
                                                    boundingClientRect:viewportTargetRect
                                                     intersectionRatio:ratio
                                                      intersectionRect:intersectionRect
                                                           isInsecting:NO
                                                            rootBounds:containerView.bounds
                                                                  time:floor([NSDate date].timeIntervalSince1970 * 1000)];
                options.preReuseInsecting = NO;
                [reusedEntries addObject:entry];
                [[IntersectionObserverReuseManager shareInstance] addReusedDataKey:entry.dataKey toScope:scope];
            }
            
            BOOL isInsecting = [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:options];
            BOOL canReport = [self canReportWithRatio:ratio containerOptions:containerOptions targetOptions:options];
            BOOL delayReportEntry = delayReport && isInsecting; // 曝光的 entry 才有 delay 的资格
            
            if (isInsecting && options.dataKey) {
                NSString *dataKey = options.dataKey;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[IntersectionObserverReuseManager shareInstance] removeReuseDataKey:dataKey fromScope:scope];
                });
            }
            
            if (canReport) {
                IntersectionObserverEntry *entry =
                    [IntersectionObserverEntry initEntryWithTargetView:curTargetView
                                                               dataKey:options.dataKey
                                                                  data:options.data
                                                    boundingClientRect:viewportTargetRect
                                                     intersectionRatio:ratio
                                                      intersectionRect:intersectionRect
                                                           isInsecting:isInsecting
                                                            rootBounds:containerView.bounds
                                                                  time:floor([NSDate date].timeIntervalSince1970 * 1000)];
                if (isInsecting) {
                    [entries addObject:entry];
                } else {
                    [hideEntries addObject:entry];
                }
                if (!delayReportEntry) {
                    // 更新各种 pre 值
                    options.preInsecting = isInsecting;
                    options.preReuseInsecting = isInsecting;
                    options.preDataKey = options.dataKey;
                    options.preData = options.data;
                    if (containerOptions.measureWhenVisibilityChanged) {
                        options.preVisible = [self isTargetViewVisible:curTargetView inContainerView:containerView];
                    }
                }
            }
            
            // 非 canReport 也要更新 preRatio
            if (!delayReportEntry) {
                options.preRatio = ratio;
            }
        }
        
        // 更新 pre 值
        if (!delayReport) {
            if (containerOptions.measureWhenVisibilityChanged) {
                containerOptions.preVisible = [self isContainerViewVisible:containerView];
            }
        }
        
        if (hideEntries.count > 0) {
            [[IntersectionObserverReuseManager shareInstance] removeVisibleEntries:hideEntries.copy fromScope:scope];
            if (containerOptions.callback) {
                containerOptions.callback(scope, hideEntries.copy);
            }
        }
        
        if (reusedEntries.count > 0) {
            // 0.2s 之后检查被复用的 view 的 dataKey 是否还是曝光状态
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSMutableArray *filterReusedEntries = [[NSMutableArray alloc] init];
                [reusedEntries enumerateObjectsUsingBlock:^(IntersectionObserverEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
                    BOOL removed = [[IntersectionObserverReuseManager shareInstance] isReusedDataKeyRemoved:entry.dataKey inScope:scope];
                    if (!removed) {
                        [filterReusedEntries addObject:entry];
                        [[IntersectionObserverReuseManager shareInstance] removeReuseDataKey:entry.dataKey fromScope:scope];
                    }
                }];
                [[IntersectionObserverReuseManager shareInstance] removeVisibleEntries:filterReusedEntries.copy fromScope:scope];
                if (containerOptions.callback && filterReusedEntries.count > 0) {
                    containerOptions.callback(scope, filterReusedEntries);
                }
            });
        }
        
        if (entries.count > 0) {
            if (delayReport) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(containerOptions.intersectionDuration / 1000.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self delayMeasureWithObserver:observer entries:entries.copy];
                });
            } else {
                [[IntersectionObserverReuseManager shareInstance] addVisibleEntries:entries.copy toScope:scope];
                if (containerOptions.callback) {
                    containerOptions.callback(scope, entries.copy);
                } else {
                    NSAssert(NO, @"no callback");
                }
            }
        }
        
    });
}

+ (void)delayMeasureWithObserver:(IntersectionObserver *)observer
                         entries:(NSArray <IntersectionObserverEntry *> *)entries {
    
    // 简单判断下当前 options 和 entries
    IntersectionObserverContainerOptions *containerOptions = observer.containerOptions;
    NSString *scope = containerOptions.scope;
    NSMapTable *targetOptions = observer.targetOptions;
    if (!containerOptions || !targetOptions || targetOptions.count <= 0 || entries.count <= 0) return;
    
    // 获取对应的 view
    UIView *containerView = containerOptions.containerView;
    UIEdgeInsets rootMargin = containerOptions.rootMargin;
    
    // 初始化数组
    NSMutableArray *filterEntries = [[NSMutableArray alloc] init];
    
    for (NSInteger i = 0; i < entries.count; i++) {
        IntersectionObserverEntry *oldEntry = entries[i];
        
        // 这里不要判断 targetView 是否 visible
        if (!oldEntry || !oldEntry.targetView) {
            continue;
        }
        
        IntersectionObserverTargetOptions *options = [targetOptions objectForKey:oldEntry.targetView];
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
        BOOL isDataKeyVisible = [[IntersectionObserverReuseManager shareInstance] isDataKeyVisible:options.dataKey inScope:scope];
        BOOL canReport = [oldEntry.dataKey isEqualToString:options.dataKey] && isInsecting == oldEntry.isInsecting && !isDataKeyVisible;
        
        if (!canReport) {
            continue;
        }
        
        IntersectionObserverEntry *entry =
            [IntersectionObserverEntry initEntryWithTargetView:targetView
                                                       dataKey:options.dataKey
                                                          data:oldEntry.data
                                            boundingClientRect:viewportTargetRect
                                             intersectionRatio:ratio
                                              intersectionRect:intersectionRect
                                                   isInsecting:isInsecting
                                                    rootBounds:containerView.bounds
                                                          time:floor([NSDate date].timeIntervalSince1970 * 1000)];
        [filterEntries addObject:entry];
        
        options.preRatio = ratio;
        options.preInsecting = isInsecting;
        options.preReuseInsecting = isInsecting;
        options.preDataKey = options.dataKey;
        options.preData = options.data;
        
        if (containerOptions.measureWhenVisibilityChanged) {
            options.preVisible = [self isTargetViewVisible:targetView inContainerView:containerView];
        }
    }
    
    if (containerOptions.measureWhenVisibilityChanged) {
        containerOptions.preVisible = [self isContainerViewVisible:containerView];
    }
    
    if (filterEntries.count > 0) {
        [[IntersectionObserverReuseManager shareInstance] addVisibleEntries:filterEntries.copy toScope:scope];
        if (containerOptions.callback) {
            containerOptions.callback(scope, filterEntries.copy);
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

+ (BOOL)canReportWithRatio:(CGFloat)ratio
          containerOptions:(IntersectionObserverContainerOptions *)containerOptions
             targetOptions:(IntersectionObserverTargetOptions *)targetOptions {
    
    BOOL isInsecting = [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:targetOptions];
    
    BOOL isDataKeyVisible = targetOptions.dataKey ? [[IntersectionObserverReuseManager shareInstance] isDataKeyVisible:targetOptions.dataKey inScope:containerOptions.scope] : NO;
    
    // 生命周期发生变化
    if (containerOptions.measureWhenAppStateChanged && targetOptions.dataKey) {
        UIApplicationState prevApplicationState = [IntersectionObserverManager shareInstance].previousApplicationState;
        if (prevApplicationState != UIApplicationStateActive &&
            UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            // 重新计算，只要是 isInsecting 即可发送事件。如果没有设置 dataKey，回到前台会多发送一次曝光事件，所以屏蔽一下。
            if (targetOptions.dataKey) {
                return isInsecting;
            }
            return NO;
        }
        if (prevApplicationState != UIApplicationStateBackground &&
            UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            // 直接返回 YES 会导致那些那些一开始没曝光的 item 会发送多 isInsecting = NO 的通知
            // 如果改为 isInsecting != targetOptions.preInsecting 会导致 cell 不复用的情况切换前后台无法触发事件，所以需要通过 updateOptionsPreProperties:fromOldOptions 同步一下 options，但是还是会存在之前非曝光过的被复用到曝光的时候，isInsecting != targetOptions.preInsecting 为 NO（isInsecting 必定为 NO，没曝光的 item 的 targetOptions.preInsecting 也是 NO），导致当前没有发送 isInsecting = NO 事件，所以最后改成 isDataKeyVisible，但是要求设置 dataKey 才能生效。
            return [[IntersectionObserverReuseManager shareInstance] isDataKeyVisible:targetOptions.dataKey inScope:containerOptions.scope];
        }
    }
    
    // 可视状态发生变化
    if (containerOptions.measureWhenVisibilityChanged && targetOptions.dataKey) {
        BOOL targetViewVisible = [self isTargetViewVisible:targetOptions.targetView inContainerView:containerOptions.containerView];
        BOOL containerViewVisible = [self isContainerViewVisible:containerOptions.containerView];
        if (targetViewVisible != targetOptions.preVisible || containerViewVisible != containerOptions.preVisible) {
            return isInsecting != targetOptions.preInsecting;
        }
    }
    
    // 数据发生变化（或者复用）
    if (targetOptions.dataKey && targetOptions.dataKey.length > 0 && ![targetOptions.dataKey isEqualToString:targetOptions.preDataKey]) {
        if (isInsecting) {
            return !isDataKeyVisible;
        } else {
            return isDataKeyVisible;
        }
    }
    
    // 前后 ratio 变化
    if ([self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:targetOptions] !=
        [self isInsectingWithRatio:targetOptions.preRatio containerOptions:containerOptions targetOptions:targetOptions]) {
        return YES;
    }
    
    // 是否达到某个 ratio
    return [self lastMatchThreshold:containerOptions.thresholds ratio:ratio] != [self lastMatchThreshold:containerOptions.thresholds ratio:targetOptions.preRatio];
}

+ (BOOL)isContainerViewVisible:(UIView *)containerView {
    if (containerView.hidden || containerView.alpha <= 0 || !containerView.window) {
        return NO;
    }
    return YES;
}

+ (BOOL)isTargetViewVisible:(UIView *)targetView inContainerView:(UIView *)containerView {
    // TODO: 这里先不要做 hidden 这个判断了，有些场景例如 cell 复用，cell 会临时被 hidden 掉，所以先去掉这个逻辑
    // BOOL flag = targetView.hidden || targetView.alpha <= 0 || !targetView.window;
    BOOL flag = !targetView.window;
    if (flag) return NO;
    BOOL visible = YES;
    while (targetView.superview && targetView.superview != containerView) {
        targetView = targetView.superview;
        // flag = targetView.hidden || targetView.alpha <= 0 || !targetView.window;
        flag = !targetView.window;
        if (flag) {
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
    if (containerOptions.measureWhenVisibilityChanged &&
        ![self isTargetViewVisible:targetOptions.targetView inContainerView:containerOptions.containerView]) {
        return NO;
    }
    if (containerOptions.measureWhenVisibilityChanged &&
        ![self isContainerViewVisible:containerOptions.containerView]) {
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

+ (BOOL)isCGRectValidated:(CGRect)rect {
    BOOL isCGRectNaN = isnan(rect.origin.x) || isnan(rect.origin.y) || isnan(rect.size.width) || isnan(rect.size.height);
    BOOL isCGRectInf = isinf(rect.origin.x) || isinf(rect.origin.y) || isinf(rect.size.width) || isinf(rect.size.height);
    return !CGRectIsNull(rect) && !CGRectIsInfinite(rect) && !isCGRectNaN && !isCGRectInf;
}

+ (void)updateOptionsPreProperties:(IntersectionObserverTargetOptions *)options
                    fromOldOptions:(IntersectionObserverTargetOptions *)oldOptions {
    if (options && oldOptions) {
        options.preRatio = oldOptions.preRatio;
        options.preInsecting = oldOptions.preInsecting;
        options.preVisible = oldOptions.preVisible;
        options.preDataKey = oldOptions.preDataKey;
        options.preData = oldOptions.preData;
        options.preDataKey = oldOptions.preDataKey;
        options.preReuseInsecting = oldOptions.preReuseInsecting;
    }
}

@end


static char kAssociatedObjectKey_UtilsContainerPreVisible;

@implementation IntersectionObserverContainerOptions (Utils)

- (void)setPreVisible:(BOOL)preVisible {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsContainerPreVisible, @(preVisible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)preVisible {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsContainerPreVisible) boolValue];
}

@end


static char kAssociatedObjectKey_UtilsPreRatio;
static char kAssociatedObjectKey_UtilsPreInsecting;
static char kAssociatedObjectKey_UtilsPreReuseInsecting;
static char kAssociatedObjectKey_UtilsPreVisible;
static char kAssociatedObjectKey_UtilsPreDataKey;
static char kAssociatedObjectKey_UtilsPreData;

@implementation IntersectionObserverTargetOptions (Utils)

- (void)setPreRatio:(CGFloat)preRatio {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreRatio, @(preRatio), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (CGFloat)preRatio {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreRatio) doubleValue];
}

- (void)setPreInsecting:(BOOL)preInsecting {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreInsecting, @(preInsecting), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)preInsecting {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreInsecting) boolValue];
}

- (void)setPreReuseInsecting:(BOOL)preReuseInsecting {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreReuseInsecting, @(preReuseInsecting), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)preReuseInsecting {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreReuseInsecting) boolValue];
}

- (void)setPreVisible:(BOOL)preVisible {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreVisible, @(preVisible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)preVisible {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreVisible) boolValue];
}

- (void)setPreDataKey:(NSString *)preDataKey {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreDataKey, preDataKey, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSString *)preDataKey {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreDataKey);
}

- (void)setPreData:(NSDictionary *)preData {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreData, preData, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)preData {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreData);
}

@end
