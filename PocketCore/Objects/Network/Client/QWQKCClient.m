//
//  Created by zhuqiang on 2018/8/3.
//  Copyright © 2018 freedostudio. All rights reserved.
//

#import "QWQKCClient.h"
#import "NSString+JSONRPC.h"
#import "JKBigInteger.h"
#import "PocketCore-Swift.h"
#import "NSData+QWHexString.h"
#import "NSString+Address.h"
#import "NSData+QWHexString.h"
#import <Geth/Geth.h>
#import <JKBigInteger2/JKBigDecimal.h>
#import "QWWalletManager+Account.h"
#import "QWChain.h"

@implementation QWQKCClient

- (void)networkInfoSuccess:(void(^)(NSDictionary *))success failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"networkInfo"
        withParameters:nil
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, id responseObject) {
                   success(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (NSString *)getTransactionRawByKeyStore:(GethKeyStore *)keyStore
                        fromAddress:(GethAddress *)fromAddress
                              nonce:(NSString *)nonce
                           gasPrice:(NSString *)gasPrice
                           gasLimit:(NSString *)gasLimit
                                 to:(NSString *)address
                              value:(NSString *)value
                               data:(NSData *)data
                    fromFullShardId:(NSString *)fromFullShardId
                      toFullShardId:(NSString *)toFullShardId
                          networkId:(NSString *)networkId
                         gasTokenId:(NSString *)gasTokenId
                    transferTokenId:(NSString *)transferTokenId {
    NSAssert(address.length == 40, @"address's length must be equal to 20");
    NSData *toData = [NSData qw_dataWithHexString:address];
    NSDictionary *params = @{
                             @"nonce" : nonce,
                             @"gasPrice" : gasPrice,
                             @"gasLimit" : gasLimit,
                             @"to" : toData,
                             @"value" : value,
                             @"data" : data,
                             @"fromFullShardId" : fromFullShardId,
                             @"toFullShardId" : toFullShardId,
                             @"networkId" : networkId,
                             @"gasTokenId" : gasTokenId,
                             @"transferTokenId" : transferTokenId
                             };
    NSError *error = nil;
    NSData *rlpHash = [TransactionUtils qkcRLPHashWithItems:params];
    NSData *signedData = [keyStore signHash:fromAddress hash:rlpHash error:&error];
    if(error){
        return nil;
    }
    return [TransactionUtils qkcRawTransactionRLPWithItems:params signature:signedData];
}

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data fromFullShardId:(NSString *)fromFullShardId toFullShardId:(NSString *)toFullShardId networkId:(NSString *)networkId gasTokenId:(NSString *)gasTokenId transferTokenId:(NSString *)transferTokenId {
    NSAssert(address.length == 40, @"address's length must be equal to 20");
    NSData *toData = [NSData qw_dataWithHexString:address];
    NSDictionary *params = @{
                             @"nonce" : nonce,
                             @"gasPrice" : gasPrice,
                             @"gasLimit" : gasLimit,
                             @"to" : toData,
                             @"value" : value,
                             @"data" : data,
                             @"fromFullShardId" : fromFullShardId,
                             @"toFullShardId" : toFullShardId,
                             @"networkId" : networkId,
                             @"gasTokenId" : gasTokenId,
                             @"transferTokenId" : transferTokenId
                             };
    return [TransactionUtils qkcRLPHashWithItems:params];
}

- (NSString *)getTransactionRawWithSignedHash:(NSData *)hash params:(NSDictionary *)params {
    return [TransactionUtils qkcRawTransactionRLPWithItems:params signature:hash];
}

- (void)sendTransactionSignedByKeyStore:(GethKeyStore *)keyStore
                            fromAddress:(GethAddress *)fromAddress
                                  nonce:(NSString *)nonce
                               gasPrice:(NSString *)gasPrice
                               gasLimit:(NSString *)gasLimit
                                     to:(NSString *)address
                                  value:(NSString *)value
                                   data:(NSData *)data
                        fromFullShardId:(NSString *)fromFullShardId
                          toFullShardId:(NSString *)toFullShardId
                              networkId:(NSString *)networkId
                             gasTokenId:(NSString *)gasTokenId
                        transferTokenId:(NSString *)transferTokenId
                                success:(void(^)(NSString *))success
                                failure:(void(^)(NSError *))failure{
    
    [self sendRawTransaction:[self getTransactionRawByKeyStore:keyStore fromAddress:fromAddress nonce:nonce gasPrice:gasPrice gasLimit:gasLimit to:address value:value data:data fromFullShardId:fromFullShardId toFullShardId:toFullShardId networkId:networkId gasTokenId:gasTokenId transferTokenId:transferTokenId] success:^(NSString *transactionId) {
        success(transactionId);
    } failure:^(NSError *error) {
        failure(error);
    }];
}

- (NSString *)getTransactionHashWithKeyStore:(GethKeyStore *)keyStore fromAddress:(GethAddress *)fromAddress params:(NSDictionary *)params {
    
    NSString *toAddress = params[@"to"];
    NSAssert(toAddress.length == 40, @"address's length must be equal to 20");
    
    NSMutableDictionary *mutableParams = params.mutableCopy;
    mutableParams[@"to"] = [NSData qw_dataWithHexString:toAddress];
//    mutableParams[@"nonce"] = params[@"nonce"];
    
    NSError *error = nil;
    NSData *rlpHash = [TransactionUtils qkcRLPHashWithItems:mutableParams];
    NSData *signedData = [keyStore signHash:fromAddress hash:rlpHash error:&error];
    if(error){
        return nil;
    }
    NSString *rawTxHexEncodeed = [TransactionUtils qkcRawTransactionRLPWithItems:mutableParams signature:signedData];
    NSData *rawTxData = [NSData qw_dataWithHexString:[rawTxHexEncodeed passByFirstTwoBytes]];
    NSString *txHash = [TransactionUtils transactionIdWithRawTxRLP:rawTxData];
    return txHash;
}

- (NSString *)getTxHashWithRawTx:(NSString *)rawTx {
    NSData *rawTxData = [NSData qw_dataWithHexString:[rawTx passByFirstTwoBytes]];
    return [TransactionUtils transactionIdWithRawTxRLP:rawTxData];
}

- (void)getAccountData:(NSString *)address
               success:(void(^)(NSDictionary *))success
               failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"getAccountData"
        withParameters:@[address, @"latest", @YES]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                   success(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)gasPriceInFullShardId:(NSString *)fullShardId callback:(void(^)(NSString *))callback{
    self.cachedGasPrice = @"0";
    
//    NSString *shardIdHex = @(fullShardId).stringValue;
//    JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:shardIdHex];
//    shardIdHex = [transformer stringValueWithRadix:16];
//    shardIdHex = [@"0x" stringByAppendingString:shardIdHex];

    [self invokeMethod:@"gasPrice"
        withParameters:@[[@"0x" stringByAppendingString:fullShardId]]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
                   NSString *gasPrice = [self.class defaultGasPrice];
                   if(responseObject){
                       JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:[responseObject passByFirstTwoBytes] andRadix:16];
                       gasPrice = transformer.stringValue;
                       if ([gasPrice isEqualToString:@"0"]) {
                           gasPrice = [self.class defaultGasPrice];
                       }
                       self.cachedGasPrice = gasPrice;
                   }
                   callback(gasPrice);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   callback([self.class defaultGasPrice]);
               }];
}

