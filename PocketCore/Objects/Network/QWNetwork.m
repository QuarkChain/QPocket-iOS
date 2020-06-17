//
//  QWNetwork.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/31.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWNetwork.h"
#import <AVOSCloud/AVOSCloud.h>
#import <AFNetworking/AFNetworking.h>
#import <objc/runtime.h>
#import "QWHeader.h"
#import "NSDate+QWExtension.h"
#import "QWQKCClient.h"
#import "QWETHClient.h"
#import<SystemConfiguration/CaptiveNetwork.h>
#import "QWTRXClient.h"
#import "QWBTCClient.h"
#import "QWONEClient.h"
#import "QWWalletManager.h"
//#include "TargetConditionals.h"

NSNotificationName const QWNetworkReachabilityStatusChangedNotification = @"QWNetworkReachabilityStatusChangedNotification";
QWUserDefaultsKey const QWNetworkShardSizeOnChain = @"QWNetworkShardSizeOnChain";

@implementation QWNetworkFetchOptions
@end

@implementation QWNetworkRequestOptions
@end

@implementation QWNetworkClientOptions

- (void)setName:(NSString *)name {
    _name = name;
}

- (void)setEndpointURLString:(NSString *)endpointURLString {
    _endpointURLString = endpointURLString;
}

- (void)setApiURLString:(NSString *)apiURLString {
    _apiURLString = apiURLString;
}

- (void)setChainID:(NSInteger)chainID {
    _chainID = chainID;
}

- (void)setMainnet:(BOOL)mainnet {
    _mainnet = mainnet;
}

- (void)setCoinType:(QWWalletCoinType)coinType {
    _coinType = coinType;
}

- (void)setNetworkId:(NSString *)networkId {
    _networkId = networkId;
}

- (BOOL)isEqual:(QWNetworkClientOptions *)object {
    if ([object isKindOfClass:self.class]) {
        return [self.name isEqual:object.name] && [self.endpointURLString isEqual:object.endpointURLString] && self.coinType == object.coinType && self.chainID == object.chainID;
    }
    return false;
}

@end

QWUserDefaultsKey const QWNetworkLastestFetchTimePrefixKey = @"QWNetworkLastestFetchTime:";
QWUserDefaultsKey const QWNetworkLastClientOptionsInfoKey = @"QWNetworkLastClientOptionsInfoKey";

#define kQWNetworkFetchTimeUserDefaultsKey(name) [NSString stringWithFormat:@"%@%@",QWNetworkLastestFetchTimePrefixKey, name]

@interface QWNetwork()
@property (nonatomic) AFHTTPSessionManager *httpManager;
@property (nonatomic) NSMutableDictionary <NSNumber *, QWClient *> *clients;
@end

@implementation QWNetwork
@synthesize client = _client;
static BOOL _reachable = true; //Reachability delays callback, defaults to true

+ (void)start {
    [[AFNetworkReachabilityManager sharedManager] startMonitoring];
    
//    [AVOSCloud setServerURLString:@"https://avoscloud.com" forServiceModule:AVServiceModuleAPI];
//    // 配置 SDK 推送
//    [AVOSCloud setServerURLString:@"https://avoscloud.com" forServiceModule:AVServiceModulePush];
//    // 配置 SDK 云引擎
//    [AVOSCloud setServerURLString:@"https://avoscloud.com" forServiceModule:AVServiceModuleEngine];
//    // 配置 SDK 即时通讯
//    [AVOSCloud setServerURLString:@"https://router-g0-push.avoscloud.com" forServiceModule:AVServiceModuleRTM];
#ifndef DEBUG
    [AVOSCloud setAllLogsEnabled:false];
#endif
    [AVOSCloud setApplicationId:@"" clientKey:@""];
    [[AFNetworkReachabilityManager sharedManager] setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        BOOL oldReachable = _reachable;
        _reachable = status == AFNetworkReachabilityStatusReachableViaWWAN || status == AFNetworkReachabilityStatusReachableViaWiFi;
        [[NSNotificationCenter defaultCenter] postNotificationName:QWNetworkReachabilityStatusChangedNotification object:self userInfo:@{@"status":@(status), @"oldIsReachable":@(oldReachable)}];
        void (^didNetworkChangedHandler)(AFNetworkReachabilityStatus status, BOOL oldIsReachable) = objc_getAssociatedObject(self, @selector(setDidNetworkChangedHandler:));
        if (didNetworkChangedHandler) {
            didNetworkChangedHandler(status, oldReachable);
        }
    }];
    
}

