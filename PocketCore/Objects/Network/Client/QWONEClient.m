//
//  QWONEClient.m
//  QuarkWallet
//
//  Created by Jazys on 2020/6/9.
//  Copyright © 2020 QuarkChain. All rights reserved.
//

#import "QWONEClient.h"
#import "QWNetwork.h"
#import <JKBigInteger2-umbrella.h>
#import "NSString+Address.h"
#import <Geth/Geth.h>
#import "PocketCore-Swift.h"
#import "NSData+QWHexString.h"
#import "QWWalletManager.h"
#import "QWChain.h"

@interface QWONEClient()
@property (nonatomic, copy) NSString *shardId;
@end

@implementation QWONEClient

//- (instancetype)init
//{
//    self = [super init];
//    if (self) {
//        NSSet *acceptableContentTypes = self.responseSerializer.acceptableContentTypes;
//        self.responseSerializer = [AFHTTPResponseSerializer serializer];
//        self.responseSerializer.acceptableContentTypes = acceptableContentTypes;
//    }
//    return self;
//}

- (void)switchEndpointURLShardIdIfNeeded:(NSString *)shardId {
    if (![self.shardId isEqualToString:shardId]) {
        [self setValue:[NSURL URLWithString:[NSString stringWithFormat:self.options.endpointURLString, shardId]] forKey:@"endpointURL"];
        self.shardId = shardId;
    }
}

- (void)getBalanceOfAddress:(NSString *)address success:(void (^)(NSDictionary *))success failure:(void (^)(NSError * _Nonnull))failure {
    dispatch_group_t group = dispatch_group_create();
    NSInteger shardSize = [[QWWalletManager defaultManager] shardSizeByCurrentNetworkForChain:[QWChain objectsWhere:[NSString stringWithFormat:@"id == '%@'", @"0"]].firstObject];
    NSMutableDictionary *balances = [NSMutableDictionary dictionary];
    for (NSInteger index = 0; index < shardSize; index++) {
        dispatch_group_enter(group);
        NSString *shardId = @(index).stringValue;
        [self switchEndpointURLShardIdIfNeeded:shardId];
        [self invokeMethod:@"hmy_getBalance" withParameters:@[address, @"latest"]  requestId:@1 success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
            balances[shardId] = responseObject;
            dispatch_group_leave(group);
        } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
            dispatch_group_leave(group);
        }];
    }
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        if (balances.count == shardSize) {
            success(balances);
        } else {
            failure(nil);
        }
    });
}

- (void)getBalanceOfAddress:(NSString *)address shardId:(NSString *)shardId success:(void (^)(NSString * _Nonnull))success failure:(void (^)(NSError * _Nonnull))failure {
    [self switchEndpointURLShardIdIfNeeded:shardId];
    [self invokeMethod:@"hmy_getBalance" withParameters:@[address, @"latest"]  requestId:@1 success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)gasPriceInShardId:(NSString *)shardId callback:(void(^)(NSString *gasPrice))callback {
    self.cachedGasPrice = @"0";
    [self switchEndpointURLShardIdIfNeeded:shardId];
    [self invokeMethod:@"hmy_gasPrice" withParameters:@[] requestId:@1 success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
        NSString *gasPrice = [self.class defaultGasPrice];
        if(responseObject) {
            JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:[responseObject passByFirstTwoBytes] andRadix:16];
            gasPrice = transformer.stringValue;
            if ([gasPrice isEqualToString:@"0"]) {
                gasPrice = [self.class defaultGasPrice];
            }
            self.cachedGasPrice = gasPrice;
        }
        callback(gasPrice);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback([self.class defaultGasPrice]);
    }];
}

