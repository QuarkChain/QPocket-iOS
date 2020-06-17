//
//  QWDataStash.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWDataStash.h"

@interface QWDataStash()

@property (nonatomic) NSMutableDictionary *stash;

@end

static QWDataStash *_instance = nil;
static dispatch_once_t _onceToken;
@implementation QWDataStash

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.stash = [NSMutableDictionary dictionary];
    }
    return self;
}

+ (instancetype)sharedStash {
    dispatch_once(&_onceToken, ^{
        _instance = [self new];
    });
    return _instance;
}

+ (void)releaseSharedStash {
    _instance = nil;
    _onceToken = 0;
}

- (void)pushValue:(id)value forKey:(NSString *)key {
    NSAssert(value, @"value is nil");
    NSMutableArray *realStash = self.stash[key];
    if (!realStash) {
        realStash = [NSMutableArray array];
        self.stash[key] = realStash;
    }
    [realStash addObject:value];
}

- (id)popValueForKey:(NSString *)key {
    NSMutableArray *realStash = self.stash[key];
    id value = realStash.lastObject;
    [realStash removeLastObject];
    return value;
}

@end
