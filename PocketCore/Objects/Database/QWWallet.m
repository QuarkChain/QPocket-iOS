//
//  QWAccount.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWallet.h"
#import <objc/runtime.h>
#import "RLMArray+QWDatabase.h"

@implementation QWWallet

+ (NSDictionary *)defaultPropertyValues {
    NSMutableDictionary *defaultPropertyValues = [super defaultPropertyValues].mutableCopy;
    defaultPropertyValues[@"iconName"] = @"WalletIcons.bundle/wallet_icon_01";
    return defaultPropertyValues;
}

- (QWWalletCoinType)currentAccountType {
    return self.currentAccount.coinType.unsignedIntegerValue;
}

- (NSString *)path {
    return self.accounts.firstObject.path;
}

- (BOOL)isWatch {
    return !self.accounts.firstObject.keystoreName.length || self.harewareWalletType != QWHardwareWalletTypeNone;
}

- (BOOL)isHD {
    return self.encryptedPhrase.length;
}

- (void)setCurrentAccounts:(NSArray<QWAccount *> *)currentAccounts {
    objc_setAssociatedObject(self, @selector(currentAccounts), currentAccounts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSArray<QWAccount *> *)currentAccounts {
    id currentAccounts = objc_getAssociatedObject(self, _cmd);
    if (!currentAccounts) {
        currentAccounts = [NSMutableArray array];
        NSInteger index = -1;
        NSInteger btcStartIndex = -1;
        for (QWAccount *account in self.accounts) {
            index++;
            if (account.coinType.unsignedIntegerValue == QWWalletCoinTypeBTC) {
                if (btcStartIndex == -1) {
                    btcStartIndex = index;
                }
                continue;
            } else {
                [currentAccounts addObject:account];
            }
        }
        [currentAccounts insertObjects:self.currentBTCAccounts.toNSArray atIndexes:[NSIndexSet indexSetWithIndex:btcStartIndex]];
        objc_setAssociatedObject(self, _cmd, currentAccounts, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return currentAccounts;
}

@end
