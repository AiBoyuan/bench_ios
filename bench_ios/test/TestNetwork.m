//
//  testNetwork.m
//  testbenchios
//
//  Created by gwh on 2019/8/15.
//  Copyright © 2019 gwh. All rights reserved.
//

#import "TestNetwork.h"

@implementation TestNetwork

+ (void)start {
    HttpModel *model = [[HttpModel alloc]init];
    model.forbiddenJSONParseError = YES;
    [ccs.httpTask get:@"https://www.jianshu.com/p/a1ec0db3c710" params:nil model:model finishBlock:^(NSString *error, HttpModel *result) {
        
    }];
    
//    [ccs.imageView cc_setImageWithURL:[NSURL URLWithString:@""]];
}

@end
