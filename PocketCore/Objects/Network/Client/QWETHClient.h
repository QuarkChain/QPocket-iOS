//
//  QWETHClient.h
//  QuarkWallet
//
//  Created by Jazys on 2018/10/18.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWClient.h"

NS_ASSUME_NONNULL_BEGIN
@class GethKeyStore, GethAddress;
@interface QWETHClient : QWClient

- (void)getGasPriceCallback:(void(^)(NSString *))callback;

- (void)getTransactionsByAddress:(NSString *)address
                            page:(NSString *)page
                         success:(void(^)(NSArray *response))success
                         failure:(void(^)(NSError *error))failure;

- (void)getTransactionsByAddress:(NSString *)address
                           tokenAddress:(NSString *)tokenAddress
                            page:(NSString *)page
                         success:(void(^)(NSArray *response))success
                         failure:(void(^)(NSError *error))failure;

- (void)sendTransactionSignedByKeyStore:(GethKeyStore *)keyStore
                            fromAddress:(GethAddress *)fromAddress
                                  nonce:(NSString *)nonce
                               gasPrice:(NSString *)gasPrice
                               gasLimit:(NSString *)gasLimit
                                     to:(NSString *)address
                                  value:(NSString *)value
                                   data:(NSData *)data
                                success:(void(^)(NSString *))success
                                failure:(void(^)(NSError *))failure;

- (NSString *)getTxHashByKeyStore:(GethKeyStore *)keyStore
                      fromAddress:(GethAddress *)fromAddress
                            nonce:(NSString *)nonce
                         gasPrice:(NSString *)gasPrice
                         gasLimit:(NSString *)gasLimit
                               to:(NSString *)address
                            value:(NSString *)value
                             data:(NSData *)data;

- (NSString *)getTxHashWithRawTx:(NSData *)rawTx;

- (NSData *)getTxRawByKeyStore:(GethKeyStore *)keyStore fromAddress:(GethAddress *)fromAddress nonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSString *)chainID;

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSNumber *)chainID sha3:(BOOL)sha3;
- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSNumber *)chainID;

- (NSData *)getTransactionRawWithSignedHash:(NSData *)hash params:(NSDictionary *)params;

- (void)getFilterByAddress:(NSString *)address success:(void(^)(NSString *response))success failure:(void(^)(NSError *error))failure;

- (void)getPendingTransactionFilterSuccess:(void(^)(NSString *response))success failure:(void(^)(NSError *error))failure;

- (void)getFilterChangesByFilterId:(NSString *)filterId success:(void(^)(NSDictionary *response))success failure:(void(^)(NSError *error))failure;

- (void)uninstallFilterId:(NSString *)filterId success:(void(^)(NSString *response))success failure:(void(^)(NSError *error))failure;

@end

NS_ASSUME_NONNULL_END
