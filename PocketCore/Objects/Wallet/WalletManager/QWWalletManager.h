//
//  QWWalletManager.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/5.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWNetwork.h"

FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidCreateFirstWalletNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidCurrentWalletChangedNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidWalletNameChangedNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidWalletIconChangedNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidWalletPhraseBackedUpNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidDeleteWalletNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidShardChangedNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidBalanceChangedNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidTokenBalanceChangedNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidAccountFavoredTokenNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidCoinNetworkChangedNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidAccountAuthenticationEnableChangedNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidDeleteTokenNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidChangedAccountAddressTypeNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidChangedAccountSubAddressNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidCreatedAccountIntoWalletNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidDeleteAccountNotification;
FOUNDATION_EXTERN NSNotificationName const QWWalletManagerDidWalletChangedCurrentAccountNotification;

FOUNDATION_EXTERN NSString *const QWWalletManagerAccountAuthenticationSecAttrServiceKey;

@class QWDatabase, QWChain;

@interface QWWalletManager : NSObject

@property (nonatomic, readonly) QWDatabase *database;

@property (nonatomic, readonly) QWNetwork *network;

+ (instancetype)defaultManager;

- (void)switchNetworkWithClientOptions:(QWNetworkClientOptions *)clientOptions;

- (void)refreshNetworkInfoIfNeededWithCompletion:(dispatch_block_t)completion;

- (NSInteger)chainSizeByCurrentNetwork;
- (NSInteger)shardSizeByCurrentNetworkForChain:(QWChain *)chain;

@end

@interface QWWalletManager (Notification)

- (void)postNotificationAddressDeviceTokens:(void(^)(NSError *error))completion;

@end
