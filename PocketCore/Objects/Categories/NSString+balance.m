//
//  NSString+balance.m
//  QuarkWallet
//
//  Created by zhuqiang on 2018/8/16.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "NSString+balance.h"
#import <JKBigInteger2/JKBigDecimal.h>
#import "QWWalletManager+Account.h"
#import "QWBalance.h"
#import "QWWallet.h"
#import "QWShard.h"
#import "QWWalletManager+Token.h"
#import "QWChain.h"
#import "QWToken.h"

@implementation NSString (balance)

- (NSString *)balanceStringFromWei18DecimalWithCeilingRoundingMode9MaximumFractionDigits {
    return [self balanceStringFromWeiWithDecimal:@"18" roundingMode:NSNumberFormatterRoundCeiling maximumFractionDigits:9];
}

- (NSString *)balanceStringFromWei18DecimalWithRoundingMode:(NSNumberFormatterRoundingMode)roundingMode maximumFractionDigits:(NSUInteger)maximumFractionDigits {
    return [self balanceStringFromWeiWithDecimal:@"18" roundingMode:roundingMode maximumFractionDigits:maximumFractionDigits];
}

- (NSString *)balanceStringFromWei18DecimalWithRoundingMode:(NSNumberFormatterRoundingMode)roundingMode {
    return [self balanceStringFromWeiWithDecimal:@"18" roundingMode:roundingMode];
}

- (NSString *)balanceStringFromWeiWithDecimal:(NSString *)decimalStringValue roundingMode:(NSNumberFormatterRoundingMode)roundingMode {
    return [self balanceStringFromWeiWithDecimal:decimalStringValue roundingMode:roundingMode maximumFractionDigits:4];
}

- (NSString *)balanceStringFromWeiWithDecimal:(NSString *)decimalStringValue roundingMode:(NSNumberFormatterRoundingMode)roundingMode maximumFractionDigits:(NSUInteger)maximumFractionDigits {
    
    JKBigDecimal *transformer = [[JKBigDecimal alloc] initWithString:self];
    NSMutableString *decimalString = [NSMutableString stringWithString:@"1"];
    for (NSInteger index = 0; index < decimalStringValue.integerValue; index++) {
        [decimalString appendString:@"0"];
    }
    JKBigDecimal *decimal = [[JKBigDecimal alloc] initWithString:decimalString];
    JKBigDecimal *qkcBalanceIntegerPart = [transformer divide:decimal];
    JKBigDecimal *qkcBalanceFractionPart = [transformer remainder:decimal];
    NSString *qkcIntegerString = [qkcBalanceIntegerPart stringValue];
    NSString *qkcFractionString = [qkcBalanceFractionPart stringValue];
    while (qkcFractionString.length < decimalString.length - 1) {
        qkcFractionString = [NSString stringWithFormat:@"0%@", qkcFractionString];
    }
    NSString *qkcString = [NSString stringWithFormat:@"%@.%@", qkcIntegerString, qkcFractionString];
    
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    formatter.maximumIntegerDigits = 12;
    formatter.minimumIntegerDigits = 1;
    formatter.maximumFractionDigits = maximumFractionDigits;
    formatter.minimumFractionDigits = 0;
    formatter.roundingMode = roundingMode;
    
    NSNumber *number = [formatter numberFromString:qkcString];
    if (!number) {
        number = @0;
    }
    NSAssert(number, @"");
    return [formatter stringFromNumber:number];
}

- (NSString *)balanceStringUnitOfGWei2WeiWithDecimal:(NSString *)decimal {
    NSMutableString *decimalString = [NSMutableString stringWithString:@"1"];
    for (NSInteger index = 0; index < decimal.integerValue / 2; index++) {
        [decimalString appendString:@"0"];
    }
    JKBigInteger *right = [[JKBigInteger alloc] initWithString:decimalString];
    JKBigInteger *left = [[JKBigInteger alloc] initWithString:self];
    JKBigInteger *result = [left multiply:right];
    return [result stringValue];
}

- (NSString *)balanceStringUnitOfQKC2Wei{
    JKBigDecimal *right = [[JKBigDecimal alloc] initWithString:@"1000000000000000000"];
    JKBigDecimal *left = [[JKBigDecimal alloc] initWithString:self];
    JKBigDecimal *result = [left multiply:right];
    NSString *ret = [result stringValue];
    if([ret rangeOfString:@"."].location != NSNotFound){
        ret = [ret substringToIndex:[ret rangeOfString:@"."].location];
    }
    return ret;
}

- (NSString *)gweiBalanceStringFromWei{
    NSString *balance = self;
    if ([self containsString:@"."]) { //round ceiling
        balance = [[[[JKBigInteger alloc] initWithString:[self componentsSeparatedByString:@"."][0]] add:[[JKBigInteger alloc] initWithString:@"1"]] stringValue];
    }
    JKBigDecimal *transformer = [[JKBigDecimal alloc] initWithString:balance];
    JKBigDecimal *decimal = [[JKBigDecimal alloc] initWithString:@"1000000000"];
    JKBigDecimal *qkcBalanceIntegerPart = [transformer divide:decimal];
    JKBigDecimal *qkcBalanceFractionPart = [transformer remainder:decimal];
    NSString *qkcIntegerString = [qkcBalanceIntegerPart stringValue];
    NSString *qkcFractionString = [qkcBalanceFractionPart stringValue];
    while (qkcFractionString.length < 9) {
        qkcFractionString = [NSString stringWithFormat:@"0%@", qkcFractionString];
    }
    NSString *qkcString = [NSString stringWithFormat:@"%@.%@", qkcIntegerString, qkcFractionString];
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    formatter.roundingMode = NSNumberFormatterRoundCeiling;
    formatter.maximumIntegerDigits = 8;
    formatter.minimumIntegerDigits = 1;
    formatter.maximumFractionDigits = 9;
    formatter.minimumFractionDigits = 0;
    NSNumber *number = [formatter numberFromString:qkcString];
    return [formatter stringFromNumber:number];
}

