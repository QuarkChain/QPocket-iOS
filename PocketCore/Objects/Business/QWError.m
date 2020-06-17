//
//  QWError.m
//  QuarkWallet
//
//  Created by Jazys on 2018/9/5.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWError.h"

NSErrorDomain const QWNetworkErrorDomain = @"QWNetworkErrorDomain";

NSErrorDomain const QWWalletManagerErrorDomain = @"QWWalletManagerErrorDomain";

NSErrorDomain const QWKeystoreErrorDomain = @"QWKeystoreErrorDomain";

@implementation QWError

+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code localizedDescription:(NSString *)localizedDescription {
    return [self errorWithDomain:domain code:code userInfo:localizedDescription.length ? @{NSLocalizedDescriptionKey:localizedDescription} : nil];
}

+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code localizedDescriptionKey:(NSString *)localizedDescriptionKey {
    return [self errorWithDomain:domain code:code userInfo:localizedDescriptionKey.length ? @{NSLocalizedDescriptionKey:localizedDescriptionKey} : nil];
}

+ (instancetype)errorWithDomain:(NSErrorDomain)domain code:(NSInteger)code localizedDescriptionKey:(NSString *)localizedDescriptionKey userInfo:(NSDictionary *)userInfo {
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    if (localizedDescriptionKey.length) {
        info[NSLocalizedDescriptionKey] = localizedDescriptionKey;
    }
    if (userInfo.count) {    
        [info addEntriesFromDictionary:userInfo];
    }
    return [self errorWithDomain:domain code:code userInfo:info];
}

@end
