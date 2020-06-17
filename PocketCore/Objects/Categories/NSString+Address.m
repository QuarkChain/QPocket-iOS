//
//  NSString+Address.m
//  GethTest
//
//  Created by zhuqiang on 2018/8/8.
//  Copyright © 2018 freedostudio. All rights reserved.
//

#import "NSString+Address.h"
#import <JKBigInteger2/JKBigInteger.h>
#import "PocketCore-Swift.h"
#import "QWWalletManager+Account.h"
#import "QWChain.h"
#import "QWAccount.h"
#import "CoreBitcoin/CoreBitcoin.h"
#import <TrezorCrypto/segwit_addr.h>
//#import "QWReactNativeMessager.h"

@implementation NSString (Address)

- (NSString *)newFullShardIdAppended {
    NSAssert(self.length == 42, @"address's length must equal to 42");
    NSString *fullShardId = @"";
    for(int i=2;i<42;i+=10){
        fullShardId = [fullShardId stringByAppendingString:[self substringWithRange:NSMakeRange(i, 2)]];
    }
    JKBigInteger *integer = [[JKBigInteger alloc] initWithString:fullShardId andRadix:16];
    NSInteger chainId = (integer.unsignedIntValue >> 16) % [[QWWalletManager defaultManager] chainSizeByCurrentNetwork];
    NSString *newFullShardId = [NSString stringWithFormat:@"%08lX", (chainId << 16) + (integer.unsignedIntValue & ((1 << 16) - 1))];
    return [QWKeystoreSwift checksumStringQKCWithString:[self stringByAppendingString:newFullShardId]];
}

- (NSString *)fullShardIdAppended{
    NSAssert(self.length == 42, @"address's length must equal to 42");
    NSString *fullShardId = @"";
    for(int i=2;i<42;i+=10){
        fullShardId = [fullShardId stringByAppendingString:[self substringWithRange:NSMakeRange(i, 2)]];
    }
    return [QWKeystoreSwift checksumStringQKCWithString:[self stringByAppendingString:fullShardId]];
}

- (NSString *)appendFullShardId:(NSString *)fullShardId{
    while (fullShardId.length < 8) {
        fullShardId = [@"0" stringByAppendingString:fullShardId];
    }
    return [QWKeystoreSwift checksumStringQKCWithString:[self stringByAppendingString:fullShardId]];
}

- (NSString *)fullShardId{
    if (self.length > 42) {
        return [self substringFromIndex:42];
    }
    return nil;
}

- (NSString *)fullShardIdTrimed{
    if (self.length > 42) {
        return [self substringToIndex:42];
    }
    return self;
}

- (NSString *)passByFirstTwoBytes{
    if (self.length < 2) {
        return self;
    }
    if([[self substringWithRange:NSMakeRange(0, 2)] isEqualToString:@"0x"]){
        return [self substringFromIndex:2];
    }else{
        return self;
    }
}

- (NSString *)truncatedString{
    if (self.length < 16) {
        return self;
    }
    NSString *firstPart = [self substringWithRange:NSMakeRange(0, 8)];
    NSString *secondPart = [self substringFromIndex:self.length-8];
    return [NSString stringWithFormat:@"%@...%@", firstPart, secondPart];
}

- (NSUInteger)shardId{
    if(self.length >= 8){
        QWChain *chain = [QWChain objectForKey:@"id" value:[NSString stringWithFormat:@"%ld", self.chainId]];
        NSUInteger shardSize = [[QWWalletManager defaultManager] shardSizeByCurrentNetworkForChain:chain ?: [QWWalletManager defaultManager].currentAccount.chain];
        NSString *fullShardId = self.length == 8 ? self : [self substringFromIndex:self.length - 8];
        JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:fullShardId andRadix:16];
        NSUInteger fullShardDecimal = [transformer unsignedIntValue];
//        NSUInteger shardId = fullShardDecimal % shardSize;
        NSUInteger shardId = fullShardDecimal & (shardSize - 1);
        return shardId;
    }else{
        return 0;
    }
}

- (NSUInteger)chainId {
    NSString *fullShardId = self.length == 8 ? self : [self substringFromIndex:self.length - 8];
    JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:fullShardId andRadix:16];
    NSUInteger fullShardDecimal = [transformer unsignedIntValue];
    return fullShardDecimal >> 16;
}

