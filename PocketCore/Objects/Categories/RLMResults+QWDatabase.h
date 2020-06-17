//
//  RLMResults+QWDatabase.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/16.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Realm/Realm.h>

@interface RLMResults (QWDatabase)

- (NSArray *)allObjectsInArray;

- (NSArray *)allObjectsInArrayByCreatedAt;

- (NSArray *)allObjectsInArrayByInvertCreatedAt;

@end
