//
//  RLMArray+QWDatabase.h
//  QuarkWallet
//
//  Created by Jazys on 2018/11/8.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Realm/Realm.h>

NS_ASSUME_NONNULL_BEGIN

@interface RLMArray (QWDatabase)

- (void)removeObject:(id)object;

- (NSArray *)toNSArray;

@end

NS_ASSUME_NONNULL_END
