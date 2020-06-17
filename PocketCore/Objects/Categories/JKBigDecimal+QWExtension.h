//
//  JKBigDecimal+QWExtension.h
//  QuarkWallet
//
//  Created by Jazys on 2020/6/2.
//  Copyright © 2020 QuarkChain. All rights reserved.
//

#import <JKBigInteger2/JKBigInteger2-umbrella.h>

NS_ASSUME_NONNULL_BEGIN

@interface JKBigDecimal (QWExtension)

- (id)initWithString:(NSString *)string figure:(NSUInteger)figure;

@end

NS_ASSUME_NONNULL_END
