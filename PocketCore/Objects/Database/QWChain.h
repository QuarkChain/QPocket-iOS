//
//  QWChain.h
//  QuarkWallet
//
//  Created by Jazys on 2019/3/18.
//  Copyright © 2019 QuarkChain. All rights reserved.
//

#import "QWDatabaseObject.h"
#import "QWShard.h"

NS_ASSUME_NONNULL_BEGIN

RLM_ARRAY_TYPE(QWShard)

@interface QWChain : QWDatabaseObject

@property (nonatomic) RLMArray<QWShard *><QWShard> *shards;

@property (nonatomic, copy) NSString *id;

@end

NS_ASSUME_NONNULL_END
