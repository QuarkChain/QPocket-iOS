//
//  QWCheckParams.h
//  QuarkWallet
//
//  Created by Jazys on 2018/12/28.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface QWCheckParams : NSObject

@end

NS_ASSUME_NONNULL_END

@interface NSDictionary (QWCheckParams)

- (BOOL)qw_isAllKeysExists:(NSArray *)keys;

@end

@interface NSArray (QWCheckParams)
// <NSDictionary *>
- (BOOL)qw_isAllDictionariesKeysExists:(NSArray *)keys;

@end
