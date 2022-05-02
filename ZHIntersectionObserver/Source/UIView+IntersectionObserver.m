//
//  UIView+IntersectionObserver.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import <objc/runtime.h>
#import "UIView+IntersectionObserver.h"
#import "IntersectionObserverOptions.h"
#import "IntersectionObserver.h"
#import "IntersectionObserverManager.h"
#import "IntersectionObserverMeasure.h"

@interface _UIViewObserver : NSObject

@property(nonatomic, weak) UIView *view;

- (void)addObserverView:(UIView *)view;

- (void)addObserver;
- (void)removeObserver;

@end

@interface UIView ()

@property(nonatomic, strong) _UIViewObserver *_uiViewTargetObserver;
@property(nonatomic, strong) _UIViewObserver *_uiViewContainerObserver;

@end

@implementation UIView (IntersectionObserver)

static char kAssociatedObjectKey_intersectionObserver;
static char kAssociatedObjectKey_uiViewTargetObserver;
static char kAssociatedObjectKey_uiViewContainerObserver;
static char kAssociatedObjectKey_intersectionObserverContainerOptions;
static char kAssociatedObjectKey_intersectionObserverTargetOptions;

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 这几个 class 实现了自己的 didMoveToWindow 且没有调用 super，所以需要每个都替换一遍方法
        NSArray<Class> *classes = @[UIView.class,
                                    UICollectionView.class,
                                    UITextField.class,
                                    UISearchBar.class,
                                    NSClassFromString(@"UITableViewLabel")];
        if (NSClassFromString(@"WKWebView")) {
            classes = [classes arrayByAddingObject:NSClassFromString(@"WKWebView")];
        }
        [classes enumerateObjectsUsingBlock:^(Class  _Nonnull class, NSUInteger idx, BOOL * _Nonnull stop) {
            IntersectionObserver_ExtendImplementationOfVoidMethodWithoutArguments(class, @selector(didMoveToWindow), ^(UIView *selfObject) {
                NSString *scope = selfObject.intersectionObserverContainerOptions.scope ?: selfObject.intersectionObserverTargetOptions.scope;
                if (scope && scope.length > 0) {
                    IntersectionObserver *observer = [[IntersectionObserverManager shareInstance] observerForScope:scope];
                    if (observer && observer.containerOptions.measureWhenVisibilityChanged) {
                        [selfObject handleViewVisibilityChangedEventForTargetView:selfObject.intersectionObserverTargetOptions ? selfObject : nil];
                    }
                }
            });
        }];
    });
}

- (void)setIntersectionObserver:(IntersectionObserver *)intersectionObserver {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_intersectionObserver, intersectionObserver, OBJC_ASSOCIATION_ASSIGN);
}

- (IntersectionObserver *)intersectionObserver {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_intersectionObserver);
}

- (void)setIntersectionObserverContainerOptions:(IntersectionObserverContainerOptions *)intersectionObserverContainerOptions {
    if (intersectionObserverContainerOptions && self.intersectionObserverTargetOptions) {
        NSAssert(NO, @"同一个 View 不能同时设置 target 和 container options");
        return;
    }
    if (intersectionObserverContainerOptions && self.intersectionObserverContainerOptions) {
        NSAssert(NO, @"同一个 View 不能设置两个 intersectionObserverContainerOptions，如需更新 options 请调用 update 接口更新");
        return;
    }
    if (intersectionObserverContainerOptions) {
        [intersectionObserverContainerOptions setValue:self forKey:@"containerView"];
    }
    if ([IntersectionObserverMeasure isContainerOptions:intersectionObserverContainerOptions
                                        sameWithOptions:self.intersectionObserverContainerOptions]) {
        // 相同 options 过滤
        return;
    }
    if (intersectionObserverContainerOptions) {
        NSString *scope = intersectionObserverContainerOptions.scope;
        [self checkContainerOptions:intersectionObserverContainerOptions];
        if (scope && scope.length > 0) {
            if (!self._uiViewContainerObserver) {
                self._uiViewContainerObserver = [[_UIViewObserver alloc] init];
                [self._uiViewContainerObserver addObserverView:self];
            }
            self.intersectionObserver = [[IntersectionObserverManager shareInstance] addObserverWithOptions:intersectionObserverContainerOptions];
            // 启动监听
            [self.intersectionObserver observe];
            // 添加成功证明某些数据变了，需要重新触发一次检查
            [[IntersectionObserverManager shareInstance] emitObserverEventWithScope:scope];
        } else {
            NSAssert(NO, @"no scope");
        }
    } else {
        if (self._uiViewContainerObserver) {
            [self._uiViewContainerObserver addObserverView:nil];
        }
        if (self.intersectionObserver) {
            [[IntersectionObserverManager shareInstance] removeObserver: self.intersectionObserver];
            self.intersectionObserver = nil;
        }
    }
    objc_setAssociatedObject(self, &kAssociatedObjectKey_intersectionObserverContainerOptions, intersectionObserverContainerOptions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IntersectionObserverContainerOptions *)intersectionObserverContainerOptions {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_intersectionObserverContainerOptions);
}

