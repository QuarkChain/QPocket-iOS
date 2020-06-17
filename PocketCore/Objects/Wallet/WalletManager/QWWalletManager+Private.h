//
//  QWWalletManager+Private.h
//  QuarkWallet
//
//  Created by Jazys on 2018/9/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager.h"
#import "QWHeader.h"

@class QWWallet, QWAccount;

FOUNDATION_EXTERN QWUserDefaultsKey const QWWalletManagerAskedForAccountBackupPhraseKey;

#define QWAccountKeystorePath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject stringByAppendingPathComponent:@"Keystores"]
#define QWWalletDatabasePath [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true).firstObject stringByAppendingPathComponent:@"Database.realm"]

@interface QWWalletManager (Private)

- (BOOL)savePassword:(NSString *)password forWallet:(QWWallet *)wallet;

- (void)deletePasswordForWallet:(QWWallet *)wallet;

- (NSString *)passwordForWallet:(QWWallet *)wallet;

- (void(^)(NSString *filePath, NSString *address, id extendedParam, NSError *error))didCreateAccountWithPassword:(NSString *)password type:(QWWalletCoinType)type wallet:(QWWallet *)_wallet isHD:(BOOL)isHD path:(NSString *)path atIndex:(NSInteger)index completion:(void(^)(QWWallet *wallet, QWAccount *account, NSError *error))completion;

@end
