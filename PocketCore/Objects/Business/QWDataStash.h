//
//  QWDataStash.h
//  QuarkWallet
//
//  Created by Jazys on 2018/8/6.
//  Copyright © 2018 QuarkChain. All rights reserved.
//  stash temp var for once

#import <Foundation/Foundation.h>

@interface QWDataStash : NSObject

+ (instancetype)sharedStash;
+ (void)releaseSharedStash;

- (void)pushValue:(id)value forKey:(NSString *)key;
- (id)popValueForKey:(NSString *)key;

@end
