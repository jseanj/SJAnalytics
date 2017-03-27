# SJAnalytics
一个无侵入的统计打点框架

## 功能

- 可以配置统计打点时所需要的全部信息，包括实例和调用方法的参数
- 可以配置是否触发统计打点
- 支持在block中回调统计打点
- 支持屏幕事件统计打点

## 原理

该框架主要监听两类事件：方法调用和点击事件。其中方法调用的事件监听是通过将原始方法的调用指向消息转发的流程，然后通过重写 `forwardInvocation` 获取原始方法的参数等信息进行打点；点击事件的监听是通过重写 `UIApplication` 的 `sendAction:to:from:forEvent:` 获取到 `target` 和 `selector` 进行打点。点击事件的监听也可以通过前者来实现，但是为了避免消息转发带来的性能损耗，建议点击事件的监听用后者来实现。

## Example

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions 
{
  [[SJAnalytics shared] configure:
     @{
       SJAnalyticsMethodCall: @[
               @{
                   SJAnalyticsClass:ViewController.class,
                   SJAnalyticsDetails: @[
                           @{
                               SJAnalyticsEvent: @"testNoParamsEvent",
                               SJAnalyticsSelector: NSStringFromSelector(@selector(testNoParams)),
                               SJAnalyticsShouldExecute:^BOOL(ViewController *instance, NSArray *params) {
                                    return NO;
                               },
                               SJAnalyticsParameters:^NSDictionary*(ViewController *instance, NSArray *params) {
                                    return @{};
                               }
                            },
                           @{
                               SJAnalyticsEvent: @"testParamsEvent",
                               SJAnalyticsSelector: NSStringFromSelector(@selector(testParams:)),
                               SJAnalyticsParameters:^NSDictionary*(ViewController *instance, NSArray *params) {
                                    return @{};
                               }
                            },
                           @{
                               SJAnalyticsEvent: @"testBlockSuccessEvent",
                               SJAnalyticsSelector: NSStringFromSelector(@selector(testBlockSuccess:failure:)),
                               SJAnalyticsShouldExecute:^BOOL(ViewController *instance, NSArray *params) {
                                    if ([params[0] isKindOfClass:[NSNull class]]) {
                                        return NO;
                                    } else {
                                        return YES;
                                    }
                               },
                               SJAnalyticsParameters:^NSDictionary*(ViewController *instance, NSArray *params) {
                                    return @{};
                               }
                            }
                   ]
                }
       ],
       SJAnalyticsUIControl: @[
               @{
                   SJAnalyticsClass:ViewController.class,
                   SJAnalyticsDetails: @[
                           @{
                               SJAnalyticsEvent: @"btnTappedEvent",
                               SJAnalyticsSelector: @"btnTapped:",
                               SJAnalyticsParameters:^NSDictionary*(ViewController *instance, NSArray *params) {
                                    return @{};
                                }
                            }
                    ]
                }
       ]
    } provider:self];
}
```

```objc
- (void)event:(NSString *)event withParameters:(NSDictionary *)parameters {
    // log your event
}
```