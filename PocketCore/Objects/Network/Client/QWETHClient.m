//
//  QWETHClient.m
//  QuarkWallet
//
//  Created by Jazys on 2018/10/18.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWETHClient.h"
#import "NSString+JSONRPC.h"
#import "JKBigInteger.h"
#import "PocketCore-Swift.h"
#import "NSData+QWHexString.h"
#import "NSString+Address.h"
#import "NSData+QWHexString.h"
#import <Geth/Geth.h>
#import <JKBigInteger2/JKBigDecimal.h>

static NSString *cachedGasPrice;
static NSString * const DEFAULT_GAS_PRICE = @"10000000000";

@implementation QWETHClient

- (void)getGasPriceCallback:(void(^)(NSString *))callback {
    
    [self invokeMethod:@"eth_gasPrice" success:^(AFHTTPRequestOperation *operation, id responseObject) {
        NSString *gasPrice = DEFAULT_GAS_PRICE;
        if(responseObject){
            JKBigInteger *transformer = [[JKBigInteger alloc] initWithString:[responseObject passByFirstTwoBytes] andRadix:16];
            gasPrice = transformer.stringValue;
            cachedGasPrice = gasPrice;
        }
        callback(gasPrice);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        callback(DEFAULT_GAS_PRICE);
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
                                success:(void(^)(NSString *))success
                                failure:(void(^)(NSError *))failure {
    NSString *rawTxHexEncodeed = [NSString stringWithFormat:@"0x%@", [self getTxRawByKeyStore:keyStore fromAddress:fromAddress nonce:nonce gasPrice:gasPrice gasLimit:gasLimit to:address value:value data:data chainID:@(self.chainID).stringValue].qw_hexString];
    [self sendRawTransaction:rawTxHexEncodeed success:^(NSString *transactionId) {
        success(transactionId);
    } failure:^(NSError *error) {
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
                             data:(NSData *)data {
    
    return [TransactionUtils transactionIdWithRawTxRLP:[self getTxRawByKeyStore:keyStore fromAddress:fromAddress nonce:nonce gasPrice:gasPrice gasLimit:gasLimit to:address value:value data:data chainID:@(self.chainID).stringValue]];

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
                       chainID:(NSString *)chainID {
    NSAssert(address.length == 40, @"invalid address length");
    NSData *toData = [NSData qw_dataWithHexString:address];
    NSDictionary *params = @{
                             @"nonce" : nonce,
                             @"gasPrice" : gasPrice,
                             @"gasLimit" : gasLimit,
                             @"to" : toData,
                             @"value" : value,
                             @"data" : data,
                             @"chainID" : @(chainID.integerValue)
                             };
    NSError *error = nil;
    NSData *rlpHash = [TransactionUtils ethRLPHashWithItems:params];
    NSData *signedData = [keyStore signHash:fromAddress hash:rlpHash error:&error];
    if(error){
        return nil;
    }
    return [TransactionUtils ethRawTransactionRLPWithItems:params signature:signedData];
}

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSNumber *)chainID {
    return [self getTransactionHashWithNonce:nonce gasPrice:gasPrice gasLimit:gasLimit to:address value:value data:data chainID:chainID sha3:true];
}

- (NSData *)getTransactionHashWithNonce:(NSString *)nonce gasPrice:(NSString *)gasPrice gasLimit:(NSString *)gasLimit to:(NSString *)address value:(NSString *)value data:(NSData *)data chainID:(NSNumber *)chainID sha3:(BOOL)sha3 {
    NSAssert(address.length == 40, @"invalid address length");
    NSData *toData = [NSData qw_dataWithHexString:address];
    NSDictionary *params = @{
                             @"nonce" : nonce,
                             @"gasPrice" : gasPrice,
                             @"gasLimit" : gasLimit,
                             @"to" : toData,
                             @"value" : value,
                             @"data" : data,
                             @"chainID" : chainID
                             };
    return [TransactionUtils ethRLPHashWithItems:params sha3:sha3];
}

- (NSData *)getTransactionRawWithSignedHash:(NSData *)hash params:(NSDictionary *)params {
    return [TransactionUtils ethRawTransactionRLPWithItems:params signature:hash];
}

#pragma mark - Subclassing

- (id)initWithEndpointURL:(NSURL *)URL {
    QWETHClient *SELF = [super initWithEndpointURL:URL];
    SELF.responseSerializer.acceptableContentTypes = [SELF.responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
    return SELF;
}

- (void)getBalanceOfAddress:(NSString *)address
                    success:(void(^)(NSString *))success
                    failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"eth_getBalance"
        withParameters:@[address, @"latest"]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
                   success(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)getTransactionCount:(NSString *)address
                    success:(void(^)(NSString *))success
                    failure:(void(^)(NSError *))failure {
    [self invokeMethod:@"eth_getTransactionCount"
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

- (void)getTransactionById:(NSString *)transactionId
                   success:(void(^)(NSDictionary *))success
                   failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"eth_getTransactionByHash"
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
    [self invokeMethod:@"eth_getTransactionReceipt"
        withParameters:@[transactionId]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSDictionary *responseObject) {
                   success(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   failure(error);
               }];
}

- (void)getTransactionsByAddress:(NSString *)address
                            page:(NSString *)page
                         success:(void(^)(NSArray *response))success
                         failure:(void(^)(NSError *error))failure {
    [self GET:[NSString stringWithFormat:@"%@api?module=account&action=txlist&address=%@&startblock=0&endblock=latest&page=%@&offset=10&sort=desc&apikey=GPS2H1PAD8GU4TYNXMT8UI99VAND5TNDG1", self.requestURLString, address, page] parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getTransactionsByAddress:(NSString *)address
                    tokenAddress:(NSString *)tokenAddress
                            page:(NSString *)page
                         success:(void(^)(NSArray *response))success
                         failure:(void(^)(NSError *error))failure {
    [self GET:[NSString stringWithFormat:@"%@api?module=account&action=tokentx&address=%@&contractaddress=%@&startblock=0&endblock=latest&page=%@&offset=10&sort=desc&apikey=GPS2H1PAD8GU4TYNXMT8UI99VAND5TNDG1", self.requestURLString, address, tokenAddress, page] parameters:nil success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)sendRawTransaction:(NSString *)rawTransaction
                   success:(void(^)(NSString *))success
                   failure:(void(^)(NSError *))failure{
    [self invokeMethod:@"eth_sendRawTransaction"
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
    [self invokeMethod:@"eth_call"
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
    [self invokeMethod:@"eth_estimateGas"
        withParameters:@[params]
             requestId:@1
               success:^(AFHTTPRequestOperation *operation, NSString *responseObject) {
                   callback(responseObject);
               }
               failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                   callback(nil);
               }];
}

- (void)getFilterByAddress:(NSString *)address success:(void(^)(NSString *response))success failure:(void(^)(NSError *error))failure {
    [self invokeMethod:@"eth_newFilter" withParameters:@[@{@"address": address}] requestId:@1 success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)getPendingTransactionFilterSuccess:(void(^)(NSString *response))success failure:(void(^)(NSError *error))failure {
    [self invokeMethod:@"eth_newPendingTransactionFilter" success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)getFilterChangesByFilterId:(NSString *)filterId success:(void(^)(NSDictionary *response))success failure:(void(^)(NSError *error))failure {
    [self invokeMethod:@"eth_getFilterChanges" withParameters:@[filterId] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

- (void)uninstallFilterId:(NSString *)filterId success:(void(^)(NSString *response))success failure:(void(^)(NSError *error))failure {
    [self invokeMethod:@"eth_uninstallFilter" withParameters:@[filterId] success:^(AFHTTPRequestOperation *operation, id responseObject) {
        success(responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
}

@end
