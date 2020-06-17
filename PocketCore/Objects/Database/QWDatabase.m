//
//  QWDatabase.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDatabase.h"
#import <Realm/Realm.h>
#import <Realm/RLMObjectStore.h>
#import "RLMResults+QWDatabase.h"

@interface QWDatabase()
@property (nonatomic, weak) RLMRealm *realm;
@end

@implementation QWDatabase

- (instancetype)initWithPath:(NSString *)path
{
    self = [super init];
    if (self) {
        self.realm = [RLMRealm defaultRealm]; // see QWWalletManager+Private hook
    }
    return self;
}

- (void)transactionWithBlock:(dispatch_block_t)block {
    [self.realm transactionWithBlock:block];
}

- (void)addObject:(QWDatabaseObject *)object {
    [self.realm addObject:(id)object];
}

- (void)addObjects:(nonnull id<NSFastEnumeration>)objects {
    [self.realm addObjects:objects];
}

- (void)deleteObject:(nonnull RLMObject *)object {
    [self.realm deleteObject:object];
}

- (void)deleteObjects:(id<NSFastEnumeration>)objects{
    [self.realm deleteObjects:objects];
}

- (NSArray<QWDatabaseObject *> *)allObjectsWithClass:(Class)class {
    return RLMGetObjects(self.realm, [class valueForKey:@"className"], nil).allObjectsInArray;
}

- (QWDatabaseObject *)objectWithClass:(Class)class where:(NSString *)where {
    return RLMGetObjects(self.realm, [class valueForKey:@"className"], [NSPredicate predicateWithFormat:where]).firstObject;
}

- (void)updateAllObjectsWithClass:(Class)class value:(id)value forKey:(NSString *)key {
    RLMResults *result = RLMGetObjects(self.realm, [class valueForKey:@"className"], nil);
    [result setValue:value forKey:key];
}

@end