+ (void)setDidNetworkChangedHandler:(void(^)(AFNetworkReachabilityStatus status, BOOL oldIsReachable))handler {
    objc_setAssociatedObject(self, _cmd, handler, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

+ (BOOL)isReachable {
    return _reachable;
}

+ (BOOL)isDebugEnvironment {
//#if TARGET_OS_SIMULATOR
//    return true;
//#endif
#ifdef DEBUG
    return [[self ssid].lowercaseString isEqualToString:@"nash.work-2.4g"];
#else
    return false;
#endif
}

+ (NSString *)ssid
{
    NSArray *ifs = CFBridgingRelease(CNCopySupportedInterfaces());
    id info = nil;
    for (NSString *ifname in ifs) {
        info = (__bridge_transfer id)CNCopyCurrentNetworkInfo((CFStringRef) ifname);
        if (info && [info count]) {
            break;
        }
    }
    NSDictionary *dic = (NSDictionary *)info;
    NSString *ssid = [[dic objectForKey:@"SSID"] lowercaseString];
    return ssid;
}

+ (NSArray <QWNetworkClientOptions *> *)allClientOptionsWithCoinType:(QWWalletCoinType)coinType {
    
    NSMutableArray *allClientOptions = [NSMutableArray array];
    
    QWNetworkClientOptions *options = [QWNetworkClientOptions new];
    
    if (coinType == QWWalletCoinTypeQKC) {
        
        options.name = @"mainnet";
        options.chainID = 1;
        options.networkId = @"1";
        options.endpointURLString = @"http://jrpc.mainnet.quarkchain.io:38391";
        options.mainnet = true;
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
        options = [QWNetworkClientOptions new];
        options.networkId = @"255";
        options.name = @"devnet";
        options.chainID = 255;
        options.endpointURLString = @"http://jrpc.devnet.quarkchain.io:38391";
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
    } else if (coinType == QWWalletCoinTypeETH) {
        
        options.name = @"mainnet";
        options.chainID = 1;
        options.endpointURLString = @"https://mainnet.infura.io/v3/";
        options.apiURLString = @"https://api.etherscan.io/";
        options.mainnet = true;
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
        options = [QWNetworkClientOptions new];
        options.name = @"ropsten testnet";
        options.chainID = 3;
        options.endpointURLString = @"https://ropsten.infura.io/v3/";
        options.apiURLString = @"https://api-ropsten.etherscan.io/";
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
        options = [QWNetworkClientOptions new];
        options.name = @"kovan testnet";
        options.chainID = 42;
        options.endpointURLString = @"https://kovan.infura.io/v3/";
        options.apiURLString = @"https://api-kovan.etherscan.io/";
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
        options = [QWNetworkClientOptions new];
        options.name = @"rinkeby testnet";
        options.chainID = 4;
        options.endpointURLString = @"https://rinkeby.infura.io/v3/";
        options.apiURLString = @"https://api-rinkeby.etherscan.io/";
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
    } else if (coinType == QWWalletCoinTypeTRX) {
        
        options.name = @"mainnet";
        options.chainID = 1;
        options.endpointURLString = @"grpc.trongrid.io:50051";
        options.apiURLString = @"https://apilist.tronscan.org/";
        options.mainnet = true;
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
        options = [QWNetworkClientOptions new];
        options.name = @"Shasta";
        options.chainID = 3;
        options.endpointURLString = @"grpc.shasta.trongrid.io:50051";
        options.apiURLString = @"https://api.shasta.tronscan.org/";
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
    } else if (coinType == QWWalletCoinTypeBTC) {
        
#if 1
        options.name = @"mainnet";
        options.chainID = 1;
        options.mainnet = true;
        options.endpointURLString = @"";
        options.apiURLString = @"https://api.blockchair.com/bitcoin/";
        options.coinType = coinType;
        [allClientOptions addObject:options];
#else
        options.name = @"testnet";
        options.chainID = 2;
        options.endpointURLString = @"";
        options.apiURLString = @"https://api.blockchair.com/bitcoin/testnet/";
        options.coinType = coinType;
        [allClientOptions addObject:options];
#endif
        
    } else if (coinType == QWWalletCoinTypeONE) {
        
        options.name = @"mainnet";
        options.chainID = 1;
        options.networkId = @"1";
        options.mainnet = true;
        options.endpointURLString = @"https://api.s%@.t.hmny.io";
        options.apiURLString = @"";
        options.coinType = coinType;
        [allClientOptions addObject:options];
        
    }
    
    return allClientOptions;
    
}

+ (NSString *)bountyApiURLString {
//    return @"https://api.qpocket.io";
//    return @"https://api-sandbox.qpocket.io";
    return @"https://api.points.qpocket.io";
//    return @"http://127.0.0.1:3000";
//    return @"http://172.16.0.195:3000";
}

+ (NSString *)bountyWebsiteURLString {
    return @"https://qbounty.quarkchain.io";
//    return @"https://sandbox-qbounty.quarkchain.io";
}

+ (NSString *)marketApiURLString {
//    return @"https://sandbox-api.coinmarketcap.com/";
//    return @"https://pro-api.coinmarketcap.com/";
    return @"https://api.coingecko.com/api/v3/";
}

+ (NSString *)marketApiKey {
    return @""; //coinmakketcap pro
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        NSAssert(NO, @"use initWithClientType");
    }
    return self;
}

- (instancetype)initWithClientType:(QWWalletCoinType)clientType
{
    self = [super init];
    if (self) {
        self.clients = [NSMutableDictionary dictionary];
        self.fetchTimeLimitInMinute = 1440;
        self.clientType = clientType;
    }
    return self;
}

- (void)didApplicationChangedLocalization:(NSNotification *)notification {
    self.ethClient.options.apiURLString = @"https://api.etherscan.io/";
}

- (QWClient *)createClientWithClientOptions:(QWNetworkClientOptions *)clientOptions {
    QWClient *client = nil;
    switch (clientOptions.coinType) {
        case QWWalletCoinTypeQKC:
        {
            client = [[QWQKCClient alloc] initWithEndpointURL:[NSURL URLWithString:clientOptions.endpointURLString]];
        }
            break;
        case QWWalletCoinTypeETH:
        {
            client = [[QWETHClient alloc] initWithEndpointURL:[NSURL URLWithString:clientOptions.endpointURLString]];
        }
            break;
        case QWWalletCoinTypeTRX:
        {
            client = [[QWTRXClient alloc] initWithEndpointURL:[NSURL URLWithString:clientOptions.endpointURLString]];
        }
            break;
        case QWWalletCoinTypeBTC:
        {
            client = [[QWBTCClient alloc] initWithEndpointURL:[NSURL URLWithString:clientOptions.endpointURLString]];
        }
            break;
        case QWWalletCoinTypeONE:
        {
            client = [QWONEClient new];
//            [[QWONEClient alloc] initWithEndpointURL:[NSURL URLWithString:clientOptions.endpointURLString]];
        }
            break;
        default:
            break;
    }
    [client setValue:clientOptions forKey:@"options"];
    return client;
}

- (void)setClientOptions:(QWNetworkClientOptions *)clientOptions {
    NSAssert(clientOptions, @"");
    if (self.clientOptions.chainID == clientOptions.chainID && self.clientOptions.coinType == clientOptions.coinType) {
        return;
    }
    _client = [self createClientWithClientOptions:clientOptions];
    self.clients[@(clientOptions.coinType)] = _client;
    NSMutableDictionary *networkLastClientOptionsInfo = [[[NSUserDefaults standardUserDefaults] objectForKey:QWNetworkLastClientOptionsInfoKey] mutableCopy];
    if (!networkLastClientOptionsInfo) {
        networkLastClientOptionsInfo = [NSMutableDictionary dictionary];
    }
    networkLastClientOptionsInfo[@(clientOptions.coinType).stringValue] = @(clientOptions.chainID);
    if (_clientOptions) {
        [[NSUserDefaults standardUserDefaults] setObject:networkLastClientOptionsInfo forKey:QWNetworkLastClientOptionsInfoKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    _clientOptions = clientOptions;
}

- (void)setClientType:(QWWalletCoinType)clientType {
    if (self.clientOptions.coinType == clientType) {
        return;
    }
    self.clientOptions = [self lastClientOptionsWithCoinType:clientType];
    !self.didClientTypeChanged ?: self.didClientTypeChanged();
}

- (QWNetworkClientOptions *)lastClientOptionsWithCoinType:(QWNetworkClientType)coinType {
    NSDictionary *networkLastClientOptionsInfo = [[NSUserDefaults standardUserDefaults] objectForKey:QWNetworkLastClientOptionsInfoKey];
    NSNumber *lastClientChainID = networkLastClientOptionsInfo[@(coinType).stringValue];
    NSArray *allClientOptionsByCoinType = [self.class allClientOptionsWithCoinType:coinType];
    QWNetworkClientOptions *clientOptions = nil;
    if (!lastClientChainID) {
        clientOptions = allClientOptionsByCoinType.firstObject;
    } else {
        for (QWNetworkClientOptions *_clientOptions in allClientOptionsByCoinType) {
            if (_clientOptions.chainID == lastClientChainID.integerValue) {
                clientOptions = _clientOptions;
                break;
            }
        }
        if (!clientOptions) {
            clientOptions = allClientOptionsByCoinType.firstObject;
        }
    }
    return clientOptions;
}

- (QWNetworkClientType)clientType {
    return self.clientOptions.coinType;
}

- (BOOL)isTestnetEnabled {
    return !self.clientOptions.isMainnet;
}

- (BOOL)isTestnetEnabledWithCoinType:(QWNetworkClientType)coinType {
    return ![self lastClientOptionsWithCoinType:coinType].isMainnet;
}

- (BOOL)isReachable {
    return _reachable;
}

- (QWClient *)clientWithCoinType:(QWWalletCoinType)coinType {
    QWClient *client = self.clients[@(coinType)];
    if (!client) {
        client = [self createClientWithClientOptions:[self lastClientOptionsWithCoinType:coinType]];
        self.clients[@(coinType)] = client;
    }
    return client;
}

- (QWQKCClient *)qkcClient {
    return (id)[self clientWithCoinType:QWWalletCoinTypeQKC];
}

- (QWETHClient *)ethClient {
    return (id)[self clientWithCoinType:QWWalletCoinTypeETH];
}

- (QWTRXClient *)trxClient {
    return (id)[self clientWithCoinType:QWWalletCoinTypeTRX];
}

- (QWBTCClient *)btcClient {
    return (id)[self clientWithCoinType:QWWalletCoinTypeBTC];
}

- (QWONEClient *)oneClient {
    return (id)[self clientWithCoinType:QWWalletCoinTypeONE];
}

- (AFHTTPSessionManager *)httpManager {
    if (!_httpManager) {
        _httpManager = [AFHTTPSessionManager manager];
        _httpManager.responseSerializer = [AFHTTPResponseSerializer serializer];
    }
    return _httpManager;
}

- (void)fetchOnlineConfigForKey:(NSString *)key completion:(void(^)(id config, NSError *error))completion {
    QWNetworkFetchOptions *options = [QWNetworkFetchOptions new];
    options.keyEqualsToValue = @{@"name" : key};
    [self fetchObjectsForName:@"OnlineConfig" options:options completion:^(NSArray<NSDictionary *> *objects, NSError *error) {
        completion(objects.firstObject[@"parameters"], error);
    }];
}

- (void)fetchObjectsForName:(NSString *)name completion:(void (^)(NSArray<NSDictionary *> *, NSError *))completion {
    [self fetchObjectsForName:name options:nil completion:completion];
}

- (BOOL)shouldFetchForName:(NSString *)name {
    NSString *fetchTimeUserDefaultsKey = kQWNetworkFetchTimeUserDefaultsKey(name);
    NSTimeInterval fetchTimeLimitInMinute = self.fetchTimeLimitInMinute;
    id lastFetchTimeObject = [[NSUserDefaults standardUserDefaults] objectForKey:fetchTimeUserDefaultsKey];
    if (!lastFetchTimeObject) {
        [[NSUserDefaults standardUserDefaults] setDouble:[NSDate date].timeIntervalSince1970 forKey:fetchTimeUserDefaultsKey];
        [[NSUserDefaults standardUserDefaults] synchronize];
        return true;
    }
    NSTimeInterval lastFetchTime = [lastFetchTimeObject doubleValue];
    if ([[NSDate date] timeIntervalInMinutesSinceTimeInterval:lastFetchTime] <= fetchTimeLimitInMinute) {
        return false;
    }
    return true;
}

- (void)resetFetchTimeLimitForName:(NSString *)name {
    NSString *fetchTimeUserDefaultsKey = kQWNetworkFetchTimeUserDefaultsKey(name);
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:fetchTimeUserDefaultsKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)fetchObjectsForName:(NSString *)name options:(QWNetworkFetchOptions *)options completion:(void(^)(NSArray <NSDictionary *> *objects, NSError *error))completion {
    [self fetchObjectsForName:name timeLimitKey:name options:options completion:completion];
}

- (void)fetchObjectsForName:(NSString *)name timeLimitKey:(NSString *)timeLimitKey options:(QWNetworkFetchOptions *)options completion:(void(^)(NSArray <NSDictionary *> *objects, NSError *error))completion {
    if (options.isFetchTimeLimitEnabled) {
        if (![self shouldFetchForName:timeLimitKey]) {
            completion(nil, [NSError errorWithDomain:QWNetworkErrorDomain code:QWNetworkErrorFetchTimeLimit userInfo:nil]);
            return;
        }
    }
    __block AVQuery *query = options.isOrRelationship ? nil : [AVQuery queryWithClassName:name];
    NSMutableArray *queries = options.isOrRelationship ? [NSMutableArray array] : nil;
    if (options.keyContainsValue.count) {
        [options.keyContainsValue enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (options.isOrRelationship) {
                AVQuery *_query = [AVQuery queryWithClassName:name];
                [_query whereKey:key containsString:obj];
                [queries addObject:_query];
            } else {
                [query whereKey:key containsString:obj];
            }
        }];
    }
    if (options.keyMatchesRegexes.count) {
        [options.keyMatchesRegexes enumerateObjectsUsingBlock:^(NSDictionary<NSString *,NSString *> * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
//                if (options.isOrRelationship) {
                    AVQuery *_query = [AVQuery queryWithClassName:name];
                    [_query whereKey:key matchesRegex:obj modifiers:@"gi"];
                    [queries addObject:_query];
//                } else {
//                    [query whereKey:key matchesRegex:obj modifiers:@"gi"];
//                }
            }];
        }];
    }
    if (options.keyMatchesRegex.count) {
        [options.keyMatchesRegex enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            if (options.isOrRelationship) {
                AVQuery *_query = [AVQuery queryWithClassName:name];
                [_query whereKey:key matchesRegex:obj modifiers:@"gi"];
                [queries addObject:_query];
            } else {
                [query whereKey:key matchesRegex:obj modifiers:@"gi"];
            }
        }];
    }
    if (options.isOrRelationship) {
        query = [AVQuery orQueryWithSubqueries:queries];
    }
    if (options.sortDescriptor) {
        [query orderBySortDescriptor:options.sortDescriptor];
    }
    if (options.keyEqualsToValue.count) {
        [options.keyEqualsToValue enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [query whereKey:key equalTo:obj];
        }];
    }
    if (options.keyEqualsToValues.count) {
        [options.keyEqualsToValues enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, NSArray<id> * _Nonnull obj, BOOL * _Nonnull stop) {
            [query whereKey:key containedIn:obj];
        }];
    }
    for (NSString *relationshipKey in options.relationshipKeys) {
        [query includeKey:relationshipKey];
    }
    if (options.limit) {
        query.limit = options.limit;
    }
    if (options.skip) {
        query.skip = options.skip;
    }
    [query findObjectsInBackgroundWithBlock:^(NSArray * _Nullable objects, NSError * _Nullable error) {
        completion([objects valueForKeyPath:@"dictionaryForObject"], error);
        NSString *fetchTimeUserDefaultsKey = kQWNetworkFetchTimeUserDefaultsKey(timeLimitKey);
        if (options.isFetchTimeLimitEnabled || [[NSUserDefaults standardUserDefaults] objectForKey:fetchTimeUserDefaultsKey] || options.needSaveFetchTimeLimitKey) { //Has saved fetch time before
            [[NSUserDefaults standardUserDefaults] setDouble:[NSDate date].timeIntervalSince1970 forKey:fetchTimeUserDefaultsKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }];
}

static AFSecurityPolicy *securityPolicy = nil;
static AFSecurityPolicy *defaultPolicy = nil;
static NSDictionary *certificates = nil;

- (void)requestWithOptions:(QWNetworkRequestOptions *)options response:(void(^)(NSDictionary *object, NSError *error))response {
    
    if (options.SSLPinningEnabled) {
        if (!securityPolicy) {
            certificates = @{@"devnet.quarkchain.io":[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"devnet.quarkchain.io" ofType:@"cer"]],
                             @"api-sandbox.qpocket.io":[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"api-sandbox.qpocket.io" ofType:@"cer"]],
                             @"api.qpocket.io":[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"api.qpocket.io" ofType:@"cer"]]
                             };
            securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModePublicKey];
            securityPolicy.allowInvalidCertificates = true;
            securityPolicy.validatesDomainName = false;
        }
        securityPolicy.pinnedCertificates = nil;
        for (NSString *host in certificates.allKeys) {
            if ([options.URLString containsString:host]) {
                securityPolicy.pinnedCertificates = @[certificates[host]];
                break;
            }
        }
        NSAssert(securityPolicy.pinnedCertificates, @"");
        self.httpManager.securityPolicy = securityPolicy;
    } else {
        if (!defaultPolicy) {
            defaultPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeNone];
            defaultPolicy.validatesDomainName = false;
            defaultPolicy.allowInvalidCertificates = true;
        }
        self.httpManager.securityPolicy = defaultPolicy;
    }
    
    if (options.formParameter) {
        NSString *method = @"POST";
        if (options.method == QWNetworkRequestOptionsMethodGET) {
            method = @"GET";
        }
        self.httpManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        for (id key in options.headerFields) {
            [self.httpManager.requestSerializer setValue:options.headerFields[key] forHTTPHeaderField:key];
        }
        NSMutableURLRequest *request = [self.httpManager.requestSerializer multipartFormRequestWithMethod:method URLString:options.URLString parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            for (NSString *key in options.parameter) {
                id value = options.parameter[key];
                NSAssert([value isKindOfClass:[NSString class]], @"form-data only support string param");
                [formData appendPartWithFormData:[value dataUsingEncoding:NSUTF8StringEncoding] name:key];
            }
        } error:nil];
        [[self.httpManager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull _response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (response) {
                if (responseObject) {
                    NSError *_error;
                    id responseJSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:&_error];
                    if (!_error) {
                        responseObject = responseJSON;
                    }
                }
                response(responseObject, error);
            }
        }] resume];
        
    } else if (!options.JSONParameter) {
        
        id success = ^(NSURLSessionDataTask * _Nonnull task, id  _Nonnull responseObject) {
            if (response) {
                NSError *error;
                id responseJSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves | NSJSONReadingAllowFragments error:&error];
                response(!error ? responseJSON : responseObject, nil);
            }
        };
        
        id failure = ^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            if (response) {
                response(nil, error);
            }
        };
        
        self.httpManager.requestSerializer = [AFJSONRequestSerializer serializer];
        for (id key in options.headerFields) {
            [self.httpManager.requestSerializer setValue:options.headerFields[key] forHTTPHeaderField:key];
        }
        
        if (options.method == QWNetworkRequestOptionsMethodGET) {
            [self.httpManager GET:options.URLString parameters:options.parameter success:success failure:failure];
        } else if (options.method == QWNetworkRequestOptionsMethodPOST) {
            [self.httpManager POST:options.URLString parameters:options.parameter success:success failure:failure];
        }
    } else {
        NSString *method = @"POST";
        if (options.method == QWNetworkRequestOptionsMethodGET) {
            method = @"GET";
        }
        NSMutableURLRequest *request = [[AFJSONRequestSerializer serializer] requestWithMethod:method URLString:options.URLString parameters:nil error:nil];
        for (id key in options.headerFields) {
            [request setValue:options.headerFields[key] forHTTPHeaderField:key];
        }
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
        [request setHTTPBody:options.parameter];
        [[self.httpManager dataTaskWithRequest:request completionHandler:^(NSURLResponse * _Nonnull _response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (response) {
                if (responseObject) {
                    NSError *_error;
                    id responseJSON = [NSJSONSerialization JSONObjectWithData:responseObject options:NSJSONReadingMutableLeaves error:&_error];
                    if (!_error) {
                        responseObject = responseJSON;
                    }
                }
                response(responseObject, error);
            }
        }] resume];
    }
    
}

