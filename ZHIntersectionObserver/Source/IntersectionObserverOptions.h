//
//  IntersectionObserverOptions.h
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import "IntersectionObserverEntry.h"

NS_ASSUME_NONNULL_BEGIN

@interface IntersectionObserverContainerOptions : NSObject

/// 作用域，一般一个列表或者界面就是一个作用域，不能为空
@property(nonatomic, copy, readonly) NSString *scope;

/// 容器 view，不能为空
@property(nonatomic, weak, readonly) UIView *containerView;

/// 该属性值是用作容器和 target 发生交集时候的计算交集的区域范围，使用该属性可以控制容器每一边的收缩或者扩张。默认值为 UIEdgeInsetsZero。
@property(nonatomic, assign, readonly) UIEdgeInsets rootMargin;

/// target 元素和容器元素相交程度达到该值的时候 IntersectionObserver 注册的回调函数将会被执行。如果你只是想要探测当 target 元素的在容器中的可见性超过 50% 的时候，你可以指定该属性值为 0.5。如果你想要 target 元素在容器元素的可见程度每多 25% 就执行一次回调，那么你可以指定一个数组 @[@0, @0.25, @0.5, @0.75, @1]。@[@0] 意味着只要有一个 target 像素出现在容器中，回调函数将会被执行。@[@1] 意味着当 target 完全出现在容器中时候 回调才会被执行。默认值是 @[@1]。
@property(nonatomic, copy, readonly, nullable) NSArray <NSNumber *> *thresholds;

/// 节流参数，频率限制，默认 100 ms。需要搭配 intersectionDuration 一起使用，不宜设置太大，否则 intersectionDuration 效果会不明显。
@property(nonatomic, assign, readonly) NSTimeInterval throttle;

/// appState 发生变化是否重新检测曝光，默认 YES。这个属性只有当设置了 dataKey 才会生效。
@property(nonatomic, assign, readonly) BOOL measureWhenAppStateChanged;

/// 可视状态发生变化是否重新检测曝光， 默认 YES。这个属性只有当设置了 dataKey 才会生效。
@property(nonatomic, assign, readonly) BOOL measureWhenVisibilityChanged;

/// 触发 intersection 事件之后经过 duration 时长再检查一次如果两次结果一样，才会 callback 给业务。可以理解为曝光时长，用于解决快速滚动或者本地数据被网络数据覆盖的场景，默认为 600 ms
@property(nonatomic, assign, readonly) NSTimeInterval intersectionDuration;

/// 注册回调 block，不要在 callback 里面做耗时的操作。注意：callback 切记不要产生内存泄露，否则可能会导致监听器没有释放出现监听异常
@property(nonatomic, copy, readonly) IntersectionObserverCallback callback;

/// 更新 rootMargin
- (void)updateRootMargin:(UIEdgeInsets)rootMargin;

/// 更新 thresholds
- (void)updateThresholds:(NSArray<NSNumber *> *)thresholds;

/// 更新 intersectionDuration
- (void)updateIntersectionDuration:(NSTimeInterval)intersectionDuration;

/// 禁止默认初始化
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// 初始化方法
+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                       containerView:(UIView *)containerView
                            callback:(IntersectionObserverCallback)callback;

/// 初始化方法
+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                          thresholds:(NSArray <NSNumber *> *)thresholds
                       containerView:(UIView *)containerView
                intersectionDuration:(NSTimeInterval)intersectionDuration
                            callback:(IntersectionObserverCallback)callback;

/// 初始化方法
+ (instancetype)initOptionsWithScope:(NSString *)scope
                          rootMargin:(UIEdgeInsets)rootMargin
                          thresholds:(NSArray <NSNumber *> *)thresholds
                            throttle:(NSTimeInterval)throttle
                       containerView:(UIView *)containerView
          measureWhenAppStateChanged:(BOOL)measureWhenAppStateChanged
        measureWhenVisibilityChanged:(BOOL)measureWhenVisibilityChanged
                intersectionDuration:(NSTimeInterval)intersectionDuration
                            callback:(IntersectionObserverCallback)callback;

@end

@interface IntersectionObserverTargetOptions : NSObject

/// 作用域，一般一个列表或者界面就是一个作用域，需要跟 IntersectionObserverContainerOptions 的 scope 一致
@property(nonatomic, copy, readonly) NSString *scope;

/// target view
@property(nonatomic, weak, readonly) UIView *targetView;

/// 一般是当前 target 对应的数据，在 callback 透传出去，方便业务使用
@property(nonatomic, copy, readonly, nullable) NSDictionary *data;

/// 一般是 data 的 id（也可以多个字段的组合），用来标记 data 是否发生变化，用在 View 复用的场景。dataKey 发生变化，会重新触发一次 intersection 检查。
@property(nonatomic, copy, readonly, nullable) NSString *dataKey;

/// 更新 data
- (void)updateDataKey:(NSString *)dataKey data:(id)data;

/// 禁止默认初始化
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// 初始化方法
+ (instancetype)initOptionsWithScope:(NSString *)scope
                          targetView:(UIView *)targetView;

/// 初始化方法
+ (instancetype)initOptionsWithScope:(NSString *)scope
                             dataKey:(NSString * __nullable)dataKey
                          targetView:(UIView *)targetView;

/// 初始化方法
+ (instancetype)initOptionsWithScope:(NSString *)scope
                             dataKey:(NSString * __nullable)dataKey
                                data:(NSDictionary * __nullable)data
                          targetView:(UIView *)targetView;

@end


NS_ASSUME_NONNULL_END
