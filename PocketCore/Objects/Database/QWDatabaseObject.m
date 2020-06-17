//
//  QWObject.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDatabaseObject.h"
#import "QWDatabase.h"

@implementation QWDatabaseObject

+ (instancetype)objectWhere:(NSString *)where {
    return [self objectsWhere:where].firstObject;
}

+ (RLMResults *)objectsForKey:(NSString *)key value:(id)value {
    return [self objectsWhereKey:key operator:@"==" value:value];
}

+ (instancetype)objectForKey:(NSString *)key value:(id)value {
    return [self objectsForKey:key value:value].firstObject;
}

+ (RLMResults *)objectsWhereKey:(NSString *)key operator:(NSString *)operator value:(id)value {
    return [self objectsWhere:[NSString stringWithFormat:@"%@ %@ '%@'", key, operator, value]];
}

+ (NSDictionary *)defaultPropertyValues {
    return @{@"createdAt":@([[NSDate date] timeIntervalSince1970])};
}

+ (instancetype)objectForKeysValuesDictionary:(NSDictionary *)keysValuesDictionary {
    
    NSMutableString *predicate = [NSMutableString string];
    [keysValuesDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [predicate appendFormat:@"%@ == '%@' AND ", key, obj];
    }];
    [predicate deleteCharactersInRange:NSMakeRange(predicate.length - 5, 5)];
    
    return [self objectsWhere:predicate].firstObject;
    
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"createdAt"]) {
        if ([value isKindOfClass:[NSDictionary class]]) {
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSSZ";
            value = @([[formatter dateFromString:value[@"iso"]] timeIntervalSince1970]);
        }
    }
    [super setValue:value forKey:key];
}

- (void)setValue:(id)value forUndefinedKey:(NSString *)key {
    NSLog(@"jazys: %@ undefinedKey : %@", self.class, key);
}

@end
