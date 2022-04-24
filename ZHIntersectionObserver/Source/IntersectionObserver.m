//
//  IntersectionObserver.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import "IntersectionObserver.h"
#import "IntersectionObserverOptions.h"
#import "IntersectionObserverMeasure.h"
#import "UIView+IntersectionObserver.h"

@implementation IntersectionObserver

- (instancetype)initWithContainerOptions:(IntersectionObserverContainerOptions *)options {
    if (self == [super init]) {
        _containerOptions = options;
        _targetOptions = [NSMapTable weakToWeakObjectsMapTable];
    }
    return self;
}

- (void)observe {
    _isObserving = YES;
}

- (void)unobserve {
    _isObserving = NO;
}

- (BOOL)addTargetOptions:(UIView *)target options:(IntersectionObserverTargetOptions *)options {
    if (target && options) {
        if ([self isTargetViewExisted:target]) {
            NSAssert(NO, @"当前 target 有 options，应该使用 update 不是重新 set 一个 options");
            return NO;
            /*
            IntersectionObserverTargetOptions *oldOptions = [self.targetOptions objectForKey:target];
            BOOL isSameOptions = [IntersectionObserverMeasure isTargetOptions:options sameWithOptions:oldOptions];
            if (isSameOptions) {
                return NO;
            } else {
                [self.targetOptions setObject:options forKey:target];
                return YES;
            }
            */
        } else {
            // view 不复用，但是 dataKey 一样，这个时候需要移除旧的 options，并且同步旧 options 的 preXxx 属性到新 options 上
            UIView *existTarget = [self isTargetDataKeyExisted:options.dataKey];
            IntersectionObserverTargetOptions *oldOptions = [self.targetOptions objectForKey:existTarget];
            if (existTarget && target != existTarget) {
                [IntersectionObserverMeasure updateOptionsPreProperties:options fromOldOptions:oldOptions];
                // NSLog(@"remove old options %@", oldOptions.dataKey);
                [self.targetOptions removeObjectForKey:existTarget];
            }
            // NSLog(@"add new options %@", options.dataKey);
            [self.targetOptions setObject:options forKey:target];
            return YES;
        }
    } else {
        NSAssert(NO, @"no target or optihons");
        return NO;
    }
}

- (BOOL)removeTargetOptions:(UIView *)target {
    if (target) {
        if ([self isTargetViewExisted:target]) {
            [self.targetOptions removeObjectForKey:target];
            return YES;
        } else {
            return NO;
        }
    } else {
        NSAssert(NO, @"no target");
        return NO;
    }
}

- (BOOL)isTargetViewExisted:(UIView *)target {
    NSEnumerator<UIView *> *targets = self.targetOptions.keyEnumerator;
    BOOL exist = NO;
    for (UIView *aTarget in targets) {
        if (target == aTarget) {
            exist = YES;
            break;
        }
    }
    return exist;
}

- (UIView *)isTargetDataKeyExisted:(NSString *)dataKey {
    if (!dataKey || dataKey.length <= 0) {
        return nil;
    }
    NSEnumerator<UIView *> *targets = self.targetOptions.keyEnumerator;
    UIView *view = nil;
    for (UIView *aTarget in targets) {
        IntersectionObserverTargetOptions *options = [self.targetOptions objectForKey:aTarget];
        if ([dataKey isEqualToString:options.dataKey]) {
            view = aTarget;
            break;
        }
    }
    return view;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@, %p>: isObserving = %@, containerOptions = %@, targetOptions = %@", self.class, self, @(_isObserving), _containerOptions, _targetOptions];
}

@end
