//
//  NSString+QWHexBinaryConverting.m
//  QuarkWallet
//
//  Created by Jazys on 2018/9/26.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "NSString+QWHexBinaryConverting.h"

@implementation NSString (QWHexBinaryConverting)

+ (NSString *)qw_binaryStringWithNumber:(NSInteger)number length:(NSInteger)length {
    NSMutableString *binaryString = [NSMutableString string];
    while (number) {
        [binaryString insertString:(number & 1) ? @"1" : @"0" atIndex:0];
        number /= 2;
    }
    if (binaryString.length < length) {
        NSInteger diff = length - binaryString.length;
        for (NSInteger index = 0; index < diff; index++) {
            [binaryString insertString:@"0" atIndex:0];
        }
    }
    return binaryString;
}

- (NSString *)qw_hexFromBinaryString {
    
    if (self.length > 16) {
        
        NSMutableArray *bins = [NSMutableArray array];
        for (int i = 0;i < self.length; i += 16) {
            [bins addObject:[self substringWithRange:NSMakeRange(i, 16)]];
        }
        
        NSMutableString *ret = [NSMutableString string];
        for (NSString *abin in bins) {
            [ret appendString:[abin qw_hexFromBinaryString]];
        }
        
        return ret;
        
    } else {
        int value = 0;
        for (int i = 0; i < self.length; i++) {
            value += pow(2, i) * [[self substringWithRange:NSMakeRange(self.length - 1 - i, 1)] intValue];
        }
        return [NSString stringWithFormat:@"%x", value];
    }
    
}

- (NSString *)qw_binaryFromHexString {
    NSMutableString *binaryString = [NSMutableString string];
    for (NSUInteger i = 0; i < self.length; i++) {
        NSString *bin = [self qw_binaryFromHexCharacter:[self characterAtIndex:i]];
        for (NSInteger j = 0; j < bin.length; j++) {
            [binaryString appendString:[NSString stringWithFormat:@"%C", [bin characterAtIndex:j]]];
        }
    }
    return binaryString;
}

- (NSString *)qw_binaryFromHexCharacter:(unichar)hexCharacter {
    
    switch (hexCharacter) {
        case '0': return @"0000";
        case '1': return @"0001";
        case '2': return @"0010";
        case '3': return @"0011";
        case '4': return @"0100";
        case '5': return @"0101";
        case '6': return @"0110";
        case '7': return @"0111";
        case '8': return @"1000";
        case '9': return @"1001";
            
        case 'a':
        case 'A': return @"1010";
            
        case 'b':
        case 'B': return @"1011";
            
        case 'c':
        case 'C': return @"1100";
            
        case 'd':
        case 'D': return @"1101";
            
        case 'e':
        case 'E': return @"1110";
            
        case 'f':
        case 'F': return @"1111";
    }
    
    NSAssert(NO, @"Not a hex character");
    
    return nil;
    
}

@end
