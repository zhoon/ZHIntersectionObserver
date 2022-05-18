//
//  IntersectionObserverEntry.h
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class IntersectionObserverEntry;

NS_ASSUME_NONNULL_BEGIN

typedef void (^IntersectionObserverCallback)(NSString *scope, NSArray<IntersectionObserverEntry *> *entries);

@interface IntersectionObserverEntry : NSObject

/// 对应 target 此时的 rect（相对于容器）
@property(nonatomic, assign) CGRect boundingClientRect;

/// 容器和目标元素的相交区域 rect
@property(nonatomic, assign) CGRect intersectionRect;

/// 相交的比例 ([0, 1])，intersectionRect 与 boundingClientRect 的比例值
@property(nonatomic, assign) CGFloat intersectionRatio;

/// 目标元素与容器相交，则返回 true。如果返回 true，则 IntersectionObserverEntry 描述了变换到交叉时的状态；如果返回 false，那么可以由此判断，变换是从交叉状态到非交叉状态
@property(nonatomic, assign) BOOL isIntersecting;

/// 容器的 bounds
@property(nonatomic, assign) CGRect rootBounds;

/// 对应的 target 对象
@property(nonatomic, weak) UIView *targetView;

/// 触发事件时的时间戳，可用来计算 target 在屏幕内停留时间，单位 ms
@property(nonatomic, assign) NSTimeInterval time;

/// 透传的 dataKey
@property(nonatomic, copy) NSString *dataKey;

/// 透传的 data
@property(nonatomic, copy) NSDictionary *data;

/// 禁止默认初始化
- (instancetype)init UNAVAILABLE_ATTRIBUTE;

/// 初始化方法
+ (instancetype)initEntryWithTargetView:(UIView *)targetView
                                dataKey:(NSString *)dataKey
                                   data:(NSDictionary *)data
                     boundingClientRect:(CGRect)boundingClientRect
                      intersectionRatio:(CGFloat)intersectionRatio
                       intersectionRect:(CGRect)intersectionRect
                         isIntersecting:(BOOL)isIntersecting
                             rootBounds:(CGRect)rootBounds
                                   time:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
