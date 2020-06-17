//
//  RLMResults+QWDatabase.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/16.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "RLMResults+QWDatabase.h"

@implementation RLMResults (QWDatabase)

- (NSArray *)allObjectsInArray {
    NSMutableArray *allObjects = [NSMutableArray arrayWithCapacity:self.count];
    for (id object in self) {
        [allObjects addObject:object];
    }
    return allObjects;
}

- (NSArray *)allObjectsInArrayByCreatedAt {
    return [[self sortedResultsUsingKeyPath:@"createdAt" ascending:true] allObjectsInArray];
}

- (NSArray *)allObjectsInArrayByInvertCreatedAt {
    return [[self sortedResultsUsingKeyPath:@"createdAt" ascending:false] allObjectsInArray];
}

@end
