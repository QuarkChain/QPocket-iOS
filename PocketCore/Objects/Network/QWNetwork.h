//
//  QWNetwork.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/31.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWHeader.h"
#import "QWClient.h"

FOUNDATION_EXTERN NSNotificationName const QWNetworkReachabilityStatusChangedNotification;

@class QWQKCClient, QWETHClient, QWTRXClient, QWBTCClient, QWONEClient;

@interface QWNetworkFetchOptions : NSObject // For LeanCloud APIs
@property (nonatomic, getter=isFetchTimeLimitEnabled) BOOL fetchTimeLimitEnabled;
@property (nonatomic) BOOL needSaveFetchTimeLimitKey;
@property (nonatomic) NSSortDescriptor *sortDescriptor;
@property (nonatomic) NSArray <NSString *> *relationshipKeys;
@property (nonatomic) NSDictionary <NSString *, id> *keyEqualsToValue;
@property (nonatomic) NSDictionary <NSString *, NSArray <id> *> *keyEqualsToValues;
@property (nonatomic) NSDictionary <NSString *, id> *keyContainsValue;
@property (nonatomic) NSDictionary <NSString *, NSString *> *keyMatchesRegex;
@property (nonatomic) NSArray <NSDictionary <NSString *, NSString *> *> *keyMatchesRegexes;
@property (nonatomic, getter=isOrRelationship) BOOL orRelationship; // defaults to and
@property (nonatomic) NSInteger limit;
@property (nonatomic) NSInteger skip;

@end

typedef enum : NSUInteger {
    QWNetworkRequestOptionsMethodGET,
    QWNetworkRequestOptionsMethodPOST,
} QWNetworkRequestOptionsMethod;

@interface QWNetworkRequestOptions : NSObject // For HTTP/S requests
@property (nonatomic) NSDictionary *headerFields;
@property (nonatomic) NSString *URLString;
@property (nonatomic) BOOL SSLPinningEnabled;
@property (nonatomic) BOOL JSONParameter;
@property (nonatomic) BOOL formParameter;
@property (nonatomic) id parameter;
@property (nonatomic) QWNetworkRequestOptionsMethod method;
@end

@interface QWNetworkClientOptions : NSObject
@property (nonatomic, copy, readonly) NSString *networkId;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *endpointURLString;
@property (nonatomic, copy, readonly) NSString *apiURLString;
@property (nonatomic, readonly) NSInteger chainID;
@property (nonatomic, getter=isMainnet, readonly) BOOL mainnet;
@property (nonatomic, readonly) QWWalletCoinType coinType;
@end

typedef QWWalletCoinType QWNetworkClientType;

@interface QWNetwork : NSObject

+ (void)start;

+ (BOOL)isDebugEnvironment;

+ (NSArray <QWNetworkClientOptions *> *)allClientOptionsWithCoinType:(QWWalletCoinType)coinType;

+ (NSString *)bountyApiURLString;

+ (NSString *)bountyWebsiteURLString;

+ (NSString *)marketApiURLString;

+ (NSString *)marketApiKey;

+ (void)setDidNetworkChangedHandler:(void(^)(AFNetworkReachabilityStatus status, BOOL oldIsReachable))handler;

+ (BOOL)isReachable;

@property (nonatomic, readonly) QWClient *client;

@property (nonatomic) NSTimeInterval fetchTimeLimitInMinute; //set 30 means half an hour, defaults to 1440(24 hours)

@property (nonatomic) QWNetworkClientOptions *clientOptions;

@property (nonatomic) QWNetworkClientType clientType;

@property (nonatomic, copy) dispatch_block_t didClientTypeChanged;

- (instancetype)initWithClientType:(QWNetworkClientType)clientType;

- (QWQKCClient *)qkcClient;

- (QWETHClient *)ethClient;

- (QWTRXClient *)trxClient;

- (QWBTCClient *)btcClient;

- (QWONEClient *)oneClient;

- (BOOL)isTestnetEnabled;

- (BOOL)isTestnetEnabledWithCoinType:(QWNetworkClientType)coinType;

- (QWNetworkClientOptions *)lastClientOptionsWithCoinType:(QWNetworkClientType)coinType;

- (BOOL)isReachable;

- (BOOL)shouldFetchForName:(NSString *)name;

- (void)resetFetchTimeLimitForName:(NSString *)name;

- (void)fetchOnlineConfigForKey:(NSString *)key completion:(void(^)(id config, NSError *error))completion;

- (void)fetchObjectsForName:(NSString *)name completion:(void(^)(NSArray <NSDictionary *> *objects, NSError *error))completion; //no fetch time limit

- (void)fetchObjectsForName:(NSString *)name options:(QWNetworkFetchOptions *)options completion:(void(^)(NSArray <NSDictionary *> *objects, NSError *error))completion;

- (void)requestWithOptions:(QWNetworkRequestOptions *)options response:(void(^)(NSDictionary *object, NSError *error))response;

- (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters response:(void(^)(NSDictionary *object, NSError *error))response;

- (void)GET:(NSString *)URLString parameters:(NSDictionary *)parameters response:(void(^)(NSDictionary *object, NSError *error))response;

- (void)uploadToName:(NSString *)name parameters:(NSDictionary *)parameters pointerParameters:(NSDictionary *)pointerParameters response:(void(^)(NSDictionary *object, NSError *error))response;

- (void)requestWithSSLPinningEnabledMethod:(QWNetworkRequestOptionsMethod)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters response:(void(^)(NSDictionary *object, NSError *error))response;

- (void)fetchObjectsForName:(NSString *)name timeLimitKey:(NSString *)timeLimitKey options:(QWNetworkFetchOptions *)options completion:(void(^)(NSArray <NSDictionary *> *objects, NSError *error))completion;

- (void)GET:(NSString *)URLString headerFields:(NSDictionary *)headerFields parameters:(NSDictionary *)parameters response:(void(^)(NSDictionary *object, NSError *error))response;

@end
