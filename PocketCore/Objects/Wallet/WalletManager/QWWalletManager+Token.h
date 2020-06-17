//
//  QWWalletManager+Token.h
//  QuarkWallet
//
//  Created by Jazys on 2018/9/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWWalletManager.h"

@class QWToken, RLMResults;

@interface QWWalletManager (Token)

@property (nonatomic, readonly) QWToken *QKC;

@property (nonatomic, readonly) QWToken *ETH;

@property (nonatomic, readonly) QWToken *TRX;

@property (nonatomic, readonly) QWToken *BTC;

@property (nonatomic, readonly) QWToken *ONE;

- (void)refreshTokensWithCompletion:(dispatch_block_t)completion;

- (RLMResults *)allERC20Tokens;

- (void)deleteToken:(QWToken *)token;

- (__kindof QWToken *)TQKC;

- (__kindof QWToken *)QKCERC20;

- (__kindof QWToken *)QKCMainnet;

- (QWToken *)mainToken;

- (QWToken *)mainTokenByCoinType:(QWWalletCoinType)coinType;

@end
