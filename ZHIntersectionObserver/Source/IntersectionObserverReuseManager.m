//
//  IntersectionObserverReuseManager.m
//  ZHIntersectionObserver
//
//  Created by 粽 on 2022/4/1.
//

#import "IntersectionObserverReuseManager.h"

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
    if (!dataKey || dataKey.length <= 0 || !scope || scope.length <= 0) {
        NSAssert(NO, @"");
        return NO;
    }
    NSMutableSet *dataKeys = self.visibleDataKeys && self.visibleDataKeys[scope] ? [[NSMutableSet alloc] initWithSet:self.visibleDataKeys[scope]] : [NSMutableSet set];
    return [dataKeys containsObject:dataKey];
}

- (void)addVisibleDataKey:(NSString *)dataKey toScope:(NSString *)scope {
    if (!dataKey || dataKey.length <= 0 || !scope || scope.length <= 0) {
        NSAssert(NO, @"");
        return;
    }
    NSMutableSet *dataKeys = self.visibleDataKeys && self.visibleDataKeys[scope] ? [[NSMutableSet alloc] initWithSet:self.visibleDataKeys[scope]] : [NSMutableSet set];
    [dataKeys addObject:dataKey];
    [self.visibleDataKeys setObject:dataKeys forKey:scope];
}

- (void)removeVisibleDataKey:(NSString *)dataKey fromScope:(NSString *)scope {
    if (!dataKey || dataKey.length <= 0 || !scope || scope.length <= 0) {
        NSAssert(NO, @"");
        return;
    }
    NSMutableSet *dataKeys = self.visibleDataKeys && self.visibleDataKeys[scope] ? [[NSMutableSet alloc] initWithSet:self.visibleDataKeys[scope]] : [NSMutableSet set];
    if ([dataKeys containsObject:dataKey]) {
        [dataKeys removeObject:dataKey];
    }
    [self.visibleDataKeys setObject:dataKeys forKey:scope];
}

@end