//
//  IntersectionObserverEntry.m
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import "IntersectionObserverEntry.h"

@implementation IntersectionObserverEntry

+ (instancetype)initEntryWithTargetView:(UIView *)targetView
                                dataKey:(NSString *)dataKey
                                   data:(NSDictionary *)data
                     boundingClientRect:(CGRect)boundingClientRect
                      intersectionRatio:(CGFloat)intersectionRatio
                       intersectionRect:(CGRect)intersectionRect
                         isIntersecting:(BOOL)isIntersecting
                             rootBounds:(CGRect)rootBounds
                                   time:(NSTimeInterval)time {
    IntersectionObserverEntry *entry = [[IntersectionObserverEntry alloc] init];
    entry.boundingClientRect = boundingClientRect;
    entry.intersectionRatio = intersectionRatio;
    entry.intersectionRect = intersectionRect;
    entry.isIntersecting = isIntersecting;
    entry.rootBounds = rootBounds;
    entry.targetView = targetView;
    entry.time = time;
    entry.dataKey = dataKey;
    entry.data = data;
    return entry;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@, %p>: boundingClientRect = %@, intersectionRatio = %@, intersectionRect = %@, isIntersecting = %@, rootBounds = %@, target = %@, time = %@, dataKey = %@ data = %@", self.class, self,  @(_boundingClientRect), @(_intersectionRatio), @(_intersectionRect), @(_isIntersecting), @(_rootBounds), _targetView, @(_time), _dataKey, _data];
}

@end
