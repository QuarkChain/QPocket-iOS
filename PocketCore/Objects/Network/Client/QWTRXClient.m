//
//  QWTRXClient.m
//  QuarkWallet
//
//  Created by Jazys on 2019/2/13.
//  Copyright © 2019 QuarkChain. All rights reserved.
//

#import "QWTRXClient.h"
#import "PocketCore-Swift.h"
#import "NSData+QWHexString.h"
#import "NSString+balance.h"
#import <AFNetworking/AFNetworking.h>
#import "Contract.pbobjc.h"
#import "Api.pbrpc.h"
#import <GRPCClient/GRPCCall+Tests.h>

@interface QWTRXClient ()
@property (nonatomic) AFHTTPRequestOperationManager *requestManager;
@property (nonatomic) Wallet *grpc;
@end

@implementation QWTRXClient

+ (Transaction *)transactionWithDictionary:(NSDictionary *)dictionary {
    NSDictionary *raw_data = dictionary[@"raw_data"];
    if (![raw_data isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    Transaction *tronTransaction = [Transaction new];
    tronTransaction.signatureArray = [NSMutableArray array];
    tronTransaction.rawData = [Transaction_raw new];
    tronTransaction.rawData.expiration = [raw_data[@"expiration"] integerValue];
    tronTransaction.rawData.feeLimit = [raw_data[@"fee_limit"] integerValue];
    tronTransaction.rawData.refBlockBytes = [NSData qw_dataWithHexString:raw_data[@"ref_block_bytes"]];
    tronTransaction.rawData.refBlockHash = [NSData qw_dataWithHexString:raw_data[@"ref_block_hash"]];
    tronTransaction.rawData.timestamp = [raw_data[@"timestamp"] integerValue];
    Transaction_Contract *contract = [Transaction_Contract new];
    contract.type = Transaction_Contract_ContractType_TriggerSmartContract;
    contract.parameter = [GPBAny new];
    NSArray *contracts = raw_data[@"contract"];
    if (![contracts isKindOfClass:[NSArray class]]) {
        return nil;
    }
    NSDictionary *contractParameter = [contracts firstObject][@"parameter"];
    if (![contractParameter isKindOfClass:[NSDictionary class]]) {
        return nil;
    }
    contract.parameter.typeURL = contractParameter[@"type_url"];
    TriggerSmartContract *smartContract = [TriggerSmartContract new];
    smartContract.callValue = [contractParameter[@"value"][@"call_value"] integerValue];
    smartContract.callTokenValue = [contractParameter[@"value"][@"call_token_value"] integerValue];
    smartContract.ownerAddress = [NSData qw_dataWithHexString:contractParameter[@"value"][@"owner_address"]];
    smartContract.contractAddress = [NSData qw_dataWithHexString:contractParameter[@"value"][@"contract_address"]];
    smartContract.data_p = [NSData qw_dataWithHexString:contractParameter[@"value"][@"data"]];
    smartContract.tokenId = [contractParameter[@"value"][@"token_id"] integerValue];
    contract.parameter.value = smartContract.data;
    tronTransaction.rawData.contractArray = [NSMutableArray array];
    [tronTransaction.rawData.contractArray addObject:contract];
    return tronTransaction;
}

- (id)initWithEndpointURL:(NSURL *)URL {
    QWTRXClient *SELF = [super initWithEndpointURL:URL];
    SELF.requestManager = [AFHTTPRequestOperationManager manager];
    SELF.requestManager.requestSerializer = [AFJSONRequestSerializer serializer];
    SELF.grpc = [[Wallet alloc] initWithHost:URL.absoluteString];
    [GRPCCall useInsecureConnectionsForHost:URL.absoluteString];
    return SELF;
}

- (void)getBalanceOfAddress:(NSString *)address success:(void(^)(NSString *))success failure:(void(^)(NSError *))failure {
    [self getAccountByAddress:address success:^(Account * _Nonnull response) {
        success([NSString stringWithFormat:@"%lld", response.balance]);
    } failure:^(NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getTransferByAddress:(NSString *)address page:(NSString *)page token:(NSString *)token success:(void(^)(NSArray *response))success failure:(void(^)(NSError *error))failure {
    if (!token.length) {
        token = @"_";
    }
    [self.requestManager GET:[self.requestURLString stringByAppendingString:@"api/transfer"] parameters:@{@"address":address, @"start":[NSString stringWithFormat:@"%ld", [page integerValue] * 10], @"limit":@"10", @"token":token} success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        success(responseObject[@"data"]);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        failure(error);
    }];
}

- (void)getResourceByAddress:(NSString *)address success:(void(^)(AccountResourceMessage *response))success failure:(void(^)(NSError *error))failure {
    Account *contract = [Account new];
    contract.address = [QWKeystoreSwift base58CheckDecodingWithString:address];
    [self.grpc getAccountResourceWithRequest:contract handler:^(AccountResourceMessage * _Nullable response, NSError * _Nullable error) {
        if (response) {
            success(response);
        } else {
            failure(error);
        }
    }];
}

- (void)freezeByAddress:(NSString *)address amount:(NSString *)amount isEnergy:(BOOL)isEnergy success:(void(^)(Transaction *transaction))success failure:(void(^)(NSError *error))failure {
    FreezeBalanceContract *contract = [FreezeBalanceContract new];
    contract.ownerAddress = [QWKeystoreSwift base58CheckDecodingWithString:address];
    contract.frozenBalance = [[amount balanceStringToSun] integerValue];
    contract.frozenDuration = 3;
    contract.resource = isEnergy ? ResourceCode_Energy : ResourceCode_Bandwidth;
    [self.grpc freezeBalance2WithRequest:contract handler:^(TransactionExtention * _Nullable response, NSError * _Nullable error) {
        if (response.hasTransaction) {
            success(response.transaction);
        } else {
            failure(error);
        }
    }];
}

- (void)unfreezeByAddress:(NSString *)address isEnergy:(BOOL)isEnergy success:(void(^)(Transaction *transaction))success failure:(void(^)(NSError *error))failure {
    
    UnfreezeBalanceContract *contract = [UnfreezeBalanceContract new];
    contract.ownerAddress = [QWKeystoreSwift base58CheckDecodingWithString:address];
    contract.resource = isEnergy ? ResourceCode_Energy : ResourceCode_Bandwidth;
    [self.grpc unfreezeBalance2WithRequest:contract handler:^(TransactionExtention * _Nullable response, NSError * _Nullable error) {
        if (response.hasTransaction) {
            success(response.transaction);
        } else {
            failure(error);
        }
    }];
    
}

- (void)createTransactionFromAddress:(NSString *)fromAddress toAddress:(NSString *)toAddress amount:(NSString *)amount success:(void(^)(Transaction *response))success failure:(void(^)(NSError *error))failure {
    
    TransferContract *contract = [TransferContract new];
    contract.ownerAddress = [QWKeystoreSwift base58CheckDecodingWithString:fromAddress];
    contract.toAddress = [QWKeystoreSwift base58CheckDecodingWithString:toAddress];
    contract.amount = [[amount balanceStringToSun] integerValue];
    [self.grpc createTransaction2WithRequest:contract handler:^(TransactionExtention * _Nullable response, NSError * _Nullable error) {
        if (response) {
            success(response.transaction);
        } else {
            failure(error);
        }
    }];

}

- (void)broadcastTransaction:(Transaction *)transaction success:(void(^)(NSDictionary *response))success failure:(void(^)(NSError *error))failure {
    
    [self.grpc broadcastTransactionWithRequest:transaction handler:^(Return * _Nullable response, NSError * _Nullable error) {
        if (response.result) {
            success(nil);
        } else {
            failure(error);
        }
    }];
    
}

- (void)getAccountByAddress:(NSString *)address success:(void(^)(Account *response))success failure:(void(^)(NSError *error))failure {
    Account *contract = [Account new];
    contract.address = [QWKeystoreSwift base58CheckDecodingWithString:address];
    [self.grpc getAccountWithRequest:contract handler:^(Account * _Nullable response, NSError * _Nullable error) {
        if (response) {
            success(response);
        } else {
            failure(error);
        }
    }];
}

- (void)getTransactionInfoById:(NSString *)txId success:(void(^)(TransactionInfo *response))success failure:(void(^)(NSError *error))failure {
    BytesMessage *bytesMessage = [BytesMessage new];
    bytesMessage.value = [NSData qw_dataWithHexString:txId];
    [self.grpc getTransactionInfoByIdWithRequest:bytesMessage handler:^(TransactionInfo * _Nullable response, NSError * _Nullable error) {
        if (response) {
            success(response);
        } else {
            failure(error);
        }
    }];
}

- (void)transferAssetWithId:(NSString *)id fromAddress:(NSString *)fromAddress toAddress:(NSString *)toAddress amount:(NSString *)amount success:(void(^)(Transaction *transaction))success failure:(void(^)(NSError *error))failure {
    TransferAssetContract *contract = [TransferAssetContract new];
    contract.assetName = [id dataUsingEncoding:NSUTF8StringEncoding];
    contract.ownerAddress = [QWKeystoreSwift base58CheckDecodingWithString:fromAddress];
    contract.toAddress = [QWKeystoreSwift base58CheckDecodingWithString:toAddress];
    contract.amount = [amount integerValue];
    [self.grpc transferAsset2WithRequest:contract handler:^(TransactionExtention * _Nullable response, NSError * _Nullable error) {
        if (response.hasTransaction) {
            success(response.transaction);
        } else {
            failure(error);
        }
    }];
}

- (void)triggerContractFromAddress:(NSString *)fromAddress contractAddress:(NSString *)contractAddress data:(NSData *)data functionSelector:(NSString *)functionSelector success:(void(^)(Transaction *transaction, id returnedValue))success failure:(void(^)(NSError *error))failure {
//    TriggerSmartContract *smartContract = [TriggerSmartContract new];
//    smartContract.ownerAddress = [QWKeystoreSwift base58CheckDecodingWithString:fromAddress];
//    smartContract.contractAddress = [QWKeystoreSwift base58CheckDecodingWithString:contractAddress];
//    smartContract.data_p = data;
//    [self.grpc triggerContractWithRequest:smartContract handler:^(TransactionExtention * _Nullable response, NSError * _Nullable error) {
//        if (response.hasResult) {
//            success(response.transaction, response.constantResultArray);
//        } else {
//            failure(error);
//        }
//    }];
    [self.requestManager POST:@"https://api.trongrid.io/wallet/triggersmartcontract" parameters:@{@"owner_address":[QWKeystoreSwift base58CheckDecodingWithString:fromAddress].qw_hexString, @"contract_address":[QWKeystoreSwift base58CheckDecodingWithString:contractAddress].qw_hexString, @"parameter" : data.qw_hexString, @"function_selector" : functionSelector, @"fee_limit":@(100000000)} success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {

        if (![responseObject[@"result"][@"result"] boolValue]) {
            failure(nil);
            return;
        }

        success([self.class transactionWithDictionary:responseObject[@"transaction"]], responseObject[@"constant_result"]);

    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {

        failure(error);

    }];
    
}

- (void)getTransactionByAddress:(NSString *)address page:(NSString *)page success:(void(^)(NSArray *response))success failure:(void(^)(NSError *error))failure {

    [self.requestManager GET:[self.requestURLString stringByAppendingString:@"api/transaction"] parameters:@{@"address":address, @"start":[NSString stringWithFormat:@"%ld", [page integerValue] * 10], @"limit":@"10"} success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        success(responseObject[@"data"]);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        failure(error);
    }];
    
}

- (void)getAssetIssueById:(NSString *)id handler:(void(^)(AssetIssueContract *_Nullable response, NSError *_Nullable error))handler {
    
    BytesMessage *message = [BytesMessage new];
    message.value = [id dataUsingEncoding:NSUTF8StringEncoding];
    [self.grpc getAssetIssueByIdWithRequest:message handler:handler];
    
}

@end
