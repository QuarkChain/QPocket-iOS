//
//  QWWalletManager+Keystore.h
//  QuarkWallet
//
//  Created by Jazys on 2018/9/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager.h"
#import "QWWallet.h"

@class GethKeyStore, GethAccount, QWKeystore, QWAccount;

@interface QWWalletManager (Keystore)

@property (nonatomic, readonly) QWKeystore *keystore;

@property (nonatomic, getter=isColdMode) BOOL coldMode;

// Create
- (void)createWalletWithPassword:(NSString *)password completion:(void(^)(QWWallet *wallet, NSError *error))completion;

// Import
- (void)createWalletWithPhrase:(NSString *)phrase withPassword:(NSString *)password completion:(void(^)(QWWallet *account, NSError *error))completion;

- (void)createWalletWithPrivateKey:(NSString *)privateKey withPassword:(NSString *)password type:(QWWalletCoinType)type completion:(void(^)(QWWallet *account, NSError *error))completion;

- (void)createWalletWithKeystoreString:(NSString *)keystoreString andKeystorePassword:(NSString *)keystorePassword withPassword:(NSString *)password type:(QWWalletCoinType)type completion:(void(^)(QWWallet *account, NSError *error))completion;

// Watch
- (void)createWalletWithAddress:(NSString *)address type:(QWWalletCoinType)type completion:(void(^)(QWWallet *wallet, NSError *error))completion;

// Hardware Watch
- (void)createWalletWithAddress:(NSString *)address type:(QWWalletCoinType)type hardwareWalletType:(QWHardwareWalletType)hardwareWalletType hardwareWalletId:(NSString *)hardwareWalletId path:(NSString *)path  completion:(void(^)(QWWallet *wallet, NSError *error))completion;

// Export
- (void)exportPhraseForWallet:(QWWallet *)wallet withPassword:(NSString *)password completion:(void(^)(NSString *phrase, NSError *error))completion;

- (void)exportPrivateKeyForAccount:(QWAccount *)account withPassword:(NSString *)password completion:(void(^)(NSString *privateKey, NSError *error))completion;

- (void)exportKeystoreForAccount:(QWAccount *)account withPassword:(NSString *)password completion:(void(^)(NSString *keystore, NSError *error))completion;

- (void)exportExtendedPrivateKeyForAccount:(QWAccount *)account withPassword:(NSString *)password completion:(void(^)(NSString *extendedPrivateKey, NSError *error))completion;

// Delete
- (void)deleteWallet:(QWWallet *)wallet withPassword:(NSString *)password;
- (void)deleteAccount:(QWAccount *)account withPassword:(NSString *)password;

// Add
- (void)createAccountForWallet:(QWWallet *)wallet type:(QWWalletCoinType)type skipExists:(BOOL)skipExists completion:(void(^)(QWWallet *wallet, NSError *error))completion;

@end
