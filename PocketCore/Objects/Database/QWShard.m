//
//  QWShard.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/15.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWShard.h"
#import "QWChain.h"

@interface QWShard()
@property (nonatomic, readonly) RLMLinkingObjects *chains;
@end

@implementation QWShard

//+ (NSString *)primaryKey {
//    return @"id";
//}

+ (NSDictionary<NSString *,RLMPropertyDescriptor *> *)linkingObjectsProperties {
    return @{@"chains": [RLMPropertyDescriptor descriptorWithClass:[QWChain class] propertyName:@"shards"]};
}

- (QWChain *)chain {
    return self.chains.firstObject;
}

@end
