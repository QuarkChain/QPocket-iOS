//
//  QWBalance.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDatabaseObject.h"

@class QWAccount, QWToken, QWShard, QWChain;

@interface QWBalance : QWDatabaseObject

@property (nonatomic, readonly) QWAccount *account;

@property (nonatomic) QWToken *token;

@property (nonatomic) QWShard *shard;

@property (nonatomic) QWChain *chain;

@property (nonatomic, copy) NSString *balance;

@end
