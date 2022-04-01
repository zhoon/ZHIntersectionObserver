//
//  IntersectionObserverReuseManager.h
//  ZHIntersectionObserver
//
//  Created by 粽 on 2022/4/1.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IntersectionObserverReuseManager : NSObject

@property(nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSSet *> *visibleDataKeys;

+ (instancetype)shareInstance;

- (BOOL)isDataKeyVisible:(NSString *)dataKey inScope:(NSString *)scope;
- (void)addVisibleDataKey:(NSString *)dataKey toScope:(NSString *)scope;
- (void)removeVisibleDataKey:(NSString *)dataKey fromScope:(NSString *)scope;

@end

NS_ASSUME_NONNULL_END
