#import "UIApplication+SJAnalytics.h"
#import <objc/runtime.h>
#import "SJAnalyticsConstants.h"

static int const SJAnalyticsProviderKey;
static int const SJAnalyticsEventDetailsKey;
static int const SJAnalyticsSelectorEventsKey;

static NSString *sj_controlStrForClassAndSelector(Class klass, SEL selector) {
    return [NSString stringWithFormat:@"%@_%@", NSStringFromClass(klass), NSStringFromSelector(selector)];
}

@implementation UIApplication (SJAnalytics)

- (id<SJAnalyticsProvider>)provider{
    return objc_getAssociatedObject(self, &SJAnalyticsProviderKey);
}

- (void)setProvider:(id<SJAnalyticsProvider>)provider {
    objc_setAssociatedObject(self, &SJAnalyticsProviderKey, provider, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)eventDetails {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, &SJAnalyticsEventDetailsKey);
    
    if (dict == nil) {
        dict = [NSMutableDictionary new];
        objc_setAssociatedObject(self, &SJAnalyticsEventDetailsKey, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return dict;
}

- (void)setEventDetails:(NSMutableDictionary *)eventDetails {
    objc_setAssociatedObject(self, &SJAnalyticsEventDetailsKey, eventDetails, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSMutableDictionary *)selectorEvents {
    NSMutableDictionary *dict = objc_getAssociatedObject(self, &SJAnalyticsSelectorEventsKey);
    
    if (dict == nil) {
        dict = [NSMutableDictionary new];
        objc_setAssociatedObject(self, &SJAnalyticsSelectorEventsKey, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    
    return dict;
}

- (void)setSelectorEvents:(NSMutableDictionary *)selectorEvents {
    objc_setAssociatedObject(self, &SJAnalyticsSelectorEventsKey, selectorEvents, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)sj_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {    
    NSArray *events = self.selectorEvents[sj_controlStrForClassAndSelector([target class], action)];
    [events enumerateObjectsUsingBlock:^(NSString *eventName, NSUInteger idx, BOOL *stop) {
        NSDictionary *detail = self.eventDetails[eventName];
        BOOL (^shouldExecuteBlock)(id object, NSArray *parameters) = detail[SJAnalyticsShouldExecute];
        NSDictionary *(^parametersBlock)(id object, NSArray *parameters) = detail[SJAnalyticsParameters];
        if (shouldExecuteBlock == nil || shouldExecuteBlock(target, @[])) {
            [self.provider event:eventName withParameters:parametersBlock(target, @[])];
        }
    }];
    
    return [self sj_sendAction:action to:target from:sender forEvent:event];
}
@end
