//
//  UIScrollView+IntersectionObserver.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import <objc/runtime.h>
#import "UIScrollView+IntersectionObserver.h"
#import "IntersectionObserverMeasure.h"
#import "IntersectionObserverOptions.h"
#import "IntersectionObserverManager.h"
#import "UIView+IntersectionObserver.h"

@interface _UIScrollViewObserver : NSObject

@property(nonatomic, weak) UIScrollView *scrollView;

- (void)addObserverView:(UIScrollView *)view;

- (void)addObserver;
- (void)removeObserver;

@end

@interface UIScrollView ()

@property(nonatomic, strong) _UIScrollViewObserver *_uiScrollViewObserver;

@property(nonatomic, strong) NSDate *prevDate;

@end

@implementation UIScrollView (IntersectionObserver)

static char kAssociatedObjectKey_uiScrollViewObserver;
static char kAssociatedObjectKey_throttlePrevDate;

- (void)set_uiScrollViewObserver:(_UIScrollViewObserver *)_uiScrollViewObserver {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_uiScrollViewObserver, _uiScrollViewObserver, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (_UIScrollViewObserver *)_uiScrollViewObserver {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_uiScrollViewObserver);
}

- (void)setPrevDate:(NSDate *)prevDate {
    objc_setAssociatedObject(self, &kAssociatedObjectKey_throttlePrevDate, prevDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate *)prevDate {
    return objc_getAssociatedObject(self, &kAssociatedObjectKey_throttlePrevDate);
}

- (void)setIntersectionObserverContainerOptions:(IntersectionObserverContainerOptions *)intersectionObserverContainerOptions {
    if (intersectionObserverContainerOptions && self.intersectionObserverContainerOptions) {
        NSAssert(NO, @"同一个 View 不能设置两个 intersectionObserverContainerOptions，如需更新 options 请调用 update 接口更新");
        return;
    }
    [super setIntersectionObserverContainerOptions:intersectionObserverContainerOptions];
    if (intersectionObserverContainerOptions) {
        if (!self._uiScrollViewObserver) {
            self._uiScrollViewObserver = [[_UIScrollViewObserver alloc] init];
            [self._uiScrollViewObserver addObserverView:self];
        }
    } else {
        if (self._uiScrollViewObserver) {
            [self._uiScrollViewObserver addObserverView:nil];
        }
    }
}

- (void)handleScrollViewVisibilityChangedEvent {
    if (self.intersectionObserverContainerOptions) {
        NSString *scope = self.intersectionObserverContainerOptions.scope;
        if (scope && scope.length > 0) {
            [[IntersectionObserverManager shareInstance] emitObserverEventWithScope:scope];
        } else {
            NSAssert(NO, @"no scope");
        }
    }
}

// 节流函数，并且确保最后一次会被调用
- (void)runThrottleTask:(void (^)(void))actionBlock interval:(NSTimeInterval)interval {
    if (!actionBlock) {
        return;
    }
    if (self.prevDate) {
        NSTimeInterval curInterval = [[NSDate date] timeIntervalSinceDate:self.prevDate] * 1000;
        if (curInterval >= interval) {
            actionBlock();
            self.prevDate = [NSDate date];
        }
    } else {
        actionBlock();
        self.prevDate = [NSDate date];
    }
    
    __weak __typeof(self)weakSelf = self;
    
    CGPoint preContentOffset = self.contentOffset;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((self.intersectionObserverContainerOptions.throttle + 100) / 1000.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        __strong __typeof(weakSelf)strongSelf = weakSelf;
        if (!strongSelf.isDragging) {
            if (preContentOffset.x == strongSelf.contentOffset.x &&
                preContentOffset.y == strongSelf.contentOffset.y) {
                actionBlock();
                self.prevDate = [NSDate date];
            }
        }
    });
}

@end

@implementation _UIScrollViewObserver

- (void)addObserverView:(UIScrollView *)view {
    if (_scrollView == view) {
        if (_scrollView) {
            NSAssert(NO, @"不要添加相同的 View，一个 View 只能添加一次");
        }
        return;
    }
    if (_scrollView) {
        [self removeObserver];
    }
    _scrollView = view;
    if (_scrollView) {
        [self addObserver];
    }
}

- (void)addObserver {
    if (_scrollView) {
        [_scrollView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    }
}

- (void)removeObserver {
    if (_scrollView) {
        [_scrollView removeObserver:self forKeyPath:@"contentOffset"];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context  {
    // 防止切到后台会切横竖屏截图
    if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
        return;
    }
    if (_scrollView.intersectionObserverContainerOptions) {
        if ([keyPath isEqualToString:@"contentOffset"]) {
            CGPoint oldContenetOffset = [change[NSKeyValueChangeOldKey] CGPointValue];
            CGPoint newContenetOffset = [change[NSKeyValueChangeNewKey] CGPointValue];
            if (oldContenetOffset.x != newContenetOffset.x || oldContenetOffset.y != newContenetOffset.y) {
                if (_scrollView.intersectionObserverContainerOptions.throttle > 0) {
                    __weak __typeof(_scrollView)weakScrollView = _scrollView;
                    [_scrollView runThrottleTask:^{
                        __strong __typeof(weakScrollView)strongScrollView = weakScrollView;
                        [strongScrollView handleScrollViewVisibilityChangedEvent];
                    } interval:_scrollView.intersectionObserverContainerOptions.throttle];
                } else {
                    [_scrollView handleScrollViewVisibilityChangedEvent];
                }
            }
        }
    }
}

- (void)dealloc {
    [self removeObserver];
}

@end


