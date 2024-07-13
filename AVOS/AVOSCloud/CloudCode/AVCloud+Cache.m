//
//  AVCloud+Cache.m
//  AVOSCloud-iOS
//
//  Created by hustlzp on 2018/7/30.
//  Copyright © 2018年 LeanCloud Inc. All rights reserved.
//

#import "AVCloud+Cache.h"
#import "AVCloud.h"
#import "AVPaasClient.h"
#import "AVErrorUtils.h"
#import "AVUtils.h"
#import "AVObject_Internal.h"
#import "AVFile_Internal.h"
#import "AVGeoPoint_Internal.h"
#import "AVObjectUtils.h"
#import "AVLogger.h"
#import "AVUtils.h"
#import "AVCacheManager.h"
#import "AVConstants.h"

@implementation AVCloud (AVCloud_Cache)

// MARK: - Public

+ (void)rpcFunctionInBackground:(NSString *)function withParameters:(nullable id)parameters cachePolicy:(AVCachePolicy)cachePolicy maxCacheAge:(NSTimeInterval)maxCacheAge block:(AVIdResultWithCacheFlagBlock)block
{   
    switch (cachePolicy) {
        case kAVCachePolicyIgnoreCache: {
            [AVCloud rpcFunctionFromNetwork:function withParameters:parameters cachePolicy:cachePolicy block:block];
            break;
        }
        case kAVCachePolicyCacheOnly: {
            [AVCloud rpcFunctionFromCache:function withParameters:parameters maxCacheAge:maxCacheAge block:block];
            break;
        }
        case kAVCachePolicyNetworkOnly: {
            [AVCloud rpcFunctionFromNetwork:function withParameters:parameters cachePolicy:cachePolicy block:block];
            break;
        }
        case kAVCachePolicyCacheElseNetwork: {
            [AVCloud rpcFunctionFromCache:function withParameters:parameters maxCacheAge:maxCacheAge block:^(id _Nullable object, BOOL fromCache, NSError * _Nullable error) {
                if (error != nil) {
                    [AVCloud rpcFunctionFromNetwork:function withParameters:parameters cachePolicy:cachePolicy block:block];
                    return;
                }
                
                block(object, true, error);
            }];
            break;
        }
        case kAVCachePolicyNetworkElseCache: {
            [AVCloud rpcFunctionFromNetwork:function withParameters:parameters cachePolicy:cachePolicy block:^(id _Nullable object, BOOL fromCache, NSError * _Nullable error) {
                if (error != nil) {
                    [AVCloud rpcFunctionFromCache:function withParameters:parameters maxCacheAge:maxCacheAge block:block];
                    return;
                }
                
                block(object, false, error);
            }];
            break;
        }
        case kAVCachePolicyCacheThenNetwork: {
            [AVCloud rpcFunctionFromCache:function withParameters:parameters maxCacheAge:maxCacheAge block:^(id _Nullable object, BOOL fromCache, NSError * _Nullable error) {
                block(object, true, error);
                
                [AVCloud rpcFunctionFromNetwork:function withParameters:parameters cachePolicy:cachePolicy block:block];
            }];
            break;
        }
    }
}

+ (void)clearRpcFunctionCache:(nonnull NSString *)function withParameters:(nullable id)parameters {
    NSDictionary *serializedParameters = [AVCloud processParameters:parameters];
    
    NSString *path = [NSString stringWithFormat:@"call/%@", function];
    NSURLRequest *request = [[AVPaasClient sharedInstance] requestWithPath:path method:@"POST" headers:nil parameters:serializedParameters];
    NSString *key = [AVCloud generateCacheKeyWithRequest:request parameters:parameters];

    [[AVCacheManager sharedInstance] clearCacheForKey:key];
}

// MARK: - Private

