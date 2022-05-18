# 简单易用的 iOS 曝光打点组件 (Intersection Observer for iOS).
在客户端中如果需要实现曝光打点的需求，经常会遇到各种各样的问题，例如：该在什么时机去打点；复用的 view 打点混乱；切换界面或者切换 APP 前后台需不需要打点；打点代码难维护等等。 ZHIntersectionObserver 就是为了解决这个问题而诞生的。

## 特性列表

- 支持设置多个临界点（thresholds）
- 支持控制列表滚动检查曝光的频率（throttle）
- View 被移除或者 hidden 和 alpha 变化支持自动检查曝光
- App 切换前台或者后台支持自动检查曝光
- 支持设置曝光时长（intersectionDuration）
- 兼容 Cell 的复用
- 支持数据变化自动检查曝光

## Demo演示

### 基础曝光功能：

<img src="/images/intersection_observer_1.gif" alt="基础曝光功能" width="320"/>

### 延迟曝光 / Cell 的复用：

<img src="/images/intersection_observer_2.gif" alt="延迟曝光 / Cell 的复用" width="320"/>

### 数据变化触发曝光：

<img src="/images/intersection_observer_3.gif" alt="数据变化触发曝光" width="320"/>

## 如何使用
```
pod 'ZHIntersectionObserver'
```
```
#import <ZHIntersectionObserver/IntersectionObserverHeader.h>
```
```Objective-C
UIView *containerView = [[UIView alloc] init];
UIView *targetView = [[UIView alloc] init];

__weak __typeof(self)weakSelf = self;

IntersectionObserverContainerOptions *containerOptions = [IntersectionObserverContainerOptions initOptionsWithScope:@"Example1" rootMargin:UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0) thresholds:@[1] intersectionDuration:300 callback:^(NSString * _Nonnull scope, NSArray<IntersectionObserverEntry *> * _Nonnull entries) {
    __strong __typeof(weakSelf)strongSelf = weakSelf;
    for (NSInteger i = 0; i < entries.count; i++) {
        IntersectionObserverEntry *entry = entries[i];
        if (entry.isIntersecting) {
            // 进入可视区域
        }
    }
}];

containerView.intersectionObserverContainerOptions = containerOptions;

// dataKey 保证全局唯一
IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example1" dataKey:@"DataKeyID"];
targetView.intersectionObserverTargetOptions = targetOptions;
```

## 支持iOS版本

iOS 11.0 及以上