- (BOOL)isValidAddressByCoinType:(QWWalletCoinType)coinType {
    return [self isValidAddressByCoinType:coinType isNative:false];
}

- (BOOL)isValidAddressByCoinType:(QWWalletCoinType)coinType isNative:(BOOL)isNative {
    switch (coinType) {
        case QWWalletCoinTypeQKC:
            return [self isQKCAddress] || [self isQKCNativeAddress];
        case QWWalletCoinTypeETH:
            return [self isETHAddress];
        case QWWalletCoinTypeTRX:
            return !isNative ? [self isTRXAddress] : [self isTRC10Address];
        case QWWalletCoinTypeBTC:
            return [self isBTCAddress] || [self isBTCPublicKey];
        case QWWalletCoinTypeONE:
            return false;
        default:
            return false;
    }
}

- (BOOL)isQKCAddress {
    NSString *regularExpression = nil;
    if (self.length == 50) {
        regularExpression = @"0[xX][0-9a-fA-F]+";
    } else if (self.length == 48) {
        regularExpression = @"[0-9a-fA-F]+";
    } else {
        return false;
    }
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", regularExpression] evaluateWithObject:self];
}

- (BOOL)isETHAddress {
    NSString *regularExpression = nil;
    if (self.length == 42) {
        regularExpression = @"0[xX][0-9a-fA-F]+";
    } else if (self.length == 40) {
        regularExpression = @"[0-9a-fA-F]+";
    } else {
        return false;
    }
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", regularExpression] evaluateWithObject:self];
}

- (BOOL)isTRXAddress {
    return self.length == 34 && [QWKeystoreSwift base58CheckDecodingWithString:self] != nil && [[self substringToIndex:1] isEqualToString:@"T"];
}

- (BOOL)isTRC10Address {
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^1[0-9]{6,}"] evaluateWithObject:self];
}

- (BOOL)isHex {
    if (![self hasPrefix:@"0x"]) {
        return false;
    }
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"0[xX][0-9a-fA-F]+"] evaluateWithObject:self];
}

- (BOOL)isNumericAddress {
    return [[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"(^[-0-9][0-9]*(.[0-9]+)?)$"] evaluateWithObject:self];
}

- (BOOL)isAlphaNumeric
{
    NSCharacterSet *unwantedCharacters =
    [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    
    return ([self rangeOfCharacterFromSet:unwantedCharacters].location == NSNotFound) ? YES : NO;
}

- (BOOL)isBTCPublicKey {
    BTCKeychain *keychain = [[BTCKeychain alloc] initWithExtendedKey:self];
    return keychain != nil && keychain.extendedPrivateKey == nil;
}

- (BOOL)isBTCAddress
{
    return [BTCAddress addressWithString:self] != nil;
    if (![self isAlphaNumeric])
    {
        return NO;
    }
    
    if (self.length < 27 || self.length > 34)
    {
        return NO;
    }
    
    if (![self hasPrefix:@"1"] && [self hasPrefix:@"3"])
    {
        return NO;
    }
    
    return YES;
}

- (BOOL)isBTCSegWitAddress {
    if ([[QWWalletManager defaultManager].network lastClientOptionsWithCoinType:QWWalletCoinTypeBTC].isMainnet) {
        return [[self substringToIndex:1] isEqualToString:@"3"];
    }
    return [[self substringToIndex:1] isEqualToString:@"2"];
}

- (NSString *)ensureEightAlphaNubmbericString{
    NSString *fullShardId = self;
    while(fullShardId.length < 8){
        fullShardId = [@"0" stringByAppendingString:fullShardId];
    }
    return fullShardId;
}

- (NSString *)fullShardIdBySwitchToShardId:(NSString *)toShardId chainId:(NSString *)chainId {
    NSString *fromFullShardId = [self substringFromIndex:42];
    JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:fromFullShardId andRadix:16];
    
    NSInteger fromFullShardIdDecimal = [transformer stringValue].integerValue;
    NSInteger fromShardId = [self shardId];
    NSInteger delta = toShardId.integerValue - fromShardId;
    
    JKBigInteger *toFullShardIdDecimal = [[JKBigInteger alloc] initWithUnsignedLong:(fromFullShardIdDecimal + delta)];
    
    NSString *fullShardId = [[toFullShardIdDecimal stringValueWithRadix:16] ensureEightAlphaNubmbericString];
    
    JKBigInteger *integer = [[JKBigInteger alloc] initWithString:fullShardId andRadix:16];
    NSString *newFullShardId = [NSString stringWithFormat:@"%08lX", (chainId.integerValue << 16) + (integer.unsignedIntValue & ((1 << 16) - 1))];
    return newFullShardId;
}

