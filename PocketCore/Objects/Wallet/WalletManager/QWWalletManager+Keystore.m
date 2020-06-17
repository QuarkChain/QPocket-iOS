//
//  QWWalletManager+Keystore.m
//  QuarkWallet
//
//  Created by Jazys on 2018/9/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager+Keystore.h"
#import <objc/runtime.h>
#import "QWWallet.h"
#import "NSString+Address.h"
#import "QWKeystore.h"
#import "QWDatabase.h"
#import "NSData+QWHexString.h"
#import "QWWalletManager+Private.h"
#import "QWWalletManager+Account.h"
#import "QWError.h"
#import <Geth/Geth.h>
#import "QWWalletManager+Token.h"
#import "QWDataStash.h"
#import "PocketCore-Swift.h"
#import "RLMArray+QWDatabase.h"

QWUserDefaultsKey QWWalletManagerColdModeKey = @"QWWalletManagerColdModeKey";

@implementation QWWalletManager (Keystore)

- (QWKeystore *)keystore {
    id keystore = objc_getAssociatedObject(self, _cmd);
    if (!keystore) {
        keystore = [[QWKeystore alloc] initWithPath:QWAccountKeystorePath mnemonicWordlistNamed:@"english"];
        objc_setAssociatedObject(self, _cmd, keystore, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return keystore;
}

- (void)createWalletWithPassword:(NSString *)password completion:(void(^)(QWWallet *wallet, NSError *error))completion {
    [self createWalletWithPhrase:nil withPassword:password completion:completion];
}

- (void)createWalletWithPhrase:(NSString *)phrase withPassword:(NSString *)password completion:(void(^)(QWWallet *wallet, NSError *error))completion {
    
    if (!phrase.length) {
        phrase = [self.keystore generateMnemonicWithStrength:128];
    }
    
    objc_setAssociatedObject(self, _cmd, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC); //delay account changed notification, until encryted phrase exported.
    
    void (^doDeleteWalletWhenCreateError)(id, id) = ^(QWWallet *wallet, NSError *error) {
        if (wallet) {
            [self deleteWallet:wallet withPassword:password notify:false];
        }
        !completion ?: completion(nil, error);
    };
    
    __block QWWalletCoinType coinType = QWWalletCoinTypeQKC;
    [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType] password:password toPath:QWAccountKeystorePath coinType:coinType completion:[self didCreateAccountWithPassword:password type:coinType wallet:nil isHD:true path:nil atIndex:-1 completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
        objc_setAssociatedObject(self, _cmd, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        if (!error) {
            coinType = QWWalletCoinTypeTRX;
            [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType] password:password toPath:QWAccountKeystorePath coinType:coinType completion:[self didCreateAccountWithPassword:password type:coinType wallet:wallet isHD:true path:nil atIndex:-1 completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
                if (!error) {
                    coinType = QWWalletCoinTypeETH;
                    [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType] password:password toPath:QWAccountKeystorePath coinType:coinType completion:[self didCreateAccountWithPassword:password type:coinType wallet:wallet isHD:true path:nil atIndex:-1 completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
                        if (!error) {
                            coinType = QWWalletCoinTypeBTC;
                            QWNetworkClientOptions *btcClientOptions = [self.network lastClientOptionsWithCoinType:QWWalletCoinTypeBTC];
                            __block NSString *path = [NSString stringWithFormat:@"49'/%@'/0'/0/0", btcClientOptions.isMainnet ? @"0" : @"1"];
                            [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType path:path] password:password toPath:QWAccountKeystorePath coinType:coinType params:@{@"segWit":@YES, @"testnet":@(!btcClientOptions.isMainnet)} completion:[self didCreateAccountWithPassword:password type:coinType wallet:wallet isHD:true path:path atIndex:-1 completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
                                if (!error) {
                                    path = [NSString stringWithFormat:@"44'/%@'/0'/0/0", btcClientOptions.isMainnet ? @"0" : @"1"];
                                    [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType path:path] password:password toPath:QWAccountKeystorePath coinType:coinType params:@{@"testnet":@(!btcClientOptions.isMainnet)} completion:[self didCreateAccountWithPassword:password type:coinType wallet:wallet isHD:true path:path atIndex:-1 completion:^(QWWallet *wallet, QWAccount *_account, NSError *error) {
                                        if (!error) {
                                            coinType = QWWalletCoinTypeONE;
                                            [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType] password:password toPath:QWAccountKeystorePath coinType:coinType completion:[self didCreateAccountWithPassword:password type:coinType wallet:wallet isHD:true path:nil atIndex:-1 completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
                                                NSData *keystoreData = [NSData dataWithContentsOfFile:[QWAccountKeystorePath stringByAppendingPathComponent:wallet.keystoreName]];
                                                [keystoreData writeToFile:[QWAccountKeystorePath stringByAppendingFormat:@"/wallets/%@", wallet.keystoreName] atomically:true];
                                                NSString *encryptedPhrase = [self.keystore encryptMnemonic:phrase forKeystore:keystoreData password:password error:&error];
                                                [self.database transactionWithBlock:^{
                                                    wallet.encryptedPhrase = encryptedPhrase;
                                                }];
                                                self.currentWallet = wallet;
                                                !completion ?: completion(wallet, error);
                                                
                                                NSMutableArray *addresses = [NSMutableArray array];
                                                for (QWAccount *account in wallet.accounts) {
                                                    [addresses addObject:@{@"address":account.address, @"coinType":account.coinType}];
                                                }
                                            }]];
                                        } else {
                                            doDeleteWalletWhenCreateError(wallet, error);
                                        }
                                    }]];
                                } else {
                                    doDeleteWalletWhenCreateError(wallet, error);
                                }
                            }]];
                        } else {
                            doDeleteWalletWhenCreateError(wallet, error);
                        }
                    }]];
                } else {
                    doDeleteWalletWhenCreateError(wallet, error);
                }
            }]];
            
        } else {
            !completion ?: completion(nil, error);
        }
    }]];
}

