//
//  IntersectionObserverManager.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import "IntersectionObserverManager.h"
#import "IntersectionObserver.h"
#import "IntersectionObserverOptions.h"
#import "IntersectionObserverMeasure.h"

@interface IntersectionObserverManager ()

@property(nonatomic, strong) NSMutableDictionary<NSString *, IntersectionObserver *> *observers;

@property(nonatomic, assign, readwrite) UIApplicationState previousApplicationState;

@end

@implementation IntersectionObserverManager

+ (instancetype)shareInstance {
    static IntersectionObserverManager *instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[IntersectionObserverManager alloc] init];
    });
    return instance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.observers = [[NSMutableDictionary alloc] init];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidBecomeActiveNotification:) name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(handleDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    }
    return self;
}

- (void)handleDidBecomeActiveNotification:(NSNotification *)notification {
    if ([self.observers allKeys].count <= 0) {
        return;
    }
    for (NSString *scope in self.observers) {
        if (scope && scope.length > 0 && self.observers[scope]) {
            IntersectionObserver *observer = self.observers[scope];
            if (!observer.containerOptions.containerView.window) {
                continue;
            }
            if (!observer.containerOptions.measureWhenAppStateChanged) {
                continue;
            }
            [self checkObserverWithScope:scope forTargetView:nil];
        }
    }
    // 延迟设置
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateActive) {
            self.previousApplicationState = UIApplicationStateActive;
        }
    });
}

- (void)handleDidEnterBackgroundNotification:(NSNotification *)notification {
    if ([self.observers allKeys].count <= 0) {
        return;
    }
    for (NSString *scope in self.observers) {
        if (scope && scope.length > 0 && self.observers[scope]) {
            IntersectionObserver *observer = self.observers[scope];
            if (!observer.containerOptions.containerView.window) {
                continue;
            }
            if (!observer.containerOptions.measureWhenAppStateChanged) {
                continue;
            }
            [self checkObserverWithScope:scope forTargetView:nil];
        }
    }
    // 延迟设置
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (UIApplication.sharedApplication.applicationState == UIApplicationStateBackground) {
            self.previousApplicationState = UIApplicationStateBackground;
        }
    });
}

- (void)emitObserverEventWithScope:(NSString *)scope {
    [self emitObserverEventWithScope:scope forTargetView:nil];
}

- (void)emitObserverEventWithScope:(NSString *)scope forTargetView:(UIView * __nullable)targetView {
    if (!scope && scope.length <= 0) {
        NSAssert(NO, @"no scope");
        return;
    }
    if (!self.observers || self.observers.count <= 0) {
        NSAssert(NO, @"no observers");
        return;
    }
    [self checkObserverWithScope:scope forTargetView:targetView];
}

- (void)checkObserverWithScope:(NSString *)scope forTargetView:(UIView * __nullable)targetView {
    if (scope && scope.length > 0) {
        IntersectionObserver *observer = self.observers[scope];
        if (observer) {
            if (!observer.isObserving) {
                return;
            }
            [self findAndHandleObserverWithScope:scope forTargetView:targetView];
        } else {
            NSAssert(NO, @"no observer");
        }
    } else {
        NSAssert(NO, @"no scope");
    }
}

- (void)findAndHandleObserverWithScope:(NSString *)scope forTargetView:(UIView * __nullable)targetView {
    for (NSString *key in [self.observers allKeys]) {
        if ([key isEqualToString:scope]) {
            IntersectionObserver *observer = [self.observers objectForKey:scope];
            if (observer) {
                if (observer.containerOptions && observer.targetOptions) {
                    [IntersectionObserverMeasure measureWithObserver:observer forTargetView:targetView];
                } else {
                    NSAssert(NO, @"no containerOptions or targetOptions");
                }
            } else {
                NSAssert(NO, @"no observer");
            }
        }
    }
}

- (NSDictionary<NSString *, IntersectionObserver *> *)allObservers {
    return self.observers;
}

- (IntersectionObserver *)addObserverWithOptions:(IntersectionObserverContainerOptions *)options {
    if (!options) {
        NSAssert(NO, @"");
        return nil;
    }
    NSString *scope = options.scope;
    if (scope) {
        IntersectionObserver *observer = self.observers[scope];
        if (observer) {
            observer.containerOptions = options;
            return observer;
        }
        observer = [[IntersectionObserver alloc] initWithContainerOptions:options];
        [self.observers setObject:observer forKey:scope];
        return observer;
    } else {
        NSAssert(NO, @"no scope");
    }
    return nil;
}

- (BOOL)removeObserverWithScope:(NSString *)scope {
    if (!scope) {
        return NO;
    }
    if (!self.observers || ![self.observers objectForKey:scope]) {
        return NO;
    }
    [self.observers removeObjectForKey:scope];
    return YES;
}

- (BOOL)removeObserver:(IntersectionObserver *)observer {
    if (!observer) {
        return NO;
    }
    if (!self.observers || ![[self.observers allValues] containsObject:observer]) {
        return NO;
    }
    NSString *scope = [self findScopeWithObserver:observer];
    if (!scope) {
        return NO;
    }
    [self.observers removeObjectForKey:scope];
    return YES;
}

- (NSString *)findScopeWithObserver:(IntersectionObserver *)observer {
    for (NSString *key in [self.observers allKeys]) {
        if (observer == self.observers[key]) {
            return key;
        }
    }
    return nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
