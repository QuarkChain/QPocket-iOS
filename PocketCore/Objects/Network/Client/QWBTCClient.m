//
//  QWBTCClient.m
//  QuarkWallet
//
//  Created by Jazys on 2019/11/1.
//  Copyright © 2019 QuarkChain. All rights reserved.
//

#import "QWBTCClient.h"
#import <CoreBitcoin/CoreBitcoin.h>
#import "NSData+QWHexString.h"
#import "QWWalletManager+Token.h"
#import <objc/runtime.h>
#import "PocketCore-Swift.h"
#import "NSString+balance.h"
#import "QWToken.h"
#import "NSDate+QWExtension.h"
#import <JKBigInteger2-umbrella.h>

QWUserDefaultsKey QWBTCClientRequestURLInfosKey = @"QWBTCClientRequestURLInfosKey";
#define kQWBTCClientAPIKey @""

@interface QWBTCClient ()
@property (nonatomic) AFHTTPRequestOperationManager *requestManager;
@end

@implementation QWBTCClient

- (id)initWithEndpointURL:(NSURL *)URL {
    QWBTCClient *SELF = [super initWithEndpointURL:URL];
    SELF.requestManager = [AFHTTPRequestOperationManager manager];
    SELF.requestManager.requestSerializer = [AFJSONRequestSerializer serializer];
//    SELF.requestManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    return SELF;
}

- (void)requestWithURLCallbackHandler:(void(^)(NSString *requestURLString))URLCallbackHandler {
    if (self.testnet) {
        URLCallbackHandler(self.requestURLString);
        return;
    }
    NSMutableDictionary *BTCClientRequestURLInfos = [[[NSUserDefaults standardUserDefaults] objectForKey:QWBTCClientRequestURLInfosKey] mutableCopy];
    if (!BTCClientRequestURLInfos) {
        BTCClientRequestURLInfos = [NSMutableDictionary dictionary];
    }
    NSTimeInterval time = [BTCClientRequestURLInfos[@"time"] doubleValue];
    __block NSString *requestURLString = BTCClientRequestURLInfos[@"url"];
    NSInteger version = 1;
    if (!requestURLString || fabs([[NSDate date] timeIntervalInHoursSinceTimeInterval:time]) >= 2) {
        QWNetworkFetchOptions *fetchOptions = [QWNetworkFetchOptions new];
        fetchOptions.keyEqualsToValue = @{@"type":@1, @"enabled":@YES};
        fetchOptions.sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"version" ascending:false];
        requestURLString = nil;
        [[QWWalletManager defaultManager].network fetchObjectsForName:@"API" options:fetchOptions completion:^(NSArray<NSDictionary *> *objects, NSError *error) {
            if (objects.count) {
                for (NSDictionary *info in objects) {
                    if (version >= [info[@"version"] integerValue]) {
                        requestURLString = info[@"apiUrl"];
                        BTCClientRequestURLInfos[@"url"] = requestURLString;
                        BTCClientRequestURLInfos[@"time"] = @([[NSDate date] timeIntervalSince1970]);
                        [[NSUserDefaults standardUserDefaults] setObject:BTCClientRequestURLInfos forKey:QWBTCClientRequestURLInfosKey];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                        URLCallbackHandler(requestURLString);
                        return;
                    }
                }
                URLCallbackHandler(nil);
            } else {
                URLCallbackHandler(nil);
            }
        }];
    } else {
        URLCallbackHandler(requestURLString);
    }
}

- (void)sendRawTransaction:(NSString *)rawTransaction success:(void(^)(id))success failure:(void(^)(NSError *))failure {
    [self requestWithURLCallbackHandler:^(NSString *requestURLString) {
        QWNetworkRequestOptions *requestOptions = [QWNetworkRequestOptions new];
        requestOptions.parameter = @{@"data":rawTransaction};
        requestOptions.formParameter = true;
        requestOptions.URLString = [NSString stringWithFormat:@"%@push/transaction?key=%@", requestURLString, kQWBTCClientAPIKey];
        requestOptions.method = QWNetworkRequestOptionsMethodPOST;
        [[QWWalletManager defaultManager].network requestWithOptions:requestOptions response:^(NSDictionary *object, NSError *error) {
            if (!error) {
                success(object);
            } else {
                failure(error);
            }
        }];
    }];
}

- (void)getTransactionRawWithTransactionHash:(NSString *)transactionHash success:(void(^)(NSDictionary *response))success failure:(void(^)(NSError *error))failure {
    [self requestWithURLCallbackHandler:^(NSString *requestURLString) {
        [self.requestManager GET:[NSString stringWithFormat:@"%@raw/transaction/%@", requestURLString, transactionHash] parameters:@{@"key":kQWBTCClientAPIKey} success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            success(responseObject);
        } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            failure(error);
        }];
    }];
}

