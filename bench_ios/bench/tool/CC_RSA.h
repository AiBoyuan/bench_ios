//
//  CC_RSA.h
//  RSAUtil
//
//  Created by gwh on 2019/3/28.
//  Copyright © 2019 ideawu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CC_RSA : NSObject

/**
 *  公钥加密
    NSString格式
 */
+ (NSString *)encryptStr:(NSString *)str publicKey:(NSString *)pubKey;

/**
 *  公钥加密
    NSData格式
 */
+ (NSData *)encryptData:(NSData *)data publicKey:(NSString *)pubKey;

/**
 *  私钥加密
    NSString格式
 */
+ (NSString *)encryptStr:(NSString *)str privateKey:(NSString *)privKey;

/**
 *  私钥加密
    NSData格式
 */
+ (NSData *)encryptData:(NSData *)data privateKey:(NSString *)privKey;

/**
 *  公钥解密
    NSString格式
 */
+ (NSString *)decryptStr:(NSString *)str publicKey:(NSString *)pubKey;

/**
 *  公钥解密
    NSData格式
 */
+ (NSData *)decryptData:(NSData *)data publicKey:(NSString *)pubKey;

/**
 *  私钥解密
    NSString格式
 */
+ (NSString *)decryptStr:(NSString *)str privateKey:(NSString *)privKey;

/**
 *  私钥解密
    NSData格式
 */
+ (NSData *)decryptData:(NSData *)data privateKey:(NSString *)privKey;

@end

NS_ASSUME_NONNULL_END