- (void)createWalletWithPrivateKey:(NSString *)privateKey withPassword:(NSString *)password type:(QWWalletCoinType)type completion:(void(^)(QWWallet *wallet, NSError *error))completion {
    [self createWalletWithPrivateKeyData:type != QWWalletCoinTypeBTC ? [NSData qw_dataWithHexString:privateKey] : privateKey withPassword:password type:type completion:completion];
}

- (void)createWalletWithKeystoreString:(NSString *)keystoreString andKeystorePassword:(NSString *)keystorePassword withPassword:(NSString *)password type:(QWWalletCoinType)type completion:(void(^)(QWWallet *account, NSError *error))completion {
    
    NSError *error;
    
    NSDictionary *keystore = [NSJSONSerialization JSONObjectWithData:[keystoreString dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableLeaves error:&error];
    
    if (error) {
        error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidKeystore localizedDescriptionKey:@"QWKeystore.error.invalidKeystore"];
        !completion ?: completion(nil, error);
        return;
    }
    
    NSNumber *addressType = [[QWDataStash sharedStash] popValueForKey:@"addressType"];
    
    if (type == QWWalletCoinTypeBTC) {
        
        BOOL segWit = true;
        if (addressType) {
            segWit = [addressType integerValue] == QWAccountAddressTypeSegWit;
        } else {
            segWit = [keystore[@"address"] isBTCSegWitAddress];
        }
        QWNetworkClientOptions *btcClientOptions = [self.network lastClientOptionsWithCoinType:QWWalletCoinTypeBTC];
        if (btcClientOptions.isMainnet) {
            if (segWit && ![[keystore[@"address"] substringToIndex:1] isEqualToString:@"3"]) {
                error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeSegwitOnlySupportCompressedKey localizedDescription:QWLocalizedFormatString(@"QWKeystore.error.segWitKeystore", QWLocalizedString(@"QWManageWalletViewController.addressTypeNormal"))];
                !completion ?: completion(nil, error);
                return;
            } else if (!segWit && ![[keystore[@"address"] substringToIndex:1] isEqualToString:@"1"]) {
                error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeSegwitOnlySupportCompressedKey localizedDescription:QWLocalizedFormatString(@"QWKeystore.error.segWitKeystore", QWLocalizedString(@"QWManageWalletViewController.addressTypeSegWit"))];
                !completion ?: completion(nil, error);
                return;
            }
        } else {
            if (segWit && ![[keystore[@"address"] substringToIndex:1] isEqualToString:@"2"]) {
                error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeSegwitOnlySupportCompressedKey localizedDescription:QWLocalizedFormatString(@"QWKeystore.error.segWitKeystore", QWLocalizedString(@"QWManageWalletViewController.addressTypeNormal"))];
                !completion ?: completion(nil, error);
                return;
            } else if (!segWit && ![[keystore[@"address"] substringToIndex:1] isEqualToString:@"n"] && ![[keystore[@"address"] substringToIndex:1] isEqualToString:@"m"]) {
                error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeSegwitOnlySupportCompressedKey localizedDescription:QWLocalizedFormatString(@"QWKeystore.error.segWitKeystore", QWLocalizedString(@"QWManageWalletViewController.addressTypeSegWit"))];
                !completion ?: completion(nil, error);
                return;
            }
        }
        
    }
    
    id privateKeyData = [self.keystore privateKeyForKeystore:keystore password:keystorePassword error:&error];
    
    if (error) {
        !completion ?: completion(nil, error);
        return;
    }
    
    if (type == QWWalletCoinTypeBTC) {
        
        NSString *wif = [[NSString alloc] initWithData:privateKeyData encoding:NSUTF8StringEncoding];
        
        if (wif) {
            privateKeyData = wif;
        } else {
            BOOL isCompressedPrivateKey = ([privateKeyData length] == (1+32+1));
            if (([addressType integerValue] == QWAccountAddressTypeSegWit) && !isCompressedPrivateKey) {
                error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeSegwitOnlySupportCompressedKey localizedDescriptionKey:@"QWKeystore.error.segWitPrivateKey"];
                !completion ?: completion(nil, error);
                return;
            }
            privateKeyData = [BTCPrivateKeyAddress addressWithData:privateKeyData publicKeyCompressed:isCompressedPrivateKey].string;
        }
        if (addressType) {
            [[QWDataStash sharedStash] pushValue:addressType forKey:@"addressType"];
        }
    }
    [self createWalletWithPrivateKeyData:privateKeyData withPassword:password type:type completion:^(QWWallet *wallet, NSError *error) {
        if (error.code == QWKeystoreErrorCodeInvalidPrivateKey) {
            error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidKeystore localizedDescriptionKey:@"QWKeystore.error.invalidKeystore"];
        }
        completion(wallet, error);
    }];
}

- (void)createWalletWithAddress:(NSString *)address type:(QWWalletCoinType)type completion:(void(^)(QWWallet *wallet, NSError *error))completion  {
    [self createWalletWithAddress:address type:type hardwareWalletType:QWHardwareWalletTypeNone hardwareWalletId:nil path:nil completion:^(QWWallet *wallet, NSError *error) {
        completion(wallet, error);
    }];
}

