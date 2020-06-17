//
//  client.h
//  JSONRPCTest
//
//  Created by zhuqiang on 2018/8/3.
//  Copyright © 2018 freedostudio. All rights reserved.
//

#import "QWClient.h"
#import <JKBigInteger2/JKBigInteger.h>
@class GethKeyStore, GethAddress;

@interface QWQKCClient : QWClient

- (void)networkInfoSuccess:(void(^)(NSDictionary *))success failure:(void(^)(NSError *))failure;

- (void)sendTransactionSignedByKeyStore:(GethKeyStore *)keyStore
                            fromAddress:(GethAddress *)fromAddress
                                  nonce:(NSString *)nonce
                               gasPrice:(NSString *)gasPrice
                               gasLimit:(NSString *)gasLimit
                                     to:(NSString *)address
                                  value:(NSString *)value
                                   data:(NSData *)data
                        fromFullShardId:(NSString *)fromFullShardId
                          toFullShardId:(NSString *)toFullShardId
                              networkId:(NSString *)networkId
                             gasTokenId:(NSString *)gasTokenId
                        transferTokenId:(NSString *)transferTokenId
                                success:(void(^)(NSString *))success
                                failure:(void(^)(NSError *))failure;

- (NSString *)getTransactionRawByKeyStore:(GethKeyStore *)keyStore
                            fromAddress:(GethAddress *)fromAddress
                                  nonce:(NSString *)nonce
                               gasPrice:(NSString *)gasPrice
                               gasLimit:(NSString *)gasLimit
                                     to:(NSString *)address
                                  value:(NSString *)value
                                   data:(NSData *)data
                        fromFullShardId:(NSString *)fromFullShardId
                          toFullShardId:(NSString *)toFullShardId
                              networkId:(NSString *)networkId
                             gasTokenId:(NSString *)gasTokenId
                          transferTokenId:(NSString *)transferTokenId;

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data fromFullShardId:(NSString *)fromFullShardId toFullShardId:(NSString *)toFullShardId networkId:(NSString *)networkId gasTokenId:(NSString *)gasTokenId transferTokenId:(NSString *)transferTokenId;

- (NSString *)getTransactionRawWithSignedHash:(NSData *)hash params:(NSDictionary *)params;

- (NSString *)getTransactionHashWithKeyStore:(GethKeyStore *)keyStore fromAddress:(GethAddress *)fromAddress params:(NSDictionary *)params;

- (NSString *)getTxHashWithRawTx:(NSString *)rawTx;

- (void)getAccountData:(NSString *)address
               success:(void(^)(NSDictionary *accountData))success
               failure:(void(^)(NSError *error))failure;

- (void)luckyDrawToAddress:(NSString *)toAddress
                   success:(void(^)(NSString *, NSString *))success
                   failure:(void(^)(NSError *))failure;

- (void)gasPriceInFullShardId:(NSString *)fullShardId
                 callback:(void(^)(NSString *))callback;

- (void)getTransactionsByAddress:(NSString *)address
                            next:(NSString *)next
                         success:(void(^)(NSDictionary *))success
                         failure:(void(^)(NSError *))failure;

- (void)getTransactionsByAddress:(NSString *)address
                            next:(NSString *)next
                           tokenId:(NSString *)tokenId
                         success:(void(^)(NSDictionary *))success
                         failure:(void(^)(NSError *))failure;

- (void)getNativeTokenGasReserves:(NSString *)address chainId:(nullable NSString *)chainId success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *))failure;

@end
