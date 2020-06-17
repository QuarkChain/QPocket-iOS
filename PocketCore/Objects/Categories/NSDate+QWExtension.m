//
//  NSDate+QWExtension.m
//  QuarkWallet
//
//  Created by Jazys on 2018/9/4.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "NSDate+QWExtension.h"

@implementation NSDate (QWExtension)

- (NSTimeInterval)timeIntervalInSecondsSinceTimeInterval:(NSTimeInterval)timeInterval {
    return [self timeIntervalSinceDate:[NSDate dateWithTimeIntervalSince1970:timeInterval]];
}

- (NSTimeInterval)timeIntervalInMinutesSinceTimeInterval:(NSTimeInterval)timeInterval {
    return [self timeIntervalInSecondsSinceTimeInterval:timeInterval] / 60;
}

- (NSTimeInterval)timeIntervalInHoursSinceTimeInterval:(NSTimeInterval)timeInterval {
    return [self timeIntervalInMinutesSinceTimeInterval:timeInterval] / 60;
}

- (NSTimeInterval)timeIntervalInDaysSinceTimeInterval:(NSTimeInterval)timeInterval {
    return [self timeIntervalInHoursSinceTimeInterval:timeInterval] / 24;
}

@end
