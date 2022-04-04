//
//  IntersectionObserverReuseManager.h
//  ZHIntersectionObserver
//
//  Created by 粽 on 2022/4/1.
//

#import <Foundation/Foundation.h>

@class IntersectionObserverEntry;

NS_ASSUME_NONNULL_BEGIN

@interface IntersectionObserverReuseManager : NSObject

@property(nonatomic, strong, readonly) NSMutableDictionary<NSString *, NSSet *> *visibleDataKeys;
@property(nonatomic, strong, readonly) NSMutableSet<NSString *> *reusedDataKeys;

+ (instancetype)shareInstance;

- (BOOL)isDataKeyVisible:(NSString *)dataKey inScope:(NSString *)scope;
- (void)addVisibleDataKey:(NSString *)dataKey toScope:(NSString *)scope;
- (void)removeVisibleDataKey:(NSString *)dataKey fromScope:(NSString *)scope;

- (void)addVisibleEntries:(NSArray <IntersectionObserverEntry *> *)entries toScope:(NSString *)scope;
- (void)removeVisibleEntries:(NSArray <IntersectionObserverEntry *> *)entries fromScope:(NSString *)scope;

- (void)addReusedDataKey:(NSString *)dataKey toScope:(NSString *)scope;
- (void)removeReuseDataKey:(NSString *)dataKey fromScope:(NSString *)scope;
- (BOOL)isReusedDataKeyRemoved:(NSString *)dataKey inScope:(NSString *)scope;

@end

NS_ASSUME_NONNULL_END
