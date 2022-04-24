//
//  IntersectionObserverReuseManager.m
//  ZHIntersectionObserver
//
//  Created by 粽 on 2022/4/1.
//

#import "IntersectionObserverReuseManager.h"
#import "IntersectionObserverEntry.h"

#define NotEmptyString(str) (str && str.length > 0)

@implementation IntersectionObserverReuseManager

+ (instancetype)shareInstance {
    static IntersectionObserverReuseManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IntersectionObserverReuseManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _visibleDataKeys = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (BOOL)isDataKeyVisible:(NSString *)dataKey inScope:(NSString *)scope {
    if (!NotEmptyString(scope)) {
        NSAssert(NO, @"");
        return NO;
    }
    if (!NotEmptyString(dataKey)) {
        // NSLog(@"Warning: IntersectionObserverReuseManager no dataKey，当前如果不是复用的 view 可以不用管");
        return NO;
    }
    NSMutableSet *dataKeys = self.visibleDataKeys && self.visibleDataKeys[scope] ? [[NSMutableSet alloc] initWithSet:self.visibleDataKeys[scope]] : [NSMutableSet set];
    return [dataKeys containsObject:dataKey];
}

- (void)addVisibleDataKey:(NSString *)dataKey toScope:(NSString *)scope {
    if (!NotEmptyString(scope)) {
        NSAssert(NO, @"");
        return;
    }
    if (!NotEmptyString(dataKey)) {
        // NSLog(@"Warning: IntersectionObserverReuseManager no dataKey，当前如果不是复用的 view 可以不用管");
        return;
    }
    NSMutableSet *dataKeys = self.visibleDataKeys && self.visibleDataKeys[scope] ? [[NSMutableSet alloc] initWithSet:self.visibleDataKeys[scope]] : [NSMutableSet set];
    [dataKeys addObject:dataKey];
    [self.visibleDataKeys setObject:dataKeys forKey:scope];
}

- (void)addVisibleEntries:(NSArray <IntersectionObserverEntry *> *)entries toScope:(NSString *)scope {
    if (!entries || entries.count <= 0) {
        NSLog(@"Info: IntersectionObserverReuseManager no entries (addVisibleEntries)");
        return;
    }
    [entries enumerateObjectsUsingBlock:^(IntersectionObserverEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        [self addVisibleDataKey:entry.dataKey toScope:scope];
    }];
}

- (void)removeVisibleDataKey:(NSString *)dataKey fromScope:(NSString *)scope {
    if (!NotEmptyString(scope)) {
        NSAssert(NO, @"");
        return;
    }
    if (!NotEmptyString(dataKey)) {
        // NSLog(@"Warning: IntersectionObserverReuseManager no dataKey，当前如果不是复用的 view 可以不用管");
        return;
    }
    NSMutableSet *dataKeys = self.visibleDataKeys && self.visibleDataKeys[scope] ? [[NSMutableSet alloc] initWithSet:self.visibleDataKeys[scope]] : [NSMutableSet set];
    if ([dataKeys containsObject:dataKey]) {
        [dataKeys removeObject:dataKey];
    }
    [self.visibleDataKeys setObject:dataKeys forKey:scope];
}

- (void)removeVisibleEntries:(NSArray <IntersectionObserverEntry *> *)entries fromScope:(NSString *)scope {
    if (!entries || entries.count <= 0) {
        NSLog(@"Info: IntersectionObserverReuseManager no entries (removeVisibleEntries)");
        return;
    }
    [entries enumerateObjectsUsingBlock:^(IntersectionObserverEntry * _Nonnull entry, NSUInteger idx, BOOL * _Nonnull stop) {
        [self removeVisibleDataKey:entry.dataKey fromScope:scope];
    }];
}

- (void)addReusedDataKey:(NSString *)dataKey toScope:(NSString *)scope {
    if (!NotEmptyString(scope)) {
        NSAssert(NO, @"");
        return;
    }
    if (!NotEmptyString(dataKey)) {
        NSLog(@"Warning: IntersectionObserverReuseManager no dataKey");
        return;
    }
    if (!self.reusedDataKeys) {
        _reusedDataKeys = [[NSMutableSet alloc] init];
    }
    NSLog(@"zhoon reuse manager add %@ %@", dataKey, scope);
    NSString *key = [NSString stringWithFormat:@"%@_%@", scope, dataKey];
    if (![self.reusedDataKeys containsObject:key]) {
        [self.reusedDataKeys addObject:key];
    }
}

- (void)removeReuseDataKey:(NSString *)dataKey fromScope:(NSString *)scope {
    if (!NotEmptyString(scope)) {
        NSAssert(NO, @"");
        return;
    }
    if (!NotEmptyString(dataKey)) {
        NSLog(@"Warning: IntersectionObserverReuseManager no dataKey");
        return;
    }
    if (!self.reusedDataKeys || self.reusedDataKeys.count <= 0) {
        return;
    }
    NSLog(@"zhoon reuse manager remove %@ %@", dataKey, scope);
    NSString *key = [NSString stringWithFormat:@"%@_%@", scope, dataKey];
    if ([self.reusedDataKeys containsObject:key]) {
        [self.reusedDataKeys removeObject:key];
    }
}

- (BOOL)isReusedDataKeyRemoved:(NSString *)dataKey inScope:(NSString *)scope {
    if (!NotEmptyString(scope)) {
        NSAssert(NO, @"");
        return YES;
    }
    if (!NotEmptyString(dataKey)) {
        NSLog(@"Warning: IntersectionObserverReuseManager no dataKey");
        return YES;
    }
    if (!self.reusedDataKeys || self.reusedDataKeys.count <= 0) {
        return YES;
    }
    NSString *key = [NSString stringWithFormat:@"%@_%@", scope, dataKey];
    BOOL removed = ![self.reusedDataKeys containsObject:key];
    NSLog(@"zhoon reuse manager isRemoved %@ %@ %@", dataKey, @(removed), scope);
    return removed;
}

- (CGFloat)ratioForDataKey:(NSString *)dataKey inScope:(NSString *)scope {
    if (!NotEmptyString(scope) || !NotEmptyString(dataKey)) {
        NSAssert(NO, @"no scope or dataKey");
        return 0;
    }
    if (!self.ratios) {
        return 0;
    }
    NSString *key = [NSString stringWithFormat:@"%@_%@", scope, dataKey];
    return [[self.ratios objectForKey:key] doubleValue]; // 要 double，否则有精度问题，例如存了 0.7，取出来是 0.6999999999
}

- (void)addRatio:(CGFloat)ratio toDataKey:(NSString *)dataKey toScope:(NSString *)scope {
    if (!NotEmptyString(scope) || !NotEmptyString(dataKey)) {
        NSAssert(NO, @"no scope or dataKey");
        return;
    }
    if (!self.ratios) {
        _ratios = [[NSMutableDictionary alloc] init];
    }
    NSString *key = [NSString stringWithFormat:@"%@_%@", scope, dataKey];
    [self.ratios setObject:@(ratio) forKey:key];
}

- (void)removeRatioFromDataKey:(NSString *)dataKey fromScope:(NSString *)scope {
    if (!NotEmptyString(scope) || !NotEmptyString(dataKey)) {
        NSAssert(NO, @"no scope or dataKey");
        return;
    }
    if (!self.ratios) {
        return;
    }
    NSString *key = [NSString stringWithFormat:@"%@_%@", scope, dataKey];
    [self.ratios removeObjectForKey:key];
}

@end