- (void)set_uiViewContainerObserver:(_UIViewObserver *)_uiViewContainerObserver {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_uiViewContainerObserver, _uiViewContainerObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_UIViewObserver *)_uiViewContainerObserver {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_uiViewContainerObserver);
}

- (void)setIntersectionObserverTargetOptions:(IntersectionObserverTargetOptions *)intersectionObserverTargetOptions {
    if (intersectionObserverTargetOptions && self.intersectionObserverContainerOptions) {
        NSAssert(NO, @"同一个 View 不能同时设置 target 和 container options");
        return;
    }
    // 如果已经存在 target options，只拿出 dataKey 和 data 去更新旧的 target options 即可
    if (intersectionObserverTargetOptions && self.intersectionObserverTargetOptions) {
        [intersectionObserverTargetOptions setValue:@YES forKey:@"notCleanWhenDealloc"];
        if ([intersectionObserverTargetOptions.scope isEqualToString:self.intersectionObserverTargetOptions.scope]) {
            id data = intersectionObserverTargetOptions.data;
            NSString *dataKey = intersectionObserverTargetOptions.dataKey;
            if (dataKey && dataKey.length > 0 && data) {
                [self.intersectionObserverTargetOptions updateDataKey:dataKey data:data];
                return;
            }
        }
        NSAssert(NO, @"同一个 View 不能设置两个 intersectionObserverTargetOptions，如需更新 options 请调用 update 接口更新");
        return;
    }
    // 设置 targetView
    if (intersectionObserverTargetOptions) {
        [intersectionObserverTargetOptions setValue:self forKey:@"targetView"];
    }
    if ([IntersectionObserverMeasure isTargetOptions:intersectionObserverTargetOptions
                                     sameWithOptions:self.intersectionObserverTargetOptions]) {
        // 相同 options 过滤
        return;
    }
    NSDictionary<NSString *, IntersectionObserver *> *observers = [[IntersectionObserverManager shareInstance] allObservers];
    if (intersectionObserverTargetOptions) {
        [self checkTargetOptions:intersectionObserverTargetOptions];
        NSString *scope = intersectionObserverTargetOptions.scope;
        if (scope && scope.length > 0) {
            if (observers && observers[scope]) {
                IntersectionObserver *targetObserver = observers[scope];
                BOOL addTargetOptionsSucceed = [targetObserver addTargetOptions:self options:intersectionObserverTargetOptions];
                if (addTargetOptionsSucceed) {
                    if (!self._uiViewTargetObserver) {
                        self._uiViewTargetObserver = [[_UIViewObserver alloc] init];
                        [self._uiViewTargetObserver addObserverView:self];
                    }
                    // 添加成功证明某些数据变了，需要重新触发一次检查
                    [[IntersectionObserverManager shareInstance] emitObserverEventWithScope:intersectionObserverTargetOptions.scope];
                }
            } else {
                NSAssert(NO, @"no target observer");
            }
        } else {
            NSAssert(NO, @"no target scope");
        }
    } else {
        if (self._uiViewTargetObserver) {
            [self._uiViewTargetObserver addObserverView:nil];
        }
        NSString *scope = self.intersectionObserverTargetOptions.scope;
        if (scope && scope.length > 0) {
            IntersectionObserver *targetObserver = observers[scope];
            [targetObserver removeTargetOptions:self];
        } else {
            NSAssert(NO, @"no target scope");
        }
    }
    objc_setAssociatedObject(self, &kAssociatedObjectKey_intersectionObserverTargetOptions, intersectionObserverTargetOptions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (IntersectionObserverTargetOptions *)intersectionObserverTargetOptions {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_intersectionObserverTargetOptions);
}

- (void)set_uiViewTargetObserver:(_UIViewObserver *)_uiViewTargetObserver {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_uiViewTargetObserver, _uiViewTargetObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_UIViewObserver *)_uiViewTargetObserver {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_uiViewTargetObserver);
}

- (void)handleViewVisibilityChangedEventForTargetView:(UIView *)targetView {
    if (self.intersectionObserverTargetOptions || self.intersectionObserverContainerOptions) {
        NSString *scope = self.intersectionObserverTargetOptions.scope ?: self.intersectionObserverContainerOptions.scope;
        if (scope && scope.length > 0) {
            [[IntersectionObserverManager shareInstance] emitObserverEventWithScope:scope forTargetView:targetView];
        } else {
            NSAssert(NO, @"no scope");
        }
    }
}

