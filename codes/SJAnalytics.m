#import "SJAnalytics.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import "UIApplication+SJAnalytics.h"

static NSMutableDictionary *eventDetails() {
    static NSMutableDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

static NSMutableDictionary *selectorEvents() {
    static NSMutableDictionary *dict;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dict = [[NSMutableDictionary alloc] init];
    });
    return dict;
}

static void sj_swizzSelector(Class class, SEL swizzledSelector, SEL originalSelector) {
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    BOOL success = class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod));
    if (success) {
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    } else {
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

static SEL sj_selectorForOriginSelector(SEL selector) {
    return NSSelectorFromString([NSStringFromSelector(selector) stringByAppendingString:@"__sj"]);
}

static NSString *sj_strForClassAndSelector(Class klass, SEL selector) {
    return [NSString stringWithFormat:@"%@_%@", NSStringFromClass(klass), NSStringFromSelector(selector)];
}

static NSArray *sj_parametersForInvocation(NSInvocation *invocation) {
    NSMethodSignature *methodSignature = [invocation methodSignature];
    NSInteger numberOfArguments = [methodSignature numberOfArguments];
    NSMutableArray *argumentsArray = [NSMutableArray arrayWithCapacity:numberOfArguments - 2];
    for (NSUInteger index = 2; index < numberOfArguments; index++) {
        const char *argumentType = [methodSignature getArgumentTypeAtIndex:index];
        #define WRAP_AND_RETURN(type) \
        do { \
            type val = 0; \
            [invocation getArgument:&val atIndex:(NSInteger)index]; \
            [argumentsArray addObject:@(val)]; \
        } while (0)
        if (strcmp(argumentType, @encode(id)) == 0 || strcmp(argumentType, @encode(Class)) == 0) {
            __autoreleasing id returnObj;
            [invocation getArgument:&returnObj atIndex:(NSInteger)index];
            [argumentsArray addObject:returnObj];
        } else if (strcmp(argumentType, @encode(char)) == 0) {
            WRAP_AND_RETURN(char);
        } else if (strcmp(argumentType, @encode(int)) == 0) {
            WRAP_AND_RETURN(int);
        } else if (strcmp(argumentType, @encode(short)) == 0) {
            WRAP_AND_RETURN(short);
        } else if (strcmp(argumentType, @encode(long)) == 0) {
            WRAP_AND_RETURN(long);
        } else if (strcmp(argumentType, @encode(long long)) == 0) {
            WRAP_AND_RETURN(long long);
        } else if (strcmp(argumentType, @encode(unsigned char)) == 0) {
            WRAP_AND_RETURN(unsigned char);
        } else if (strcmp(argumentType, @encode(unsigned int)) == 0) {
            WRAP_AND_RETURN(unsigned int);
        } else if (strcmp(argumentType, @encode(unsigned short)) == 0) {
            WRAP_AND_RETURN(unsigned short);
        } else if (strcmp(argumentType, @encode(unsigned long)) == 0) {
            WRAP_AND_RETURN(unsigned long);
        } else if (strcmp(argumentType, @encode(unsigned long long)) == 0) {
            WRAP_AND_RETURN(unsigned long long);
        } else if (strcmp(argumentType, @encode(float)) == 0) {
            WRAP_AND_RETURN(float);
        } else if (strcmp(argumentType, @encode(double)) == 0) {
            WRAP_AND_RETURN(double);
        } else if (strcmp(argumentType, @encode(BOOL)) == 0) {
            WRAP_AND_RETURN(BOOL);
        } else if (strcmp(argumentType, @encode(char *)) == 0) {
            WRAP_AND_RETURN(const char *);
        } else if (strcmp(argumentType, @encode(void (^)(void))) == 0) {
            __unsafe_unretained id block = nil;
            [invocation getArgument:&block atIndex:(NSInteger)index];
            if (block) {
                [argumentsArray addObject:[block copy]];
            } else {
                [argumentsArray addObject:[NSNull null]];
            }
        } else {
            NSUInteger valueSize = 0;
            NSGetSizeAndAlignment(argumentType, &valueSize, NULL);
            
            unsigned char valueBytes[valueSize];
            [invocation getArgument:valueBytes atIndex:(NSInteger)index];
            
            [argumentsArray addObject:[NSValue valueWithBytes:valueBytes objCType:argumentType]];
        }
    }
    return [argumentsArray copy];
}

static void SJForwardInvocation(__unsafe_unretained id assignSlf, SEL selector, NSInvocation *invocation) {
    NSArray *events = selectorEvents()[sj_strForClassAndSelector([assignSlf class], invocation.selector)];
    [events enumerateObjectsUsingBlock:^(NSString *eventName, NSUInteger idx, BOOL *stop) {
        NSDictionary *detail = eventDetails()[eventName];
        NSArray *argumentsArray = sj_parametersForInvocation(invocation);
        BOOL (^shouldExecuteBlock)(id object, NSArray *parameters) = detail[SJAnalyticsShouldExecute];
        NSDictionary *(^parametersBlock)(id object, NSArray *parameters) = detail[SJAnalyticsParameters];
        if (shouldExecuteBlock == nil || shouldExecuteBlock(assignSlf, argumentsArray)) {
            [[SJAnalytics shared].provider event:eventName withParameters:parametersBlock(assignSlf, argumentsArray)];
        }
    }];
    SEL newSelector = sj_selectorForOriginSelector(invocation.selector);
    invocation.selector = newSelector;
    [invocation invoke];
}

@implementation SJAnalytics

+ (instancetype)shared {
    static SJAnalytics *analytics;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        analytics = [[SJAnalytics alloc] init];
    });
    return analytics;
}