- (void)createWalletWithAddress:(NSString *)address type:(QWWalletCoinType)type hardwareWalletType:(QWHardwareWalletType)hardwareWalletType hardwareWalletId:(NSString *)hardwareWalletId path:(NSString *)path completion:(void(^)(QWWallet *wallet, NSError *error))completion {
    NSDictionary *extendedParam = nil;
    if (type == QWWalletCoinTypeBTC) {
        if ([address isBTCAddress]) {
            extendedParam = @{@"segWit":@(address.isBTCSegWitAddress)};
        } else {
            BTCKeychain *keychain = [[BTCKeychain alloc] initWithExtendedKey:address];
            keychain = [keychain derivedKeychainWithPath:@"/0/0"];
            BOOL isSegWit = [address hasPrefix:@"ypub"] || [address hasPrefix:@"upub"];
            extendedParam = @{@"segWit":@(isSegWit), @"extendedPublicKey":address};
            if ([self.network lastClientOptionsWithCoinType:QWWalletCoinTypeBTC].isMainnet) {
                address = isSegWit ? keychain.key.witnessAddress.string : keychain.key.address.string;
            } else {
                address = isSegWit ? keychain.key.witnessAddressTestnet.string : keychain.key.addressTestnet.string;
            }
        }
    }
    NSInteger index = -1;
    if (hardwareWalletType == QWHardwareWalletTypeLedger) {
        index = -2; //a flag
    }
    if (hardwareWalletId) {
        [[QWDataStash sharedStash] pushValue:@{@"id":hardwareWalletId} forKey:@"hardwareWallet"];
    }
    [self didCreateAccountWithPassword:nil type:type wallet:nil isHD:false path:path atIndex:index completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
        completion(wallet, error);
    }](nil, address, extendedParam, nil);
}

- (void)exportExtendedPrivateKeyForAccount:(QWAccount *)account withPassword:(NSString *)password completion:(void(^)(NSString *extendedPrivateKey, NSError *error))completion {
    NSString *keystoreName = account.keystoreName; // use first account's keystore to encry phrase.
    //    dispatch_async(dispatch_queue_create("com.quarkwallet.exportphrase", 0), ^{
    NSData *keystoreData = [NSData dataWithContentsOfFile:[QWAccountKeystorePath stringByAppendingPathComponent:keystoreName]];
    NSError *error;
    NSString *extendedPrivateKey = [self.keystore decryptMnemonic:account.encryptedExtendedPrivateKey forKeystore:keystoreData password:password error:&error];
    //        dispatch_sync(dispatch_get_main_queue(), ^{
    completion(extendedPrivateKey, error);
//      });
    //    });
}

- (void)exportPhraseForWallet:(QWWallet *)wallet withPassword:(NSString *)password completion:(void(^)(NSString *phrase, NSError *error))completion {
    
    NSString *keystoreName = wallet.keystoreName; // use first account's keystore to encry phrase.
    NSString *encryptedPhrase = wallet.encryptedPhrase;
    
//    dispatch_async(dispatch_queue_create("com.quarkwallet.exportphrase", 0), ^{
        NSData *keystoreData = [NSData dataWithContentsOfFile:[QWAccountKeystorePath stringByAppendingFormat:@"/wallets/%@", keystoreName]];
        NSError *error;
        NSString *phrase = [self.keystore decryptMnemonic:encryptedPhrase forKeystore:keystoreData password:password error:&error];
//        dispatch_sync(dispatch_get_main_queue(), ^{
            completion(phrase, error);
//        });
//    });
    
}

- (void)exportPrivateKeyForAccount:(QWAccount *)account withPassword:(NSString *)password completion:(void(^)(NSString *privateKey, NSError *error))completion {
    
    NSAssert(completion, @"?");
    
    NSString *keystoreName = account.keystoreName;
    
//    dispatch_async(dispatch_queue_create("com.quarkwallet.exportprivatekey", 0), ^{
        
        NSData *keystoreData = [NSData dataWithContentsOfFile:[QWAccountKeystorePath stringByAppendingPathComponent:keystoreName]];
        NSError *error;
        NSDictionary *keystore = [NSJSONSerialization JSONObjectWithData:keystoreData options:NSJSONReadingMutableLeaves error:&error];
        if (error) {
            error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidKeystore localizedDescriptionKey:@"QWKeystore.error.invalidKeystore"];
            completion(nil, error);
            return;
        }
    
    NSData *privateKeyData = [self.keystore privateKeyForKeystore:keystore password:password error:&error];
    NSString *privateKey = nil;
    if (account.coinType.integerValue != QWWalletCoinTypeBTC) {
        privateKey = privateKeyData.qw_hexString;
    } else {
        privateKey = [[NSString alloc] initWithData:privateKeyData encoding:NSUTF8StringEncoding];
    }
//        dispatch_sync(dispatch_get_main_queue(), ^{
            completion(privateKey, error);
//        });
        
//    });
    
}

- (void)exportKeystoreForAccount:(QWAccount *)account withPassword:(NSString *)password completion:(void(^)(NSString *keystore, NSError *error))completion {
    
    NSString *keystoreName = account.keystoreName;
    
    dispatch_async(dispatch_queue_create("com.quarkwallet.exportkeystore", 0), ^{
        
        NSData *keystoreData = [NSData dataWithContentsOfFile:[QWAccountKeystorePath stringByAppendingPathComponent:keystoreName]];
        
        NSError *error;
        [self.keystore verifyPasswordForKeystore:keystoreData password:password error:&error];
        
        NSMutableString *keystore = nil;
        
        if (!error) {
            keystore = [[NSMutableString alloc] initWithData:keystoreData encoding:NSUTF8StringEncoding];
            NSRange range = NSMakeRange(0, keystore.length);
            [keystore replaceOccurrencesOfString:@" " withString:@"" options:NSLiteralSearch range:range];
            range = NSMakeRange(0, keystore.length);
            [keystore replaceOccurrencesOfString:@"\n" withString:@"" options:NSLiteralSearch range:range];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            completion(keystore, error);
        });
        
    });
    
}

