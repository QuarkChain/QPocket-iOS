//
//  QWWalletManager+Account.m
//  QuarkWallet
//
//  Created by Jazys on 2018/9/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager+Account.h"
#import "QWWallet.h"
#import <objc/runtime.h>
#import "QWWalletManager+Token.h"
#import "QWShard.h"
#import "QWBalance.h"
#import "QWQKCClient.h"
#import "QWDatabase.h"
#import "NSString+Address.h"
#import "QWTransaction.h"
#import "QWToken.h"
#import "PocketCore-Swift.h"
#import "QWError.h"
#import "QWWalletManager+Keystore.h"
#import <JKBigInteger2/JKBigDecimal.h>
#import "QWKeystore.h"
#import "QWNetwork.h"
#import <Geth/Geth.h>
#import "QWWalletManager+Private.h"
#import "QWETHClient.h"
#import "RLMResults+QWDatabase.h"
#import "NSString+balance.h"
#import "QWCheckParams.h"
#import "QWTRXClient.h"
#import "NSData+QWHexString.h"
#import "QWChain.h"
#import "NSString+QWExtension.h"
#import "QWBTCClient.h"
#import "QWONEClient.h"

QWUserDefaultsKey const QWWalletManageAutomaticFavorTokenBlacklistKey = @"QWWalletManageAutomaticFavorTokenBlacklistKey";

@implementation QWWalletManager (Account)

- (void)setCurrentWallet:(QWWallet *)currentWallet {
    id oldWallet = objc_getAssociatedObject(self, @selector(currentWallet));
    [self.database transactionWithBlock:^{
        [self.database updateAllObjectsWithClass:[QWWallet class] value:@NO forKey:@"primary"];
        currentWallet.primary = true;
    }];
    objc_setAssociatedObject(self, @selector(currentWallet), currentWallet, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    self.network.clientType = currentWallet.currentAccountType;
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidCurrentWalletChangedNotification object:self userInfo:oldWallet ? @{@"oldWallet":oldWallet} : nil];
}

