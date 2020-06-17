//
//  QWTRXClient.h
//  QuarkWallet
//
//  Created by Jazys on 2019/2/13.
//  Copyright © 2019 QuarkChain. All rights reserved.
//

#import "QWClient.h"
#import "Tron.pbobjc.h"

NS_ASSUME_NONNULL_BEGIN

@class AccountResourceMessage, TransactionExtention, AssetIssueContract;

@interface QWTRXClient : QWClient

+ (Transaction *)transactionWithDictionary:(NSDictionary *)dictionary;

- (void)getTransferByAddress:(NSString *)address page:(NSString *)page token:(nullable NSString *)token success:(void(^)(NSArray *response))success failure:(void(^)(NSError *error))failure;

- (void)getResourceByAddress:(NSString *)address success:(void(^)(AccountResourceMessage *response))success failure:(void(^)(NSError *error))failure;

- (void)freezeByAddress:(NSString *)address amount:(NSString *)amount isEnergy:(BOOL)isEnergy success:(void(^)(Transaction *transaction))success failure:(void(^)(NSError *error))failure;

- (void)unfreezeByAddress:(NSString *)address isEnergy:(BOOL)isEnergy success:(void(^)(Transaction *transaction))success failure:(void(^)(NSError *error))failure;

- (void)createTransactionFromAddress:(NSString *)fromAddress toAddress:(NSString *)toAddress amount:(NSString *)amount success:(void(^)(Transaction *transaction))success failure:(void(^)(NSError *error))failure;

- (void)broadcastTransaction:(Transaction *)transaction success:(void(^)(NSDictionary *response))success failure:(void(^)(NSError *error))failure;

- (void)getAccountByAddress:(NSString *)address success:(void(^)(Account *response))success failure:(void(^)(NSError *error))failure;

- (void)getTransactionInfoById:(NSString *)txId success:(void(^)(TransactionInfo *response))success failure:(void(^)(NSError *error))failure;

- (void)transferAssetWithId:(NSString *)id fromAddress:(NSString *)fromAddress toAddress:(NSString *)toAddress amount:(NSString *)amount success:(void(^)(Transaction *transaction))success failure:(void(^)(NSError *error))failure;

- (void)triggerContractFromAddress:(NSString *)fromAddress contractAddress:(NSString *)contractAddress data:(NSData *)data functionSelector:(NSString *)functionSelector success:(void(^)(Transaction *transaction, id returnedValue))success failure:(void(^)(NSError *error))failure;

- (void)getTransactionByAddress:(NSString *)address page:(NSString *)page success:(void(^)(NSArray *response))success failure:(void(^)(NSError *error))failure;

- (void)getAssetIssueById:(NSString *)id handler:(void(^)(AssetIssueContract *_Nullable response, NSError *_Nullable error))handler;

@end

NS_ASSUME_NONNULL_END
