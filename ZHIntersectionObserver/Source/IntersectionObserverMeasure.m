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

#define NotEmptyString(str) (str && str.length > 0)

@interface IntersectionObserverContainerOptions (Utils)

@property(nonatomic, assign) BOOL preVisible;

@end


@interface IntersectionObserverTargetOptions (Utils)

@property(nonatomic, assign) BOOL preVisible;
@property(nonatomic, copy) NSString *preDataKey;
@property(nonatomic, copy) NSDictionary *preData;

@end


@implementation IntersectionObserverMeasure

+ (void)measureWithObserver:(IntersectionObserver *)observer {
    [self measureWithObserver:observer forTargetView:nil];
}

+ (void)measureWithObserver:(IntersectionObserver *)observer forTargetView:(UIView * __nullable)targetView {
    
    // updateDataKey 调用后马上开始重新计算，但是这个时候如果是复用的 view 例如 cell，如果复用前和复用后位置不一样，那么在计算 isInsecting 的时候可能会错误。例如被复用的 view 在复用前是在屏幕外，那么复用的时候计算出来的 isInsecting 就是在屏幕外的，所以需要等待 view 重新布局之后再计算，通过 dispatch_async 使得计算再下个 runloop 再触发
    dispatch_async(dispatch_get_main_queue(), ^{
        
        IntersectionObserverContainerOptions *containerOptions = observer.containerOptions;
        NSMapTable *targetOptions = observer.targetOptions;
        if (!containerOptions || !targetOptions || targetOptions.count <= 0) {
            return;
        }
        
        NSString *scope = containerOptions.scope;
        UIView *containerView = containerOptions.containerView;
        UIEdgeInsets rootMargin = containerOptions.rootMargin;
        BOOL delayReport = containerOptions.intersectionDuration > 0;
        
        // 初始化数组
        NSMutableArray *entries = [[NSMutableArray alloc] init];
        NSMutableArray *reusedEntries = [[NSMutableArray alloc] init];
        NSMutableArray *hideEntries = [[NSMutableArray alloc] init];
        
        // NSLog(@"=================");
        
        /*
        NSMutableArray *logDataKeys = [[NSMutableArray alloc] init];
        for (UIView *target in targetOptions.keyEnumerator) {
            IntersectionObserverTargetOptions *options = [targetOptions objectForKey:target];
            if (NotEmptyString(options.dataKey)) {
                [logDataKeys addObject:[NSString stringWithFormat:@"%@ %p", options.dataKey, target]];
            }
        }
        NSLog(@"current dataKeys: %@", [logDataKeys componentsJoinedByString:@", "]);
        */

        for (UIView *target in targetOptions.keyEnumerator) {
            
            // 获取 targetOptions 和 targetView
            IntersectionObserverTargetOptions *options = [targetOptions objectForKey:target];
            UIView *curTargetView = options.targetView;
            
            // targetView 参数有值意味着只需要更新 targetView 对应的曝光状态就好了，其他忽略
            if (targetView && targetView != curTargetView) {
                continue;
            }
            
            // 计算 ratio 和 rect
            NSDictionary *calcResult = [self calcRatioWithTargetView:curTargetView containerView:containerView rootMargin:rootMargin];
            CGFloat ratio = [[calcResult objectForKey:@"ratio"] doubleValue];
            CGRect viewportTargetRect = [[calcResult objectForKey:@"viewportTargetRect"] CGRectValue];
            CGRect intersectionRect = [[calcResult objectForKey:@"intersectionRect"] CGRectValue];
            
            BOOL isReused = NO;
            BOOL isInsecting = [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:options];
            
            void (^delayRemoveReuseDataKey)(void) = ^void() {
                NSString *dataKey = options.dataKey;
                // 之所以 delay remove，是因为这个时候对应的 dataKey 还没 add 进复用池中
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    // NSLog(@"removeReuseDataKey %@ aaa", dataKey);
                    [[IntersectionObserverReuseManager shareInstance] removeReuseDataKey:dataKey fromScope:scope];
                });
            };
            
            // 收集被复用的正在显示的 view（dataKey），delay 一定时间后检查这个 view 是否对应的旧 dataKay 还在显示，没有显示则发送 hide 的通知
            if (NotEmptyString(options.dataKey) && NotEmptyString(options.preDataKey) && ![options.dataKey isEqualToString:options.preDataKey]) {
                if ([[IntersectionObserverReuseManager shareInstance] isDataKeyVisible:options.preDataKey inScope:scope]) {
                    // TODO: 有没有可能 throttle 太大导致服用之后旧的 dataKey 没有 hide 通知，因为还没等到检查 reusedEntries 这个 options 就被销毁了
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
                    // 把被复用的 dataKey 添加到一个复用池中
                    [reusedEntries addObject:entry];
                    // NSLog(@"zhoon reuse manager add current %@", options.dataKey);
                    [[IntersectionObserverReuseManager shareInstance] addReusedDataKey:entry.dataKey toScope:scope];
                }
                // 不能放到上面 if 里面，否则当可视的 dataKey1 复用了不可视的 dataKey3，可视的 dataKey1 不会走 remove，
                // 从而导致这个可视的 dataKey1 被可视的 dataKey2 复用之后加入复用池后没有被移除，所以会收到多余的 hide 事件通知
                if (isInsecting) {
                    // 被复用并且 isInsecting = YES 需要延迟移除，避免收到 hide 事件通知
                    isReused = YES;
                    delayRemoveReuseDataKey();
                }
            }
            
            BOOL canReport = [self canReportWithRatio:ratio containerOptions:containerOptions targetOptions:options];
            
            if (canReport) {
                if (!isReused) {
                    // 非复用（例如滚动触发）的这里才延迟移除，否则会导致多移除从而 hide 事件没有通知
                    delayRemoveReuseDataKey();
                }
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
                    // NSLog(@"showEntry %@", options.dataKey);
                    [entries addObject:entry];
                } else {
                    // NSLog(@"hideEntry %@", options.dataKey);
                    if ([[IntersectionObserverReuseManager shareInstance] isDataKeyVisible:entry.dataKey inScope:scope]) {
                        [hideEntries addObject:entry];
                        // NSLog(@"removeReuseDataKey %@ bbb", entry.dataKey);
                        [[IntersectionObserverReuseManager shareInstance] removeReuseDataKey:entry.dataKey fromScope:scope];
                    }
                }
            } else {
                // NSLog(@"notReport %@", options.dataKey);
            }
            
            if (!canReport || !delayReport) {
                options.preDataKey = options.dataKey;
                options.preData = options.data;
            }
            
            // NSLog(@"write ratio %@ %@ aaa", options.dataKey, @(ratio));
            options.preVisible = [self isTargetViewVisible:curTargetView inContainerView:containerView];
            [[IntersectionObserverReuseManager shareInstance] addRatio:ratio toDataKey:options.dataKey toScope:scope];
        }
        
        containerOptions.preVisible = [self isContainerViewVisible:containerView];
        
        if (hideEntries.count > 0) {
            // 更新曝光池里面的数据
            [[IntersectionObserverReuseManager shareInstance] removeVisibleEntries:hideEntries.copy fromScope:scope];
            if (containerOptions.callback) {
                containerOptions.callback(scope, hideEntries.copy);
            }
        }
        
        if (reusedEntries.count > 0) {
            // 0.2s 之后检查被复用的 view 的 dataKey 是否还是曝光状态
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSMutableArray *filterReusedEntries = [[NSMutableArray alloc] init];
                NSMutableArray *testArrary = [[NSMutableArray alloc] init];
                [reusedEntries enumerateObjectsUsingBlock:^(IntersectionObserverEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
                    BOOL removed = [[IntersectionObserverReuseManager shareInstance] isReusedDataKeyRemoved:entry.dataKey inScope:scope];
                    if (!removed) {
                        [testArrary addObject:entry.dataKey];
                        [filterReusedEntries addObject:entry];
                        // NSLog(@"removeReuseDataKey %@ ccc", entry.dataKey);
                        [[IntersectionObserverReuseManager shareInstance] removeReuseDataKey:entry.dataKey fromScope:scope];
                    }
                }];
                NSLog(@"filterReusedEntries %@ %@", @(filterReusedEntries.count), testArrary);
                if (filterReusedEntries.count > 0) {
                    [[IntersectionObserverReuseManager shareInstance] removeVisibleEntries:filterReusedEntries.copy fromScope:scope];
                    if (containerOptions.callback) {
                        containerOptions.callback(scope, filterReusedEntries);
                    }
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
        
        BOOL isInsecting = [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:options];
        BOOL isDataKeyVisible = [[IntersectionObserverReuseManager shareInstance] isDataKeyVisible:oldEntry.dataKey inScope:scope];
        BOOL canReport = [oldEntry.dataKey isEqualToString:options.dataKey] && isInsecting == oldEntry.isInsecting && !isDataKeyVisible;
        
        // 不需要更新 ratio，都是 delay 前就更新了
        options.preDataKey = options.dataKey;
        options.preData = options.data;
        
        if (canReport) {
            IntersectionObserverEntry *entry =
                [IntersectionObserverEntry initEntryWithTargetView:targetView
                                                           dataKey:oldEntry.dataKey
                                                              data:oldEntry.data
                                                boundingClientRect:viewportTargetRect
                                                 intersectionRatio:ratio
                                                  intersectionRect:intersectionRect
                                                       isInsecting:isInsecting
                                                        rootBounds:containerView.bounds
                                                              time:floor([NSDate date].timeIntervalSince1970 * 1000)];
            [filterEntries addObject:entry];
            // NSLog(@"removeReuseDataKey %@ ddd", entry.dataKey);
            [[IntersectionObserverReuseManager shareInstance] removeReuseDataKey:entry.dataKey fromScope:scope];
        }
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
    
    CGFloat ratio = 0;
    
    CGRect convertTargetRect = [targetView convertRect:targetView.bounds toView:containerView];
    CGRect viewportTargetRect = CGRectMake(CGRectGetMinX(convertTargetRect) - containerView.bounds.origin.x, CGRectGetMinY(convertTargetRect) - floor(containerView.bounds.origin.y), CGRectGetWidth(convertTargetRect), CGRectGetHeight(convertTargetRect)); // 没加 floor 有些场景 intersectionRect 会错误，高度少了那么一点点
    
    if (![self isCGRectValidated:viewportTargetRect]) {
        return @{@"ratio": @(ratio), @"viewportTargetRect": @(CGRectZero), @"intersectionRect": @(CGRectZero)};
    }
    
    CGFloat targetViewSize = CGRectGetWidth(convertTargetRect) * CGRectGetHeight(convertTargetRect);
    if (targetViewSize <= 0) {
        return @{@"ratio": @(ratio), @"viewportTargetRect": @(CGRectZero), @"intersectionRect": @(CGRectZero)};
    }
    
    CGRect containerViewInsetRect = UIEdgeInsetsInsetRect(CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds)), rootMargin);
    if (![self isCGRectValidated:containerViewInsetRect]) {
        return @{@"ratio": @(ratio), @"viewportTargetRect": @(CGRectZero), @"intersectionRect": @(CGRectZero)};
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
    
    CGFloat preRatio = [[IntersectionObserverReuseManager shareInstance] ratioForDataKey:targetOptions.dataKey inScope:containerOptions.scope];
    BOOL isInsecting = [self isInsectingWithRatio:ratio containerOptions:containerOptions targetOptions:targetOptions];
    BOOL isDataKeyVisible = targetOptions.dataKey ? [[IntersectionObserverReuseManager shareInstance] isDataKeyVisible:targetOptions.dataKey inScope:containerOptions.scope] : NO;
    
    // 生命周期发生变化
    if (containerOptions.measureWhenAppStateChanged && NotEmptyString(targetOptions.dataKey)) {
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
            // 如果改为 isInsecting != preInsecting 会导致 cell 不复用的情况切换前后台无法触发事件，所以需要通过 updateOptionsPreProperties:fromOldOptions 同步一下 options，但是还是会存在之前非曝光过的被复用到曝光的时候，isInsecting != preInsecting 为 NO（isInsecting 必定为 NO，没曝光的 item 的 preInsecting 也是 NO），导致当前没有发送 isInsecting = NO 事件，所以最后改成 isDataKeyVisible，但是要求设置 dataKey 才能生效。
            return [[IntersectionObserverReuseManager shareInstance] isDataKeyVisible:targetOptions.dataKey inScope:containerOptions.scope];
        }
    }
    
    // 可视状态发生变化
    if (containerOptions.measureWhenVisibilityChanged && NotEmptyString(targetOptions.dataKey)) {
        BOOL targetViewVisible = [self isTargetViewVisible:targetOptions.targetView inContainerView:containerOptions.containerView];
        BOOL containerViewVisible = [self isContainerViewVisible:containerOptions.containerView];
        if (targetViewVisible != targetOptions.preVisible || containerViewVisible != containerOptions.preVisible) {
            return isInsecting ? !isDataKeyVisible : isDataKeyVisible;
        }
    }
    
    // 数据发生变化（或者复用）
    if (NotEmptyString(targetOptions.dataKey) && NotEmptyString(targetOptions.preDataKey) && ![targetOptions.dataKey isEqualToString:targetOptions.preDataKey]) {
        // NSLog(@"数据变化 dataChange %@ %@ %@", targetOptions.dataKey, @(isInsecting), @(isDataKeyVisible));
        return isInsecting ? !isDataKeyVisible : isDataKeyVisible;
    }
    
    // 前后 ratio 变化
    BOOL preInsecting = [self isInsectingWithRatio:preRatio containerOptions:containerOptions targetOptions:targetOptions];
    if (isInsecting != preInsecting) {
        // NSLog(@"前后 ratio 变化 %@ %@ %@ %@", targetOptions.dataKey, @(ratio), @(preRatio), @(isDataKeyVisible));
        return isInsecting ? !isDataKeyVisible : isDataKeyVisible;
    }
    
    // 是否达到某个 ratio
    BOOL reachRatio = [self lastMatchThreshold:containerOptions.thresholds ratio:ratio] != [self lastMatchThreshold:containerOptions.thresholds ratio:preRatio];
    // NSLog(@"达到 reachRatio %@ %@ %@ %@ %@", targetOptions.dataKey, @(ratio), @(preRatio), @(isInsecting), @(reachRatio));
    return reachRatio;
}