- (void)deleteAccount:(QWAccount *)account withPassword:(NSString *)password {
    [self deleteAccount:account withPassword:password postNotification:true];
}

- (void)deleteAccount:(QWAccount *)account withPassword:(NSString *)password postNotification:(BOOL)post {
    BOOL isCurrentAccount = [account isEqualToObject:[QWWalletManager defaultManager].currentAccount];
    NSNumber *coinType = account.coinType;
    QWWallet *wallet = account.wallet;
    NSInteger index = -1;
    for (QWAccount *_account in account.wallet.accounts.toNSArray) {
        index++;
        if ([_account isEqualToObject:account]) {
            [self.database transactionWithBlock:^{
                QWAccount *relatedAddressTypeAccount = nil;
                if (account.coinType.integerValue == QWWalletCoinTypeBTC) {
                    for (QWAccount *btcAccount in [account.wallet.accounts objectsWhere:[NSString stringWithFormat:@"coinType == %ld", QWWalletCoinTypeBTC]]) {
                        if (![btcAccount isEqualToObject:account]) {
                            NSArray *_paths = [account.path componentsSeparatedByString:@"/"];
                            NSArray *paths = [btcAccount.path componentsSeparatedByString:@"/"];
                            if ([_paths[1] isEqualToString:paths[1]] && [_paths[2] isEqualToString:paths[2]]) {
                                relatedAddressTypeAccount = btcAccount;
                                break;
                            }
                        }
                    }
                    NSMutableDictionary *QWKeystoreBTCIDMap = [[[NSUserDefaults standardUserDefaults] objectForKey:QWKeystoreBTCIDMapKey] mutableCopy];
                    if (QWKeystoreBTCIDMap) {
                        [[NSFileManager defaultManager] removeItemAtPath:[QWAccountKeystorePath stringByAppendingPathComponent:account.keystoreName] error:NULL];
                        if (QWKeystoreBTCIDMap[account.address]) {
                            [QWKeystoreBTCIDMap removeObjectForKey:account.address];
                        } else {
                            NSString *key = [QWKeystoreBTCIDMap allKeysForObject:account.keystoreName].firstObject;
                            if (key) {
                                [QWKeystoreBTCIDMap removeObjectForKey:key];
                            }
                        }
                        if (relatedAddressTypeAccount) {
                            [[NSFileManager defaultManager] removeItemAtPath:[QWAccountKeystorePath stringByAppendingPathComponent:relatedAddressTypeAccount.keystoreName] error:NULL];
                            if (QWKeystoreBTCIDMap[relatedAddressTypeAccount.address]) {
                                [QWKeystoreBTCIDMap removeObjectForKey:relatedAddressTypeAccount.address];
                            } else {
                                NSString *key = [QWKeystoreBTCIDMap allKeysForObject:relatedAddressTypeAccount.keystoreName].firstObject;
                                if (key) {
                                    [QWKeystoreBTCIDMap removeObjectForKey:key];
                                }
                            }
                        }
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:QWKeystoreBTCIDMap forKey:QWKeystoreBTCIDMapKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    NSInteger j = -1;
                    for (QWAccount *btcAccount in account.wallet.currentBTCAccounts.toNSArray) {
                        j++;
                        if ([btcAccount isEqualToObject:account] || [btcAccount isEqualToObject:relatedAddressTypeAccount]) {
                            [account.wallet.currentBTCAccounts removeObjectAtIndex:j];
                        }
                    }
                } else {
                    GethAccount *gethAccount = [self.keystore gethAccountWithKeystoreName:account.keystoreName];
                    NSError *error = nil;
                    if (gethAccount) {
                        [self.keystore.gethKeystore deleteAccount:gethAccount passphrase:password error:&error];
                        NSAssert(!error, @"");
                    }
                }
                [self.database deleteObjects:account.transactions];
                [self.database deleteObjects:account.balances];
                [account.wallet.accounts removeObjectAtIndex:index];
                [self.database deleteObject:account];
                if (relatedAddressTypeAccount) {
                    [self.database deleteObjects:relatedAddressTypeAccount.transactions];
                    [self.database deleteObjects:relatedAddressTypeAccount.balances];
                    NSInteger j = -1;
                    for (QWAccount *__account in relatedAddressTypeAccount.wallet.accounts) {
                        j++;
                        if ([__account isEqualToObject:relatedAddressTypeAccount]) {
                            [relatedAddressTypeAccount.wallet.accounts removeObjectAtIndex:j];
                            break;
                        }
                    }
                    [self.database deleteObject:relatedAddressTypeAccount];
                }
            }];
            break;
        }
    }
    
    if (post) {
        [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidDeleteAccountNotification object:self userInfo:@{@"account":account, @"wallet":wallet, @"isCurrent":@(isCurrentAccount), @"coinType":coinType}];
    }
    
}

- (void)deleteWallet:(QWWallet *)wallet withPassword:(NSString *)password {
    [self deleteWallet:wallet withPassword:password notify:true];
}

- (void)deleteWallet:(QWWallet *)wallet withPassword:(NSString *)password notify:(BOOL)notify {
    BOOL isCurrentWallet = [wallet isEqualToObject:[QWWalletManager defaultManager].currentWallet];
    NSNumber *coinType = @(wallet.currentAccountType);
    if (!wallet.isWatch) {
        for (QWAccount *account in wallet.accounts) {
            if (account.coinType.integerValue == QWWalletCoinTypeBTC) {
                QWAccount *relatedAddressTypeAccount = nil;
                for (QWAccount *btcAccount in [account.wallet.accounts objectsWhere:[NSString stringWithFormat:@"coinType == %ld", QWWalletCoinTypeBTC]]) {
                    if (![btcAccount isEqualToObject:account]) {
                        NSArray *_paths = [account.path componentsSeparatedByString:@"/"];
                        NSArray *paths = [btcAccount.path componentsSeparatedByString:@"/"];
                        if ([_paths[1] isEqualToString:paths[1]] && [_paths[2] isEqualToString:paths[2]]) {
                            relatedAddressTypeAccount = account;
                            break;
                        }
                    }
                }
                NSMutableDictionary *QWKeystoreBTCIDMap = [[[NSUserDefaults standardUserDefaults] objectForKey:QWKeystoreBTCIDMapKey] mutableCopy];
                if (QWKeystoreBTCIDMap) {
                    [[NSFileManager defaultManager] removeItemAtPath:[QWAccountKeystorePath stringByAppendingPathComponent:account.keystoreName] error:NULL];
                    if (QWKeystoreBTCIDMap[account.address]) {
                        [QWKeystoreBTCIDMap removeObjectForKey:account.address];
                    } else {
                        NSString *key = [QWKeystoreBTCIDMap allKeysForObject:account.keystoreName].firstObject;
                        if (key) {
                            [QWKeystoreBTCIDMap removeObjectForKey:key];
                        }
                    }
                    if (relatedAddressTypeAccount) {
                        [[NSFileManager defaultManager] removeItemAtPath:[QWAccountKeystorePath stringByAppendingPathComponent:relatedAddressTypeAccount.keystoreName] error:NULL];
                        if (QWKeystoreBTCIDMap[relatedAddressTypeAccount.address]) {
                            [QWKeystoreBTCIDMap removeObjectForKey:relatedAddressTypeAccount.address];
                        } else {
                            NSString *key = [QWKeystoreBTCIDMap allKeysForObject:relatedAddressTypeAccount.keystoreName].firstObject;
                            if (key) {
                                [QWKeystoreBTCIDMap removeObjectForKey:key];
                            }
                        }
                    }
                }
                [[NSUserDefaults standardUserDefaults] setObject:QWKeystoreBTCIDMap forKey:QWKeystoreBTCIDMapKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
            } else {
                GethAccount *gethAccount = [self.keystore gethAccountWithKeystoreName:account.keystoreName];
                NSError *error = nil;
                [self.keystore.gethKeystore deleteAccount:gethAccount passphrase:password error:&error];
                NSAssert(!error, @"");
            }
        }
        [self deletePasswordForWallet:wallet];
        [[NSFileManager defaultManager] removeItemAtPath:[QWAccountKeystorePath stringByAppendingFormat:@"/wallets/%@", wallet.keystoreName] error:NULL];
    }
    [self.database transactionWithBlock:^{
        for (QWAccount *account in wallet.accounts) {
            [self.database deleteObjects:account.transactions];
            [self.database deleteObjects:account.balances];
            [self.database deleteObject:account];
        }
        [wallet.currentBTCAccounts removeAllObjects];
        [wallet.accounts removeAllObjects];
        [self.database deleteObject:wallet];
    }];
    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidDeleteWalletNotification object:self userInfo:@{@"wallet":wallet, @"isCurrent":@(isCurrentWallet), @"coinType":coinType}];
}

#pragma mark - Private

- (void)createWalletWithPrivateKeyData:(id)privateKeyData withPassword:(NSString *)password type:(QWWalletCoinType)type completion:(void(^)(QWWallet *wallet, NSError *error))completion {
    if (type != QWWalletCoinTypeBTC) {
        
        [self.keystore savePrivateKey:privateKeyData password:password toPath:QWAccountKeystorePath coinType:type completion:[self didCreateAccountWithPassword:password type:type wallet:nil isHD:false path:nil atIndex:-1 completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
            if (!error) {
            } else if (wallet) {
                [self deleteWallet:wallet withPassword:password notify:false];
            }
            completion(wallet, error);
        }]];
        
    } else {
        
        void (^doDeleteWalletWhenCreateError)(id, id) = ^(QWWallet *wallet, NSError *error) {
            if (error) {
                [self deleteWallet:wallet withPassword:password notify:false];
                wallet = nil;
            }
            completion(wallet, error);
        };
        
        NSNumber *addressType = [[QWDataStash sharedStash] popValueForKey:@"addressType"];
        BOOL segWit = true;
        if (addressType) {
            segWit = [addressType integerValue] == QWAccountAddressTypeSegWit;
        }
        
        QWNetworkClientOptions *btcClientOptions = [self.network lastClientOptionsWithCoinType:QWWalletCoinTypeBTC];
        
        [self.keystore savePrivateKey:privateKeyData password:password toPath:QWAccountKeystorePath coinType:type params:@{@"testnet":@(!btcClientOptions.isMainnet), @"segWit":@(segWit)} completion:^(NSString *filePath, NSString *address, id extendedParam, NSError *error) {
            if (!error) {
                [self didCreateAccountWithPassword:password type:type wallet:nil isHD:false path:nil atIndex:-1 completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
                    if (!error) {
                        
                        [self.keystore savePrivateKey:privateKeyData password:password toPath:QWAccountKeystorePath coinType:type params:@{@"testnet":@(!btcClientOptions.isMainnet), @"segWit":@(!segWit)} completion:^(NSString *_filePath, NSString *address, id extendedParam, NSError *error) {
                            
                            if (!error) { // success, because same private key, different address (SegWit/Normal)
                                [self didCreateAccountWithPassword:password type:type wallet:wallet isHD:false path:nil atIndex:-1 completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
                                    if (!error) {
                                        !completion ?: completion(wallet, error);
                                    } else {
                                        doDeleteWalletWhenCreateError(wallet, error);
                                    }
                                }](_filePath, address, extendedParam, nil);
                            } else if (error.code == QWKeystoreErrorCodeSegwitOnlySupportCompressedKey) { // if is uncompressed private key ignore create segwit account
                                !completion ?: completion(wallet, nil);
                            } else {
                                doDeleteWalletWhenCreateError(wallet, error);
                            }
                            
                        }];
                        
                    } else {
                        doDeleteWalletWhenCreateError(wallet, error);
                    }
                }](filePath, address, extendedParam, error);
            } else {
                !completion ?: completion(nil, error);
            }
        }];
        
    }
}

