**iOS 客户端检查曝光组件。Intersection Observer for iOS.**

**特性列表**

- 支持设置多个临界点（thresholds）
- 支持控制列表滚动检查曝光的频率（throttle）
- View 被移除或者 hidden 或者 alpha 变化支持自动检查曝光
- App 切换前台或者后台支持自动检查曝光
- 支持设置曝光时长（intersectionDuration）
- 支持数据变化自动检查曝光
- 兼容 UITableViewCell 的复用

**如何使用**
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

IntersectionObserverContainerOptions *containerOptions = [IntersectionObserverContainerOptions initOptionsWithScope:@"Example1" rootMargin:UIEdgeInsetsMake(CGRectGetMaxY(self.navigationController.navigationBar.frame), 0, 0, 0) thresholds:@[1] containerView:containerView intersectionDuration:300 callback:^(NSString * _Nonnull scope, NSArray<IntersectionObserverEntry *> * _Nonnull entries) {
    __strong __typeof(weakSelf)strongSelf = weakSelf;
    for (NSInteger i = 0; i < entries.count; i++) {
        IntersectionObserverEntry *entry = entries[i];
        if (entry.isInsecting) {
            // 进入可视区域
        } else {
            // 移出可视区域
        }
    }
}];

containerView.intersectionObserverContainerOptions = containerOptions;

IntersectionObserverTargetOptions *targetOptions = [IntersectionObserverTargetOptions initOptionsWithScope:@"Example1" targetView:targetView];
targetView.intersectionObserverTargetOptions = targetOptions;
```

**支持iOS版本**

iOS 11.0 及以上
