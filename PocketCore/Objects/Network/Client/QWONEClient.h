//
//  QWONEClient.h
//  QuarkWallet
//
//  Created by Jazys on 2020/6/9.
//  Copyright © 2020 QuarkChain. All rights reserved.
//

#import "QWClient.h"

NS_ASSUME_NONNULL_BEGIN

@class GethKeyStore, GethAddress;

@interface QWONEClient : QWClient

- (void)getBalanceOfAddress:(NSString *)address success:(void (^)(NSDictionary *))success failure:(void (^)(NSError * _Nonnull))failure;

- (void)getBalanceOfAddress:(NSString *)address shardId:(NSString *)shardId success:(void (^)(NSString * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure;

- (void)gasPriceInShardId:(NSString *)shardId callback:(void(^)(NSString *gasPrice))callback;

- (void)getTransactionCount:(NSString *)address shardId:(NSString *)shardId success:(void (^)(NSString * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure;

- (void)sendTransactionSignedByKeyStore:(GethKeyStore *)keyStore fromAddress:(GethAddress *)fromAddress nonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data shardID:(NSNumber *)shardID toShardID:(NSNumber *)toShardID success:(void(^)(NSString *))success failure:(void(^)(NSError *))failure;

- (void)sendRawTransaction:(NSString *)rawTransaction shardId:(NSString *)shardId success:(void(^)(NSString *))success failure:(void(^)(NSError *))failure;

- (NSString *)getTxHashByKeyStore:(GethKeyStore *)keyStore fromAddress:(GethAddress *)fromAddress nonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data shardID:(NSNumber *)shardID toShardID:(NSNumber *)toShardID;

- (void)getTransactionsByAddress:(NSString *)address shardId:(NSString *)shardId page:(NSNumber *)page success:(void(^)(NSArray *))success failure:(void(^)(NSError *))failure;

- (void)getTransactionById:(NSString *)transactionId shardId:(NSString *)shardId success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *))failure;

- (void)getTransactionReceipt:(NSString *)transactionId shardId:(NSString *)shardId success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *))failure;

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSNumber *)chainID shardID:(NSNumber *)shardID toShardID:(NSNumber *)toShardID;

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSNumber *)chainID sha3:(BOOL)sha3 shardID:(NSNumber *)shardID toShardID:(NSNumber *)toShardID;

@end

NS_ASSUME_NONNULL_END
