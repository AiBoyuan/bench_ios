//
//  GHttpSessionTask.m
//  NSURLSessionTest
//
//  Created by apple on 15/11/24.
//  Copyright © 2015年 apple. All rights reserved.
//

#import "CC_HttpTask.h"
#import "CC_ResponseLogicModel.h"
#import "Reachability.h"
#import "CC_ImageUploadTask.h"
#import "CC_HttpHelper.h"

#import "CC_Mask.h"

@interface CC_HttpTask()

@end

@implementation CC_HttpTask
@synthesize configure,finishBlock,finishUploadImagesBlock;

// 测试域名是否可用的服务端地址
static NSString *static_domainTestKey = @"/client/service.json?service=TEST";
// 测试是否是线下环境地址
static NSString *static_netTestUrl = @"http://d.net/";
// 根据是否包含关键字判断是否是线下环境地址
static NSString *static_netTestContain = @"http://d.net/";

+ (instancetype)shared {
    return [CC_Base.shared cc_registerSharedInstance:self block:^{
        [CC_HttpTask.shared start];
    }];
}

- (void)start {
    //初始化默认配置
    [configure start];
}

#pragma mark network
- (BOOL)isNetworkReachable {
    Reachability *internetReach = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [internetReach currentReachabilityStatus];
#ifndef __OPTIMIZE__
    switch (netStatus) {
        case NotReachable:
            CCLOG(@"Network is not reachable");
            break;
        case ReachableViaWiFi:
            CCLOG(@"Network is WiFi");
            break;
        case ReachableViaWWAN:
            CCLOG(@"Network is WWAN");
            break;
        default:
            break;
    }
#endif
    if(netStatus == NotReachable) {
        return NO;
    }
    return YES;
}

- (void)post:(id)url params:(id)paramsDic model:(HttpModel *)model finishBlock:(void (^)(NSString *, HttpModel *))block {
    [self request:url params:paramsDic model:model request:nil finishCallbackBlock:^(NSString *error, HttpModel *result) {
        block(error,result);
    } type:CCHttpTaskTypePost];
}

- (void)get:(id)url params:(id)paramsDic model:(HttpModel *)model finishBlock:(void (^)(NSString *error, HttpModel *result))block {
    [self request:url params:paramsDic model:model request:nil finishCallbackBlock:^(NSString *error, HttpModel *result) {
        block(error,result);
    } type:CCHttpTaskTypeGet];
}

- (void)sendRequest:(NSURLRequest *)request model:(HttpModel *)model finishBlock:(void (^)(NSString *error, HttpModel *result))block {
    [self request:nil params:nil model:model request:request finishCallbackBlock:^(NSString *error, HttpModel *result) {
        block(error,result);
    } type:CCHttpTaskTypeRequest];
}

