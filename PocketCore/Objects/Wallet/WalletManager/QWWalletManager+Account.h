//
//  QWWalletManager+Account.h
//  QuarkWallet
//
//  Created by Jazys on 2018/9/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager.h"
#import "QWHeader.h"
#import "QWAccount.h"

FOUNDATION_EXPORT QWUserDefaultsKey const QWWalletManageAutomaticFavorTokenBlacklistKey;

@class QWWallet, JKBigInteger, QWToken, QWAccount;

@interface QWWalletManager (Account)

@property (nonatomic) QWWallet *currentWallet; //call setter will notify observer

- (QWAccount *)currentAccount;

- (QWWalletCoinType)currentCoinType;

- (NSString *)currentCoinName;

- (NSString *)coinNameWithCoinType:(QWWalletCoinType)coinType;

- (NSString *)localizedChainNameWithCoinType:(QWWalletCoinType)coinType;

- (JKBigInteger *)primaryBalance;

- (JKBigInteger *)totalBalance;

- (void)refreshCurrentAccountTokensBalanceWithCompletion:(dispatch_block_t)completion;

- (void)refreshCurrentAccountBalanceWithCompletion:(void(^)(id params, NSError *))completion;

- (void)refreshCurrentAccountTransactionsWithCompletion:(void(^)(NSString *))completion;

- (NSError *)changeAccountName:(QWAccount *)account name:(NSString *)name syncToAllAccounts:(BOOL)syncToAllAccounts;

- (void)changeWalletIcon:(QWWallet *)wallet iconName:(NSString *)iconName;

- (void)markWalletPhraseAsBackedUp:(QWWallet *)wallet;

- (void)switchShardId:(NSUInteger)newShardId chainId:(NSUInteger)chainId;

- (void)favorTokenForAccount:(QWAccount *)account token:(QWToken *)token;

- (void)switchCoinTypeForWallet:(QWWallet *)wallet account:(QWAccount *)account;

- (void)refreshTransactionsForToken:(QWToken *)token completion:(void(^)(NSString *))completion;

- (void)refreshCurrentAccountBalanceDBWithBalance:(NSString *)balance;

- (void)refreshCurrentAccountTokenTransactions:(QWToken *)token completion:(void(^)(NSString *))completion;

- (void)refreshAccountTransactionsWithAccount:(QWAccount *)account completion:(void(^)(NSString *))completion;

- (void)toggleAccountAddressType:(QWAccount *)account addressType:(QWAccountAddressType)addressType;

- (NSString *)getNewAccountAddress:(QWAccount *)account;

- (void)setAccountAddress:(QWAccount *)account address:(NSString *)address;

- (void)setCurrentAccountForWallet:(QWWallet *)wallet account:(QWAccount *)account;

@end
