//
//  QWTransaction.h
//  QuarkWallet
//
//  Created by zhuqiang on 2018/8/17.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDatabaseObject.h"

@class QWWallet, QWToken, QWShard, QWAccount, QWChain;

typedef NS_ENUM(NSInteger, QWTransactionStatus) {
    QWTransactionStatusSuccess,
    QWTransactionStatusFailed,
    QWTransactionStatusPending
};

typedef NS_ENUM(NSInteger, QWTransactionDirection) {
    QWTransactionDirectionSent,
    QWTransactionDirectionReceived
};

typedef NS_ENUM(NSInteger, QWTransactionType) {
    QWTransactionTypeNormal,
    QWTransactionTypeVoteAssetContract = 3,
    QWTransactionTypeVoteWitnessContract,
    QWTransactionTypeFreeze = 11,
    QWTransactionTypeUnfreeze,
    QWTransactionTypeTriggerSmartContract = 31,
};

@interface QWTransaction : QWDatabaseObject

@property (nonatomic, readonly) QWAccount *account;

@property (nonatomic, copy) NSString *txId;
@property (nonatomic, copy) NSString *amount;
@property (nonatomic, copy) NSString *from;
@property (nonatomic, copy) NSString *to;
@property (nonatomic, copy) NSString *block;
@property (nonatomic) NSInteger timestamp;
@property (nonatomic, copy) NSString *cost;
@property (nonatomic) QWTransactionStatus status;
@property (nonatomic) QWShard *shard;
@property (nonatomic) QWChain *chain;
@property (nonatomic) QWToken *token;
@property (nonatomic) QWTransactionDirection direction;
@property (nonatomic) QWTransactionType type;
@property (nonatomic, copy) NSString *gasTokenSymbol;
@property (nonatomic, copy) NSString *gasTokenId;
@property (nonatomic, copy) NSString *transferTokenId;
@property (nonatomic, copy) NSString *transferTokenSymbol;
@property (nonatomic) QWShard *toShard;

@end
