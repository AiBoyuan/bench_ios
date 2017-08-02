//
//  AppButton.h
//  JCZJ
//
//  Created by apple on 16/12/27.
//  Copyright © 2016年 apple. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CC_Button : UIButton{
    void (^tappedBlock)(UIButton *button);
}

@property(strong) void (^tappedBlock)(UIButton *button);

/**
 * button的基本功能创建
 */
+ (CC_Button *)createWithFrame:(CGRect)frame
    andTitleString_stateNoraml:(NSString *)titleStr_stateNoraml
andAttributedString_stateNoraml:(NSAttributedString *)attributedString_stateNoraml
     andTitleColor_stateNoraml:(UIColor *)color_stateNoraml
                  andTitleFont:(UIFont *)font
            andBackGroundColor:(UIColor *)backColor
                      andImage:(UIImage *)image
            andBackGroundImage:(UIImage *)backGroundImage
                        inView:(UIView *)view;

/**
 * 防止连续点击后重复调用tap方法
 */
- (void)addTappedBlock:(void (^)(UIButton *button))block;

@end