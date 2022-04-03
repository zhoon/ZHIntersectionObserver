//
//  IntersectionObserverUtils.h
//  WeHear
//
//  Created by zhoonchen on 2021/6/28.
//

#import <objc/runtime.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class IntersectionObserver, IntersectionObserverContainerOptions, IntersectionObserverTargetOptions;

NS_ASSUME_NONNULL_BEGIN

@interface IntersectionObserverUtils : NSObject

/// 计算相交并且触发 callback
+ (void)measureWithObserver:(IntersectionObserver *)observer;
+ (void)measureWithObserver:(IntersectionObserver *)observer forTargetView:(UIView * __nullable)targetView;

/// 判断两个 options 是否相等
+ (BOOL)isContainerOptions:(IntersectionObserverContainerOptions *)options1
           sameWithOptions:(IntersectionObserverContainerOptions *)options2;

/// 判断两个 options 是否相等
+ (BOOL)isTargetOptions:(IntersectionObserverTargetOptions *)options1
        sameWithOptions:(IntersectionObserverTargetOptions *)options2;

@end


/// 以下方法参考自 QMUI（https://github.com/Tencent/QMUI_iOS）

@interface NSMethodSignature (IntersectionObserver)

/**
 以 NSString 格式返回当前 NSMethodSignature 的 typeEncoding，例如 v@:
 */
@property(nullable, nonatomic, copy, readonly) NSString *intersectionObserver_typeString;

/**
 以 const char 格式返回当前 NSMethodSignature 的 typeEncoding，例如 v@:
 */
@property(nullable, nonatomic, readonly) const char *intersectionObserver_typeEncoding;

@end


@implementation NSMethodSignature (IntersectionObserver)

- (NSString * __nullable)intersectionObserver_typeString {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    NSString *typeString = [self performSelector:NSSelectorFromString([NSString stringWithFormat:@"_%@String", @"type"])];
    #pragma clang diagnostic pop
    return typeString;
}

- (const char * __nullable)intersectionObserver_typeEncoding {
    return self.intersectionObserver_typeString.UTF8String;
}

@end


CG_INLINE BOOL
IntersectionObserver_HasOverrideSuperclassMethod(Class targetClass, SEL targetSelector) {
    Method method = class_getInstanceMethod(targetClass, targetSelector);
    if (!method) return NO;
    
    Method methodOfSuperclass = class_getInstanceMethod(class_getSuperclass(targetClass), targetSelector);
    if (!methodOfSuperclass) return YES;
    
    return method != methodOfSuperclass;
}


CG_INLINE BOOL
IntersectionObserver_OverrideImplementation(Class targetClass, SEL targetSelector, id (^implementationBlock)(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void))) {
    Method originMethod = class_getInstanceMethod(targetClass, targetSelector);
    IMP imp = method_getImplementation(originMethod);
    BOOL hasOverride = IntersectionObserver_HasOverrideSuperclassMethod(targetClass, targetSelector);
    
    // 以 block 的方式达到实时获取初始方法的 IMP 的目的，从而避免先 swizzle 了 subclass 的方法，再 swizzle superclass 的方法，会发现前者调用时不会触发后者 swizzle 后的版本的 bug。
    IMP (^originalIMPProvider)(void) = ^IMP(void) {
        IMP result = NULL;
        if (hasOverride) {
            result = imp;
        } else {
            // 如果 superclass 里依然没有实现，则会返回一个 objc_msgForward 从而触发消息转发的流程
            // https://github.com/Tencent/QMUI_iOS/issues/776
            Class superclass = class_getSuperclass(targetClass);
            result = class_getMethodImplementation(superclass, targetSelector);
        }
        
        // 这只是一个保底，这里要返回一个空 block 保证非 nil，才能避免用小括号语法调用 block 时 crash
        // 空 block 虽然没有参数列表，但在业务那边被转换成 IMP 后就算传多个参数进来也不会 crash
        if (!result) {
            result = imp_implementationWithBlock(^(id selfObject){
                NSLog(@"%@ 没有初始实现，%@\n%@", NSStringFromSelector(targetSelector), selfObject, [NSThread callStackSymbols]);
            });
        }
        
        return result;
    };
    
    if (hasOverride) {
        method_setImplementation(originMethod, imp_implementationWithBlock(implementationBlock(targetClass, targetSelector, originalIMPProvider)));
    } else {
        const char *typeEncoding = method_getTypeEncoding(originMethod) ?: [targetClass instanceMethodSignatureForSelector:targetSelector].intersectionObserver_typeEncoding;
        class_addMethod(targetClass, targetSelector, imp_implementationWithBlock(implementationBlock(targetClass, targetSelector, originalIMPProvider)), typeEncoding);
    }
    
    return YES;
}

CG_INLINE BOOL
IntersectionObserver_ExtendImplementationOfVoidMethodWithoutArguments(Class targetClass, SEL targetSelector, void (^implementationBlock)(__kindof NSObject *selfObject)) {
    return IntersectionObserver_OverrideImplementation(targetClass, targetSelector, ^id(__unsafe_unretained Class originClass, SEL originCMD, IMP (^originalIMPProvider)(void)) {
        void (^block)(__unsafe_unretained __kindof NSObject *selfObject) = ^(__unsafe_unretained __kindof NSObject *selfObject) {
            
            void (*originSelectorIMP)(id, SEL);
            originSelectorIMP = (void (*)(id, SEL))originalIMPProvider();
            originSelectorIMP(selfObject, originCMD);
            
            implementationBlock(selfObject);
        };
        #if __has_feature(objc_arc)
        return block;
        #else
        return [block copy];
        #endif
    });
}

NS_ASSUME_NONNULL_END
