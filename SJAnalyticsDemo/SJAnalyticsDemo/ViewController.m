//
//  ViewController.m
//  SJAnalyticsDemo
//
//  Created by knewcloud on 2017/3/24.
//  Copyright © 2017年 jseanj. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self testNoParams];
    [self testParams:@"test"];
    [self testBlockSuccess:^{
        NSLog(@"success");
    } failure:^{
        NSLog(@"failure");
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)testNoParams {
    NSLog(@"testNoParams");
}

- (void)testParams:(NSString *)param {
    NSLog(@"testParams: %@", param);
}

- (void)testBlockSuccess:(void(^)())success failure:(void(^)())failure {
    NSLog(@"testBlock");
    if (success) {
        success();
    }
    if (failure) {
        failure();
    }
}

@end
