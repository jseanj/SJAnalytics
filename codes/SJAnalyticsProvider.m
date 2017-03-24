#import "SJAnalyticsProvider.h"

@implementation SJAnalyticsProvider

+ (instancetype)shared {
    static SJAnalyticsProvider *provider;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        provider = [[SJAnalyticsProvider alloc] init];
    });
    return provider;
}

- (void)event:(NSString *)event withParameters:(NSDictionary *)parameters {
    // log
}

@end
