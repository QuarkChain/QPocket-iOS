//
//  NSString+balance.h
//  QuarkWallet
//
//  Created by zhuqiang on 2018/8/16.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWHeader.h"

@class QWToken;

@interface NSString (balance)
- (NSString *)balanceStringFromSun;
- (NSString *)balanceStringToSun;
- (NSString *)balanceStringFromWei18DecimalWithRoundingMode:(NSNumberFormatterRoundingMode)roundingMode;
- (NSString *)balanceStringFromWei18DecimalWithRoundingMode:(NSNumberFormatterRoundingMode)roundingMode maximumFractionDigits:(NSUInteger)maximumFractionDigits;
- (NSString *)balanceStringFromWei18DecimalWithCeilingRoundingMode9MaximumFractionDigits;
- (NSString *)gweiBalanceStringFromWei;
- (NSString *)balanceStringUnitOfGWei2WeiWithDecimal:(NSString *)decimal;
- (NSString *)balanceStringUnitOfQKC2Wei;

- (NSString *)balanceStringFromWeiWithDecimal:(NSString *)decimal roundingMode:(NSNumberFormatterRoundingMode)roundingMode;

- (BOOL)hasEnoughBalanceInPrimary;
- (BOOL)hasEnoughBalanceInShard:(NSString *)shardId onChain:(NSString *)chainId forToken:(QWToken *)token;
- (NSArray *)shardsHasEnoughBalanceForShard:(NSString *)shardId onChain:(NSString *)chainId forToken:(QWToken *)token;
- (BOOL)hasEnoughBalanceInTotalForPrimaryShardId:(NSString *)shardId onChain:(NSString *)chainId forToken:(QWToken *)token;

- (BOOL)hasEnoughBalanceByCoinType:(QWWalletCoinType)coinType;

- (NSString *)balanceStringUnitWithDecimal:(NSString *)decimal;

- (NSString *)balanceStringForLog;

- (NSString *)balanceStringFromWeiWithDecimal:(NSString *)decimalStringValue roundingMode:(NSNumberFormatterRoundingMode)roundingMode maximumFractionDigits:(NSUInteger)maximumFractionDigits;

@end
