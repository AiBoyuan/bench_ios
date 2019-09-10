//
//  CC_Runtime.h
//  testbenchios
//
//  Created by gwh on 2019/8/6.
//  Copyright © 2019 gwh. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CC_Runtime : NSObject

+ (instancetype)shared;

+ (id)cc_getObject:(id)object key:(SEL)key;
+ (void)cc_setObject:(id)object key:(SEL)key value:(id)value;

+ (void)cc_exchange:(SEL)s1 to:(SEL)s2;

@end

NS_ASSUME_NONNULL_END
