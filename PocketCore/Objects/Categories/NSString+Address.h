//
//  NSString+Address.h
//  GethTest
//
//  Created by zhuqiang on 2018/8/8.
//  Copyright © 2018 freedostudio. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "QWHeader.h"

@interface NSString (Address)
- (NSString *)fullShardIdAppended;
- (NSString *)appendFullShardId:(NSString *)fullShardId;
- (NSString *)fullShardIdTrimed;
- (NSString *)passByFirstTwoBytes;
- (NSString *)truncatedString;
- (NSUInteger)shardId;
- (NSUInteger)chainId;
- (BOOL)isValidAddressByCoinType:(QWWalletCoinType)coinType;
- (BOOL)isValidAddressByCoinType:(QWWalletCoinType)coinType isNative:(BOOL)isNative;
- (BOOL)isQKCAddress;
- (BOOL)isQKCNativeAddress;
- (BOOL)isETHAddress;
- (BOOL)isTRXAddress;
- (BOOL)isBTCAddress;
- (BOOL)isBTCPublicKey;
- (BOOL)isBTCSegWitAddress;
- (BOOL)isAlphaNumeric;
- (BOOL)isHex;
- (NSString *)fullShardIdBySwitchToShardId:(NSString *)toShardId chainId:(NSString *)chainId;
- (NSString *)ensureEightAlphaNubmbericString;
- (NSString *)newFullShardIdAppended;
- (NSString *)fullShardId;
- (BOOL)isNumericAddress;
- (NSString *)hexIdFromQKC36RadixId;
- (NSString *)qkc36RadixIdFromHexId;
@end
