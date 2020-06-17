//
//  NSString+QWExtension.m
//  QuarkWallet
//
//  Created by Jazys on 2019/3/25.
//  Copyright © 2019 QuarkChain. All rights reserved.
//

#import "NSString+QWExtension.h"
#import <JKBigInteger2/JKBigInteger.h>
#import "NSString+Address.h"

@implementation NSString (QWExtension)

- (BOOL)isEmailAddress {
    NSString *emailRegex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:self];
}

- (BOOL)isValidVerifyCode {
    NSString *pattern = @"^[0-9]{6}";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", pattern];
    return [predicate evaluateWithObject:self];
}

- (NSString *)integerStringFromHex {
    return [[JKBigInteger alloc] initWithString:[self passByFirstTwoBytes] andRadix:16].stringValue;
}

@end
