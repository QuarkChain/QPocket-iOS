//
//  QWKeystore.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/5.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWHeader.h"

FOUNDATION_EXPORT QWUserDefaultsKey QWKeystoreBTCIDMapKey;

@class GethKeyStore, GethAccount;

@interface QWKeystore : NSObject

@property (nonatomic) GethKeyStore *gethKeystore;

@property (nonatomic, copy) NSString *mnemonicWordlistNamed;

+ (NSArray <NSString *> *)allMnemonicWordlistNames;

- (instancetype)initWithPath:(NSString *)path mnemonicWordlistNamed:(NSString *)mnemonicWordlistNamed;

- (GethAccount *)gethAccountWithKeystoreName:(NSString *)keystoreName;

- (NSError *)verifyPasswordForKeystoreName:(NSString *)keystoreName password:(NSString *)password coinType:(QWWalletCoinType)coinType;

- (void)savePrivateKey:(id)privateKey password:(NSString *)password toPath:(NSString *)path coinType:(QWWalletCoinType)coinType completion:(void(^)(NSString *filePath, NSString *address, id extendedParam, NSError *error))completion;

- (void)savePrivateKey:(id)privateKey password:(NSString *)password toPath:(NSString *)path coinType:(QWWalletCoinType)coinType params:(NSDictionary *)params completion:(void(^)(NSString *filePath, NSString *address, id extendedParam, NSError *error))completion;

#pragma mark - Class methods

+ (NSString *)detectWordlistNamedFromMnemonic:(NSString *)mnemonic;

- (NSString *)convertMnemonicUsingCurrentWordlist:(NSString *)mnemonic;

- (NSString *)generateMnemonicWithStrength:(NSInteger)strength;

- (id)privateKeyWithMnemonic:(NSString *)mnemonic coinType:(NSUInteger)coinType; //BTC return btc keychain

- (id)privateKeyWithMnemonic:(NSString *)mnemonic coinType:(NSUInteger)coinType path:(NSString *)path;

- (NSError *)verifyMnemonic:(NSString *)mnemonic;

- (void)verifyPasswordForKeystore:(NSData *)keystore password:(NSString *)password error:(NSError **)error;

- (NSData *)privateKeyForKeystore:(NSDictionary *)keystore password:(NSString *)password error:(NSError **)error;

- (NSString *)encryptMnemonic:(NSString *)mnemonic forKeystore:(NSData *)keystore password:(NSString *)password error:(NSError **)error;

- (NSString *)decryptMnemonic:(NSString *)encryptedMnemonic forKeystore:(NSData *)keystore password:(NSString *)password error:(NSError **)error;

- (void)saveKeystore:(NSData *)keystore keystorePassword:(NSString *)keystorePassword newPassword:(NSString *)password toPath:(NSString *)path completion:(void(^)(NSString *filePath, NSString *address, NSError *error))completion DEPRECATED_ATTRIBUTE;

- (NSData *)signHash:(NSData *)hash withKeystoreName:(NSString *)keystoreName withPassword:(NSString *)password;

- (NSData *)signHashOnly:(NSData *)hashData withKeystoreName:(NSString *)keystoreName withPassword:(NSString *)password;

- (NSString *)derivedAddressWithPublicKey:(NSString *)publicKey atIndex:(NSUInteger)index isSegWit:(BOOL)isSegWit isMainnet:(BOOL)isMainnet;

@end
