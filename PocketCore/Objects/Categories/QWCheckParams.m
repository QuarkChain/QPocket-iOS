//
//  QWCheckParams.m
//  QuarkWallet
//
//  Created by Jazys on 2018/12/28.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWCheckParams.h"

@implementation QWCheckParams

@end

@implementation NSDictionary (QWCheckParams)

- (BOOL)qw_isAllKeysExists:(NSArray *)keys {
    for (id key in keys) {
        if (![self objectForKey:key]) {
            return false;
        }
    }
    return true;
}

@end

@implementation NSArray (QWCheckParams)

- (BOOL)qw_isAllDictionariesKeysExists:(NSArray *)keys {
    for (NSDictionary *dictionary in self) {
        if (![dictionary qw_isAllKeysExists:keys]) {
            return false;
        }
    }
    return true;
}

@end
