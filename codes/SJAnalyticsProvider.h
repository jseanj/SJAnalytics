#import <Foundation/Foundation.h>

@interface SJAnalyticsProvider : NSObject
+ (instancetype)shared;
- (void)event:(NSString *)event withParameters:(NSDictionary *)parameters;
@end