+ (void)rpcFunctionFromNetwork:(NSString *)function withParameters:(nullable id)parameters cachePolicy:(AVCachePolicy)cachePolicy block:(AVIdResultWithCacheFlagBlock)block
{
    NSDictionary *serializedParameters = [AVCloud processParameters:parameters];
    
    NSString *path = [NSString stringWithFormat:@"call/%@", function];
    NSURLRequest *request = [[AVPaasClient sharedInstance] requestWithPath:path method:@"POST" headers:nil parameters:serializedParameters];
    NSString *key = [AVCloud generateCacheKeyWithRequest:request parameters:serializedParameters];
    
    [[AVPaasClient sharedInstance]
     performRequest:request
     success:^(NSHTTPURLResponse *response, id responseObject) {
         id result = [self processedFunctionResultFromObject:responseObject[@"result"]];
         [AVUtils callIdResultWithCacheFlagBlock:block object:result fromCache:false error:nil];
         if (cachePolicy != kAVCachePolicyIgnoreCache) {
             [[AVCacheManager sharedInstance] saveJSON:responseObject forKey:key];
         }
     }
     failure:^(NSHTTPURLResponse *response, id responseObject, NSError *inError) {
         [AVUtils callIdResultWithCacheFlagBlock:block object:nil fromCache:false error:inError];
     }];
}

+ (void)rpcFunctionFromCache:(NSString *)function withParameters:(nullable id)parameters maxCacheAge:(NSTimeInterval)maxCacheAge block:(AVIdResultWithCacheFlagBlock)block
{
    NSDictionary *serializedParameters = [self processParameters:parameters];
    
    NSString *path = [NSString stringWithFormat:@"call/%@", function];
    NSURLRequest *request = [[AVPaasClient sharedInstance] requestWithPath:path method:@"POST" headers:nil parameters:serializedParameters];
    NSString *key = [AVCloud generateCacheKeyWithRequest:request parameters:serializedParameters];
    
    [[AVCacheManager sharedInstance] getWithKey:key maxCacheAge:maxCacheAge block:^(id  _Nullable object, NSError * _Nullable error) {
        if (error != nil || object == nil) {
            block(nil, true, error);
            return;
        }
        
        id result = [self processedFunctionResultFromObject:object[@"result"]];
        
        block(result, true, nil);
    }];
}

+ (id)processedFunctionResultFromObject:(id)response {
    id newResultValue;
    if ([response isKindOfClass:[NSArray class]]) {
        newResultValue = [[self class] processedFunctionResultFromArray:response];
    } else if ([response isKindOfClass:[NSDictionary class]]) {
        newResultValue = [[self class] processedFunctionResultFromDic:response];
    } else {
        // String or somethings
        newResultValue = response;
    }
    return newResultValue;
}

+ (id)processedFunctionResultFromArray:(NSArray *)array {
    NSMutableArray *newArray = [NSMutableArray arrayWithCapacity:array.count];
    for (id obj in [array copy]) {
        [newArray addObject:[[self class] processedFunctionResultFromObject:obj]];
    }
    return [newArray copy];
}

+ (id)processedFunctionResultFromDic:(NSDictionary *)dic {
    NSString * type = [dic valueForKey:@"__type"];
    if (type == nil || ![type isKindOfClass:[NSString class]]) {
        NSMutableDictionary *newDic = [NSMutableDictionary dictionaryWithCapacity:dic.count];
        
        for (NSString *key in [dic allKeys]) {
            id o = [dic objectForKey:key];
            [newDic setValue:[[self class] processedFunctionResultFromObject:o] forKey:key];
        }
        
        return [newDic copy];
    } else {
        // 有 __type，则像解析 AVQuery 的结果一样
        return [AVObjectUtils objectFromDictionary:dic];
    }
    return dic;
}

+ (NSString *)generateCacheKeyWithRequest:(NSURLRequest *)request parameters:(nullable NSDictionary *)parameters {
    NSString *result = request.URL.absoluteString;
    
    if (parameters) {
        NSArray *keys = [[parameters allKeys] sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull a, id  _Nonnull b) {
            return [a compare:b];
        }];
        
        for (NSString *key in keys) {
            id value = parameters[key];
            result = [result stringByAppendingString:[NSString stringWithFormat:@".%@-%@", key, value]];
        }
    }
    
    return result;
}

@end
