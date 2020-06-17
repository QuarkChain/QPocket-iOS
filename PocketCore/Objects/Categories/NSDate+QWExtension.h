//
//  NSDate+QWExtension.h
//  QuarkWallet
//
//  Created by Jazys on 2018/9/4.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (QWExtension)

- (NSTimeInterval)timeIntervalInSecondsSinceTimeInterval:(NSTimeInterval)timeInterval;

- (NSTimeInterval)timeIntervalInMinutesSinceTimeInterval:(NSTimeInterval)timeInterval;

- (NSTimeInterval)timeIntervalInHoursSinceTimeInterval:(NSTimeInterval)timeInterval;

- (NSTimeInterval)timeIntervalInDaysSinceTimeInterval:(NSTimeInterval)timeInterval;

@end
