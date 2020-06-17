
//  QWWalletManager.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/5.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager.h"
#import "QWDatabase.h"
#import "QWToken.h"
#import "QWQKCClient.h"
#import "QWShard.h"
#import "QWBalance.h"
#import "QWHeader.h"
#import "QWNetwork.h"
#import "QWWallet.h"
#import "QWTransaction.h"
#import "QWWalletManager+Account.h"
#import "QWWalletManager+Keystore.h"
#import "QWWalletManager+Private.h"
#import "QWKeystore.h"
#import <Geth/Geth.h>
#import "NSString+Address.h"
#import "QWChain.h"
#import "RLMArray+QWDatabase.h"
#import "QWAccount.h"
#import <objc/runtime.h>

NSNotificationName const QWWalletManagerDidCreateFirstWalletNotification = @"QWWalletManagerDidCreateFirstWalletNotification";
NSNotificationName const QWWalletManagerDidCurrentWalletChangedNotification = @"QWWalletManagerDidCurrentWalletChangedNotification";
NSNotificationName const QWWalletManagerDidWalletNameChangedNotification = @"QWWalletManagerDidWalletNameChangedNotification";
NSNotificationName const QWWalletManagerDidWalletIconChangedNotification = @"QWWalletManagerDidWalletIconChangedNotification";
NSNotificationName const QWWalletManagerDidWalletPhraseBackedUpNotification = @"QWWalletManagerDidWalletPhraseBackedUpNotification";
NSNotificationName const QWWalletManagerDidDeleteWalletNotification = @"QWWalletManagerDidDeleteWalletNotification";
NSNotificationName const QWWalletManagerDidDeleteAccountNotification = @"QWWalletManagerDidDeleteAccountNotification";
NSNotificationName const QWWalletManagerDidShardChangedNotification = @"QWWalletManagerDidShardChangedNotification";
NSNotificationName const QWWalletManagerDidBalanceChangedNotification = @"QWWalletManagerDidBalanceChangedNotification";
NSNotificationName const QWWalletManagerDidTokenBalanceChangedNotification = @"QWWalletManagerDidTokenBalanceChangedNotification";
NSNotificationName const QWWalletManagerDidAccountFavoredTokenNotification = @"QWWalletManagerDidAccountFavoredTokenNotification";
NSNotificationName const QWWalletManagerDidCoinNetworkChangedNotification = @"QWWalletManagerDidCoinNetworkChangedNotification";
NSNotificationName const QWWalletManagerDidAccountAuthenticationEnableChangedNotification = @"QWWalletManagerDidAccountAuthenticationEnableChangedNotification";
NSNotificationName const QWWalletManagerDidDeleteTokenNotification = @"QWWalletManagerDidDeleteTokenNotification";
NSString *const QWWalletManagerAccountAuthenticationSecAttrServiceKey = @"com.quarkwallet";
NSNotificationName const QWWalletManagerDidChangedAccountAddressTypeNotification = @"QWWalletManagerDidChangedAccountAddressTypeNotification";
NSNotificationName const QWWalletManagerDidChangedAccountSubAddressNotification = @"QWWalletManagerDidChangedAccountSubAddressNotification";
NSNotificationName const QWWalletManagerDidCreatedAccountIntoWalletNotification = @"QWWalletManagerDidCreatedAccountIntoWalletNotification";
NSNotificationName const QWWalletManagerDidWalletChangedCurrentAccountNotification = @"QWWalletManagerDidWalletChangedCurrentAccountNotification";

QWUserDefaultsKey QWWalletManagerAccountAddressesForQKCNetworkSwitching = @"QWWalletManagerAccountAddressesForQKCNetworkSwitching";
QWUserDefaultsKey QWWalletManagerChainShardSizesByNetworkIdQKCNetworkSwitching = @"QWWalletManagerChainShardSizesByNetworkIdQKCNetworkSwitching";
QWUserDefaultsKey QWWalletManagerChainShardSizesByNetworkIdONENetworkSwitching = @"QWWalletManagerChainShardSizesByNetworkIdONENetworkSwitching";
QWUserDefaultsKey QWWalletManagerUpdateInfosKey = @"QWWalletManagerUpdateInfosKey";

@interface QWWalletManager ()
{
    NSString *_currencySymbol;
    NSMutableDictionary <NSString *, NSDictionary <NSString *, NSNumber *> *> *_chainShardSizesByNetworkId;
}
- (NSMutableDictionary<NSString *,NSDictionary<NSString *,NSNumber *> *> *)chainShardSizesByNetworkIdWithCoinType:(QWWalletCoinType)coinType;
@end

@implementation QWWalletManager (Database)

