//
//  CC_Delegate.h
//  bench_ios
//
//  Created by gwh on 2019/8/29.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol CC_Delegate

@end

@interface CC_Delegate : NSObject

@property (nonatomic, retain) NSObject *delegate;

- (void)cc_performSelector:(SEL)selector params:(id)param,...;

@end

NS_ASSUME_NONNULL_END
