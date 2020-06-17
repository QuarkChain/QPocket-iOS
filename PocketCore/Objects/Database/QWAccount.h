//
//  QWAccount.h
//  QuarkWallet
//
//  Created by Jazys on 2018/10/18.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDatabaseObject.h"

RLM_ARRAY_TYPE(QWBalance)
RLM_ARRAY_TYPE(QWTransaction)
RLM_ARRAY_TYPE(QWToken)

@class QWTransaction, QWBalance, QWShard, QWToken, QWWallet, QWChain;

typedef enum : NSUInteger {
    QWAccountAddressTypeNormal = 0,
    QWAccountAddressTypeSegWit = 1,
} QWAccountAddressType;

NS_ASSUME_NONNULL_BEGIN

@interface QWAccount : QWDatabaseObject

@property (nonatomic, copy) NSString *address;

@property (nonatomic, copy) NSString *keystoreName;

@property (nonatomic) QWShard *shard;

@property (nonatomic, readonly) QWChain *chain;

@property (nonatomic) RLMArray<QWBalance *><QWBalance> *balances;

@property (nonatomic) RLMArray<QWTransaction *><QWTransaction> *transactions;

@property (nonatomic) RLMArray<QWToken *><QWToken> *favoriteTokens;

@property (nonatomic) NSNumber<RLMInt> *coinType; //QWWalletCoinType

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *iconName;

@property (nonatomic, readonly) QWWallet *wallet;

// Cause realm doesn't support subclass in RLMArray, these properties just for Bitcoin.
@property (nonatomic, copy) NSString *extendedPublicKey;
@property (nonatomic, copy) NSString *encryptedExtendedPrivateKey;
@property (nonatomic) NSNumber <RLMInt> *addressType; //QWAccountAddressType
@property (nonatomic) RLMArray<RLMString> *addresses;
@property (nonatomic) RLMArray<RLMString> *usedAddresses;
@property (nonatomic, copy) NSString *subAddress;

@property (nonatomic, copy) NSString *path;

- (RLMResults <QWBalance *> *)balancesForToken:(QWToken *)token;

- (QWBalance *)balanceForToken:(QWToken *)token;

- (QWBalance *)balanceForToken:(QWToken *)token onChain:(QWChain *)chain inShard:(QWShard *)shard;

- (RLMResults <QWTransaction *> *)transactionsOnPrimaryShard;

- (QWShard *)getShardFromChainWithShardId:(NSUInteger)shardId;

@end

NS_ASSUME_NONNULL_END