- (void)POST:(NSString *)URLString parameters:(NSDictionary *)parameters response:(void(^)(NSDictionary *object, NSError *error))response {
    QWNetworkRequestOptions *options = [QWNetworkRequestOptions new];
    options.URLString = URLString;
    options.parameter = parameters;
    options.method = QWNetworkRequestOptionsMethodPOST;
    [self requestWithOptions:options response:response];
}

- (void)GET:(NSString *)URLString parameters:(NSDictionary *)parameters response:(void (^)(NSDictionary *, NSError *))response {
    [self GET:URLString headerFields:nil parameters:parameters response:response];
}

- (void)GET:(NSString *)URLString headerFields:(NSDictionary *)headerFields parameters:(NSDictionary *)parameters response:(void(^)(NSDictionary *object, NSError *error))response {
    QWNetworkRequestOptions *options = [QWNetworkRequestOptions new];
    options.URLString = URLString;
    options.parameter = parameters;
    options.method = QWNetworkRequestOptionsMethodGET;
    options.headerFields = headerFields;
    [self requestWithOptions:options response:response];
}

- (void)uploadToName:(NSString *)name parameters:(NSDictionary *)parameters pointerParameters:(NSDictionary *)pointerParameters response:(void(^)(NSDictionary *object, NSError *error))response {
    AVObject *object = [AVObject objectWithClassName:name];
    [pointerParameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, NSDictionary *obj, BOOL * _Nonnull stop) {
        NSAssert([obj isKindOfClass:[NSDictionary class]] && obj.count == 1, @"");
        AVObject *pointerObject = [AVObject objectWithClassName:obj.allKeys.firstObject objectId:obj.allValues.firstObject];
        [object setObject:pointerObject forKey:key];
    }];
    [parameters enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [object setObject:obj forKey:key];
    }];
    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        !response ?: response(nil, error);
    }];
}

- (void)requestWithSSLPinningEnabledMethod:(QWNetworkRequestOptionsMethod)method URLString:(NSString *)URLString parameters:(NSDictionary *)parameters response:(void(^)(NSDictionary *object, NSError *error))response {
    QWNetworkRequestOptions *options = [QWNetworkRequestOptions new];
    options.URLString = URLString;
    options.parameter = parameters;
    options.method = method;
    options.SSLPinningEnabled = true;
    [self requestWithOptions:options response:response];
}

@end
