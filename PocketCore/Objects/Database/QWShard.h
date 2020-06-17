//
//  QWShard.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDatabaseObject.h"

@class QWChain;

@interface QWShard : QWDatabaseObject

@property (nonatomic, copy) NSString *id;

@property (nonatomic, readonly) QWChain *chain;

@end
