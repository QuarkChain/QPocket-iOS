//
//  NSString+JSONRPC.m
//  JSONRPCTest
//
//  Created by zhuqiang on 2018/8/2.
//  Copyright © 2018 freedostudio. All rights reserved.
//

#import "NSString+JSONRPC.h"

@implementation NSString (JSONRPC)
- (NSUInteger)hex2Int{
    unsigned result = 0;
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setScanLocation:2]; // bypass '0x' character
    [scanner scanHexInt:&result];
    return result;
}
@end