- (void)checkContainerOptions:(IntersectionObserverContainerOptions *)containerOptions {
    if (!containerOptions.scope || containerOptions.scope.length <= 0 ||
        !containerOptions.containerView || !containerOptions.callback) {
        NSAssert(NO, @"container options error");
    }
}

- (void)checkTargetOptions:(IntersectionObserverTargetOptions *)targetOptions {
    if (!targetOptions.scope || targetOptions.scope.length <= 0 || !targetOptions.targetView) {
        NSAssert(NO, @"target options error");
    }
}

@end

@implementation _UIViewObserver

- (void)addObserverView:(UIView *)view {
    if (_view == view) {
        if (_view) {
            NSAssert(NO, @"不要添加相同的 View，一个 View 只能添加一次");
        }
        return;
    }
    if (_view) {
        [self removeObserver];
    }
    _view = view;
    if (_view) {
        [self addObserver];
    }
}

- (void)addObserver {
    if (_view) {
        [_view addObserver:self forKeyPath:@"alpha" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        [_view addObserver:self forKeyPath:@"hidden" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        // 这里不要用 layer 的 bounds 和 position，有 kvo 的 crash
        [_view addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
        [_view addObserver:self forKeyPath:@"center" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
}

- (void)removeObserver {
    if (_view) {
        [_view removeObserver:self forKeyPath:@"alpha"];
        [_view removeObserver:self forKeyPath:@"hidden"];
        [_view removeObserver:self forKeyPath:@"frame"];
        [_view removeObserver:self forKeyPath:@"center"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context  {
    // 防止切到后台会切横竖屏截图
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    if (_view.intersectionObserverTargetOptions || _view.intersectionObserverContainerOptions) {
        NSString *scope = _view.intersectionObserverContainerOptions.scope ?: _view.intersectionObserverTargetOptions.scope;
        if (!scope) {
            NSAssert(NO, @"no scope");
        }
        if ([keyPath isEqualToString:@"frame"]) {
            CGRect oldFrame = [change[NSKeyValueChangeOldKey] CGRectValue];
            CGRect newFrame = [change[NSKeyValueChangeNewKey] CGRectValue];
            if (!CGRectEqualToRect(oldFrame, newFrame)) {
                [_view handleViewVisibilityChangedEventForTargetView:_view.intersectionObserverTargetOptions ? _view : nil];
            }
        }
        if ([keyPath isEqualToString:@"center"]) {
            CGPoint oldPoint = [change[NSKeyValueChangeOldKey] CGPointValue];
            CGPoint newPoint = [change[NSKeyValueChangeNewKey] CGPointValue];
            if (!CGPointEqualToPoint(oldPoint, newPoint)) {
                [_view handleViewVisibilityChangedEventForTargetView:_view.intersectionObserverTargetOptions ? _view : nil];
            }
        }
        if ([keyPath isEqualToString:@"alpha"]) {
            IntersectionObserver *observer = [[IntersectionObserverManager shareInstance] observerForScope:scope];
            if (observer.containerOptions.measureWhenVisibilityChanged &&
                [change[NSKeyValueChangeOldKey] doubleValue] != [change[NSKeyValueChangeNewKey] doubleValue]) {
                // 延迟设置，一些场景只是临时某一瞬间修改然后改回来
                __weak __typeof(_view)weakView = _view;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    __strong __typeof(weakView)strongView = weakView;
                    if (strongView && strongView.alpha == [change[NSKeyValueChangeNewKey] doubleValue]) {
                        [strongView handleViewVisibilityChangedEventForTargetView:strongView.intersectionObserverTargetOptions ? strongView : nil];
                    }
                });
            }
        }
        if ([keyPath isEqualToString:@"hidden"]) {
            IntersectionObserver *observer = [[IntersectionObserverManager shareInstance] observerForScope:scope];
            if (observer.containerOptions.measureWhenVisibilityChanged &&
                [change[NSKeyValueChangeOldKey] boolValue] != [change[NSKeyValueChangeNewKey] boolValue]) {
                // 延迟设置，一些场景只是临时某一瞬间修改然后改回来
                __weak __typeof(_view)weakView = _view;
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    __strong __typeof(weakView)strongView = weakView;
                    if (strongView && strongView.hidden == [change[NSKeyValueChangeNewKey] boolValue]) {
                        [strongView handleViewVisibilityChangedEventForTargetView:strongView.intersectionObserverTargetOptions ? strongView : nil];
                    }
                });
            }
        }
    }
}

- (void)dealloc {
    [self removeObserver];
}

@end