- (QWWallet *)currentWallet {
    id currentWallet = objc_getAssociatedObject(self, _cmd);
    if (!currentWallet) {
        currentWallet = [QWWallet objectWhere:@"primary == true"];
        if (!currentWallet) {
            QWWallet *firstWallet = [QWWallet allObjects].firstObject;
            [self.database transactionWithBlock:^{
                firstWallet.primary = true;
            }];
            currentWallet = firstWallet;
        }
        [self.database transactionWithBlock:^{
            for (QWWallet *wallet in [QWWallet allObjects]) {
                if (!wallet.currentAccount) {
                    wallet.currentAccount = wallet.accounts.firstObject;
                    NSLog(@"jazys found wallet current account is nil, auto set to the first account wallet: %@ account: %@", wallet, wallet.currentAccount);
                }
            }
        }];
        objc_setAssociatedObject(self, _cmd, currentWallet, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return currentWallet;
}

- (QWAccount *)currentAccount {
    return self.currentWallet.currentAccount;
}

- (QWWalletCoinType)currentCoinType {
    return self.currentWallet.currentAccountType;
}

- (NSString *)currentCoinName {
    return [self coinNameWithCoinType:self.currentCoinType];
}

- (NSString *)coinNameWithCoinType:(QWWalletCoinType)coinType {
    switch (coinType) {
        case QWWalletCoinTypeQKC:
            return @"QKC";
        case QWWalletCoinTypeETH:
            return @"ETH";
        case QWWalletCoinTypeTRX:
            return @"TRX";
        case QWWalletCoinTypeBTC:
            return @"BTC";
        case QWWalletCoinTypeONE:
            return @"ONE";
        default:
            break;
    }
    return nil;
}

- (NSString *)localizedChainNameWithCoinType:(QWWalletCoinType)coinType {
    switch (coinType) {
        case QWWalletCoinTypeBTC:
            return QWLocalizedString(@"QWWalletSwitchViewController.category.btc");
        case QWWalletCoinTypeETH:
            return QWLocalizedString(@"QWWalletSwitchViewController.category.eth");
        case QWWalletCoinTypeTRX:
            return QWLocalizedString(@"QWWalletSwitchViewController.category.trx");
        case QWWalletCoinTypeQKC:
            return QWLocalizedString(@"QWWalletSwitchViewController.category.qkc");
        case QWWalletCoinTypeONE:
            return QWLocalizedString(@"QWWalletSwitchViewController.category.one");
        default:
            return nil;
    }
}

- (JKBigInteger *)primaryBalance{
    RLMResults <QWBalance *> *balances = [[QWWalletManager defaultManager].currentWallet.currentAccount balancesForToken:self.QKC];
    NSString *primaryShardId = self.currentWallet.currentAccount.shard.id;
    RLMResults <QWBalance *> *result = [balances objectsWhere:[NSString stringWithFormat:@"shard.id = '%@'", primaryShardId]];
    QWBalance *primaryBalance = result.firstObject;
    return [[JKBigInteger alloc] initWithString:primaryBalance.balance];
}

- (JKBigInteger *)totalBalance{
    RLMResults <QWBalance *> *balances = [[QWWalletManager defaultManager].currentWallet.currentAccount balancesForToken:[QWWalletManager defaultManager].mainToken];
    JKBigInteger *total = [[JKBigInteger alloc] initWithString:@"0"];
    for(QWBalance *balance in balances){
        JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:balance.balance];
        total = [total add:transformer];
    }
    return total;
}

- (void)refreshCurrentAccountBalanceWithCompletion:(void(^)(id params, NSError *error))completion {
    [self refreshCurrentAccountBalanceWithCompletion:completion notify:true];
}

- (void)refreshCurrentAccountBalanceWithCompletion:(void(^)(id params, NSError *error))completion notify:(BOOL)notify {
    [self refreshAccountBalance:self.currentAccount withCompletion:completion notify:notify];
}

- (void)refreshAccountBalance:(QWAccount *)currentAccount withCompletion:(void(^)(id params, NSError *error))completion notify:(BOOL)notify {
    
    UIViewController *visibleViewController = nil;
    
    if (currentAccount.coinType.unsignedIntegerValue == QWWalletCoinTypeQKC) {
        
        [self.network.qkcClient getAccountData:currentAccount.address success:^(NSDictionary *balances) {
            
            if (!currentAccount.isInvalidated) {
                !completion ?: completion(nil, nil);
                return;
            }
            
            NSMutableDictionary *nativeTokenAddressDictionary = [NSMutableDictionary dictionary];
            
            for (QWToken *nativeToken in [QWToken objectsWhere:[NSString stringWithFormat:@"coinType == %ld AND chainId == %ld AND native == true", QWWalletCoinTypeQKC, (long)self.network.clientOptions.chainID]]) {
                nativeTokenAddressDictionary[nativeToken.address] = nativeToken;
                RLMResults *allQKCBalances = [currentAccount.balances objectsWhere:[NSString stringWithFormat:@"token.symbol == '%@'", nativeToken.symbol]];
                [self.database transactionWithBlock:^{
                    [self.database deleteObjects:allQKCBalances];
                }];
            }
         
            for (NSDictionary *dict in balances[@"shards"]) {
                for (NSDictionary *balanceInfo in dict[@"balances"]) {
                    JKBigInteger *balanceInt = [[JKBigInteger alloc] initWithString:@"0"];
                    QWToken *nativeToken = nativeTokenAddressDictionary[balanceInfo[@"tokenId"]];
                    NSString *balanceString = balanceInfo[@"balance"];
                    balanceInt = [[JKBigInteger alloc] initWithString:[balanceString passByFirstTwoBytes] andRadix:16];
                    QWChain *chain = [QWChain objectForPrimaryKey:[dict[@"chainId"] integerStringFromHex]];
                    QWShard *shard = [chain.shards objectsWhere:[NSString stringWithFormat:@"id == '%@'", [dict[@"shardId"] integerStringFromHex]]].firstObject;
                    QWBalance *balance = [currentAccount balanceForToken:nativeToken onChain:chain inShard:shard];
                    [self.database transactionWithBlock:^{
                        balance.balance = [balanceInt stringValue];
                    }];
                }
            }
            
            !completion ?: completion(nil, nil);
            
            if (notify) {
                [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidBalanceChangedNotification object:self];
            }
            
        } failure:^(NSError *error) {
            !completion ?: completion(nil, error);
        }];
    } else if (currentAccount.coinType.unsignedIntegerValue == QWWalletCoinTypeETH) {
        [self.network.ethClient getBalanceOfAddress:currentAccount.address success:^(NSString * _Nonnull balanceString) {
            
            if (!currentAccount.isInvalidated) {
                !completion ?: completion(nil, nil);
                return;
            }
            
            [self.database transactionWithBlock:^{
                [self.database deleteObjects:[currentAccount.balances objectsWhere:[NSString stringWithFormat:@"token.symbol == '%@'", self.ETH.symbol]]];
            }];
            
            JKBigInteger *balanceInt = [[JKBigInteger alloc] initWithString:[balanceString passByFirstTwoBytes] andRadix:16];
            QWBalance *balance = [currentAccount balanceForToken:self.ETH];
            [self.database transactionWithBlock:^{
                balance.balance = [balanceInt stringValue];
            }];
            
            !completion ?: completion(nil, nil);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidBalanceChangedNotification object:self];
            
        } failure:^(NSError * _Nonnull error) {
            
            !completion ?: completion(nil, error);
            
        }];
    } else if (currentAccount.coinType.unsignedIntegerValue == QWWalletCoinTypeTRX) {
        [self.network.trxClient getBalanceOfAddress:currentAccount.address success:^(NSString * _Nonnull balanceString) {
            
            if (!currentAccount.isInvalidated) {
                !completion ?: completion(nil, nil);
                return;
            }
            
            [self refreshCurrentAccountBalanceDBWithBalance:balanceString];
            
            !completion ?: completion(nil, nil);
            
            
        } failure:^(NSError * _Nonnull error) {
            
            !completion ?: completion(nil, error);
            
        }];
    } else if (currentAccount.coinType.unsignedIntegerValue == QWWalletCoinTypeBTC) {
        [self.network.btcClient getInfoOfAddressOrPublicKey:currentAccount.extendedPublicKey ?: currentAccount.address isAddress:currentAccount.extendedPublicKey == nil page:@"0" success:^(NSDictionary * _Nonnull info) {
            
            if (!currentAccount.isInvalidated) {
                !completion ?: completion(nil, nil);
                return;
            }
            
            NSDictionary *data = info[@"data"];
            
            if (![info[@"data"] isKindOfClass:[NSDictionary class]]) {
                !completion ?: completion(nil, nil);
                return;
            }
            
            [self.database transactionWithBlock:^{
                [self.database deleteObjects:[[QWWalletManager defaultManager].currentAccount.balances objectsWhere:[NSString stringWithFormat:@"token.symbol == '%@'", self.BTC.symbol]]];
            }];
            
            NSString *balanceString = @"0";
            if (currentAccount.extendedPublicKey) {
                balanceString = [data.allValues.firstObject[@"xpub"][@"balance"] stringValue];
            } else {
                balanceString = [data.allValues.firstObject[@"address"][@"balance"] stringValue];
            }
            
            QWBalance *balance = [currentAccount balanceForToken:self.BTC];
            
            NSMutableArray *usedAddresses = [NSMutableArray array];
            for (NSString *usedAddress in [data.allValues.firstObject[@"addresses"] allKeys]) {
                [usedAddresses addObject:[usedAddress componentsSeparatedByString:@": "].lastObject];
            }
            
            [self.database transactionWithBlock:^{
                [currentAccount.usedAddresses removeAllObjects];
                [currentAccount.usedAddresses addObjects:usedAddresses];
                balance.balance = balanceString;
            }];
            
            objc_setAssociatedObject(currentAccount, @selector(transaction), data, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidBalanceChangedNotification object:self];
            
            !completion ?: completion(info, nil);
            
        } failure:^(NSError * _Nonnull error) {
            !completion ?: completion(nil, error);
        }];
    } else if (currentAccount.coinType.unsignedIntegerValue == QWWalletCoinTypeONE) {
        [self.network.oneClient getBalanceOfAddress:currentAccount.address success:^(NSDictionary *balances) {

            if (!currentAccount.isInvalidated) {
                !completion ?: completion(nil, nil);
                return;
            }
            
            [self.database transactionWithBlock:^{
                [self.database deleteObjects:[currentAccount.balances objectsWhere:[NSString stringWithFormat:@"token.symbol == '%@'", self.ONE.symbol]]];
            }];
            
            [balances enumerateKeysAndObjectsUsingBlock:^(NSString *shardId, NSString *balanceString, BOOL * _Nonnull stop) {
                JKBigInteger *balanceInt = [[JKBigInteger alloc] initWithString:[balanceString passByFirstTwoBytes] andRadix:16];
                QWBalance *balance = [currentAccount balanceForToken:self.ONE onChain:currentAccount.chain inShard:[currentAccount getShardFromChainWithShardId:shardId.integerValue]];
                [self.database transactionWithBlock:^{
                    balance.balance = [balanceInt stringValue];
                }];
            }];
            
            !completion ?: completion(nil, nil);
            
            [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidBalanceChangedNotification object:self];
            
        } failure:^(NSError * _Nonnull error) {
            !completion ?: completion(nil, error);
        }];
    }
}

