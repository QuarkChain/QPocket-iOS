//
//  QWObject.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Realm/Realm.h>

@interface QWDatabaseObject : RLMObject

@property (nonatomic, copy) NSString *objectId; //id, object from network(leanCloud) will use this.

@property (nonatomic) NSInteger order;

@property (nonatomic) NSNumber <RLMDouble> *createdAt; //NSTimeInterval

+ (instancetype)objectWhere:(NSString *)where;

+ (instancetype)objectForKey:(NSString *)key value:(id)value;

+ (instancetype)objectForKeysValuesDictionary:(NSDictionary *)keysValuesDictionary;

+ (RLMResults *)objectsWhereKey:(NSString *)key operator:(NSString *)operator value:(id)value; //judgement == > < >= <= !=

+ (RLMResults *)objectsForKey:(NSString *)key value:(id)value;

@end
