//
//  QWClient.m
//  QuarkWallet
//
//  Created by Jazys on 2018/10/18.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWClient.h"
#import <JKBigInteger2/JKBigDecimal.h>
#import "QWNetwork.h"

@implementation QWClient

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.requestSerializer = [AFJSONRequestSerializer serializer];
        [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        self.responseSerializer.acceptableContentTypes = [NSSet setWithObjects:@"application/json", @"application/json-rpc", @"application/jsonrequest", @"text/html", nil];
    }
    return self;
}

- (NSInteger)chainID {
    return self.options.chainID;
}

- (NSString *)requestURLString {
    return self.options.apiURLString;
}

- (BOOL)testnet {
    return !self.options.isMainnet;
}

+ (NSString *)defaultGasPrice {
    return @"10000000000";
}

- (void)getBalanceOfAddress:(NSString *)address
                    success:(void(^)(NSString *balance))success
                    failure:(void(^)(NSError *error))failure {
    
}

- (void)getTransactionCount:(NSString *)address
                    success:(void(^)(NSString *))success
                    failure:(void(^)(NSError *))failure {
    
}

- (void)getTransactionById:(NSString *)transactionId
                   success:(void(^)(NSDictionary *))success
                   failure:(void(^)(NSError *))failure {
    
}

- (void)getTransactionReceipt:(NSString *)transactionId
                      success:(void(^)(NSDictionary *))success
                      failure:(void(^)(NSError *))failure {
    
}

- (void)sendRawTransaction:(NSString *)rawTransaction
                   success:(void(^)(NSString *))success
                   failure:(void(^)(NSError *))failure {
    
}

- (void)call:(NSString *)contractAddress
        from:(NSString *)from
     dataHex:(NSString *)dataHex
     success:(void(^)(NSString *dataString))success
     failure:(void(^)(NSError *error))failure {
    
}

- (void)estimateGasWithParam:(NSDictionary *)params callback:(void(^)(NSString *))callback {
    
}

- (JKBigInteger *)defaultGasPrice{
    if(self.cachedGasPrice && ![self.cachedGasPrice isEqualToString:@"0"]){
        return [[JKBigInteger alloc] initWithString:self.cachedGasPrice];
    }else{
        return [[JKBigInteger alloc] initWithString:[self.class defaultGasPrice]];
    }
}

- (JKBigInteger *)defaultTransferGasLimit{
    return [[JKBigInteger alloc] initWithString:@"30000"];
}

- (JKBigInteger *)defaultContractCallGasLimit{
    return [[JKBigInteger alloc] initWithString:@"1000000"];
}

- (JKBigInteger *)defaultTransferCost{
    return [[self defaultGasPrice] multiply:[self defaultTransferGasLimit]];
}

@end
