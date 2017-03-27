#import <Foundation/Foundation.h>

extern NSString * const SJAnalyticsMethodCall;
extern NSString * const SJAnalyticsUIControl;
extern NSString * const SJAnalyticsClass;
extern NSString * const SJAnalyticsSelector;
extern NSString * const SJAnalyticsDetails;
extern NSString * const SJAnalyticsParameters;
extern NSString * const SJAnalyticsShouldExecute;
extern NSString * const SJAnalyticsEvent;

@protocol SJAnalyticsProvider <NSObject>
- (void)event:(NSString *)event withParameters:(NSDictionary *)parameters;
@end

@interface SJAnalytics : NSObject
@property (nonatomic, strong) id<SJAnalyticsProvider> provider;
+ (instancetype)shared;
- (void)configure:(NSDictionary *)configurationDictionary provider:(id<SJAnalyticsProvider>)provider;
@end
