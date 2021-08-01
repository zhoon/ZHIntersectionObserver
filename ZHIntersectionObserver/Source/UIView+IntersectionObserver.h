//
//  UIView+IntersectionObserver.h
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import <UIKit/UIKit.h>

@class IntersectionObserver, IntersectionObserverContainerOptions, IntersectionObserverTargetOptions;

NS_ASSUME_NONNULL_BEGIN

@interface UIView (IntersectionObserver)

// 设置 intersectionObserverContainerOptions，会产生一个 observer，只供读取
@property(nonatomic, weak, readonly, nullable) IntersectionObserver *intersectionObserver;

// 设置 container options
@property(nonatomic, strong, nullable) IntersectionObserverContainerOptions *intersectionObserverContainerOptions;

// 设置 target options
@property(nonatomic, strong, nullable) IntersectionObserverTargetOptions *intersectionObserverTargetOptions;

@end

NS_ASSUME_NONNULL_END
