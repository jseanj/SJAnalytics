#import <Foundation/Foundation.h>
@protocol SJAnalyticsProvider <NSObject>
- (void)event:(NSString *)event withParameters:(NSDictionary *)parameters;
@end
