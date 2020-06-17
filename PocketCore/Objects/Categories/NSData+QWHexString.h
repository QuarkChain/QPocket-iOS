//
//  NSData+QWHexString.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (QWHexString)

+ (NSData *)qw_dataWithHexString:(NSString *)hexString;

- (NSString *)qw_hexString;

- (NSString *)qw_binaryString;

@end
