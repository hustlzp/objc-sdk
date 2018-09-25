//
//  AVCloud+Cache.h
//  AVOSCloud-iOS
//
//  Created by hustlzp on 2018/7/30.
//  Copyright © 2018年 LeanCloud Inc. All rights reserved.
//

#import "AVConstants.h"
#import "AVCloud.h"

@interface AVCloud (Cache)

+ (void)rpcFunctionInBackground:(nonnull NSString *)function withParameters:(nullable id)parameters cachePolicy:(AVCachePolicy)cachePolicy maxCacheAge:(NSTimeInterval)maxCacheAge block:(AVIdResultBlock)block;

+ (void)rpcFunctionInBackground:(nonnull NSString *)function cachePolicy:(AVCachePolicy)cachePolicy maxCacheAge:(NSTimeInterval)maxCacheAge block:(AVIdResultBlock)block;

@end
