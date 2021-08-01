//
//  IntersectionObserver.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import "IntersectionObserver.h"
#import "IntersectionObserverOptions.h"
#import "IntersectionObserverUtils.h"

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
        if ([self isTargetExisted:target]) {
            IntersectionObserverTargetOptions *oldOptions = [self.targetOptions objectForKey:target];
            BOOL isSameOptions = [IntersectionObserverUtils isTargetOptions:options sameWithOptions:oldOptions];
            if (isSameOptions) {
                return NO;
            } else {
                [self.targetOptions setObject:options forKey:target];
                return YES;
            }
        } else {
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
        if ([self isTargetExisted:target]) {
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

- (BOOL)isTargetExisted:(UIView *)target {
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

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@, %p>: isObserving = %@, containerOptions = %@, targetOptions = %@", self.class, self, @(_isObserving), _containerOptions, _targetOptions];
}

@end