- (void)updateDatabaseAndRecordNetworkInfoIfNeededWithShardSizeOnChainDictionary:(NSDictionary *)shardSizeOnChainDictionary networkId:(NSString *)networkId coinType:(QWWalletCoinType)coinType {
    if ([QWChain allObjects].count < shardSizeOnChainDictionary.count) {
        [self.database transactionWithBlock:^{
            [shardSizeOnChainDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSNumber *obj, BOOL * _Nonnull stop) {
                QWChain *chain = [QWChain objectForKey:@"id" value:key];
                if (!chain) {
                    chain = [QWChain new];
                    chain.id = key;
                    for (NSInteger index = 0; index < obj.unsignedIntegerValue; index++) {
                        QWShard *shard = [QWShard new];
                        shard.id = [NSString stringWithFormat:@"%ld", (long)index];
                        [chain.shards addObject:shard];
                    }
                    [self.database addObject:chain];
                }
            }];
        }];
    } else {
        for (QWChain *chain in [QWChain allObjects]) {
            if(chain.shards.count < [shardSizeOnChainDictionary[chain.id] unsignedIntegerValue]) {
                NSLog(@"jazys: reset specified shards on chain : %@", chain.id);
                [self.database transactionWithBlock:^{
                    for (NSInteger index = 0; index < [shardSizeOnChainDictionary[chain.id] unsignedIntegerValue]; index++) {
                        QWShard *shard = [QWShard new];
                        shard.id = [NSString stringWithFormat:@"%ld", (long)index];
                        [chain.shards addObject:shard];
                    }
                }];
            }
        }
    }
    NSMutableDictionary *chainShardSizesByNetworkId = [self chainShardSizesByNetworkIdWithCoinType:coinType];
    chainShardSizesByNetworkId[networkId] = shardSizeOnChainDictionary;
    [[NSUserDefaults standardUserDefaults] setObject:chainShardSizesByNetworkId forKey:coinType == QWWalletCoinTypeQKC ? QWWalletManagerChainShardSizesByNetworkIdQKCNetworkSwitching : QWWalletManagerChainShardSizesByNetworkIdONENetworkSwitching];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _chainShardSizesByNetworkId = nil;
}

@end

@implementation QWWalletManager

+ (void)load {
    //init the database ASAP
    [self performSelectorOnMainThread:@selector(defaultManager) withObject:nil waitUntilDone:false];
}

+ (instancetype)defaultManager {
    static QWWalletManager *_instance = nil;
#if !TARGET_INTERFACE_BUILDER
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [self new];
    });
#endif
    return _instance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didTextFieldTextChanged:) name:UITextFieldTextDidChangeNotification object:nil];
        _database = [[QWDatabase alloc] initWithPath:QWWalletDatabasePath];
        [self initNetwork];
        __weak typeof(self) weakSelf = self;
        self.network.didClientTypeChanged = ^{
            __strong typeof(weakSelf) self = weakSelf;
            self->_chainShardSizesByNetworkId = nil;
        };
    }
    return self;
}

- (void)didTextFieldTextChanged:(NSNotification *)notificaton {
    UITextField *textField = notificaton.object;
    if (textField.keyboardType == UIKeyboardTypeDecimalPad) {
        textField.text = [textField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    }
}

- (void)initNetwork {
    _network = [[QWNetwork alloc] initWithClientType:QWWalletCoinTypeQKC];
    [self refreshNetworkInfoIfNeededWithCompletion:NULL];
    if (self.currentWallet) {
        _network.clientType = self.currentCoinType;
    }
    _chainShardSizesByNetworkId = nil;
}

- (void)switchNetworkWithClientOptions:(QWNetworkClientOptions *)clientOptions {
    
    if (self.currentCoinType == QWWalletCoinTypeQKC) {
        // save Old
        NSMutableDictionary *accountAddressesByNetworkId = [[[NSUserDefaults standardUserDefaults] objectForKey:QWWalletManagerAccountAddressesForQKCNetworkSwitching] mutableCopy];
        if (!accountAddressesByNetworkId) {
            accountAddressesByNetworkId = [NSMutableDictionary dictionary];
        }
        NSMutableDictionary *accountAddresses = [accountAddressesByNetworkId[self.network.clientOptions.networkId] mutableCopy];
        if (!accountAddresses) {
            accountAddresses = [NSMutableDictionary dictionary];
        }
        for (QWAccount *account in [QWAccount allObjects]) {
            if (account.coinType.unsignedIntegerValue == QWWalletCoinTypeQKC) {
                accountAddresses[[account.address fullShardIdTrimed]] = account.address;
            }
        }
        accountAddressesByNetworkId[self.network.clientOptions.networkId] = accountAddresses;
        
        [[NSUserDefaults standardUserDefaults] setObject:accountAddressesByNetworkId forKey:QWWalletManagerAccountAddressesForQKCNetworkSwitching];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // set New
        accountAddresses = [accountAddressesByNetworkId[clientOptions.networkId] mutableCopy];
        
        [self.database transactionWithBlock:^{
            for (QWAccount *account in [QWAccount allObjects]) {
                if (account.coinType.unsignedIntegerValue == QWWalletCoinTypeQKC) {
                    NSString *address = accountAddresses[[account.address fullShardIdTrimed]];
                    if (address) {
                        account.address = address;
                    }
                }
            }
        }];
        
    }
    
    self.network.clientOptions = clientOptions;
    
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidCoinNetworkChangedNotification object:nil];
    
}

#define defaultShardSizeOnChain @{@"0":@1, @"1":@1, @"2":@1, @"3":@1, @"4":@1, @"5":@1, @"6":@1, @"7":@1}

