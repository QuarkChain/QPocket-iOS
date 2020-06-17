//
//  QWWalletManager+Private.m
//  QuarkWallet
//
//  Created by Jazys on 2018/9/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager+Private.h"
#import "QWWalletManager.h"
#import <Realm/Realm.h>
#import "QWDatabase.h"
#import <objc/runtime.h>
#import "QWNetwork.h"

QWUserDefaultsKey const QWWalletManagerAskedForAccountBackupPhraseKey = @"QWWalletManagerAskedForAccountBackupPhraseKey";

@implementation RLMRealm (QWWalletManagerHook)

+ (instancetype)defaultRealm {
    static id _realm = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_realm) {
            _realm = [RLMRealm realmWithURL:[NSURL fileURLWithPath:QWWalletDatabasePath]];
        }
    });
    return _realm;
}

@end