- (BOOL)hasEnoughBalanceInPrimary{
    JKBigInteger *left = [[JKBigInteger alloc] initWithString:self];
    JKBigInteger *right = [QWWalletManager defaultManager].primaryBalance;
    return [left compare:right] != NSOrderedDescending;
}

- (NSArray *)shardsHasEnoughBalanceForShard:(NSString *)shardId onChain:(NSString *)chainId forToken:(QWToken *)token {
    NSMutableArray *shards = [NSMutableArray array];
    JKBigInteger *amountInteger = [[JKBigInteger alloc] initWithString:self];
    for (QWBalance *balance in [[QWWalletManager defaultManager].currentAccount balancesForToken:token]) {
        if ([balance.shard.id isEqualToString:shardId] && [balance.chain.id isEqualToString:chainId]) {
            continue;
        }
        JKBigInteger *amountInShard = [[JKBigInteger alloc] initWithString:balance.balance];
        if([amountInteger compare:amountInShard] != NSOrderedDescending){
            [shards addObject:@{@"shard": balance.shard.id, @"balance": balance.balance, @"chain": balance.chain.id}];
        }
    }
    
    [shards sortUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        NSComparisonResult ret = [[[JKBigInteger alloc] initWithString:obj1[@"balance"]] compare:[[JKBigInteger alloc] initWithString:obj2[@"balance"]]];
        if(ret == NSOrderedAscending){
            return NSOrderedDescending;
        }else if(ret == NSOrderedDescending){
            return NSOrderedAscending;
        }else{
            return ret;
        }
    }];
    return shards;
}

- (BOOL)hasEnoughBalanceInTotalForPrimaryShardId:(NSString *)shardId onChain:(NSString *)chainId forToken:(QWToken *)token {
    JKBigInteger *left = [[JKBigInteger alloc] initWithString:self];
    JKBigInteger *total = [[JKBigInteger alloc] initWithString:@"0"];
    for (QWBalance *balance in [[QWWalletManager defaultManager].currentAccount balancesForToken:token]) {
        if([balance.shard.id isEqualToString:shardId] && [balance.chain.id isEqualToString:chainId]) continue;
        JKBigInteger *balanceInt = [[JKBigInteger alloc] initWithString:balance.balance];
        if([balanceInt compare:[self PM_GetCrossShardCost]] == NSOrderedDescending){
            total = [total add:[balanceInt subtract:[self PM_GetCrossShardCost]]];
        }
    }
    return [left compare:total] != NSOrderedDescending;
}

- (BOOL)hasEnoughBalanceInShard:(NSString *)shardId onChain:(NSString *)chainId forToken:(QWToken *)token {
    JKBigInteger *left = [[JKBigInteger alloc] initWithString:self];
    
    RLMResults <QWBalance *> *balances = [[QWWalletManager defaultManager].currentAccount balancesForToken:token];
    RLMResults <QWBalance *> *result = [balances objectsWhere:[NSString stringWithFormat:@"shard.id == '%@' AND chain.id == '%@'", shardId, chainId]];
    QWBalance *primaryBalance = result.firstObject;
    if (!primaryBalance) {
        return false;
    }
    JKBigInteger *right = [[JKBigInteger alloc] initWithString:primaryBalance.balance];
                           
    return [left compare:right] != NSOrderedDescending;

}

- (JKBigInteger *)PM_GetCrossShardCost{
    return [[QWWalletManager defaultManager].network.client defaultTransferCost];
}

- (BOOL)hasEnoughBalanceByCoinType:(QWWalletCoinType)coinType {
    JKBigInteger *left = [[JKBigInteger alloc] initWithString:self];
    
    QWToken *mainToken = [[QWWalletManager defaultManager] mainTokenByCoinType:coinType];
    QWBalance *primaryBalance = coinType != QWWalletCoinTypeONE ? [[QWWalletManager defaultManager].currentAccount balancesForToken:mainToken].firstObject : [[QWWalletManager defaultManager].currentAccount.balances objectsWhere:[NSString stringWithFormat:@"token.symbol == '%@' && shard.id == '%@'", mainToken.symbol, [QWWalletManager defaultManager].currentAccount.shard.id]].firstObject;
    JKBigInteger *right = [[JKBigInteger alloc] initWithString:primaryBalance.balance];
    
    return [left compare:right] != NSOrderedDescending;
}

- (NSString *)balanceStringForLog {
    return [self balanceStringUnitWithDecimal:@"6"];
}

#pragma mark - TRON

- (NSString *)balanceStringFromSun {
    return [self balanceStringFromWeiWithDecimal:@"6" roundingMode:NSNumberFormatterRoundFloor];
}

- (NSString *)balanceStringToSun {
    return [self balanceStringUnitWithDecimal:@"6"];
}

- (NSString *)balanceStringUnitWithDecimal:(NSString *)decimal {
    NSMutableString *decimalString = [NSMutableString stringWithString:@"1"];
    for (NSInteger index = 0; index < decimal.integerValue; index++) {
        [decimalString appendString:@"0"];
    }
    JKBigDecimal *right = [[JKBigDecimal alloc] initWithString:decimalString];
    JKBigDecimal *left = [[JKBigDecimal alloc] initWithString:self];
    JKBigDecimal *result = [left multiply:right];
    return [[[JKBigInteger alloc] initWithString:result.stringValue] stringValue];
}

@end