- (void)refreshNetworkInfoIfNeededWithCompletion:(dispatch_block_t)completion {
    
    //Harmony one shard size
    [self updateDatabaseAndRecordNetworkInfoIfNeededWithShardSizeOnChainDictionary:@{@"0":@4} networkId:[self.network lastClientOptionsWithCoinType:QWWalletCoinTypeONE].networkId coinType:QWWalletCoinTypeONE];
    
    if (!self.network.qkcClient) {
        !completion ?: completion();
        return;
    }
    
    QWNetworkClientOptions *clientOptions = self.network.clientOptions;
    if (![QWChain allObjects].count) {
        [self updateDatabaseAndRecordNetworkInfoIfNeededWithShardSizeOnChainDictionary:defaultShardSizeOnChain networkId:clientOptions.networkId coinType:QWWalletCoinTypeQKC];
    }
    [self.network.qkcClient networkInfoSuccess:^(NSDictionary *networkInfo) {
        if (!networkInfo) {
            [self updateDatabaseAndRecordNetworkInfoIfNeededWithShardSizeOnChainDictionary:defaultShardSizeOnChain networkId:clientOptions.networkId coinType:QWWalletCoinTypeQKC];
            return;
        }
        NSUInteger shardSize = 0;
        NSInteger index = -1;
        NSMutableDictionary *shardSizeOnChain = [NSMutableDictionary dictionary];
        if ([networkInfo[@"shardSizes"] isKindOfClass:[NSArray class]]) {
            for (NSString *shardSizeString in networkInfo[@"shardSizes"]) {
                index++;
                JKBigInteger *integer = [[JKBigInteger alloc] initWithString:[shardSizeString passByFirstTwoBytes] andRadix:16];
                if (shardSize < integer.unsignedIntValue) {
                    shardSize = integer.unsignedIntValue;
                }
                shardSizeOnChain[[NSString stringWithFormat:@"%ld", index]] = @(integer.unsignedIntValue);
            }
        }
        [self updateDatabaseAndRecordNetworkInfoIfNeededWithShardSizeOnChainDictionary:shardSizeOnChain networkId:clientOptions.networkId coinType:QWWalletCoinTypeQKC];
        !completion ?: completion();
    } failure:^(NSError *error) {
        if (![QWChain allObjects].count) {
            [self updateDatabaseAndRecordNetworkInfoIfNeededWithShardSizeOnChainDictionary:defaultShardSizeOnChain networkId:clientOptions.networkId coinType:QWWalletCoinTypeQKC];
        }
        !completion ?: completion();
    }];
    
}

- (NSInteger)chainSizeByCurrentNetwork {
    if (self.currentCoinType == QWWalletCoinTypeONE) {
        return [self chainShardSizesByNetworkIdWithCoinType:QWWalletCoinTypeONE][[self.network lastClientOptionsWithCoinType:QWWalletCoinTypeONE].networkId].count;;
    }
    return [self chainShardSizesByNetworkIdWithCoinType:QWWalletCoinTypeQKC][[self.network lastClientOptionsWithCoinType:QWWalletCoinTypeQKC].networkId].count;
}

- (NSInteger)shardSizeByCurrentNetworkForChain:(QWChain *)chain {
    if (self.currentCoinType == QWWalletCoinTypeONE) {
        return [self chainShardSizesByNetworkIdWithCoinType:QWWalletCoinTypeONE][[self.network lastClientOptionsWithCoinType:QWWalletCoinTypeONE].networkId][chain.id].integerValue;
    }
    return [self chainShardSizesByNetworkIdWithCoinType:QWWalletCoinTypeQKC][[self.network lastClientOptionsWithCoinType:QWWalletCoinTypeQKC].networkId][chain.id].integerValue;
}

//- (NSInteger)shardSizeByCurrentNetwork {
//    return [[self.chainShardSizesByNetworkId[self.network.clientOptions.networkId].allValues valueForKeyPath:@"@sum.integerValue"] integerValue];
//}

- (NSMutableDictionary<NSString *,NSDictionary<NSString *,NSNumber *> *> *)chainShardSizesByNetworkIdWithCoinType:(QWWalletCoinType)coinType {
    if (!_chainShardSizesByNetworkId) {
        NSString *key = coinType == QWWalletCoinTypeQKC ? QWWalletManagerChainShardSizesByNetworkIdQKCNetworkSwitching : QWWalletManagerChainShardSizesByNetworkIdONENetworkSwitching;
        _chainShardSizesByNetworkId = [[[NSUserDefaults standardUserDefaults] objectForKey:key] mutableCopy];
        if (!_chainShardSizesByNetworkId) {
            _chainShardSizesByNetworkId = [NSMutableDictionary dictionaryWithDictionary:coinType == QWWalletCoinTypeQKC ? @{@"1":defaultShardSizeOnChain, @"255":defaultShardSizeOnChain} : @{@"1":@{@"0":@4}}];
            [[NSUserDefaults standardUserDefaults] setObject:_chainShardSizesByNetworkId forKey:key];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    return _chainShardSizesByNetworkId;
}

@end
