#import <UIKit/UIKit.h>
#import "SJAnalyticsProvider.h"

@interface UIApplication (SJAnalytics)
@property (nonatomic, strong) id<SJAnalyticsProvider> provider;
@property (nonatomic, strong) NSMutableDictionary *eventDetails;
@property (nonatomic, strong) NSMutableDictionary *selectorEvents;
- (BOOL)sj_sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event;
@end
