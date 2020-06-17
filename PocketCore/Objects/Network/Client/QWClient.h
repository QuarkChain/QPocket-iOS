//
//  QWClient.h
//  QuarkWallet
//
//  Created by Jazys on 2018/10/18.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "AFJSONRPCClient.h"

NS_ASSUME_NONNULL_BEGIN

@class JKBigInteger, QWNetworkClientOptions;
@interface QWClient : AFJSONRPCClient

@property (nonatomic, readonly) QWNetworkClientOptions *options;

@property (nonatomic, copy) NSString *cachedGasPrice;

- (NSInteger)chainID;

- (NSString *)requestURLString;

- (BOOL)testnet;

+ (NSString *)defaultGasPrice;

- (void)getBalanceOfAddress:(NSString *)address
                    success:(void(^)(NSString *balance))success
                    failure:(void(^)(NSError *error))failure;

- (void)getTransactionCount:(NSString *)address
                    success:(void(^)(NSString *))success
                    failure:(void(^)(NSError *))failure;

- (void)getTransactionById:(NSString *)transactionId
                   success:(void(^)(NSDictionary *))success
                   failure:(void(^)(NSError *))failure;

- (void)getTransactionReceipt:(NSString *)transactionId
                      success:(void(^)(NSDictionary *))success
                      failure:(void(^)(NSError *))failure;

- (void)sendRawTransaction:(NSString *)rawTransaction
                   success:(void(^)(id))success
                   failure:(void(^)(NSError *))failure;

- (void)call:(NSString *)contractAddress
        from:(NSString *)from
     dataHex:(NSString *)dataHex
     success:(void(^)(NSString *dataString))success
     failure:(void(^)(NSError *error))failure;

- (void)estimateGasWithParam:(NSDictionary *)params callback:(void(^)(NSString *))callback;

- (JKBigInteger *)defaultGasPrice;
- (JKBigInteger *)defaultTransferGasLimit;
- (JKBigInteger *)defaultContractCallGasLimit;
- (JKBigInteger *)defaultTransferCost;

@end

NS_ASSUME_NONNULL_END
