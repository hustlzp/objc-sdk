//
//  LCRTMConnection.h
//  AVOSCloudIM
//
//  Created by pzheng on 2020/05/20.
//  Copyright © 2020 LeanCloud Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MessagesProtoOrig.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

@class LCRTMConnection;
@class AVApplication;

typedef NS_ENUM(NSUInteger, LCRTMService) {
    LCRTMServiceLiveQuery = 1,
    LCRTMServiceInstantMessaging = 2,
};

typedef NSString * LCIMProtocol NS_STRING_ENUM;
FOUNDATION_EXPORT LCIMProtocol const LCIMProtocol3;
FOUNDATION_EXPORT LCIMProtocol const LCIMProtocol1;

typedef NSMutableDictionary<NSString *, NSMutableDictionary<NSString *, LCRTMConnection *> *> * LCRTMInstantMessagingRegistry;
typedef NSMutableDictionary<NSString *, LCRTMConnection *> * LCRTMLiveQueryRegistryRegistry;
typedef void(^LCRTMConnectionOutCommandCallback)(AVIMGenericCommand * _Nullable inCommand, NSError * _Nullable error);

@interface LCRTMServiceConsumer : NSObject

@property (nonatomic, readonly) AVApplication *application;
@property (nonatomic, readonly) LCRTMService service;
@property (nonatomic, readonly) LCIMProtocol protocol;
@property (nonatomic, readonly) NSString *peerID;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithApplication:(AVApplication *)application
                            service:(LCRTMService)service
                           protocol:(LCIMProtocol)protocol
                             peerID:(NSString *)peerID NS_DESIGNATED_INITIALIZER;

@end

@interface LCRTMConnectionManager : NSObject

+ (instancetype)sharedManager;

@property (nonatomic) LCRTMInstantMessagingRegistry imProtobuf3Registry;
@property (nonatomic) LCRTMInstantMessagingRegistry imProtobuf1Registry;
@property (nonatomic) LCRTMLiveQueryRegistryRegistry liveQueryRegistry;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (LCRTMConnection *)registerWithServiceConsumer:(LCRTMServiceConsumer *)serviceConsumer
                                           error:(NSError * __autoreleasing *)error;

- (void)unregisterWithServiceConsumer:(LCRTMServiceConsumer *)serviceConsumer;

@end

@protocol LCRTMConnectionDelegate <NSObject>

- (void)LCRTMConnectionInConnecting:(LCRTMConnection *)connection;

- (void)LCRTMConnectionDidConnect:(LCRTMConnection *)connection;

- (void)LCRTMConnection:(LCRTMConnection *)connection didDisconnectWithError:(NSError * _Nullable)error;

- (void)LCRTMConnection:(LCRTMConnection *)connection didReceiveCommand:(AVIMGenericCommand *)inCommand;

@end

@interface LCRTMConnectionDelegator : NSObject

@property (nonatomic, readonly) NSString *peerID;
@property (nonatomic, readonly) dispatch_queue_t queue;
@property (nonatomic, weak) id<LCRTMConnectionDelegate> delegate;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (instancetype)initWithPeerID:(NSString *)peerID
                      delegate:(id<LCRTMConnectionDelegate>)delegate
                         queue:(dispatch_queue_t)queue NS_DESIGNATED_INITIALIZER;

@end

@interface LCRTMConnection : NSObject

@property (nonatomic, readonly) AVApplication *application;
@property (nonatomic, readonly) LCIMProtocol protocol;
@property (nonatomic) NSMutableDictionary<NSString *, LCRTMConnectionDelegator *> *instantMessagingDelegatorMap;
@property (nonatomic) NSMutableDictionary<NSString *, LCRTMConnectionDelegator *> *liveQueryDelegatorMap;

- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

- (void)connectWithServiceConsumer:(LCRTMServiceConsumer *)serviceConsumer
                         delegator:(LCRTMConnectionDelegator *)delegator;

@end

NS_ASSUME_NONNULL_END
