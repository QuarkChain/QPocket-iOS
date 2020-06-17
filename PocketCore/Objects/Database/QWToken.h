//
//  QWToken.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDatabaseObject.h"
#import "QWHeader.h"

@interface QWToken : QWDatabaseObject

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) NSString *iconURL;

@property (nonatomic, copy) NSString *iconNamed;

@property (nonatomic, copy) NSString *address;

@property (nonatomic, copy) NSString *symbol;

@property (nonatomic, copy) NSString *totalSupply;

@property (nonatomic, copy) NSString *decimals;

@property (nonatomic, copy) NSString *URL;

@property (nonatomic, copy) NSString *descriptionEn;

@property (nonatomic, copy) NSString *descriptionCn;

@property (nonatomic) NSNumber<RLMInt> *coinType; //QWWalletCoinType

@property (nonatomic) NSNumber<RLMInt> *chainId; //testnet id

@property (nonatomic, getter=isNative) BOOL native;

@property (nonatomic, getter=isBuiltIn) BOOL builtIn;

@property (nonatomic, readonly) RLMLinkingObjects *accounts;

- (NSString *)defaultShardId;

- (NSString *)defaultChainId;

- (NSString *)testnetSymbolIfNeeded;

+ (instancetype)tokenWithAddress:(NSString *)address coinType:(QWWalletCoinType)coinType chainId:(NSInteger)chainId;

+ (NSString *)tokenFetchConditionWithAddress:(NSString *)address coinType:(QWWalletCoinType)coinType chainId:(NSInteger)chainId;

- (NSString *)tokenFetchCondition;

- (BOOL)isQKC;

@end