- (void(^)(NSString *filePath, NSString *address, id extendedParam, NSError *error))didCreateAccountWithPassword:(NSString *)password type:(QWWalletCoinType)type wallet:(QWWallet *)_wallet isHD:(BOOL)isHD path:(NSString *)path atIndex:(NSInteger)index completion:(void(^)(QWWallet *wallet, QWAccount *__account, NSError *error))completion {
    return ^(NSString *filePath, NSString *address, id extendedParam, NSError *error) {
        NSAssert(![path containsString:@"m/"], @"don't contains m/");
        QWAccount *account = nil;
        for (QWAccount *_account in [QWAccount allObjects]) {
            if (_account.coinType.unsignedIntegerValue == type) {
                if (type == QWWalletCoinTypeQKC) {
                    if ([[address fullShardIdTrimed].lowercaseString isEqualToString:[_account.address fullShardIdTrimed].lowercaseString]) {
                        account = _account;
                        break;
                    }
                } else {
                    if ([address.lowercaseString isEqualToString:_account.address.lowercaseString]) {
                        account = _account;
                        break;
                    }
                }
            }
        }
        if (account) { // Already watched this account.
            error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeDuplicateKeystore localizedDescriptionKey:@"QWKeystore.error.duplicatedKeystore" userInfo:nil];
            NSString *keystoreName = filePath.lastPathComponent;
            if (keystoreName) { //QWKeytore doesn't know QWAccount already watched, so delete the useless keytore.
                if (account.coinType.unsignedIntegerValue != QWWalletCoinTypeBTC) {
                    GethAccount *gethAccount = [self.keystore gethAccountWithKeystoreName:keystoreName];
                    NSError *error = nil;
                    [self.keystore.gethKeystore deleteAccount:gethAccount passphrase:password error:&error];
                } else {
                    [[NSFileManager defaultManager] removeItemAtPath:[QWAccountKeystorePath stringByAppendingPathComponent:keystoreName] error:nil];
                    NSMutableDictionary *QWKeystoreBTCIDMap = [[[NSUserDefaults standardUserDefaults] objectForKey:QWKeystoreBTCIDMapKey] mutableCopy];
                    for (NSString *address in QWKeystoreBTCIDMap.allKeys.copy) {
                        NSString *_keystoreName = QWKeystoreBTCIDMap[address];
                        if ([keystoreName isEqualToString:_keystoreName]) {
                            [QWKeystoreBTCIDMap removeObjectForKey:address];
                            break;
                        }
                    }
                    [[NSUserDefaults standardUserDefaults] setObject:QWKeystoreBTCIDMap forKey:QWKeystoreBTCIDMapKey];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }
            account = nil;
        }
        QWWallet *wallet = _wallet;
        if (!error) {
            if (!wallet) {
                wallet = [QWWallet new];
                wallet.primary = true;
                __block __weak NSString *(^findUniqueAccountName)(NSString *, NSInteger) = NULL;
                findUniqueAccountName = ^NSString *(NSString *prefix, NSInteger suffix) {
                    NSString *try = [NSString stringWithFormat:@"%@-%ld", prefix, (long)suffix];
                    if ([QWWallet objectForKey:@"name" value:try]) {
                        return findUniqueAccountName(prefix, suffix + 1);
                    }
                    return try;
                };
                wallet.name = @"HD-Wallet";
                if (!isHD) {
                    switch (type) {
                        case QWWalletCoinTypeQKC:
                            wallet.name = @"QKC-Wallet";
                            break;
                        case QWWalletCoinTypeETH:
                            wallet.name = @"ETH-Wallet";
                            break;
                        case QWWalletCoinTypeTRX:
                            wallet.name = @"TRX-Wallet";
                            break;
                        case QWWalletCoinTypeBTC:
                            wallet.name = @"BTC-Wallet";
                            break;
                        case QWWalletCoinTypeONE:
                            wallet.name = @"ONE-Wallet";
                            break;
                        default:
                            break;
                    }
                }
                if ([QWWallet objectForKey:@"name" value:wallet.name]) {
                    wallet.name = findUniqueAccountName(wallet.name, 1);
                }
                NSArray *walletIconNames = @[@""];
//                [[QWApplicationManager sharedManager] walletIconNames];
                wallet.iconName = walletIconNames[arc4random_uniform((uint32_t)walletIconNames.count)];
//                wallet.currentAccountType = @(type);
                if (index == -2) {
                    wallet.harewareWalletType = QWHardwareWalletTypeLedger;
                }
                NSDictionary *hardware = [[QWDataStash sharedStash] popValueForKey:@"hardwareWallet"];
                wallet.hardwareWalletId = hardware[@"id"];
            }
            account = [QWAccount new];
            account.keystoreName = [filePath lastPathComponent];
            NSString *accountName = wallet.name;
//            if (isHD) { //查看之前有没有统一修改名称，升级后新account保持统一
//                NSString *name = nil;
//                BOOL same = true;
//                for (QWAccount *account in wallet.accounts) {
//                    if (!name) {
//                        name = account.name;
//                    } else {
//                        if (![name isEqualToString:account.name]) {
//                            same = false;
//                            break;
//                        }
//                    }
//                }
//                if (same) {
//                    accountName = wallet.accounts.firstObject.name ?: wallet.name;
//                }
//            }
            account.name = accountName;
            account.iconName = wallet.iconName;
            account.coinType = @(type);
            account.address = address;
            account.shard = [account getShardFromChainWithShardId:type == QWWalletCoinTypeQKC ? address.shardId : 0];
            account.path = path ?: [NSString stringWithFormat:@"44'/%ld'/0'/0/0", type];
            if (type == QWWalletCoinTypeBTC) {
                if (account.keystoreName) {
                    NSData *keystoreData = [NSData dataWithContentsOfFile:[QWAccountKeystorePath stringByAppendingPathComponent:account.keystoreName]];
                    account.encryptedExtendedPrivateKey = [self.keystore encryptMnemonic:extendedParam[@"extendedPrivateKey"] forKeystore:keystoreData password:password error:NULL];
                }
                account.extendedPublicKey = extendedParam[@"extendedPublicKey"];
                account.subAddress = account.address;
                [account.addresses addObject:address];
                account.addressType = @([extendedParam[@"segWit"] boolValue] ? QWAccountAddressTypeSegWit : QWAccountAddressTypeNormal);
                if (!wallet.accounts.count || wallet.currentBTCAccounts.count * 2 == [wallet.accounts objectsWhere:[NSString stringWithFormat:@"coinType == %d", QWWalletCoinTypeBTC]].count) {
                    objc_setAssociatedObject(wallet, @selector(currentBTCAddressType), @(extendedParam ? [extendedParam[@"segWit"] boolValue] ? QWAccountAddressTypeSegWit : QWAccountAddressTypeNormal : QWAccountAddressTypeSegWit), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }
                NSNumber *preferredBTCAddressType = objc_getAssociatedObject(wallet, @selector(currentBTCAddressType));
                if (account.addressType.integerValue == preferredBTCAddressType.integerValue) {
                    [self.database transactionWithBlock:^{
                        NSInteger insertIndex = 0;
                        NSInteger accountPath = [account.path componentsSeparatedByString:@"/"][2].integerValue;
                        for (NSInteger index = 0; index < wallet.currentBTCAccounts.count; index++) {
                            if (accountPath > [wallet.currentBTCAccounts[index].path componentsSeparatedByString:@"/"][2].integerValue) {
                                if (index + 1 < wallet.currentBTCAccounts.count) {
                                    if (accountPath < [wallet.currentBTCAccounts[index + 1].path componentsSeparatedByString:@"/"][2].integerValue) {
                                        insertIndex = index + 1;
                                    }
                                } else {
                                    insertIndex = wallet.currentBTCAccounts.count;
                                }
                            }
                        }
                        [wallet.currentBTCAccounts insertObject:account atIndex:insertIndex];
                    }];
                }
            } else if (type == QWWalletCoinTypeETH) {
                [account.favoriteTokens addObject:[self QKCERC20]];
            }
            [self.database transactionWithBlock:^{
                if (index < 0) {
                    [wallet.accounts addObject:account];
                } else {
                    [wallet.accounts insertObject:account atIndex:index];
                }
                if (!_wallet) {
                    if (!wallet.isWatch) {
                        wallet.keystoreName = account.keystoreName;
                    }
                    wallet.currentAccount = account;
                    [self.database addObject:wallet];
                }
                [wallet setValue:nil forKey:@"currentAccounts"];
            }];
            if (!_wallet) {
                if (password.length) {
//                    if ([[UIDevice currentDevice] isLocalAuthenticationAvailable]) {
                        [self savePassword:password forWallet:wallet];
//                    }
                }
                if (![objc_getAssociatedObject(self, @selector(createWalletWithPhrase:withPassword:completion:)) boolValue]) {
                    self.currentWallet = wallet;
                }
                if ([QWWallet allObjects].count == 1) {
                    if (self.isColdMode) {
                        objc_setAssociatedObject(self, @selector(isColdMode), @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                        [[NSUserDefaults standardUserDefaults] setBool:true forKey:QWWalletManagerColdModeKey];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidCreateFirstWalletNotification object:self userInfo:@{@"wallet":wallet}];
                }
            }
        }
        !completion ?: completion(wallet, account, error);
    };
}

- (void)createAccountForWallet:(QWWallet *)wallet type:(QWWalletCoinType)coinType skipExists:(BOOL)skipExists completion:(void(^)(QWWallet *wallet, NSError *error))completion {
    
    [self createAccountForWallet:wallet password:[self passwordForWallet:wallet] type:coinType existsPaths:nil skipExists:skipExists completion:completion];
    
}

- (void)createAccountForWallet:(QWWallet *)wallet password:(NSString *)password type:(QWWalletCoinType)coinType existsPaths:(NSArray <NSNumber *> *)existsPaths skipExists:(BOOL)skipExists completion:(void(^)(QWWallet *wallet, NSError *error))completion {
    
    NSArray *coinTypeOrder = @[@(QWWalletCoinTypeQKC), @(QWWalletCoinTypeTRX), @(QWWalletCoinTypeETH), @(QWWalletCoinTypeBTC)];
    NSInteger coinTypeIndex = [coinTypeOrder indexOfObject:@(coinType)];
    NSInteger path = 0;
    NSInteger startIndex = 0;
    for (NSInteger index = 0; index < wallet.accounts.count; index++) {
        QWAccount *account = wallet.accounts[index];
        if (account.coinType.integerValue == coinType) {
            startIndex = index;
            break;
        } else if ([coinTypeOrder indexOfObject:account.coinType] < coinTypeIndex) {
            startIndex = index + 1;
        }
    }
    NSInteger insertIndex = 0;
    RLMResults *sameCoinTypeAccounts = [wallet.accounts objectsWhere:[NSString stringWithFormat:@"coinType == %ld", coinType]];
    BOOL willBeFirst = true;
    for (NSInteger index = 0; index < NSIntegerMax; index++) {
        BOOL found = false;
        for (QWAccount *account in sameCoinTypeAccounts) {
            if (index == [[account.path componentsSeparatedByString:@"/"][2] integerValue]) {
                found = true;
                willBeFirst = false;
                break;
            }
        }
        if (!found) {
            if ([existsPaths containsObject:@(index)]) {
                insertIndex--; //existed offset
                continue;
            }
            path = index;
            break;
        }
    }
    insertIndex += startIndex + path;
    if (coinType == QWWalletCoinTypeBTC && !willBeFirst) {
        insertIndex += 1; // btc has two accounts
    }
    
    void (^createAccountCompletion)(QWWallet *, QWAccount *, NSError *) = ^(QWWallet *wallet, QWAccount *account, NSError *error) {
        if (!error) {
            completion(wallet, error);
            [[NSNotificationCenter defaultCenter] postNotificationName:QWWalletManagerDidCreatedAccountIntoWalletNotification object:self userInfo:@{@"wallet":wallet, @"account":account}];
        } else {
            
            [self deleteAccount:account withPassword:password postNotification:false];
            
            if (!skipExists) {
                NSMutableDictionary *userInfo = error.userInfo.mutableCopy;
                if (!userInfo) {
                    userInfo = [NSMutableDictionary dictionary];
                }
                userInfo[@"existsPath"] = @(path);
                NSError *newError = [NSError errorWithDomain:error.domain code:error.code userInfo:userInfo];
                completion(nil, newError);
            } else {
                [self createAccountForWallet:wallet password:password type:coinType existsPaths:existsPaths ? [existsPaths arrayByAddingObject:@(path)] : @[@(path)] skipExists:true completion:completion];
            }
            
        }
    };
    
    [self exportPhraseForWallet:wallet withPassword:password completion:^(NSString *phrase, NSError *error) {
        __block NSString *fullPath = nil;
        if (coinType == QWWalletCoinTypeBTC) {
            QWNetworkClientOptions *btcClientOptions = [self.network lastClientOptionsWithCoinType:QWWalletCoinTypeBTC];
            fullPath = [NSString stringWithFormat:@"49'/%@'/%ld'/0/0", btcClientOptions.isMainnet ? @"0" : @"1", path];
            [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType path:fullPath] password:password toPath:QWAccountKeystorePath coinType:coinType params:@{@"segWit":@YES, @"testnet":@(!btcClientOptions.isMainnet)} completion:[self didCreateAccountWithPassword:password type:coinType wallet:wallet isHD:true path:fullPath atIndex:insertIndex completion:^(QWWallet *wallet, QWAccount *account, NSError *error) {
                if (!error) {
                    fullPath = [NSString stringWithFormat:@"44'/%@'/%ld'/0/0", btcClientOptions.isMainnet ? @"0" : @"1", path];
                    [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType path:fullPath] password:password toPath:QWAccountKeystorePath coinType:coinType params:@{@"testnet":@(!btcClientOptions.isMainnet)} completion:[self didCreateAccountWithPassword:password type:coinType wallet:wallet isHD:true path:fullPath atIndex:insertIndex + 1 completion:^(QWWallet *wallet, QWAccount *_account, NSError *error) {
                        createAccountCompletion(wallet, _account ?: account, error);
                    }]];
                } else {
                    createAccountCompletion(wallet, account, error);
                }
            }]];
        } else {
            fullPath = [NSString stringWithFormat:@"44'/%ld'/%ld'/0/0", coinType, path];
            [self.keystore savePrivateKey:[self.keystore privateKeyWithMnemonic:phrase coinType:coinType path:fullPath] password:password toPath:QWAccountKeystorePath coinType:coinType completion:[self didCreateAccountWithPassword:password type:coinType wallet:wallet isHD:true path:fullPath atIndex:insertIndex completion:createAccountCompletion]];
        }
    }];
    
}

- (void)setColdMode:(BOOL)coldMode {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:QWWalletManagerColdModeKey]) {
        objc_setAssociatedObject(self, @selector(isColdMode), @(coldMode), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

- (BOOL)isColdMode {
    NSNumber *isColdMode = objc_getAssociatedObject(self, _cmd);
    if (!isColdMode) {
        isColdMode = [[NSUserDefaults standardUserDefaults] objectForKey:QWWalletManagerColdModeKey];
    }
    return isColdMode.boolValue;
}

@end
