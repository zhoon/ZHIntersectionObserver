//
//  IntersectionObserverManager.h
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class IntersectionObserver, IntersectionObserverContainerOptions;

NS_ASSUME_NONNULL_BEGIN

@interface IntersectionObserverManager : NSObject

+ (instancetype)shareInstance;

/// 记录 UIApplicationState
@property(nonatomic, assign, readonly) UIApplicationState previousApplicationState;

/// 触发事件，一般在滚动事件里面触发。业务也可以根据实际情况自行触发事件。
- (void)emitObserverEventWithScope:(NSString *)scope;
- (void)emitObserverEventWithScope:(NSString *)scope forTargetView:(UIView * __nullable)targetView;

/// 添加 observer
- (IntersectionObserver *)addObserverWithOptions:(IntersectionObserverContainerOptions *)options;

/// 删除 observer
- (BOOL)removeObserverWithScope:(NSString *)scope;
- (BOOL)removeObserver:(IntersectionObserver *)observer;

/// 获取所有 observers
- (NSDictionary<NSString *, IntersectionObserver *> *)allObservers;

// 获取对应 scope 的 observer
- (IntersectionObserver *)observerForScope:(NSString *)scope;

@end

NS_ASSUME_NONNULL_END
