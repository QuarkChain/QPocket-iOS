//
//  QWDatabase.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>
@class QWDatabaseObject, RLMResults;
@interface QWDatabase : NSObject

- (instancetype)initWithPath:(NSString *)path;

- (void)transactionWithBlock:(dispatch_block_t)block;

- (void)addObject:(QWDatabaseObject *)object;

- (void)addObjects:(id<NSFastEnumeration>)objects;

- (void)deleteObject:(QWDatabaseObject *)object;

- (void)deleteObjects:(id<NSFastEnumeration>)objects;

- (__kindof QWDatabaseObject *)objectWithClass:(Class)class where:(NSString *)where;

- (NSArray <__kindof QWDatabaseObject *> *)allObjectsWithClass:(Class)class;

- (void)updateAllObjectsWithClass:(Class)class value:(id)value forKey:(NSString *)key;

@end
