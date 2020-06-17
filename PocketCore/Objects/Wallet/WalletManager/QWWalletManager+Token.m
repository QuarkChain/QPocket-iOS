//
//  QWWalletManager+Token.m
//  QuarkWallet
//
//  Created by Jazys on 2018/9/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager+Token.h"
#import <objc/runtime.h>
#import "QWToken.h"
#import "QWDatabase.h"
#import "QWNetwork.h"
#import "QWError.h"
#import "QWWalletManager+Account.h"
#import "QWAccount.h"
#import "QWTransaction.h"
#import "RLMArray+QWDatabase.h"
#import "QWBalance.h"
#import "NSString+Address.h"

@implementation QWWalletManager (Token)

- (void)deleteToken:(QWToken *)token {
    
    NSMutableDictionary *blacklist = [[[NSUserDefaults standardUserDefaults] objectForKey:QWWalletManageAutomaticFavorTokenBlacklistKey] mutableCopy];
    NSString *blacklistKey = [NSString stringWithFormat:@"%@_%@_%ld_%ld", [self.currentAccount.address fullShardIdTrimed], [token.address lowercaseString], token.coinType.integerValue, token.chainId.integerValue];
    if ([blacklist[blacklistKey] boolValue]) {
        [blacklist removeObjectForKey:blacklistKey];
        [[NSUserDefaults standardUserDefaults] setObject:blacklist forKey:QWWalletManageAutomaticFavorTokenBlacklistKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    [self.database transactionWithBlock:^{
        
        NSString *condition = [QWToken tokenFetchConditionWithAddress:token.address coinType:token.coinType.integerValue chainId:token.chainId.integerValue];
        
        RLMResults *transactions = [QWTransaction objectsWhere:condition];
        for (QWTransaction *transaction in transactions) {
            [transaction.account.transactions removeObject:transaction];
            [self.database deleteObject:transaction];
        }
        
        RLMResults *balances = [QWBalance objectsWhere:condition];
        for (QWBalance *balance in balances) {
            [balance.account.balances removeObject:balance];
            [self.database deleteObject:balance];
        }
        
        for (QWAccount *account in token.accounts) {
            [account.favoriteTokens removeObject:token];
        }
        
        [self.database deleteObject:token];
        
    }];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidDeleteTokenNotification object:self userInfo:@{@"token":token}];
    
}

- (void)refreshTokensWithCompletion:(dispatch_block_t)completion {
    
    UIViewController *visibleViewController = nil;
    
    NSMutableArray *refreshTokensCompletions = objc_getAssociatedObject(self, _cmd);
    
    if (!refreshTokensCompletions) {
        
        refreshTokensCompletions = [NSMutableArray array];
        
        objc_setAssociatedObject(self, _cmd, refreshTokensCompletions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [refreshTokensCompletions addObject:completion];
        
        QWNetworkFetchOptions *fetchOptions = [QWNetworkFetchOptions new];
        fetchOptions.keyEqualsToValue = @{@"coinType":self.currentAccount.coinType,
                                         @"chainId":@(self.network.clientOptions.chainID),
                                          @"approved":@YES};
        
        RLMResults *allERC20Tokens = [self allERC20Tokens];
        
        [[QWWalletManager defaultManager].network fetchObjectsForName:@"Token" options:fetchOptions completion:^(NSArray<NSDictionary *> *objects, NSError *error) {
            
            if (!error) {
                
                for (QWToken *token in allERC20Tokens) { //check built-in token list and delete if needed
                    if ([token isEqualToObject:[self QKC]] || !token.isBuiltIn) {
                        continue;
                    }
                    BOOL found = false;
                    for (NSDictionary *object in objects) {
                        if ([token.address caseInsensitiveCompare:object[@"address"]] == NSOrderedSame) {
                            found = true;
                            break;
                        }
                    }
                    if (!found) {
                        [self deleteToken:token];
                    }
                }
                
                [self.database transactionWithBlock:^{
                    for (NSDictionary *object in objects) {
                        QWToken *token = [QWToken tokenWithAddress:object[@"address"] coinType:[object[@"coinType"] integerValue] chainId:[object[@"chainId"] integerValue]];
                        if (!token) {
                            token = [QWToken new];
                            token.builtIn = true;
                            [self.database addObject:token];
                        }
                        [token setValuesForKeysWithDictionary:object];
                    }
                }];
                
            }
            
            for (dispatch_block_t _completion in refreshTokensCompletions) {
                _completion();
            }
            
            objc_setAssociatedObject(self, @selector(refreshTokensWithCompletion:), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
        }];
        
    } else {
        [refreshTokensCompletions addObject:completion];
    }
    
}

- (__kindof QWToken *)ETH {
    
    QWToken *ETH = objc_getAssociatedObject(self, _cmd);
    
    if (!ETH) {
        
        ETH = [QWToken objectForKey:@"symbol" value:@"ETH"];
        
        if (!ETH) {
            
            NSMutableString *string = [NSMutableString stringWithString:@"0x"];
            for (NSInteger index = 0; index < 40; index++) {
                [string appendString:@"0"];
            }
            ETH = [QWToken new];
            ETH.builtIn = true;
            ETH.order = 99;
            ETH.name = @"ethereum";
            ETH.symbol = @"ETH";
            ETH.address = string;
            ETH.decimals = @"18";
            ETH.iconNamed = @"wallet_token_eth";
            ETH.URL = @"https://www.ethereum.org";
            ETH.coinType = @(QWWalletCoinTypeETH);
            ETH.descriptionEn = @"The crypto-fuel for Ethereum network.";
            ETH.descriptionCn = @"以太坊系统的基础货币。";
            ETH.chainId = @1;
            ETH.native = true;
            string = [NSMutableString stringWithString:@"1"];
            for (NSInteger index = 0; index < 28; index++) {
                [string appendString:@"0"];
            }
            ETH.totalSupply = string; //Ten billion / (10 ^ decimals)
            
            [self.database transactionWithBlock:^{
                [self.database addObject:ETH];
            }];
            
        }
        
        objc_setAssociatedObject(self, _cmd, ETH, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    }
    
    return ETH;
    
}

- (__kindof QWToken *)QKC {
    
    if (self.currentCoinType == QWWalletCoinTypeQKC) {
        
        if (!self.network.clientOptions.isMainnet) {
            return [self TQKC];
        }
        
        return [self QKCMainnet];
        
    } else if (self.currentCoinType == QWWalletCoinTypeETH) {
        return [self QKCERC20];
    }
    
    return nil;
    
}

- (QWToken *)QKCMainnet {
    
    QWToken *QKC = objc_getAssociatedObject(self, _cmd);
    
    if (!QKC) {
        
        NSString *address = @"0x8bb0";
        
        QKC = [QWToken tokenWithAddress:address coinType:QWWalletCoinTypeQKC chainId:1];
        
        if (!QKC) {
            
            QKC = [QWToken new];
            QKC.builtIn = true;
            QKC.order = 99;
            QKC.name = @"QuarkChain";
            QKC.symbol = @"QKC";
            QKC.address = address;
            QKC.decimals = @"18";
            QKC.URL = @"https://www.quarkchain.io";
            QKC.coinType = @(QWWalletCoinTypeQKC);
            QKC.descriptionEn = @"QuarkChain is a flexible, scalable, and user-oriented blockchain infrastructure by applying sharding technology.";
            QKC.descriptionCn = @"夸克链是一个基于分片技术来搭建的灵活、高拓展性且方便使用的区块链底层架构。它是世界上首个成功实现状态分片的公链之一。";
            QKC.iconNamed = @"wallet_token_qkc";
            QKC.chainId = @1;
            QKC.native = true;
            NSMutableString *qkcString = [NSMutableString stringWithString:@"1"];
            for (NSInteger index = 0; index < 28; index++) {
                [qkcString appendString:@"0"];
            }
            QKC.totalSupply = qkcString; //Ten billion / (10 ^ decimals)
            
            [self.database transactionWithBlock:^{
                [self.database addObject:QKC];
            }];
            
        }
        
        objc_setAssociatedObject(self, _cmd, QKC, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    }
    
    return QKC;
    
}

- (__kindof QWToken *)TQKC {
    
    QWToken *TQKC = objc_getAssociatedObject(self, _cmd);
    
    if (!TQKC) {
        
        NSString *address = @"0x8bb0";
        
        TQKC = [QWToken tokenWithAddress:address coinType:QWWalletCoinTypeQKC chainId:255];
        
        if (!TQKC) {
            
            TQKC = [QWToken new];
            TQKC.builtIn = true;
            TQKC.order = 99;
            TQKC.name = @"QuarkChain";
            TQKC.symbol = @"QKC";
            TQKC.address = address;
            TQKC.decimals = @"18";
            TQKC.URL = @"https://www.quarkchain.io";
            TQKC.coinType = @(QWWalletCoinTypeQKC);
            TQKC.descriptionEn = @"QuarkChain is a flexible, scalable, and user-oriented blockchain infrastructure by applying sharding technology.";
            TQKC.descriptionCn = @"夸克链是一个基于分片技术来搭建的灵活、高拓展性且方便使用的区块链底层架构。它是世界上首个成功实现状态分片的公链之一。";
            TQKC.iconNamed = @"wallet_token_qkc";
            TQKC.chainId = @255;
            TQKC.native = true;
            NSMutableString *qkcString = [NSMutableString stringWithString:@"1"];
            for (NSInteger index = 0; index < 28; index++) {
                [qkcString appendString:@"0"];
            }
            TQKC.totalSupply = qkcString; //Ten billion / (10 ^ decimals)
            
            [self.database transactionWithBlock:^{
                [self.database addObject:TQKC];
            }];
            
        }
        
        objc_setAssociatedObject(self, _cmd, TQKC, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    }
    
    return TQKC;
    
}

- (__kindof QWToken *)QKCERC20 {
    
    QWToken *QKCERC20 = objc_getAssociatedObject(self, _cmd);
    
    if (!QKCERC20) {
        
        NSString *address = @"0xEA26c4aC16D4a5A106820BC8AEE85fd0b7b2b664";
        
        QKCERC20 = [QWToken tokenWithAddress:address coinType:QWWalletCoinTypeETH chainId:1];
        
        if (!QKCERC20) {
            
            QKCERC20 = [QWToken new];
            QKCERC20.builtIn = true;
            QKCERC20.order = 99;
            QKCERC20.name = @"QuarkChain";
            QKCERC20.symbol = @"QKC";
            QKCERC20.address = address;
            QKCERC20.decimals = @"18";
            QKCERC20.URL = @"https://www.quarkchain.io";
            QKCERC20.coinType = @(QWWalletCoinTypeETH);
            QKCERC20.descriptionEn = @"QuarkChain is a flexible, scalable, and user-oriented blockchain infrastructure by applying sharding technology.";
            QKCERC20.descriptionCn = @"夸克链是一个基于分片技术来搭建的灵活、高拓展性且方便使用的区块链底层架构。它是世界上首个成功实现状态分片的公链之一。";
            QKCERC20.iconNamed = @"wallet_token_qkc";
            QKCERC20.chainId = @1;
            QKCERC20.native = false;
            NSMutableString *qkcString = [NSMutableString stringWithString:@"1"];
            for (NSInteger index = 0; index < 28; index++) {
                [qkcString appendString:@"0"];
            }
            QKCERC20.totalSupply = qkcString; //Ten billion / (10 ^ decimals)
            
            [self.database transactionWithBlock:^{
                [self.database addObject:QKCERC20];
            }];
            
        }
        
        objc_setAssociatedObject(self, _cmd, QKCERC20, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    }
    
    return QKCERC20;
    
}

- (__kindof QWToken *)TRX {
    
    QWToken *TRX = objc_getAssociatedObject(self, _cmd);
    
    if (!TRX) {
        
        TRX = [QWToken objectForKey:@"symbol" value:@"TRX"];
        
        if (!TRX) {
            
            NSMutableString *string = nil;
            TRX = [QWToken new];
            TRX.builtIn = true;
            TRX.order = 99;
            TRX.name = @"Tronix";
            TRX.symbol = @"TRX";
            TRX.address = @"1000000";
            TRX.decimals = @"6";
            TRX.iconNamed = @"wallet_token_trx";
            TRX.URL = @"https://tron.network";
            TRX.coinType = @(QWWalletCoinTypeTRX);
            TRX.descriptionEn = @"TRON is one of the largest blockchain-based operating systems in the world.";
            TRX.descriptionCn = @"波场TRON是全球最大的区块链去中心化应用操作系统。";
            TRX.chainId = @1;
            TRX.native = true;
            string = [NSMutableString stringWithString:@"1"];
            for (NSInteger index = 0; index < 28; index++) {
                [string appendString:@"0"];
            }
            TRX.totalSupply = string; //Ten billion / (10 ^ decimals)
            
            [self.database transactionWithBlock:^{
                [self.database addObject:TRX];
            }];
            
        }
        
        objc_setAssociatedObject(self, _cmd, TRX, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    }
    
    return TRX;
    
}

- (__kindof QWToken *)BTC {
    
    QWToken *BTC = objc_getAssociatedObject(self, _cmd);
    
    if (!BTC) {
        
        BTC = [QWToken objectForKey:@"symbol" value:@"BTC"];
        
        if (!BTC) {
            
            BTC = [QWToken new];
            BTC.builtIn = true;
            BTC.order = 99;
            BTC.name = @"Bitcoin";
            BTC.symbol = @"BTC";
            BTC.address = @"0";
            BTC.decimals = @"8";
            BTC.iconNamed = @"wallet_token_btc";
            BTC.URL = @"https://bitcoin.org/";
            BTC.coinType = @(QWWalletCoinTypeBTC);
            BTC.descriptionEn = @"A Peer-to-Peer Electronic Cash System";
            BTC.descriptionCn = @"一种点对点的电子现金系统";
            BTC.chainId = @1;
            BTC.native = true;
            BTC.totalSupply = @"21000000"; //Ten billion / (10 ^ decimals)
            
            [self.database transactionWithBlock:^{
                [self.database addObject:BTC];
            }];
            
        }
        
        objc_setAssociatedObject(self, _cmd, BTC, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    }
    
    return BTC;
    
}

- (__kindof QWToken *)ONE {
    
    QWToken *ONE = objc_getAssociatedObject(self, _cmd);
    
    if (!ONE) {
        
        ONE = [QWToken objectForKey:@"symbol" value:@"ONE"];
        
        if (!ONE) {
            
            ONE = [QWToken new];
            ONE.builtIn = true;
            ONE.order = 99;
            ONE.name = @"harmony";
            ONE.symbol = @"ONE";
            ONE.address = @"one1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqquzw7vz"; //0x00...00(length 42)
            ONE.decimals = @"18";
            ONE.iconNamed = @"wallet_token_one";
            ONE.URL = @"https://www.harmony.one";
            ONE.coinType = @(QWWalletCoinTypeONE);
            ONE.descriptionEn = @"The crypto-fuel for Harmony network.";
            ONE.descriptionCn = @"Harmony的基础货币。";
            ONE.chainId = @1;
            ONE.native = true;
            NSMutableString *string = [NSMutableString stringWithString:@"126"];
            for (NSInteger index = 0; index < 8; index++) {
                [string appendString:@"0"];
            }
            ONE.totalSupply = string; //ONE
            
            [self.database transactionWithBlock:^{
                [self.database addObject:ONE];
            }];
            
        }
        
        objc_setAssociatedObject(self, _cmd, ONE, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
    }
    
    return ONE;
    
}

- (RLMResults *)allERC20Tokens {
    return [QWToken objectsWhere:[NSString stringWithFormat:@"symbol != '%@' AND coinType == %ld AND chainId == %ld", self.mainToken.symbol, (long)self.currentAccount.coinType.unsignedIntegerValue, (long)self.network.clientOptions.chainID]];
}

- (QWToken *)mainTokenByCoinType:(QWWalletCoinType)coinType {
    switch (coinType) {
        case QWWalletCoinTypeETH:
            return self.ETH;
        case QWWalletCoinTypeTRX:
            return self.TRX;
        case QWWalletCoinTypeQKC:
            return [self.network lastClientOptionsWithCoinType:QWWalletCoinTypeQKC].isMainnet ? self.QKCMainnet : self.TQKC;
        case QWWalletCoinTypeBTC:
            return self.BTC;
        case QWWalletCoinTypeONE:
            return self.ONE;
        default:
            return nil;
    }
}

- (QWToken *)mainToken {
    return [self mainTokenByCoinType:self.currentCoinType];
}

@end
