//
//  NSData+QWHexString.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "NSData+QWHexString.h"
#import "NSString+QWHexBinaryConverting.h"

@implementation NSData (QWHexString)

+ (NSData *)qw_dataWithHexString:(NSString *)hexString {
    
    if (!hexString.length) {
        return nil;
    }
    
    if ([hexString hasPrefix:@"0x"] || [hexString hasPrefix:@"0X"]) {
        hexString = [hexString substringFromIndex:2];
    }
    
    hexString = [[hexString uppercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    if (!(hexString && [hexString length] > 0 && [hexString length]%2 == 0)) {
        return nil;
    }
    
    Byte tempbyt[1]={0};
    NSMutableData* bytes=[NSMutableData data];
    for(int i=0;i<[hexString length];i++)
    {
        unichar hex_char1 = [hexString characterAtIndex:i]; ////两位16进制数中的第一位(高位*16)
        int int_ch1;
        if(hex_char1 >= '0' && hex_char1 <='9')
            int_ch1 = (hex_char1-48)*16;   //// 0 的Ascll - 48
        else if(hex_char1 >= 'A' && hex_char1 <='F')
            int_ch1 = (hex_char1-55)*16; //// A 的Ascll - 65
        else
            return nil;
        i++;
        
        unichar hex_char2 = [hexString characterAtIndex:i]; ///两位16进制数中的第二位(低位)
        int int_ch2;
        if(hex_char2 >= '0' && hex_char2 <='9')
            int_ch2 = (hex_char2-48); //// 0 的Ascll - 48
        else if(hex_char2 >= 'A' && hex_char2 <='F')
            int_ch2 = hex_char2-55; //// A 的Ascll - 65
        else
            return nil;
        
        tempbyt[0] = int_ch1+int_ch2;  ///将转化后的数放入Byte数组里
        [bytes appendBytes:tempbyt length:1];
    }
    
    return bytes;
    
}

- (NSString *)qw_hexString {
    NSString *string = self.description;
//    [NSString stringWithFormat:@"%@", self];
    if (@available(iOS 13.0, *)) {
        string = self.debugDescription;
    }
    return [[[string stringByReplacingOccurrencesOfString: @"<" withString: @""] stringByReplacingOccurrencesOfString: @">" withString: @""] stringByReplacingOccurrencesOfString: @" " withString: @""];
}

- (NSString *)qw_binaryString {
    return [[self qw_hexString] qw_binaryFromHexString];
}

//- (NSString *)description {
//    if (@available(iOS 13.0, *)) {
//        return super.debugDescription;
//    } else {
//        return super.description;
//    }
//}

@end