- (void)request:(id)url params:(id)paramsDic model:(HttpModel *)model request:(NSURLRequest *)request finishCallbackBlock:(void (^)(NSString *error, HttpModel *result))block type:(CCHttpTaskType)type {
    
    model = [CC_HttpHelper.shared commonModel:model url:url params:paramsDic configure:configure type:type];
    
    CC_HttpTask *executorDelegate = [[CC_HttpTask alloc] init];
    executorDelegate.finishBlock = block; // 绑定执行完成时的block

    NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession  *session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:executorDelegate delegateQueue:nil];

    NSURLRequest *urlReq;
    if (request) {
        urlReq = request;
    } else {
        urlReq = [[CC_HttpHelper shared] requestWithUrl:model.requestDomain andParamters:model.requestParamsStr model:model configure:configure type:type];
    }
    model.requestUrl=[NSString stringWithFormat:@"%@%@",urlReq.URL.absoluteString,model.requestParamsStr];
    
    NSURLSessionDownloadTask *mytask = [session downloadTaskWithRequest:urlReq completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        [session finishTasksAndInvalidate];
        
        if (error.code == -1003) {
            NSURL *urlBase =  error.userInfo[NSURLErrorFailingURLErrorKey];
            NSString *ipStr = CC_HttpTask.shared.configure.scopeIp;
            if (ipStr.length>0 && urlBase.host.length>0) {
                NSMutableString *mutUrlStr = [NSMutableString stringWithString:urlBase.relativeString];
                NSURL *newUrl = [NSURL URLWithString:[mutUrlStr stringByReplacingOccurrencesOfString:urlBase.host withString:ipStr]];
                [CC_CoreThread.shared cc_gotoMainSync:^{
                    [CC_HttpTask.shared.configure httpHeaderAdd:@"host" value:urlBase.host];
                    [CC_HttpTask.shared request:newUrl params:paramsDic model:model request:request finishCallbackBlock:^(NSString *error, HttpModel *result) {
                        block(error,result);
                    } type:0];
                    executorDelegate.finishBlock(@"", model);
                }];
                return;
            }
        } else {
            [CC_HttpTask.shared.configure httpHeaderRemove:@"host"];
        }
        
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        NSString *dateStr = httpResponse.allHeaderFields[@"Date"];
        model.responseDate = [dateStr cc_convertToDate];
        
        if (error) {
            [model parsingError:error];
        } else {
            NSString *resultStr = [NSString stringWithContentsOfURL:location encoding:NSUTF8StringEncoding error:&error];
            if (!resultStr) {
                CCLOG(@"UTF8编码解析失败");
                NSStringEncoding enc = CFStringConvertEncodingToNSStringEncoding(kCFStringEncodingGB_18030_2000);
                resultStr = [NSString stringWithContentsOfURL:location encoding:enc error:&error];
                if (resultStr) {
                    CCLOG(@"返回头是GBK编码");
                }
            }
            if (model.forbiddenJSONParseError == YES) {
                //html data
                model.resultStr = resultStr;
            } else {
                [model parsingResult:resultStr];
            }
            model.networkError = nil;
            
            if (CC_HttpTask.shared.configure.headerEncrypt == YES && model.forbiddenEncrypt == NO) {
                if ([CC_HttpTask.shared.configure.encryptDomain isEqualToString:model.requestDomain.absoluteString]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
                    Class clazz = NSClassFromString(@"CC_HttpEncryption");
                    resultStr = [clazz performSelector:@selector(getDecryptText:) withObject:model.resultDic];
#pragma clang diagnostic pop
                    if (resultStr) {
                        [model parsingResult:resultStr];
                    }
                }
            }
        }
        
        if (model.resultDic) {
            if (CC_HttpTask.shared.configure.headerEncrypt) {
                CCLOG(@"%@",model.requestParams);
            }
            if (model.debug) {
                CCLOG(@"%@\n%@",model.requestUrl,[[NSString alloc] initWithData:[NSJSONSerialization dataWithJSONObject:model.resultDic options:NSJSONWritingPrettyPrinted error:nil] encoding:NSUTF8StringEncoding]);
            }
        } else {
            CCLOG(@"%@\n%@",model.requestUrl,model.resultStr);
        }
        
        if (model.debug) {
            NSDate *date = [NSDate date];
            NSTimeZone *zone = [NSTimeZone systemTimeZone];
            NSInteger interval = [zone secondsFromGMTForDate:date];
            NSDate *localDate = [date dateByAddingTimeInterval:interval];
            model.responseLocalDate = localDate;
//            [[CCReqRecord getInstance]insertRequestDataWithHHSService:paramsDic[@"service"] requestUrl:tempUrl.absoluteString parameters:paraStr resModelDic:[model cc_getClassKVDic]];
        }
        NSArray *keyNames = [CC_HttpTask.shared.configure.logicBlockMap allKeys];
        for (NSString *name in keyNames) {
            CC_ResLModel *logicModel = CC_HttpTask.shared.configure.logicBlockMap[name];
            if (logicModel.logicPathList.count > 0) {
                [CC_HttpTask.shared reponseLogicPassed:logicModel result:model.resultDic index:0];
                //使用更新后的数据
                CC_ResLModel *newModel = CC_HttpTask.shared.configure.logicBlockMap[logicModel.logicName];
                if (newModel.logicPassed) {
                    [CC_CoreThread.shared cc_gotoMainSync:^{
                        newModel.logicBlock(model,block);
                    }];
                    if (newModel.logicPassStop) {
                        [CC_CoreThread.shared cc_gotoMainSync:^{
                            [[CC_Mask shared]stop];
                        }];
                        return;
                    }
                }
            }
        }
        
        [CC_CoreThread.shared cc_gotoMainSync:^{
            executorDelegate.finishBlock(model.errorMsgStr, model);
        }];
        
    }];
    [mytask resume];
}

