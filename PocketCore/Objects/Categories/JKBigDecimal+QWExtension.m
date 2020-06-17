//
//  JKBigDecimal+QWExtension.m
//  QuarkWallet
//
//  Created by Jazys on 2020/6/2.
//  Copyright © 2020 QuarkChain. All rights reserved.
//

#import "JKBigDecimal+QWExtension.h"

@implementation JKBigDecimal (QWExtension)

- (id)initWithString:(NSString *)string figure:(NSUInteger)figure {
    JKBigDecimal *decimal = [self initWithString:string];
    decimal.figure = figure;
    return decimal;
}

@end
