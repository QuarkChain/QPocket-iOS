//
//  QWToken.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWToken.h"
#import "NSString+Address.h"
#import "QWWalletManager+Token.h"
#import "QWNetwork.h"
#import "QWAccount.h"

@implementation QWToken

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"coinType"]) {
        value = @([value integerValue]);
    } else if ([key isEqualToString:@"chainId"]) {
        value = @([value integerValue]);
    }
    [super setValue:value forKey:key];
}

+ (instancetype)tokenWithAddress:(NSString *)address coinType:(QWWalletCoinType)coinType chainId:(NSInteger)chainId {
    return [self objectsWhere:[NSString stringWithFormat:@"address ==[c] '%@' AND coinType == %ld AND chainId == %ld", address, coinType, chainId]].firstObject;
}

+ (NSString *)tokenFetchConditionWithAddress:(NSString *)address coinType:(QWWalletCoinType)coinType chainId:(NSInteger)chainId {
    return [NSString stringWithFormat:@"token.address ==[c] '%@' AND token.coinType == %ld AND token.chainId == %ld", address, coinType, chainId];
}

+ (NSDictionary<NSString *,RLMPropertyDescriptor *> *)linkingObjectsProperties {
    return @{@"accounts": [RLMPropertyDescriptor descriptorWithClass:[QWAccount class] propertyName:@"favoriteTokens"]};
}

- (NSString *)tokenFetchCondition {
    return [self.class tokenFetchConditionWithAddress:self.address coinType:self.coinType.integerValue chainId:self.chainId.integerValue];
}

//+ (NSString *)primaryKey {
//    return @"symbol";
//}

- (NSString *)defaultShardId {
    return @([self.address shardId]).stringValue;
}

- (NSString *)defaultChainId {
    return @([self.address chainId]).stringValue;
}

- (NSString *)testnetSymbolIfNeeded {
//    if ([self.symbol isEqualToString:@"QKC"]) {
//        if ([QWWalletManager defaultManager].network.isTestnetEnabled) {
//            return [@"t" stringByAppendingString:self.symbol];
//        }
//    }
    return self.symbol;
}

- (BOOL)isQKC {
    return [self.address isEqualToString:[QWWalletManager defaultManager].QKC.address];
}

@end