- (void)refreshCurrentAccountBalanceDBWithBalance:(NSString *)balanceString {
    
    if (self.currentCoinType == QWWalletCoinTypeTRX) {
        
        [self.database transactionWithBlock:^{
            [self.database deleteObjects:[[QWWalletManager defaultManager].currentAccount.balances objectsWhere:[NSString stringWithFormat:@"token.symbol == '%@'", self.TRX.symbol]]];
        }];
        
        QWBalance *balance = [[QWWalletManager defaultManager].currentAccount balanceForToken:self.TRX];
        [self.database transactionWithBlock:^{
            balance.balance = balanceString;
        }];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidBalanceChangedNotification object:self];
        
    }
    
}

- (void)refreshCurrentAccountTransactionsWithCompletion:(void(^)(NSString *))completion {
    [self refreshAccountTransactionsWithAccount:self.currentAccount completion:completion];
}

- (void)refreshAccountTransactionsWithAccount:(QWAccount *)account completion:(void(^)(NSString *))completion {
    
    dispatch_group_t group = dispatch_group_create();
    __block NSArray *completeTxs = [NSArray array];
    __block NSArray *pendingTxs = [NSArray array];
    UIViewController *visibleViewController = nil;
    
    if (account.coinType.unsignedIntegerValue == QWWalletCoinTypeQKC) {
        __block NSString *next = nil;
        dispatch_group_enter(group);
        [self.network.qkcClient getTransactionsByAddress:account.address next:@"0x00" success:^(NSDictionary *response) {
            pendingTxs = response[@"txList"];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
        dispatch_group_enter(group);
        [self.network.qkcClient getTransactionsByAddress:account.address next:nil success:^(NSDictionary *response) {
            completeTxs = response[@"txList"];
            dispatch_group_leave(group);
            next = response[@"next"];
        }failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            NSArray *txs = [pendingTxs arrayByAddingObjectsFromArray:completeTxs];
            if ([txs qw_isAllDictionariesKeysExists:@[@"txId", @"fromAddress", @"toAddress", @"blockHeight", @"value", @"timestamp", @"success"]]) {
                [self.database transactionWithBlock:^{
                    [self.database deleteObjects:account.transactionsOnPrimaryShard];
                }];
                [self writeTxs2Database:txs forToken:nil account:account forAccountTokenTransaction:false];
            }
            !completion ?: completion(next);
        });
    } else if (account.coinType.unsignedIntegerValue == QWWalletCoinTypeETH) {
        
        [self.network.ethClient getTransactionsByAddress:account.address page:@"1" success:^(NSArray *response) {
            completeTxs = response;
            [self.database transactionWithBlock:^{
                [self.database deleteObjects:[account.transactionsOnPrimaryShard objectsWhere:[self.ETH tokenFetchCondition]]];
            }];
            [self writeTxs2Database:completeTxs forToken:nil account:account forAccountTokenTransaction:false];
            !completion ?: completion(nil);
        } failure:^(NSError * _Nonnull error) {
            !completion ?: completion(nil);
        }];
        
    } else if (account.coinType.unsignedIntegerValue == QWWalletCoinTypeTRX) {
        
        [self.network.trxClient getTransactionByAddress:account.address page:@"0" success:^(NSArray * _Nonnull response) {
            completeTxs = response;
            [self.database transactionWithBlock:^{
                [self.database deleteObjects:[account.transactionsOnPrimaryShard objectsWhere:[self.TRX tokenFetchCondition]]];
            }];
            [self writeTxs2Database:completeTxs forToken:nil account:account forAccountTokenTransaction:false];
            !completion ?: completion(nil);
        } failure:^(NSError * _Nonnull error) {
            !completion ?: completion(nil);
        }];
        
    } else if (account.coinType.unsignedIntegerValue == QWWalletCoinTypeBTC) {
        
        __weak typeof(self) weakSelf = self;
        
        void (^refreshTransaction)(NSDictionary *data) = ^(NSDictionary *data) {
            
            typeof(weakSelf) self = weakSelf;
            
            NSArray *transactions = data.allValues.firstObject[@"transactions"];
            NSArray *addresses = [data.allValues.firstObject[@"addresses"] allKeys];
            if (!addresses) {
                addresses = @[account.address];
            }
            NSDateFormatter *dateFormatter = [NSDateFormatter new];
            dateFormatter.dateFormat = @"yyyy-MM-dd hh:mm:ss";
//            [NSTimeZone timeZoneWithName:@"Asia/Shanghai"]
            NSDate *beijingDate = [NSDate dateWithTimeIntervalSince1970:-[NSTimeZone systemTimeZone].secondsFromGMT];
            
            [self.network.btcClient getTransactionsDetails:transactions success:^(NSDictionary * _Nonnull response) {
                
                [self.database transactionWithBlock:^{
                    [self.database deleteObjects:[account.transactionsOnPrimaryShard objectsWhere:[self.BTC tokenFetchCondition]]];
                }];
                
                NSDictionary *transactionInfo = response[@"data"];
                for (NSString *transactionHash in transactions) {
                    NSDictionary *txInfo = transactionInfo[transactionHash];
                    NSDictionary *tx = txInfo[@"transaction"];
                    
                    QWTransaction *transaction = [QWTransaction new];
                    transaction.txId = tx[@"hash"];
                    transaction.block = [tx[@"block_id"] stringValue];
                    transaction.timestamp = [[dateFormatter dateFromString:tx[@"time"]] timeIntervalSinceDate:beijingDate];
                    transaction.token = self.BTC;
                    transaction.direction = QWTransactionDirectionReceived;
                    transaction.cost = [tx[@"fee"] stringValue];
                    
                    JKBigInteger *amount = [[JKBigInteger alloc] initWithString:@"0"];
                    NSNumber *value = @0;
                    for (NSDictionary *input in txInfo[@"inputs"]) {
                        if ([addresses containsObject:input[@"recipient"]]) {
                            transaction.direction = QWTransactionDirectionSent;
                            transaction.from = account.address;
                            amount = [amount add:[[JKBigInteger alloc] initWithString:[input[@"value"] stringValue]]];
                        } else if (transaction.direction == QWTransactionDirectionReceived) {
                            if ([input[@"value"] compare:value] == NSOrderedDescending) {
                                value = input[@"value"];
                                transaction.from = input[@"recipient"];
                            }
                        }
                    }
                    
                    if (transaction.direction == QWTransactionDirectionSent) {
                        JKBigInteger *inputAmout = [[JKBigInteger alloc] initWithString:amount.stringValue];
                        for (NSDictionary *output in txInfo[@"outputs"]) {
                            if ([addresses containsObject:output[@"recipient"]]) {
                                amount = [amount subtract:[[JKBigInteger alloc] initWithString:[output[@"value"] stringValue]]];
                            } else if (!transaction.to) {
                                transaction.to = output[@"recipient"];
                            }
                        }
                        amount = [amount subtract:[[JKBigInteger alloc] initWithString:transaction.cost]];
                        if (!transaction.to) { // transfer to self
                            transaction.to = account.address;
                            amount = [[JKBigInteger alloc] initWithString:@"0"];
                        }
                        if ([amount compare:[[JKBigInteger alloc] initWithString:@"0"]] == NSOrderedAscending) {
                            amount = inputAmout;
                        }
                    } else {
                        transaction.to = account.address;
                        for (NSDictionary *output in txInfo[@"outputs"]) {
                            if ([addresses containsObject:output[@"recipient"]]) {
                                amount = [amount add:[[JKBigInteger alloc] initWithString:[output[@"value"] stringValue]]];
                            }
                        }
                    }
                    
                    transaction.shard = account.shard;
                    transaction.chain = account.chain;
                    transaction.amount = amount.stringValue;
                    
                    if ([tx[@"block_id"] isKindOfClass:[NSNumber class]] && ![tx[@"block_id"] isEqual:@-1]) {
                        transaction.status = QWTransactionStatusSuccess;
                    } else {
                        transaction.status = QWTransactionStatusPending;
                    }
                    
                    [self.database transactionWithBlock:^{
                        [account.transactions addObject:transaction];
                    }];
                    
                }
                !completion ?: completion(nil);
            } failure:^(NSError * _Nonnull error) {
                !completion ?: completion(nil);
            }];
            
        };
        
        NSDictionary *data = objc_getAssociatedObject(account, @selector(transaction));
        
        if (!data) {
            
            [self refreshCurrentAccountBalanceWithCompletion:^(id params, NSError *error) {
                
                if (!params) {
                    !completion ?: completion(nil);
                    return;
                }
                
                refreshTransaction(params[@"data"]);
                
            }];
            
        } else {
            
            refreshTransaction(data);
            objc_setAssociatedObject(account, @selector(transaction), nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
        }
        
    } else if (account.coinType.unsignedIntegerValue == QWWalletCoinTypeONE) {
        [self.network.oneClient getTransactionsByAddress:account.address shardId:account.shard.id page:@0 success:^(NSArray *response) {
            completeTxs = response;
            [self.database transactionWithBlock:^{
                [self.database deleteObjects:[account.transactionsOnPrimaryShard objectsWhere:[self.ONE tokenFetchCondition]]];
            }];
            [self writeTxs2Database:completeTxs forToken:nil account:account forAccountTokenTransaction:false];
            !completion ?: completion(nil);
        } failure:^(NSError *error) {
            !completion ?: completion(nil);
        }];
    }
    
}

- (void)refreshCurrentAccountTokenTransactions:(QWToken *)token completion:(void(^)(NSString *))completion {
    
    __block NSArray *completeTxs = [NSArray array];
    
    UIViewController *visibleViewController = nil;
    
    QWAccount *currentAccount = self.currentWallet.currentAccount;
    
    if (self.currentCoinType == QWWalletCoinTypeQKC) {
        
        __block NSString *next = nil;
        __block NSArray *pendingTxs = nil;
        __block NSArray *transactions = nil;
        dispatch_group_t group = dispatch_group_create();
        dispatch_group_enter(group);
        [self.network.qkcClient getTransactionsByAddress:currentAccount.address next:@"0x00" tokenId:token.address success:^(NSDictionary *response) {
            pendingTxs = response[@"txList"];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
        dispatch_group_enter(group);
        [self.network.qkcClient getTransactionsByAddress:currentAccount.address next:nil tokenId:token.address success:^(NSDictionary *response) {
            transactions = response[@"txList"];
            next = response[@"next"];
            dispatch_group_leave(group);
        }failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            completeTxs = [pendingTxs arrayByAddingObjectsFromArray:transactions];
            if ([completeTxs qw_isAllDictionariesKeysExists:@[@"txId", @"fromAddress", @"toAddress", @"blockHeight", @"value", @"timestamp", @"success"]]) {
                [self.database transactionWithBlock:^{
                    [self.database deleteObjects:[currentAccount.transactionsOnPrimaryShard objectsWhere:[token tokenFetchCondition]]];
                }];
                [self writeTxs2Database:completeTxs forToken:token account:currentAccount forAccountTokenTransaction:true];
            }
            !completion ?: completion(next);
        });
        
    } else if (self.currentCoinType == QWWalletCoinTypeTRX) {
        
        [self.network.trxClient getTransferByAddress:currentAccount.address page:@"0" token:token.name success:^(NSArray * _Nonnull response) {
            completeTxs = response;
            [self.database transactionWithBlock:^{
                [self.database deleteObjects:[currentAccount.transactionsOnPrimaryShard objectsWhere:[token tokenFetchCondition]]];
            }];
            [self writeTxs2Database:completeTxs forToken:token account:currentAccount forAccountTokenTransaction:true];
            !completion ?: completion(nil);
        } failure:^(NSError * _Nonnull error) {
            !completion ?: completion(nil);
        }];
        
    } else if (self.currentCoinType == QWWalletCoinTypeETH) {
        
        [self.network.ethClient getTransactionsByAddress:self.currentAccount.address tokenAddress:token.address page:@"0" success:^(NSArray * _Nonnull response) {
            completeTxs = response;
            [self.database transactionWithBlock:^{
                [self.database deleteObjects:[currentAccount.transactionsOnPrimaryShard objectsWhere:[token tokenFetchCondition]]];
            }];
            [self writeTxs2Database:completeTxs forToken:token account:currentAccount forAccountTokenTransaction:true];
            !completion ?: completion(nil);
        } failure:^(NSError * _Nonnull error) {
            !completion ?: completion(nil);
        }];
        
    }
    
}

- (void)refreshTransactionsForToken:(QWToken *)token completion:(void(^)(NSString *))completion {
    
    UIViewController *visibleViewController = nil;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    dispatch_group_enter(group);
    __block NSArray *completeTxs = [NSArray array];
    __block NSArray *pendingTxs = [NSArray array];
    
    QWAccount *currentAccount = self.currentAccount;
    
    if (token.coinType.integerValue == QWWalletCoinTypeQKC) {
        __block NSString *next = nil;
        [self.network.qkcClient getTransactionsByAddress:token.address next:@"0x00" success:^(NSDictionary *response) {
            pendingTxs = response[@"txList"];
            dispatch_group_leave(group);
        } failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
        [self.network.qkcClient getTransactionsByAddress:token.address next:nil success:^(NSDictionary *response) {
            completeTxs = response[@"txList"];
            dispatch_group_leave(group);
            next = response[@"next"];
        }failure:^(NSError *error) {
            dispatch_group_leave(group);
        }];
        
        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                NSArray *txs = [pendingTxs arrayByAddingObjectsFromArray:completeTxs];
                if ([txs qw_isAllDictionariesKeysExists:@[@"txId", @"fromAddress", @"toAddress", @"blockHeight", @"value", @"timestamp", @"success"]]) {
                    [self.database transactionWithBlock:^{
                        NSMutableArray *transactions = [NSMutableArray array];
                        for (QWTransaction *transaction in [QWTransaction objectsWhere:token.tokenFetchCondition]) {
                            if (!transaction.account) {
                                [transactions addObject:transaction];
                            }
                        }
                        [self.database deleteObjects:transactions];
                    }];
                    [self writeTxs2Database:txs forToken:token account:currentAccount forAccountTokenTransaction:false];
                }
            !completion ?: completion(next);
        });
    } else if (token.coinType.integerValue == QWWalletCoinTypeETH) {
        
        [self.network.ethClient getTransactionsByAddress:token.address page:@"1" success:^(NSArray *response) {
            completeTxs = response;
                [self.database transactionWithBlock:^{
                    NSMutableArray *transactions = [NSMutableArray array];
                    for (QWTransaction *transaction in [QWTransaction objectsWhere:token.tokenFetchCondition]) {
                        if (!transaction.account) {
                            [transactions addObject:transaction];
                        }
                    }
                    [self.database deleteObjects:transactions];
                }];
                [self writeTxs2Database:completeTxs forToken:token account:currentAccount forAccountTokenTransaction:false];
            !completion ?: completion(nil);
        } failure:^(NSError * _Nonnull error) {
            !completion ?: completion(nil);
        }];
        
    }
}

- (void)writeTxs2Database:(NSArray *)txs forToken:(QWToken *)token account:(QWAccount *)account forAccountTokenTransaction:(BOOL)forAccountTokenTransaction {
    
    QWWalletCoinType coinType = token ? token.coinType.unsignedIntegerValue : account.coinType.unsignedIntegerValue;
    
    if (coinType == QWWalletCoinTypeQKC) {
        
//        NSMutableDictionary *tokensPool = [NSMutableDictionary dictionary];
        
        for (NSDictionary *tx in txs) {
            
            QWTransaction *transaction = [QWTransaction new];
            
            transaction.transferTokenId = tx[@"transferTokenId"];
            transaction.transferTokenSymbol = tx[@"transferTokenStr"];
            
            transaction.txId = tx[@"txId"];
            transaction.from = tx[@"fromAddress"];
            transaction.to = tx[@"toAddress"];
            
            NSString *blockString = tx[@"blockHeight"];
            JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:[blockString passByFirstTwoBytes]
                                                                    andRadix:16];
            transaction.block = [transformer stringValue];
            
            NSString *valueString = tx[@"value"];
            transformer = [[JKBigInteger alloc] initWithString:[valueString passByFirstTwoBytes]
                                                      andRadix:16];
            transaction.amount = [transformer stringValue];
            
            NSString *timestampString = tx[@"timestamp"];
            transformer = [[JKBigInteger alloc] initWithString:[timestampString passByFirstTwoBytes]
                                                      andRadix:16];
            transaction.timestamp = [transformer unsignedIntValue];
            
            if (forAccountTokenTransaction) {
                transaction.chain = self.currentAccount.chain;
                transaction.shard = self.currentWallet.currentAccount.shard;
            } else {
                transaction.chain = !token ? self.currentAccount.chain : [QWChain objectForKey:@"id" value:[token defaultChainId]];
                transaction.shard = !token ? self.currentWallet.currentAccount.shard : [QWShard objectForKey:@"id" value:[token defaultShardId]];
            }
            
            transaction.token = !token ? self.QKC : token;
            transaction.gasTokenId = tx[@"gasTokenId"];
            transaction.gasTokenSymbol = tx[@"gasTokenStr"];
            
            if([transaction.from isEqualToString:[self.currentWallet.currentAccount.address lowercaseString]]){
                transaction.direction = QWTransactionDirectionSent;
            }else{
                transaction.direction = QWTransactionDirectionReceived;
            }
            
            NSNumber *status = tx[@"success"];
            if (status.boolValue) {
                transaction.status = QWTransactionStatusSuccess;
            }else{
                if([tx[@"timestamp"] isEqualToString:@"0x0"]){
                    transaction.status = QWTransactionStatusPending;
                }else{
                    transaction.status = QWTransactionStatusFailed;
                }
            }
            
            [self.database transactionWithBlock:^{
                if (!token) {
                    [self.currentWallet.currentAccount.transactions addObject:transaction];
                } else {
                    if (forAccountTokenTransaction) {
                        [self.currentWallet.currentAccount.transactions addObject:transaction];
                    } else {
                        [self.database addObject:transaction];
                    }
                }
            }];
        }
        
    } else if (coinType == QWWalletCoinTypeETH) {
        
        for (NSDictionary *tx in txs) {
            QWTransaction *transaction = [QWTransaction new];
            transaction.txId = tx[@"hash"];
            transaction.from = tx[@"from"];
            transaction.to = tx[@"to"];
            
            transaction.block = tx[@"blockNumber"];
            
            transaction.amount = tx[@"value"];
            
            transaction.timestamp = [tx[@"timeStamp"] integerValue];
            
            if (forAccountTokenTransaction) {
                transaction.chain = self.currentAccount.chain;
                transaction.shard = self.currentWallet.currentAccount.shard;
            } else {
                transaction.chain = !token ? self.currentAccount.chain : [QWChain objectForKey:@"id" value:[token defaultChainId]];
                transaction.shard = !token ? self.currentWallet.currentAccount.shard : [QWShard objectForKey:@"id" value:[token defaultShardId]];
            }
            
            transaction.token = !token ? self.ETH : token;
            
            if([transaction.from isEqualToString:[self.currentWallet.currentAccount.address lowercaseString]]){
                transaction.direction = QWTransactionDirectionSent;
            }else{
                transaction.direction = QWTransactionDirectionReceived;
            }
            
            if (!tx[@"isError"] || [tx[@"isError"] isEqualToString:@"0"]) {
                transaction.status = QWTransactionStatusSuccess;
            }else{
                if([tx[@"timeStamp"] isEqualToString:@"0"]){
                    transaction.status = QWTransactionStatusPending;
                }else{
                    transaction.status = QWTransactionStatusFailed;
                }
            }
            
            [self.database transactionWithBlock:^{
                if (!token) {
                    [self.currentWallet.currentAccount.transactions addObject:transaction];
                } else {
                    if (forAccountTokenTransaction) {
                        [self.currentWallet.currentAccount.transactions addObject:transaction];
                    } else {
                        [self.database addObject:transaction];
                    }
                }
            }];
        }
        
    } else if (coinType == QWWalletCoinTypeTRX) {
        
        for (NSDictionary *tx in txs) {
            QWTransaction *transaction = [QWTransaction new];
            
            if (tx[@"hash"]) {
                transaction.txId = tx[@"hash"];
                transaction.from = tx[@"ownerAddress"];
                transaction.to = tx[@"toAddress"];
                if (!transaction.to.length) {
                    transaction.to = transaction.from; // frozen in 3.0
                }
                NSDictionary *contractData = tx[@"contractData"];
                transaction.amount = [(contractData[@"call_value"] ?: !contractData[@"asset_name"] ? contractData[@"amount"] ?: @(0) : @(0)) stringValue];
            } else {
                transaction.txId = tx[@"transactionHash"];
                transaction.from = tx[@"transferFromAddress"];
                transaction.to = tx[@"transferToAddress"];
                transaction.amount = [tx[@"amount"] stringValue];
            }
            
            transaction.type = [tx[@"contractType"] integerValue];
            if (transaction.type != QWTransactionTypeFreeze &&
                transaction.type != QWTransactionTypeUnfreeze &&
                transaction.type != QWTransactionTypeTriggerSmartContract &&
                transaction.type != QWTransactionTypeVoteAssetContract &&
                transaction.type != QWTransactionTypeVoteWitnessContract) {
                transaction.type = QWTransactionTypeNormal;
            }
            
            transaction.block = [tx[@"block"] stringValue];
            
            transaction.timestamp = [tx[@"timestamp"] integerValue] / 1000;
            
            if (forAccountTokenTransaction) {
                transaction.chain = self.currentAccount.chain;
                transaction.shard = self.currentWallet.currentAccount.shard;
            } else {
                transaction.chain = !token ? self.currentAccount.chain : [QWChain objectForKey:@"id" value:[token defaultChainId]];
                transaction.shard = !token ? self.currentWallet.currentAccount.shard : [QWShard objectForKey:@"id" value:[token defaultShardId]];
            }
            
            transaction.token = !token ? self.TRX : token;
            
            if([transaction.from isEqualToString:self.currentWallet.currentAccount.address]){
                transaction.direction = QWTransactionDirectionSent;
            }else{
                transaction.direction = QWTransactionDirectionReceived;
            }
            
//            if ([tx[@"isError"] isEqualToString:@"0"]) {
            if ([tx[@"confirmed"] boolValue]) {
                transaction.status = QWTransactionStatusSuccess;
            } else {                
                transaction.status = QWTransactionStatusPending;
            }
//            }else{
//                if([[tx[@"timestamp"] stringValue] isEqualToString:@"0"]){
//                }else{
//                    transaction.status = QWTransactionStatusFailed;
//                }
//            }
            
            [self.database transactionWithBlock:^{
                if (!token) {
                    [self.currentWallet.currentAccount.transactions addObject:transaction];
                } else {
                    if (!forAccountTokenTransaction) {
                        [self.database addObject:transaction];
                    } else {
                        [self.currentWallet.currentAccount.transactions addObject:transaction];
                    }
                }
            }];
        }
        
    } else if (coinType == QWWalletCoinTypeONE) {
        
        for (NSDictionary *tx in txs) {
            QWTransaction *transaction = [QWTransaction new];
            transaction.txId = tx[@"hash"];
            transaction.from = tx[@"from"];
            transaction.to = tx[@"to"];
            
            transaction.block = tx[@"blockNumber"];
            
            transaction.amount = [[[JKBigInteger alloc] initWithString:[tx[@"value"] passByFirstTwoBytes] andRadix:16] stringValue];
            
            transaction.timestamp = [[[[JKBigInteger alloc] initWithString:[tx[@"timestamp"] passByFirstTwoBytes] andRadix:16] stringValue] integerValue];
            
            if (forAccountTokenTransaction) {
                transaction.chain = self.currentAccount.chain;
//                transaction.shard = self.currentWallet.currentAccount.shard;
            } else {
                transaction.chain = !token ? self.currentAccount.chain : [QWChain objectForKey:@"id" value:[token defaultChainId]];
//                transaction.shard = !token ? self.currentWallet.currentAccount.shard : [QWShard objectForKey:@"id" value:[token defaultShardId]];
            }
            transaction.shard = [QWShard objectForKey:@"id" value:[tx[@"shardID"] stringValue]];
            transaction.toShard = [QWShard objectForKey:@"id" value:[tx[@"toShardID"] stringValue]];
            
            transaction.token = !token ? self.ONE : token;
            
            if([transaction.from isEqualToString:[self.currentWallet.currentAccount.address lowercaseString]]){
                transaction.direction = QWTransactionDirectionSent;
            }else{
                transaction.direction = QWTransactionDirectionReceived;
            }
            
            if (!tx[@"isError"] || [tx[@"isError"] isEqualToString:@"0"]) {
                transaction.status = QWTransactionStatusSuccess;
            }else{
                if([tx[@"timeStamp"] isEqualToString:@"0"]){
                    transaction.status = QWTransactionStatusPending;
                }else{
                    transaction.status = QWTransactionStatusFailed;
                }
            }
            
            [self.database transactionWithBlock:^{
                if (!token) {
                    [self.currentWallet.currentAccount.transactions addObject:transaction];
                } else {
                    if (forAccountTokenTransaction) {
                        [self.currentWallet.currentAccount.transactions addObject:transaction];
                    } else {
                        [self.database addObject:transaction];
                    }
                }
            }];
        }
        
    }
}

- (void)refreshCurrentAccountTokensBalanceWithCompletion:(dispatch_block_t)completion {
    UIViewController *visibleViewController = nil;
    NSMutableArray *tokens = [self.allERC20Tokens allObjectsInArray].mutableCopy;
    if (!tokens.count) {
        !completion ?: completion();
    }
    NSInteger chainID = self.network.clientOptions.chainID;
    QWAccount *currentAccount = self.currentWallet.currentAccount;
    dispatch_group_t group = dispatch_group_create();
    
    void (^favoriteTokenIfNeeded)(QWToken *, NSString *) = ^(QWToken *token, NSString *balance) {
        // add token to account's favoriteTokens list automaticlly if needed
        QWToken *_token = [currentAccount.favoriteTokens objectsWhere:[NSString stringWithFormat:@"address ==[c] '%@' AND chainId == %ld", token.address, chainID]].firstObject;
        if (!_token) {
            NSDictionary *blacklist = [[NSUserDefaults standardUserDefaults] objectForKey:QWWalletManageAutomaticFavorTokenBlacklistKey];
            if (![blacklist[[NSString stringWithFormat:@"%@_%@_%ld_%ld", [currentAccount.address fullShardIdTrimed], [token.address lowercaseString], token.coinType.integerValue, token.chainId.integerValue]] boolValue]) {
                if (![[balance balanceStringFromWeiWithDecimal:token.decimals roundingMode:NSNumberFormatterRoundFloor] isEqualToString:@"0"]) {
                    [self favorTokenForAccount:currentAccount token:token];
                }
            }
        }
    };
    
    if (self.currentCoinType == QWWalletCoinTypeTRX) {
        BOOL containsNativeToken = false;
        for (QWToken *token in tokens) {
            if (token.isInvalidated) {
                continue;
            }
            if (token.isNative) {
                containsNativeToken = true;
            } else {
                [self.network.trxClient triggerContractFromAddress:self.currentAccount.address contractAddress:token.address data:[ERC20Encoder encodeArgumentsBalanceOfAddressString:[QWKeystoreSwift base58CheckDecodingWithString:self.currentAccount.address].qw_hexString] functionSelector:@"balanceOf(address)" success:^(Transaction * _Nonnull transaction, NSArray *returnedValue) {
                    if (currentAccount.isInvalidated) {
                        return;
                    }
                    NSString *dataString = returnedValue.firstObject;
                    if (dataString) {
                        RLMResults *allTokenBalances = [currentAccount.balances objectsWhere:[token tokenFetchCondition]];
                        [self.database transactionWithBlock:^{
                            [self.database deleteObjects:allTokenBalances];
                        }];
                        QWBalance *balanceObject = [currentAccount balanceForToken:token];
                        [self.database transactionWithBlock:^{
                            balanceObject.balance = [[JKBigInteger alloc] initWithString:dataString andRadix:16].stringValue;
                        }];
                        favoriteTokenIfNeeded(token, balanceObject.balance);
                    }
                } failure:^(NSError * _Nonnull error) {

                }];
            }
        }
        if (containsNativeToken) {
            
            [self.network.trxClient getAccountByAddress:self.currentAccount.address success:^(Account * _Nonnull response) {
                if (currentAccount.invalidated) {
                    return;
                }
                [response.assetV2 enumerateKeysAndInt64sUsingBlock:^(NSString * _Nonnull key, int64_t value, BOOL * _Nonnull stop) {
                    QWToken *token = [QWToken tokenWithAddress:key coinType:QWWalletCoinTypeTRX chainId:chainID];
                    if (token) {
                        RLMResults *allTokenBalances = [currentAccount.balances objectsWhere:[token tokenFetchCondition]];
                        [self.database transactionWithBlock:^{
                            [self.database deleteObjects:allTokenBalances];
                        }];
                        QWBalance *balanceObject = [currentAccount balanceForToken:token];
                        [self.database transactionWithBlock:^{
                            balanceObject.balance = [NSString stringWithFormat:@"%lld", value];
                        }];
                        favoriteTokenIfNeeded(token, balanceObject.balance);
                    }
                }];
                
            } failure:^(NSError * _Nonnull error) {
                
            }];
            
        }
        
    } else {
        BOOL containsNativeToken = false;
        for (QWToken *token in tokens) {
            if (token.isInvalidated) {
                continue;
            }
            if (self.currentCoinType == QWWalletCoinTypeQKC && token.isNative) {
                containsNativeToken = true;
                continue;
            }
            dispatch_group_enter(group);
            NSString *fromAddress = self.currentAccount.address;
            NSString *address = fromAddress;
            if (self.currentCoinType == QWWalletCoinTypeQKC) {
                NSString *fullShardId = [self.currentAccount.address fullShardIdBySwitchToShardId:@([token.address shardId]).stringValue chainId:@([token.address chainId]).stringValue];
                fromAddress = [[self.currentAccount.address fullShardIdTrimed] appendFullShardId:fullShardId];
                address = self.currentWallet.currentAccount.address.fullShardIdTrimed;
            }
            [self.network.client call:token.address from:fromAddress dataHex:[ERC20Encoder encodeBalanceOfAddressString:address] success:^(NSString *dataString) {
                if (currentAccount.isInvalidated || token.isInvalidated) {
                    dispatch_group_leave(group);
                    return;
                }
                RLMResults *allTokenBalances = [currentAccount.balances objectsWhere:[QWToken tokenFetchConditionWithAddress:token.address coinType:token.coinType.integerValue chainId:token.chainId.integerValue]];
                [self.database transactionWithBlock:^{
                    [self.database deleteObjects:allTokenBalances];
                }];
                
                NSString *balance = @"0";
                if(![dataString isEqualToString:@"0x"]){
                    balance = [SmartContractDecoder decodeReturnedUint256WithResponse:dataString error:nil];
                }
                QWBalance *balanceObject = [currentAccount balanceForToken:token];
                [self.database transactionWithBlock:^{
                    balanceObject.balance = balance;
                }];
                
                favoriteTokenIfNeeded(token, balance);
                
                dispatch_group_leave(group);
            } failure:^(NSError *error) {
                dispatch_group_leave(group);
            }];
        }
        if (containsNativeToken) {
            dispatch_group_enter(group);
            [self refreshCurrentAccountBalanceWithCompletion:^(id params, NSError *error) {
                if (error) {
                    dispatch_group_leave(group);
                    return;
                }
                for (QWToken *nativeToken in [QWToken objectsWhere:[NSString stringWithFormat:@"coinType == %ld AND chainId == %ld AND native == true", QWWalletCoinTypeQKC, (long)self.network.clientOptions.chainID]]) {
                    if ([nativeToken isEqualToObject:self.QKC]) {
                        continue;
                    }
                    JKBigInteger *totalBalance = [[JKBigInteger alloc] initWithString:@"0"];
                    for (QWBalance *balance in [self.currentAccount balancesForToken:nativeToken]) {
                        totalBalance = [totalBalance add:[[JKBigInteger alloc] initWithString:balance.balance]];
                    }
                    favoriteTokenIfNeeded(nativeToken, totalBalance.stringValue);
//                    QWToken *_token = [currentAccount.favoriteTokens objectsWhere:[NSString stringWithFormat:@"address ==[c] '%@' AND chainId == %ld", nativeToken.address, chainID]].firstObject;
//                    if (!_token) {
//                        [self favorTokenForAccount:currentAccount token:nativeToken]; //qkc native token logic
//                    }
                }
                
                dispatch_group_leave(group);
            } notify:false];
        }
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        !completion ?: completion();
        [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidTokenBalanceChangedNotification object:nil];
    });
}

