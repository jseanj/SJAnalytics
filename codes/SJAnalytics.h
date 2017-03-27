#import <Foundation/Foundation.h>
#import "SJAnalyticsProvider.h"
#import "SJAnalyticsConstants.h"

@interface SJAnalytics : NSObject
@property (nonatomic, strong) id<SJAnalyticsProvider> provider;
+ (instancetype)shared;
- (void)configure:(NSDictionary *)configurationDictionary provider:(id<SJAnalyticsProvider>)provider;
@end
