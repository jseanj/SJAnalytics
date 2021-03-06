//
//  AppDelegate.m
//  SJAnalyticsDemo
//
//  Created by knewcloud on 2017/3/24.
//  Copyright © 2017年 jseanj. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "SJAnalytics.h"

@interface AppDelegate () <SJAnalyticsProvider>

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
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
    
    return YES;
}

#pragma mark - SJAnalyticsProvider
- (void)event:(NSString *)event withParameters:(NSDictionary *)parameters {
    NSLog(@"event: %@, and parameters: %@", event, parameters);
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