- (NSError *)changeAccountName:(QWAccount *)account name:(NSString *)name syncToAllAccounts:(BOOL)syncToAllAccounts {
    if (name.length < 1 || name.length > 12) {
        return [QWError errorWithDomain:QWWalletManagerErrorDomain code:QWWalletManagerErrorInvalidAccountNameLength localizedDescriptionKey:@"QWWalletManager.error.invalidNameLength"];
    }
    if ([QWAccount objectForKey:@"name" value:name]) {
        return [QWError errorWithDomain:QWWalletManagerErrorDomain code:QWWalletManagerErrorDuplicateAccountName localizedDescriptionKey:@"QWWalletManager.error.duplicatedName"];
    }
    [self.database transactionWithBlock:^{
        if (syncToAllAccounts) {
            for (QWAccount *_account in account.wallet.accounts) {
                _account.name = name;
            }
        } else {
            account.name = name;
        }
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidWalletNameChangedNotification object:self userInfo:@{@"wallet":account.wallet}];
    return nil;
}

- (void)changeWalletIcon:(QWWallet *)wallet iconName:(NSString *)iconName {
    [self.database transactionWithBlock:^{
        for (QWAccount *account in wallet.accounts) {
            account.iconName = iconName;
        }
        wallet.iconName = iconName;
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidWalletIconChangedNotification object:self userInfo:@{@"wallet":wallet}];
}

- (void)markWalletPhraseAsBackedUp:(QWWallet *)wallet {
    [self.database transactionWithBlock:^{
        wallet.phraseBackedUp = true;
    }];
    
    NSMutableDictionary *askedBackupAccounts = [[[NSUserDefaults standardUserDefaults] objectForKey:QWWalletManagerAskedForAccountBackupPhraseKey] mutableCopy];
    [askedBackupAccounts removeObjectForKey:wallet.accounts.firstObject.address.fullShardIdTrimed];
    [[NSUserDefaults standardUserDefaults] setObject:askedBackupAccounts forKey:QWWalletManagerAskedForAccountBackupPhraseKey];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidWalletPhraseBackedUpNotification object:self userInfo:@{@"wallet":wallet}];
}

- (void)favorTokenForAccount:(QWAccount *)account token:(QWToken *)token {
    [self.database transactionWithBlock:^{
        [account.favoriteTokens addObject:token];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidAccountFavoredTokenNotification object:self userInfo:@{@"account":account, @"token":token}];
}

- (void)switchShardId:(NSUInteger)newShardId chainId:(NSUInteger)newChainId {
    [self.currentWallet.currentAccount setValue:nil forKey:@"chain"];
    [self.database transactionWithBlock:^{
        if (self.currentAccount.coinType.unsignedIntegerValue == QWWalletCoinTypeQKC) {
            self.currentAccount.address = [[self.currentAccount.address fullShardIdTrimed] appendFullShardId:[self.currentAccount.address fullShardIdBySwitchToShardId:[NSString stringWithFormat:@"%ld", newShardId] chainId:[NSString stringWithFormat:@"%ld", newChainId]]];
        }
        self.currentAccount.shard = [self.currentAccount getShardFromChainWithShardId:newShardId];
    }];
//    [self.currentWallet.currentAccount setValue:nil forKey:@"shard"];
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidShardChangedNotification object:nil];
}

- (void)switchCoinTypeForWallet:(QWWallet *)wallet account:(QWAccount *)account {
    NSNumber *coinTypeNumber = account.coinType;
    [self.database transactionWithBlock:^{
        wallet.currentAccount = account;
    }];
    self.network.clientType = account.coinType.integerValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidCoinNetworkChangedNotification object:nil userInfo:@{@"wallet":wallet}];
}

