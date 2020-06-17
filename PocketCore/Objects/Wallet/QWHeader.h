//
//  QWHeader.h
//  QuarkWallet
//
//  Created by Jazys on 2018/7/30.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#ifndef QWHeader_h
#define QWHeader_h

#import "QWError.h"

typedef enum : NSInteger {
    QWWalletCoinTypeUnknown = -1,
    QWWalletCoinTypeBTC = 0,
    QWWalletCoinTypeETH = 60,
    QWWalletCoinTypeTRX = 195,
    QWWalletCoinTypeQKC = 99999999,
    QWWalletCoinTypeONE = 1023
} QWWalletCoinType;

typedef NSString *QWUserDefaultsKey NS_EXTENSIBLE_STRING_ENUM;

#define kScreenWidth ([UIScreen mainScreen].bounds.size.width)
#define kScreenHeight ([UIScreen mainScreen].bounds.size.height)
#define IS_IPHONEX (kScreenWidth == 375.f && kScreenHeight == 812.f ? YES : NO)
#define NSStringFromKeyPath(objc, keyPath) ((void)objc.keyPath, @(#keyPath))

#define DefaultShardSize 32

//#if TARGET_INTERFACE_BUILDER
#define QWLocalizedString(key) [[NSBundle bundleForClass:self.class] localizedStringForKey:(key) value:nil table:@"QWLocalizable"]
//#else
//#define QWLocalizedString(key) [[[QWApplicationManager sharedManager] localizationBundle] localizedStringForKey:(key) value:nil table:@"QWLocalizable"]
//#endif

#define QWLocalizedFormatString(format, ...) [NSString stringWithFormat:QWLocalizedString(format), __VA_ARGS__]

#define DISCOVER_ENABLED

#endif /* QWHeader_h */