- (void)luckyDrawToAddress:(NSString *)toAddress
                   success:(void(^)(NSString *, NSString *))success
                   failure:(void(^)(NSError *))failure{
    NSString *fromAddress = @"0x6d3af223727309928CeFCD8303A892DD0E4A3E956d73cdDD";
    int random = 1 +  (arc4random() % 100);
    JKBigInteger *transformer =  [[JKBigInteger alloc] initWithString:@(random).stringValue];
    transformer = [transformer multiply:[[JKBigInteger alloc] initWithString:@"1000000000000000000"]];
    NSString *amount = [transformer stringValueWithRadix:16];
    amount = [@"0x" stringByAppendingString:amount];
    [self invokeMethod:@"donate"
        withParameters:@[fromAddress, toAddress, amount]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
                   success(responseObject, @(random).stringValue);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];

}

- (void)getTransactionsByAddress:(NSString *)address
                            next:(NSString *)next
                         success:(void(^)(NSDictionary *))success
                         failure:(void(^)(NSError *))failure{
    [self getTransactionsByAddress:address next:next tokenId:nil success:success failure:failure];
}

- (void)getTransactionsByAddress:(NSString *)address
                            next:(NSString *)next
                         tokenId:(NSString *)tokenId
                         success:(void(^)(NSDictionary *))success
                         failure:(void(^)(NSError *))failure {
    NSMutableArray *params = [NSMutableArray arrayWithArray:@[address, next ?: @"0x", @"0xa"]];
    if (tokenId) {
        [params addObject:tokenId];
    }
    [self invokeMethod:@"getTransactionsByAddress"
        withParameters:params
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                   success(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

#pragma mark - Subclassing

- (void)getBalanceOfAddress:(NSString *)address
                    success:(void(^)(NSString *))success
                    failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"getBalance"
        withParameters:@[address]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                   NSString *bypassFirstTwoByte = [responseObject[@"balance"] substringFromIndex:2];
                   JKBigInteger *balance = [[JKBigInteger alloc] initWithString:bypassFirstTwoByte andRadix:16];
                   success([balance stringValue]);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)getTransactionCount:(NSString *)address
                    success:(void(^)(NSString *))success
                    failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"getTransactionCount"
        withParameters:@[address]
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

- (void)getTransactionById:(NSString *)transactionId
                   success:(void(^)(NSDictionary *))success
                   failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"getTransactionById"
        withParameters:@[transactionId]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                   success(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)getTransactionReceipt:(NSString *)transactionId
                      success:(void(^)(NSDictionary *))success
                      failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"getTransactionReceipt"
        withParameters:@[transactionId]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                   success(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)sendRawTransaction:(NSString *)rawTransaction
                   success:(void(^)(NSString *))success
                   failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"sendRawTransaction"
        withParameters:@[rawTransaction]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                   success((NSString *)responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)call:(NSString *)contractAddress
        from:(NSString *)from
     dataHex:(NSString *)dataHex
     success:(void(^)(NSString *))success
     failure:(void(^)(NSError *))failure{
    NSString *gas = @"0xf4240";
    NSString *gasPrice = @"0x0";
    [self invokeMethod:@"call"
        withParameters:@[@{@"from":from, @"to":contractAddress,@"gasPrice": gasPrice, @"gas": gas, @"data":dataHex, @"value": @"0x0"}, @"latest"]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
                   success(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)estimateGasWithParam:(NSDictionary *)params callback:(void(^)(NSString *))callback{
    [self invokeMethod:@"estimateGas"
        withParameters:@[params]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
                   callback(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   callback(@"0xf4240");
               }];
}

- (void)getNativeTokenGasReserves:(NSString *)address chainId:(NSString *)chainId success:(void(^)(NSDictionary *))success failure:(void(^)(NSError *))failure {
    
    address = address.passByFirstTwoBytes;
    
    NSDictionary *generalNativeTokenManagerAddresses = @{
        @"0":@"0x514B43000000000000000000000000000000000300000000",
        @"1":@"0x514B43000000000000000000000000000000000300010000",
        @"2":@"0x514B43000000000000000000000000000000000300020000",
        @"3":@"0x514B43000000000000000000000000000000000300030000",
        @"4":@"0x514B43000000000000000000000000000000000300040000",
        @"5":@"0x514B43000000000000000000000000000000000300050000",
        @"6":@"0x514B43000000000000000000000000000000000300060000",
        @"7":@"0x514B43000000000000000000000000000000000300070000"
    };
    
    NSString *contractAddress = generalNativeTokenManagerAddresses[chainId ?: [QWWalletManager defaultManager].currentAccount.chain.id];
    
    [self call:contractAddress from:contractAddress dataHex:[ERC20Encoder encodeGasReservesWithTokenId:address] success:^(NSString * _Nonnull dataString) {
        
        if (!dataString.length || [dataString isEqualToString:@"0x"]) {
            failure ?: failure(nil);
            return;
        }
        
        NSMutableDictionary *gasReserves = [SmartContractDecoder decodeReturnedValuesForGasReservesWithResponse:dataString error:NULL].mutableCopy;
        
        if ([gasReserves[@"admin"] isEqualToString:@"0x0000000000000000000000000000000000000000"]) {
            success(gasReserves);
            return;
        }
        
        gasReserves[@"exchangeRate"] = [NSString stringWithFormat:@"%f", [gasReserves[@"numerator"] floatValue] / [gasReserves[@"denominator"] floatValue]];
        
        [self call:contractAddress from:contractAddress dataHex:[ERC20Encoder encodeGasReserveBalanceWithTokenId:address owner:gasReserves[@"admin"]] success:^(NSString * _Nonnull dataString) {
            
            if (!dataString.length || [dataString isEqualToString:@"0x"]) {
                failure ?: failure(nil);
                return;
            }
            
            NSDictionary *gasReserveBalance = [SmartContractDecoder decodeReturnedValuesForGasReserveBalanceWithResponse:dataString error:NULL];
            gasReserves[@"gasReserveBalance"] = [[[[JKBigDecimal alloc] initWithString:gasReserveBalance[@"gasReserveBalance"]] divide:[[JKBigDecimal alloc] initWithString:gasReserves[@"exchangeRate"]]] stringValue];
            
            success(gasReserves);

        } failure:^(NSError * _Nonnull error) {
            failure ?: failure(error);
        }];
        
    } failure:^(NSError * _Nonnull error) {
        failure ?: failure(error);
    }];
    
}

+ (NSString *)defaultGasPrice {
    return @"1000000000";
}

@end