- (void)toggleAccountAddressType:(QWAccount *)account addressType:(QWAccountAddressType)addressType {
    if (account.addressType.integerValue == addressType) {
        return;
    }
    QWWallet *wallet = account.wallet;
    
    [self.database transactionWithBlock:^{
        NSInteger index = -1;
        for (QWAccount *_account in wallet.currentBTCAccounts) {
            index++;
            if ([_account isEqualToObject:account]) {
                [wallet.currentBTCAccounts removeObjectAtIndex:index];
                break;
            }
        }
        for (QWAccount *_account in [wallet.accounts objectsWhere:[NSString stringWithFormat:@"coinType == %ld && addressType == %ld", QWWalletCoinTypeBTC, addressType]]) {
            NSArray *_paths = [_account.path componentsSeparatedByString:@"/"];
            NSArray *paths = [account.path componentsSeparatedByString:@"/"];
            if ([_paths[1] isEqualToString:paths[1]] && [_paths[2] isEqualToString:paths[2]]) {
                [wallet.currentBTCAccounts insertObject:_account atIndex:index];
                wallet.currentAccount = _account;
                break;
            }
        }
    }];

    [self setValue:[QWWallet objectWhere:@"primary == true"] forKey:NSStringFromKeyPath(self, currentWallet)];
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidChangedAccountAddressTypeNotification object:nil userInfo:@{@"account":account}];
}

- (NSString *)getNewAccountAddress:(QWAccount *)account {
    NSAssert(account.extendedPublicKey.length, @"");
    NSString *address = [self.keystore derivedAddressWithPublicKey:account.extendedPublicKey atIndex:account.addresses.count isSegWit:account.addressType.integerValue == QWAccountAddressTypeSegWit isMainnet:self.network.clientOptions.isMainnet];
    [self.database transactionWithBlock:^{
        [account.addresses addObject:address];
    }];
    return address;
}

- (void)setAccountAddress:(QWAccount *)account address:(NSString *)address {
    [self.database transactionWithBlock:^{
        account.subAddress = address;
        [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidChangedAccountSubAddressNotification object:self userInfo:@{@"account":account}];
    }];
}

- (void)setCurrentAccountForWallet:(QWWallet *)wallet account:(QWAccount *)account {
    [self.database transactionWithBlock:^{
        wallet.currentAccount = account;
        [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidWalletChangedCurrentAccountNotification object:self userInfo:@{@"wallet":wallet, @"account":account}];
    }];
}

@end