+ (BOOL)isContainerViewVisible:(UIView *)containerView {
    if (containerView.hidden || containerView.alpha <= 0 || !containerView.window) {
        return NO;
    }
    return YES;
}

+ (BOOL)isTargetViewVisible:(UIView *)targetView inContainerView:(UIView *)containerView {
    BOOL flag = targetView.hidden || targetView.alpha <= 0 || !targetView.window;
    // BOOL flag = !targetView.window;
    if (flag) return NO;
    BOOL visible = YES;
    while (targetView.superview && targetView.superview != containerView) {
        targetView = targetView.superview;
        flag = targetView.hidden || targetView.alpha <= 0 || !targetView.window;
        // flag = !targetView.window;
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
        // 这里没有复用，所以没有 preData 和 preDataKey，只需要更新 preRatio 和 preVisible
        CGFloat preRatio = [[IntersectionObserverReuseManager shareInstance] ratioForDataKey:oldOptions.dataKey inScope:options.scope];
        // NSLog(@"write ratio %@ %@ bbb", options.dataKey, @(preRatio));
        [[IntersectionObserverReuseManager shareInstance] addRatio:preRatio toDataKey:options.dataKey toScope:options.scope];
        options.preVisible = oldOptions.preVisible;
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


static char kAssociatedObjectKey_UtilsPreVisible;
static char kAssociatedObjectKey_UtilsPreDataKey;
static char kAssociatedObjectKey_UtilsPreData;

@implementation IntersectionObserverTargetOptions (Utils)

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

- (void)setPreVisible:(BOOL)preVisible {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_UtilsPreVisible, @(preVisible), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)preVisible {
    return [objc_getAssociatedObject(self, &kAssociatedObjectKey_UtilsPreVisible) boolValue];
}

@end
