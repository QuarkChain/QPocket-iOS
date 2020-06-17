//
//  NSString+QWHexBinaryConverting.h
//  QuarkWallet
//
//  Created by Jazys on 2018/9/26.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (QWHexBinaryConverting)

+ (NSString *)qw_binaryStringWithNumber:(NSInteger)number length:(NSInteger)length;

- (NSString *)qw_binaryFromHexString;

- (NSString *)qw_hexFromBinaryString;

@end

NS_ASSUME_NONNULL_END
