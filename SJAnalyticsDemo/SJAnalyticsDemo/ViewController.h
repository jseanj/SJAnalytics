//
//  ViewController.h
//  SJAnalyticsDemo
//
//  Created by knewcloud on 2017/3/24.
//  Copyright © 2017年 jseanj. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

- (void)testNoParams;
- (void)testParams:(NSString *)param;
- (void)testBlockSuccess:(void(^)())success failure:(void(^)())failure;

@end

