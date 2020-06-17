//
//  QWError.h
//  QuarkWallet
//
//  Created by Jazys on 2018/9/5.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSErrorDomain const QWNetworkErrorDomain;

typedef NS_ENUM(NSInteger, QWNetworkError) {
    QWNetworkErrorUnknown = -1,
    QWNetworkErrorNone,
    QWNetworkErrorFetchTimeLimit,
};

FOUNDATION_EXPORT NSErrorDomain const QWWalletManagerErrorDomain;

typedef NS_ENUM(NSInteger, QWWalletManagerError) {
    QWWalletManagerErrorUnknown = -1,
    QWWalletManagerErrorNone,
    QWWalletManagerErrorEmptyAccountPassword,
    QWWalletManagerErrorAccountAuthenticationExpired,
    QWWalletManagerErrorDuplicateAccountName,
    QWWalletManagerErrorInvalidAccountNameLength
};

FOUNDATION_EXPORT NSErrorDomain const QWKeystoreErrorDomain;

typedef NS_ENUM(NSInteger, QWKeystoreErrorCode) {
    QWKeystoreErrorCodeInvalidPassword,
    QWKeystoreErrorCodeInvalidMnemonic,
    QWKeystoreErrorCodeInvalidPrivateKey,
    QWKeystoreErrorCodeInvalidKeystore,
    QWKeystoreErrorCodeUnsupportedKDF,
    QWKeystoreErrorCodeUnsupportedCipher,
    QWKeystoreErrorCodeDuplicateKeystore,
    QWKeystoreErrorCodeSegwitOnlySupportCompressedKey
};

@interface QWError : NSError

+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code localizedDescription:(NSString *)localizedDescription;

+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code localizedDescriptionKey:(NSString *)localizedDescriptionKey;

+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code localizedDescriptionKey:(NSString *)localizedDescriptionKey userInfo:(NSDictionary *)userInfo;

@end
