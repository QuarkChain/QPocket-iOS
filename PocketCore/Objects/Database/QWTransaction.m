//
//  QWTransaction.m
//  QuarkWallet
//
//  Created by zhuqiang on 2018/8/17.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWTransaction.h"
#import "QWDatabase.h"
#import "QWWallet.h"
#import "QWToken.h"
#import "QWShard.h"

@interface QWTransaction()
@property (nonatomic, readonly) RLMLinkingObjects *accounts;
@end


@implementation QWTransaction
+ (NSDictionary<NSString *,RLMPropertyDescriptor *> *)linkingObjectsProperties {
    return @{@"accounts": [RLMPropertyDescriptor descriptorWithClass:[QWAccount class] propertyName:@"transactions"]};
}

+ (NSDictionary *)defaultPropertyValues {
    NSMutableDictionary *defaultPropertyValues = [super defaultPropertyValues].mutableCopy;
    defaultPropertyValues[@"cost"] = @"0";
    return defaultPropertyValues;
}

- (QWAccount *)account {
    return self.accounts.firstObject;
}
@end
