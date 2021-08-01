//
//  IntersectionObserver.h
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import "IntersectionObserverEntry.h"

@class IntersectionObserverContainerOptions, IntersectionObserverTargetOptions;

NS_ASSUME_NONNULL_BEGIN

@interface IntersectionObserver : NSObject

@property(nonatomic, assign, readonly) BOOL isObserving;
@property(nonatomic, weak) IntersectionObserverContainerOptions *containerOptions;
@property(nonatomic, strong) NSMapTable<UIView *, IntersectionObserverTargetOptions *> *targetOptions;

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithContainerOptions:(IntersectionObserverContainerOptions *)options NS_DESIGNATED_INITIALIZER;

// 开始监听
- (void)observe;

// 暂停监听
- (void)unobserve;

// 添加 target 和 target options
- (BOOL)addTargetOptions:(UIView *)target options:(IntersectionObserverTargetOptions *)options;

// 删除 target 对应的 options
- (BOOL)removeTargetOptions:(UIView *)target;

@end

NS_ASSUME_NONNULL_END