#pragma mark NSURLSessionDelegate
- (void)URLSession:(NSURLSession *)session didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * __nullable credential))completionHandler {
    //信任伪造HTTPS证书
    //    if([challenge.protectionSpace.host isEqualToString:@"api.lz517.me"] /*check if this is host you trust: */ ){
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
    //    }
}

- (void)resetResponseLogicPopOnce:(NSString *)logicName {
    CC_ResLModel *model = configure.logicBlockMap[logicName];
    model.logicPopOnce = 0;
    [configure.logicBlockMap setObject:model forKey:logicName];
}

- (void)addResponseLogic:(NSString *)logicName logicStr:(NSString *)logicStr stop:(BOOL)stop popOnce:(BOOL)popOnce logicBlock:(void (^)(HttpModel *result, void (^finishCallbackBlock)(NSString *error,HttpModel *result)))block {
    CC_ResLModel *model = [[CC_ResLModel alloc]init];
    model.logicName = logicName;
    model.logicPassStop = stop;
    model.logicBlock = block;
    model.logicPopOnce = popOnce;
    if ([logicStr containsString:@"="]) {
        NSArray *equal = [logicStr componentsSeparatedByString:@"="];
        model.logicEqualName = equal[1];
        NSString *pathStr = equal[0];
        model.logicPathList = [pathStr componentsSeparatedByString:@","];
    }else{
        model.logicPathList = [logicStr componentsSeparatedByString:@","];
    }
    
    if (!configure.logicBlockMap) {
        configure.logicBlockMap = [[NSMutableDictionary alloc]init];
    }
    [configure.logicBlockMap setObject:model forKey:logicName];
}

- (void)reponseLogicPassed:(CC_ResLModel *)model result:(id)result index:(int)index {
    if (!result) {
        return;
    }
    model.logicPassed = 0;
    if ([result isKindOfClass:[NSString class]]||
        [result isKindOfClass:[NSNumber class]]) {
        if ([result isKindOfClass:[NSNumber class]]) {
            result = [NSString stringWithFormat:@"%@",result];
        }
        if (model.logicEqualName) {
            if ([result isEqualToString:model.logicEqualName]) {//字段相等 通过
                model.logicPassed = 1;
            }else{
                model.logicPassed = 0;
            }
        }else{//有这个字段 通过
            model.logicPassed = 1;
        }
        [configure.logicBlockMap setObject:model forKey:model.logicName];
        return;
    }
    if (index >= model.logicPathList.count) {
        NSCAssert(index < model.logicPathList.count, @"该路径下不是一个字段");
        return;
    }
    [self reponseLogicPassed:model result:result[model.logicPathList[index]] index:index+1];
}

//上传多张图片-指定图片压缩比例
- (void)imageUpload:(NSArray *)images url:(id)url params:(id)paramsDic imageScale:(CGFloat)imageScale reConnectTimes:(NSInteger)times finishBlock:(void (^)(NSArray<HttpModel *> *, NSArray<HttpModel *> *))uploadImageBlock {
    [[CC_Base.shared cc_init:CC_ImageUploadTask.class] uploadImages:images url:url params:paramsDic imageScale:imageScale reConnectTimes:times configure:configure finishBlock:uploadImageBlock];
}

//上传多张图片-指定图片大小 单位 兆
- (void)imageUpload:(NSArray *)images url:(id)url params:(id)paramsDic imageSize:(NSUInteger)imageSize reConnectTimes:(NSInteger)times finishBlock:(void (^)(NSArray<HttpModel *> *, NSArray<HttpModel *> *))uploadImageBlock {
    [[CC_Base.shared cc_init:CC_ImageUploadTask.class] uploadImages:images url:url params:paramsDic imageSize:imageSize reConnectTimes:times configure:configure finishBlock:uploadImageBlock];
}

@end