- (void)getTransactionCount:(NSString *)address shardId:(NSString *)shardId success:(void(^)(NSString *))success failure:(void(^)(NSError *))failure {
    [self switchEndpointURLShardIdIfNeeded:shardId];
    [self invokeMethod:@"hmy_getTransactionCount"
        withParameters:@[address, @"latest"]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                   NSString *bypassFirstTwoByte = [(NSString *)responseObject substringFromIndex:2];
                   JKBigInteger *count = [[JKBigInteger alloc] initWithString:bypassFirstTwoByte andRadix:16];
                   success([count stringValue]);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)sendTransactionSignedByKeyStore:(GethKeyStore *)keyStore
                            fromAddress:(GethAddress *)fromAddress
                                  nonce:(NSString *)nonce
                               gasPrice:(NSString *)gasPrice
                               gasLimit:(NSString *)gasLimit
                                     to:(NSString *)address
                                  value:(NSString *)value
                                   data:(NSData *)data
                                shardID:(NSNumber *)shardID
                              toShardID:(NSNumber *)toShardID
                                success:(void(^)(NSString *))success
                                failure:(void(^)(NSError *))failure {
    NSString *rawTxHexEncodeed = [NSString stringWithFormat:@"0x%@", [self getTxRawByKeyStore:keyStore fromAddress:fromAddress nonce:nonce gasPrice:gasPrice gasLimit:gasLimit to:address value:value data:data chainID:@(self.chainID).stringValue shardID:shardID toShardID:toShardID].qw_hexString];
    [self sendRawTransaction:rawTxHexEncodeed shardId:shardID.stringValue success:^(NSString *transactionId) {
        success(transactionId);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (void)sendRawTransaction:(NSString *)rawTransaction shardId:(NSString *)shardId success:(void(^)(NSString *))success failure:(void(^)(NSError *))failure {
    [self switchEndpointURLShardIdIfNeeded:shardId];
    [self invokeMethod:@"hmy_sendRawTransaction"
    withParameters:@[rawTransaction]
         requestId:@1
           success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
               success((NSString *)responseObject);
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               failure(error);
           }];
}

- (NSString *)getTxHashByKeyStore:(GethKeyStore *)keyStore
                      fromAddress:(GethAddress *)fromAddress
                            nonce:(NSString *)nonce
                         gasPrice:(NSString *)gasPrice
                         gasLimit:(NSString *)gasLimit
                               to:(NSString *)address
                            value:(NSString *)value
                             data:(NSData *)data
                          shardID:(NSNumber *)shardID
                        toShardID:(NSNumber *)toShardID {
    
    return [TransactionUtils transactionIdWithRawTxRLP:[self getTxRawByKeyStore:keyStore fromAddress:fromAddress nonce:nonce gasPrice:gasPrice gasLimit:gasLimit to:address value:value data:data chainID:@(self.chainID).stringValue shardID:shardID toShardID:toShardID]];

}

- (NSString *)getTxHashWithRawTx:(NSData *)rawTx {
    return [TransactionUtils transactionIdWithRawTxRLP:rawTx];
}

- (NSData *)getTxRawByKeyStore:(GethKeyStore *)keyStore
                   fromAddress:(GethAddress *)fromAddress
                         nonce:(NSString *)nonce
                      gasPrice:(NSString *)gasPrice
                      gasLimit:(NSString *)gasLimit
                            to:(NSString *)address
                         value:(NSString *)value
                          data:(NSData *)data
                       chainID:(NSString *)chainID
                       shardID:(NSNumber *)shardID
                     toShardID:(NSNumber *)toShardID {
    NSAssert(address.length == 40, @"invalid address length");
    NSData *toData = [NSData qw_dataWithHexString:address];
    NSDictionary *params = @{
                             @"nonce" : nonce,
                             @"gasPrice" : gasPrice,
                             @"gasLimit" : gasLimit,
                             @"to" : toData,
                             @"value" : value,
                             @"data" : data,
                             @"chainID" : @(chainID.integerValue),
                             @"shardID":shardID,
                             @"toShardID":toShardID
                             };
    NSError *error = nil;
    NSData *rlpHash = [TransactionUtils oneRLPHashWithItems:params];
    NSData *signedData = [keyStore signHash:fromAddress hash:rlpHash error:&error];
    if(error){
        return nil;
    }
    return [TransactionUtils oneRawTransactionRLPWithItems:params signature:signedData];
}

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSNumber *)chainID shardID:(NSNumber *)shardID toShardID:(NSNumber *)toShardID {
    return [self getTransactionHashWithNonce:nonce gasPrice:gasPrice gasLimit:gasLimit to:address value:value data:data chainID:chainID sha3:true shardID:shardID toShardID:toShardID];
}

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSNumber *)chainID sha3:(BOOL)sha3 shardID:(NSNumber *)shardID toShardID:(NSNumber *)toShardID {
    NSAssert(address.length == 40, @"invalid address length");
    NSData *toData = [NSData qw_dataWithHexString:address];
    NSDictionary *params = @{
                             @"nonce" : nonce,
                             @"gasPrice" : gasPrice,
                             @"gasLimit" : gasLimit,
                             @"to" : toData,
                             @"value" : value,
                             @"data" : data,
                             @"chainID" : chainID,
                             @"shardID": shardID,
                             @"toShardID": toShardID
                             };
    return [TransactionUtils oneRLPHashWithItems:params sha3:sha3];
}

- (void)estimateGasWithParam:(NSDictionary *)params callback:(void (^)(NSString *))callback {
    [self switchEndpointURLShardIdIfNeeded:params[@"shardId"]];
    NSMutableDictionary *_params = params.mutableCopy;
    [_params removeObjectForKey:@"shardId"];
    [self invokeMethod:@"hmy_estimateGas"
        withParameters:@[_params]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
                   callback(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   callback(nil);
               }];
}

- (void)getTransactionsByAddress:(NSString *)address shardId:(NSString *)shardId page:(NSNumber *)page success:(void(^)(NSArray *))success failure:(void(^)(NSError *))failure {
    [self switchEndpointURLShardIdIfNeeded:shardId];
    [self invokeMethod:@"hmy_getTransactionsHistory" withParameters:@[@{@"address":address, @"pageIndex":page, @"pageSize":@10, @"fullTx":@YES, @"txType":@"ALL", @"order":@"DESC"}] requestId:@1 success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
        success(responseObject[@"transactions"]);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(nil);
    }];
}

- (void)getTransactionById:(NSString *)transactionId shardId:(NSString *)shardId success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *))failure {
    [self switchEndpointURLShardIdIfNeeded:shardId];
    [self invokeMethod:@"hmy_getTransactionByHash"
    withParameters:@[transactionId]
         requestId:@1
           success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
               success(responseObject);
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               failure(error);
           }];
}

- (void)getTransactionReceipt:(NSString *)transactionId shardId:(NSString *)shardId success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *))failure {
    [self switchEndpointURLShardIdIfNeeded:shardId];
    [self invokeMethod:@"hmy_getTransactionReceipt"
    withParameters:@[transactionId]
         requestId:@1
           success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
               success(responseObject);
           }
           failure:^(AFHTTPRequestOperation *operation, NSError *error) {
               failure(error);
           }];
}

@end
