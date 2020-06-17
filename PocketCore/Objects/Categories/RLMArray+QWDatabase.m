//
//  RLMArray+QWDatabase.m
//  QuarkWallet
//
//  Created by Jazys on 2018/11/8.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "RLMArray+QWDatabase.h"

@implementation RLMArray (QWDatabase)

- (void)removeObject:(id)object {
    NSAssert([object isKindOfClass:[RLMObject class]], @"");
    NSInteger index = [self indexOfObject:object];
    if (index != NSNotFound) {
        [self removeObjectAtIndex:index];
    }
}

- (NSArray *)toNSArray {
    NSMutableArray *array = [NSMutableArray array];
    for (id object in self) {
        [array addObject:object];
    }
    return array;
}

@end