- (void)getInfoOfAddressOrPublicKey:(NSString *)addressOrPublicKey isAddress:(BOOL)isAddress page:(NSString *)page success:(void(^)(NSDictionary *info))success failure:(void(^)(NSError *error))failure {
    page = page ?: @"0";
    NSString *path = isAddress ? @"address" : @"xpub";
    [self requestWithURLCallbackHandler:^(NSString *requestURLString) {
        [self.requestManager GET:[NSString stringWithFormat:@"%@dashboards/%@/%@", requestURLString, path, addressOrPublicKey] parameters:@{@"limit":@"10,10000", @"offset":[NSString stringWithFormat:@"%ld", page.integerValue * 10], @"key":kQWBTCClientAPIKey} success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            success(responseObject);
        } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            failure(error);
        }];
    }];
}

- (void)getTransactionsDetails:(NSArray <NSString *> *)transactions success:(void(^)(NSDictionary *response))success failure:(void(^)(NSError *error))failure {
//    NSAssert(transactions.count <= 10, @"");
    [self requestWithURLCallbackHandler:^(NSString *requestURLString) {
        [self.requestManager GET:[NSString stringWithFormat:@"%@dashboards/transactions/%@", requestURLString, [transactions componentsJoinedByString:@","]] parameters:@{@"key":kQWBTCClientAPIKey} success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
            success(responseObject);
        } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
            failure(error);
        }];
    }];
}

- (NSDictionary *)findBuildTransactionWithUTXOs:(NSArray *)sortedUtxos toAddress:(NSString *)toAddress changeAddress:(NSString *)changeAddress amount:(NSString *)amount fee:(NSString *)fee feePrice:(NSString *)feePrice key:(id)key isSegWit:(BOOL)isSegWit {
    
    NSMutableArray *utxos = [NSMutableArray array];
    JKBigInteger *feeObject = [[JKBigInteger alloc] initWithString:fee];
    JKBigInteger *transferAmount = [[JKBigInteger alloc] initWithString:amount];
    JKBigInteger *spentAmount = [transferAmount add:feeObject];
    
    //  1.找是否有正好花费掉的utxo
    for (NSDictionary *utxo in sortedUtxos) {
        if ([[[JKBigInteger alloc] initWithString:[utxo[@"value"] stringValue]] compare:spentAmount] == NSOrderedSame) {
            [utxos addObject:utxo];
            break;
        }
    }
    //  2.找小于花费的全部加起来是否正好等于花费
    if (!utxos.count) {
        JKBigInteger *unspentAmount = [[JKBigInteger alloc] initWithString:@"0"];
        for (NSDictionary *utxo in sortedUtxos) {
            JKBigInteger *value = [[JKBigInteger alloc] initWithString:[utxo[@"value"] stringValue]];
            if ([value compare:spentAmount] == NSOrderedAscending) {
                unspentAmount = [unspentAmount add:value];
                [utxos addObject:utxo];
            } else {
                break;
            }
        }
        NSComparisonResult comparisonResult = [unspentAmount compare:spentAmount];
        if (comparisonResult == NSOrderedAscending) { //3.a 小于花费的部分加一起还小于花费，用第一个比花费大的
            [utxos removeAllObjects];
            for (NSDictionary *utxo in sortedUtxos) {
                if ([[[JKBigInteger alloc] initWithString:[utxo[@"value"] stringValue]] compare:spentAmount] == NSOrderedDescending) {
                    [utxos addObject:utxo];
                    break;
                }
            }
            if (!utxos.count) {
                return nil;
            }
            //            NSAssert(utxos.count, @"balance not enough?");
        } else if (comparisonResult == NSOrderedDescending) { //3.b 小于花费的部分加一起大于花费，用背包算法
            NSArray *smallerThanSpentAmountUTXOs = utxos.copy;
            [utxos removeAllObjects];
            JKBigInteger *lastUnspentAmount = [[JKBigInteger alloc] initWithUnsignedLong:NSUIntegerMax];
            for (NSInteger index = 0; index < 1000; index++) {  //循环一千次产生随机添加数组和未添加数组，每次对比上一次结果找到金额最小并且大于等于花费的结果
                NSMutableArray *addedUTXOs = [NSMutableArray array];
                NSMutableArray *notAddedUTXOs = [NSMutableArray array];
                NSMutableArray *tempUTXOs = [NSMutableArray array];
                for (NSDictionary *utxo in smallerThanSpentAmountUTXOs) {
                    if (arc4random_uniform(2)) {
                        [addedUTXOs addObject:utxo];
                    } else {
                        [notAddedUTXOs addObject:utxo];
                    }
                }
                [tempUTXOs addObjectsFromArray:addedUTXOs];
                unspentAmount = [[JKBigInteger alloc] initWithString:@"0"];
                for (NSDictionary *addedUTXO in addedUTXOs) {
                    unspentAmount = [unspentAmount add:[[JKBigInteger alloc] initWithString:[addedUTXO[@"value"] stringValue]]];
                }
                if ([unspentAmount compare:spentAmount] == NSOrderedAscending) {
                    for (NSDictionary *notAddedUTXO in notAddedUTXOs) {
                        unspentAmount = [unspentAmount add:[[JKBigInteger alloc] initWithString:[notAddedUTXO[@"value"] stringValue]]];
                        [tempUTXOs addObject:notAddedUTXO];
                        if ([unspentAmount compare:spentAmount] != NSOrderedAscending) {
                            break;
                        }
                    }
                }
                if ([unspentAmount compare:lastUnspentAmount] == NSOrderedAscending) {
                    utxos = tempUTXOs;
                    lastUnspentAmount = unspentAmount;
                }
                
                if ([lastUnspentAmount compare:spentAmount] == NSOrderedSame) { //刚好等于花费, break
                    break;
                }
            }
        }
    }
    
    NSDictionary *transactionInfo = [self buildTransactionWithUTXOs:utxos toAddress:toAddress changeAddress:changeAddress amount:amount fee:feeObject.unsignedIntValue key:key isSegWit:isSegWit];
    NSUInteger bytes = [transactionInfo[@"size"] unsignedIntegerValue];
    JKBigInteger *newFee = [[[JKBigInteger alloc] initWithString:feePrice] multiply:[[JKBigInteger alloc] initWithUnsignedLong:bytes]];
    if ([newFee compare:feeObject] == NSOrderedDescending) {
        NSDictionary *transactionInfo2 = [self findBuildTransactionWithUTXOs:sortedUtxos toAddress:toAddress changeAddress:changeAddress amount:amount fee:newFee.stringValue feePrice:feePrice key:key isSegWit:isSegWit];
        return transactionInfo2 ?: transactionInfo;
    } else {
        return transactionInfo;
    }
    
}

