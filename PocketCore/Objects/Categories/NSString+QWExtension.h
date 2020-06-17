//
//  NSString+QWExtension.h
//  QuarkWallet
//
//  Created by Jazys on 2019/3/25.
//  Copyright © 2019 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSString (QWExtension)

- (BOOL)isEmailAddress;

- (BOOL)isValidVerifyCode;

- (NSString *)integerStringFromHex; // 16 -> 10

@end

NS_ASSUME_NONNULL_END