- (void)configure:(NSDictionary *)configurationDictionary provider:(id<SJAnalyticsProvider>)provider {
    self.provider = provider;
    NSArray *trackedMethodCallEventClasses = configurationDictionary[SJAnalyticsMethodCall];
    [trackedMethodCallEventClasses enumerateObjectsUsingBlock:^(NSDictionary *eventDictionary, NSUInteger idx, BOOL *stop) {
        [self __addMethodCallEventAnalyticsHook:eventDictionary];
    }];
    NSArray *trackedUIControlEventClasses = configurationDictionary[SJAnalyticsUIControl];
    if (trackedUIControlEventClasses.count) {
        sj_swizzSelector([UIApplication class], @selector(sj_sendAction:to:from:forEvent:), @selector(sendAction:to:from:forEvent:));
        [UIApplication sharedApplication].provider = self.provider;
    }
    [trackedUIControlEventClasses enumerateObjectsUsingBlock:^(NSDictionary *eventDictionary, NSUInteger idx, BOOL *stop) {
        [self __addUIControlEventAnalyticsHook:eventDictionary];
    }];
}

- (void)__addMethodCallEventAnalyticsHook:(NSDictionary *)eventDictionary {
    Class klass = eventDictionary[SJAnalyticsClass];
    [eventDictionary[SJAnalyticsDetails] enumerateObjectsUsingBlock:^(id dict, NSUInteger idx, BOOL *stop) {
        NSString *selectorName = dict[SJAnalyticsSelector];
        SEL originSelector = NSSelectorFromString(selectorName);
        Method originMethod = class_getInstanceMethod(klass, originSelector);
        const char *typeEncoding = method_getTypeEncoding(originMethod);
        
        SEL newSelector = sj_selectorForOriginSelector(originSelector);
        class_addMethod(klass, newSelector, method_getImplementation(originMethod), typeEncoding);
        
        class_replaceMethod(klass, originSelector, _objc_msgForward, typeEncoding);
        
        if (class_getMethodImplementation(klass, @selector(forwardInvocation:)) != (IMP)SJForwardInvocation) {
            class_replaceMethod(klass, @selector(forwardInvocation:), (IMP)SJForwardInvocation, "v@:@");
        }
        
        NSMutableDictionary *detailDict = [dict mutableCopy];
        [detailDict removeObjectForKey:SJAnalyticsEvent];
        [eventDetails() setObject:detailDict forKey:dict[SJAnalyticsEvent]];
        
        NSString *selectorKey = sj_strForClassAndSelector(klass, originSelector);
        NSMutableArray *events = selectorEvents()[selectorKey];
        if (!events) events = [NSMutableArray new];
        [events addObject:dict[SJAnalyticsEvent]];
        [selectorEvents() setObject:events forKey:selectorKey];
    }];
}

- (void)__addUIControlEventAnalyticsHook:(NSDictionary *)eventDictionary {
    Class klass = eventDictionary[SJAnalyticsClass];
    [eventDictionary[SJAnalyticsDetails] enumerateObjectsUsingBlock:^(id dict, NSUInteger idx, BOOL *stop) {
        NSString *selectorName = dict[SJAnalyticsSelector];
        SEL originSelector = NSSelectorFromString(selectorName);
        
        NSMutableDictionary *detailDict = [dict mutableCopy];
        [detailDict removeObjectForKey:SJAnalyticsEvent];
        [[UIApplication sharedApplication].eventDetails setObject:detailDict forKey:dict[SJAnalyticsEvent]];
        
        NSString *selectorKey = sj_strForClassAndSelector(klass, originSelector);
        NSMutableArray *events = [UIApplication sharedApplication].selectorEvents[selectorKey];
        if (!events) events = [NSMutableArray new];
        [events addObject:dict[SJAnalyticsEvent]];
        [[UIApplication sharedApplication].selectorEvents setObject:events forKey:selectorKey];
    }];
}

@end
