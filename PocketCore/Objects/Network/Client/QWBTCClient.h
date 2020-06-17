//
//  QWBTCClient.h
//  QuarkWallet
//
//  Created by Jazys on 2019/11/1.
//  Copyright © 2019 QuarkChain. All rights reserved.
//

#import "QWClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface QWBTCClient : QWClient

- (void)getInfoOfAddressOrPublicKey:(NSString *)addressOrPublicKey isAddress:(BOOL)isAddress page:(nullable NSString *)page success:(void(^)(NSDictionary *info))success failure:(void(^)(NSError *error))failure;

- (void)getTransactionsDetails:(NSArray <NSString *> *)transactions success:(void(^)(NSDictionary *response))success failure:(void(^)(NSError *error))failure;

- (void)getTransactionRawWithTransactionHash:(NSString *)transactionHash success:(void(^)(NSDictionary *response))success failure:(void(^)(NSError *error))failure;

- (NSDictionary *)findBuildTransactionWithUTXOs:(NSArray *)UTXOs toAddress:(NSString *)toAddress changeAddress:(NSString *)changeAddress amount:(NSString *)amount fee:(NSString *)fee feePrice:(NSString *)feePrice key:(id)key isSegWit:(BOOL)isSegWit;

- (NSDictionary *)buildTransactionWithUTXOs:(NSArray *)UTXOs toAddress:(NSString *)toAddress changeAddress:(NSString *)changeAddress amount:(NSString *)amount fee:(int64_t)fee key:(id)key isSegWit:(BOOL)isSegWit;

@end

NS_ASSUME_NONNULL_END
