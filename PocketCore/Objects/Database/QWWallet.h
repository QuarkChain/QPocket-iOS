//
//  QWAccount.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDatabaseObject.h"
#import "QWAccount.h"
#import "QWHeader.h"

RLM_ARRAY_TYPE(QWAccount)

typedef NS_ENUM(NSInteger, QWHardwareWalletType) {
    QWHardwareWalletTypeNone,
    QWHardwareWalletTypeLedger
};

@interface QWWallet : QWDatabaseObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *iconName;

@property (nonatomic, copy) NSString *encryptedPhrase;

@property (nonatomic, copy) NSString *keystoreName; //for phrase encry and can use as ID, the keystore is the copy of first account's keystore

@property (nonatomic, copy) NSString *passwordHint;

@property (nonatomic, getter=isPhraseBackedUp) BOOL phraseBackedUp;

@property (nonatomic, getter=isPrimary) BOOL primary;

@property (nonatomic) RLMArray<QWAccount *><QWAccount> *accounts;

@property (nonatomic, readonly) QWWalletCoinType currentAccountType;

@property (nonatomic) QWAccount *currentAccount;

//@property (nonatomic) NSNumber<RLMInt> *btcAccountAddressType;

//@property (nonatomic, weak, readonly) QWAccount *btcAccount;

@property (nonatomic) QWHardwareWalletType harewareWalletType;

@property (nonatomic) NSString *hardwareWalletId;

@property (nonatomic) RLMArray <QWAccount *><QWAccount> *currentBTCAccounts;

@property (nonatomic, readonly) NSString *path;

- (BOOL)isWatch;

- (BOOL)isHD;

- (NSArray <QWAccount *> *)currentAccounts;

@end