- (NSString *)hexIdFromQKC36RadixId {
    
    int (^charToInt)(unichar, NSError **) = ^int(unichar c, NSError **e) {
        char _cAZ09[sizeof(unichar) * 5 + sizeof(",") * 4];
        sprintf(_cAZ09, "%d,%d,%d,%d,%d", c, 'A', 'Z', '0', '9');
        NSArray <NSString *> *cAZ09 = [[[NSString alloc] initWithCString:_cAZ09 encoding:NSUTF8StringEncoding] componentsSeparatedByString:@","];
        if (cAZ09[0].intValue >= cAZ09[1].intValue && cAZ09[0].intValue <= cAZ09[2].intValue) {
            return 10 + cAZ09[0].intValue - cAZ09[1].intValue;
        }
        if (cAZ09[0].intValue >= cAZ09[3].intValue && cAZ09[0].intValue <= cAZ09[4].intValue) {
            return cAZ09[0].intValue - cAZ09[3].intValue;
        }
        *e = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil]; // ("unknown character {}".format(char))
        return 0;
    };

    if (self.length >= 13) {
        return nil; //name too long
    }

    if (![[NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9A-Z]+$"] evaluateWithObject:self]) {
        return nil; //"name can only contain 0-9, A-Z"
    }
   
    NSError *error = nil;
    NSUInteger id = charToInt([self characterAtIndex:self.length - 1], &error);
    
    if (error) {
        return nil;
    }
    
    int tokenBase = 36;
    NSUInteger base = tokenBase;
    
    for (NSInteger index = self.length - 2; index >= 0; index--) {
        id += base * (charToInt([self characterAtIndex:index], &error) + 1);
        base *= tokenBase;
        if (error) {
            return nil;
        }
    }
    
    if (id > 4873763662273663091) { //Token id max is 4873763662273663091 = "ZZZZZZZZZZZZ"
        return nil;
    }
    
    return [[[JKBigInteger alloc] initWithUnsignedLong:id] stringValueWithRadix:16];
            
}

- (BOOL)isQKCNativeAddress {
    return self.isHex && ([[JKBigInteger alloc] initWithString:self.passByFirstTwoBytes].unsignedIntValue <= 4873763662273663091);
}

- (NSString *)qkc36RadixIdFromHexId {
    
    if (![self isQKCNativeAddress]) {
        return nil;
    }
    
    int tokenBase = 36;
    
    unichar (^intToChar)(int, NSError **) = ^unichar(int id, NSError **e) {
        if (id < 0 || id >= tokenBase) {
            *e = [NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:nil]; // invalid char
            return 0;
        }
        char _zeroA[sizeof(unichar) * 2 + sizeof(",")];
        sprintf(_zeroA, "%d,%d", '0', 'A');
        NSArray <NSString *> *zeroA = [[[NSString alloc] initWithCString:_zeroA encoding:NSUTF8StringEncoding] componentsSeparatedByString:@","];
        if (id < 10) {
            return zeroA[0].intValue + id;
        }
        return zeroA[1].intValue + id - 10;
    };
    
    NSInteger id = [[JKBigInteger alloc] initWithString:self.passByFirstTwoBytes andRadix:16].unsignedIntValue;
    
    NSMutableString *qkc36RadixId = [NSMutableString string];
    
    NSError *error = nil;

    unichar c = intToChar(id % tokenBase, &error);
    
    if (error) {
        return nil;
    }
    
    [qkc36RadixId appendString:[NSString stringWithCharacters:&c length:1]];
    
    id = (int)(id / tokenBase) - 1;
    while (id >= 0) {
        unichar c = intToChar(id % tokenBase, &error);
        if (error) {
            return nil;
        }
        [qkc36RadixId insertString:[NSString stringWithCharacters:&c length:1] atIndex:0];
        id = (int)(id / tokenBase) - 1;
    }
    
    return qkc36RadixId;
    
}

@end