- (NSDictionary *)buildTransactionWithUTXOs:(NSArray *)UTXOs toAddress:(NSString *)toAddress changeAddress:(NSString *)changeAddress amount:(NSString *)amount fee:(int64_t)fee key:(id)key isSegWit:(BOOL)isSegWit {

    NSAssert([key isKindOfClass:[BTCKeychain class]] || [key isKindOfClass:[BTCKey class]], @"");

    NSMutableArray *outputs = [NSMutableArray array];
    NSMutableArray *privateKeys = [NSMutableArray array];
    for (NSDictionary *utxoInfo in UTXOs) {
        UTXO *utxo = [[UTXO alloc] initWithTxHash:utxoInfo[@"transaction_hash"] vout:[utxoInfo[@"index"] intValue] amount:[utxoInfo[@"value"] integerValue] address:utxoInfo[@"address"] scriptPubKey:utxoInfo[@"script_hex"] derivedPath:utxoInfo[@"path"] sequence:0];
        [outputs addObject:utxo];
        if ([key isKindOfClass:[BTCKeychain class]]) {
            BTCKey *_key = [key derivedKeychainWithPath:utxoInfo[@"path"]].key;
            NSString *address = isSegWit ? _key.witnessAddress.string : _key.address.string;
            if (self.testnet) {
                address = isSegWit ? _key.witnessAddressTestnet.string : _key.addressTestnet.string;
            }
            NSInteger index = 0;
            while (![address isEqualToString:utxoInfo[@"address"]]) {
                index++;
                _key = [key derivedKeychainWithPath:[NSString stringWithFormat:@"0/%ld", index]].key;
                address = isSegWit ? _key.witnessAddress.string : _key.address.string;
                if (self.testnet) {
                    address = isSegWit ? _key.witnessAddressTestnet.string : _key.addressTestnet.string;
                }
                if (index > 1000) {
                    NSLog(@"jazys: path is too long");
                    break;
                }
            }
            [privateKeys addObject:_key];
        } else {
            [privateKeys addObject:key];
        }
    }

//    BTCAmount parsedAmount = [amount balanceStringUnitWithDecimal:[QWWalletManager defaultManager].BTC.decimals].integerValue;

    NSError *error = nil;
    
    BTCTransactionSigner *signer = [[BTCTransactionSigner alloc] initWithUtxos:outputs keys:privateKeys amount:amount.integerValue fee:fee toAddress:[BTCAddress addressWithString:toAddress] changeAddress:[BTCAddress addressWithString:changeAddress] error:&error];
    
    if (error) {
        NSLog(@"jazys: %@", error);
        return nil;
    }
    
    TransactionSignedResult *signedResult = nil;
    
    if (isSegWit) {
        signedResult = [signer signSegWitAndReturnError:&error];
    } else {
        signedResult = [signer signAndReturnError:&error];
    }
    
    if (error) {
        NSLog(@"jazys: %@", error);
        return nil;
    }
    
    return @{@"transaction":signedResult.signedTx, @"txHash":signedResult.txHash, @"size":@(signedResult.size), @"utxos":UTXOs};
    
}

@end
