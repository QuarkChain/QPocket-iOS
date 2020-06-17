//
//  QWAccount.m
//  QuarkWallet
//
//  Created by Jazys on 2018/10/18.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWAccount.h"
#import "QWToken.h"
#import "QWShard.h"
#import "RLMResults+QWDatabase.h"
#import "QWDatabase.h"
#import "QWBalance.h"
#import <JKBigInteger2/JKBigInteger.h>
#import "QWWalletManager.h"
#import "NSString+Address.h"
#import "QWWallet.h"
#import "QWChain.h"

@interface QWAccount()
@property (nonatomic, readonly) RLMLinkingObjects *wallets;
@end

@implementation QWAccount
@synthesize shard = _shard;
@synthesize chain = _chain;

+ (NSDictionary<NSString *,RLMPropertyDescriptor *> *)linkingObjectsProperties {
    return @{@"wallets": [RLMPropertyDescriptor descriptorWithClass:[QWWallet class] propertyName:@"accounts"],
             @"wallets": [RLMPropertyDescriptor descriptorWithClass:[QWWallet class] propertyName:@"currentBTCAccounts"]};
}

- (QWShard *)getShardFromChainWithShardId:(NSUInteger)shardId {
//    NSUInteger shardId = self.coinType.unsignedIntegerValue == QWWalletCoinTypeQKC ? [self.address shardId] : 0;
    return [[self.chain shards] objectsWhere:[NSString stringWithFormat:@"id == '%@'", [NSString stringWithFormat:@"%lu", shardId]]].firstObject;
}

- (QWChain *)chain {
    if (!_chain || _chain.isInvalidated) {
        NSUInteger chainId = self.coinType.unsignedIntegerValue == QWWalletCoinTypeQKC ? [self.address chainId] : 0;
        _chain = [QWChain objectForPrimaryKey:[NSString stringWithFormat:@"%lu", (unsigned long)chainId]];
    }
    return _chain;
}

- (QWBalance *)balanceForToken:(QWToken *)token {
    QWShard *shard = self.shard;
    if(self.coinType.unsignedIntegerValue != QWWalletCoinTypeQKC && self.coinType.unsignedIntegerValue != QWWalletCoinTypeONE){
        shard = [QWShard objectForKey:@"id" value:[token defaultShardId]];
    }
    return [self balanceForToken:token onChain:self.chain inShard:shard];
}

- (QWBalance *)balanceForToken:(QWToken *)token onChain:(QWChain *)chain inShard:(QWShard *)shard {
    QWBalance *balance = [self.balances objectsWhere:[[QWToken tokenFetchConditionWithAddress:token.address coinType:token.coinType.integerValue chainId:token.chainId.integerValue] stringByAppendingFormat:@" AND shard.id == '%@' AND chain.id == '%@'", shard.id, chain.id]].firstObject;
    if(!balance){
        balance = [QWBalance new];
        balance.token = token;
        balance.chain = chain;
        for (QWShard *_shard in chain.shards) {
            if ([_shard.id isEqualToString:shard.id]) {
                balance.shard = _shard;
                break;
            }
        }
        [[QWWalletManager defaultManager].database transactionWithBlock:^{
            [self.balances addObject:balance];
        }];
    }
    return balance;
}

- (RLMResults <QWBalance *> *)balancesForToken:(QWToken *)token {
    return [self.balances objectsWhere:[QWToken tokenFetchConditionWithAddress:token.address coinType:token.coinType.integerValue chainId:token.chainId.integerValue]];
}

- (RLMResults <QWTransaction *> *)transactionsOnPrimaryShard{
    if (self.transactions.isInvalidated) {
        return nil;
    }
    return [self.transactions objectsWhere:[NSString stringWithFormat:@"chain.id == '%@' AND shard.id == '%@'", self.chain.id, self.shard.id]];
}

- (QWWallet *)wallet {
    return self.wallets.firstObject;
}

@end
