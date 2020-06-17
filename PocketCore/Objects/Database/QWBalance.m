//
//  QWBalance.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWBalance.h"
#import "QWDatabase.h"
#import "QWAccount.h"
#import "QWToken.h"
#import "QWShard.h"

@interface QWBalance()

@property (nonatomic, readonly) RLMLinkingObjects *accounts;

@end

@implementation QWBalance

+ (NSDictionary<NSString *,RLMPropertyDescriptor *> *)linkingObjectsProperties {
    return @{@"accounts": [RLMPropertyDescriptor descriptorWithClass:[QWAccount class] propertyName:@"balances"]};
}

+ (NSDictionary *)defaultPropertyValues {
    NSMutableDictionary *defaultPropertyValues = [super defaultPropertyValues].mutableCopy;
    defaultPropertyValues[@"balance"] = @"0";
    return defaultPropertyValues;
}

- (QWAccount *)account {
    return self.accounts.firstObject;
}

@end
