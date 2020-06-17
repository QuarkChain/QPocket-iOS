//
//  QWKeystore.m
//  QuarkWallet
//
//  Created by Jazys on 2018/8/5.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

#import "QWKeystore.h"
#import "TrezorCrypto.h"
#import <Geth/Geth.h>
#import "PocketCore-Swift.h"
#import "NSData+QWHexString.h"
#import "NSData+Encryption.h"
#import "QWError.h"
#import "NSString+QWHexBinaryConverting.h"
#import "EthereumCrypto.h"
#import "NSString+Address.h"
#import "CoreBitcoin/CoreBitcoin.h"
#import "QWWalletManager+Private.h"
@import CommonCrypto;

QWUserDefaultsKey QWKeystoreBTCIDMapKey = @"QWKeystoreBTCIDMapKey";

@interface QWKeystore()
@property (nonatomic) NSArray <NSString *> *wordlist;
@end

@implementation QWKeystore

+ (NSArray<NSString *> *)allMnemonicWordlistNames {
    NSBundle *wordlistsBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"Wordlists.bundle" ofType:nil inDirectory:nil]];
    NSArray <NSString *> *allWordlistPaths = [wordlistsBundle pathsForResourcesOfType:nil inDirectory:nil];
    NSMutableArray *allMnemonicWordlistNames = [NSMutableArray array];
    for (NSString *wordlistPath in allWordlistPaths) {
        [allMnemonicWordlistNames addObject:[[wordlistPath lastPathComponent] stringByDeletingPathExtension]];
    }
    return allMnemonicWordlistNames;
}

+ (NSString *)detectWordlistNamedFromMnemonic:(NSString *)mnemonic {
    NSArray *words = [mnemonic componentsSeparatedByString:@" "];
    if (words.count < 12) {
        return nil;
    }
    NSLinguisticTagger *tagger = [[NSLinguisticTagger alloc] initWithTagSchemes:@[NSLinguisticTagSchemeLanguage] options:0];
    tagger.string = mnemonic;
    NSDictionary *allWordlistNamedMap = @{@"en":@"english",
                                          @"zh-Hans":@"chinese_simplified",
                                          @"zh-Hant":@"chinese_traditional",
                                          };
//                                          @"fr":@"french",
//                                          @"it":@"italian",
//                                          @"ja":@"japanese",
//                                          @"ko":@"korean",
//                                          @"es":@"spanish"};
    NSMutableArray *allWordlistNames = allWordlistNamedMap.allValues.mutableCopy;
    NSString *preferredWordlistNamed = allWordlistNamedMap[[tagger tagAtIndex:0 scheme:NSLinguisticTagSchemeLanguage tokenRange:NULL sentenceRange:NULL]];
    if (!preferredWordlistNamed) {
        preferredWordlistNamed = allWordlistNamedMap[@"en"];
    }
    [allWordlistNames removeObject:preferredWordlistNamed];
    [allWordlistNames insertObject:preferredWordlistNamed atIndex:0];
    for (NSString *wordlistNamed in allWordlistNames) {
        NSArray *wordlist = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Wordlists.bundle/%@", wordlistNamed] ofType:@"json"]] options:NSJSONReadingMutableLeaves error:nil];
        BOOL match = true;
        for (NSString *word in words) {
            if ([wordlist indexOfObject:word] == NSNotFound) {
                match = false;
                break;
            }
        }
        if (match) {
            return wordlistNamed;
        }
    }
    return nil;
}

- (instancetype)initWithPath:(NSString *)path mnemonicWordlistNamed:(NSString *)mnemonicWordlistNamed
{
    self = [super init];
    
    if (self) {
        self.gethKeystore = [[GethKeyStore alloc] init:path scryptN:4096 scryptP:6];
        self.mnemonicWordlistNamed = mnemonicWordlistNamed;
        if (![[NSFileManager defaultManager] fileExistsAtPath:[path stringByAppendingPathComponent:@"wallets"]]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[path stringByAppendingPathComponent:@"wallets"] withIntermediateDirectories:true attributes:nil error:NULL];
        }
    }
    return self;
}

- (void)setMnemonicWordlistNamed:(NSString *)mnemonicWordlistNamed {
    
    _mnemonicWordlistNamed = mnemonicWordlistNamed.copy;
    
    self.wordlist = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Wordlists.bundle/%@", _mnemonicWordlistNamed] ofType:@"json"]] options:NSJSONReadingMutableLeaves error:nil];
    
}

- (NSString *)generateMnemonicWithStrength:(NSInteger)strength {
    
    NSAssert(strength % 32 == 0, @"Strength must be divisible by 32");
    
    NSMutableData *seedData = [NSMutableData dataWithLength:(strength / 8)];
    
    // Generate the random data
    if (SecRandomCopyBytes(kSecRandomDefault, seedData.length, seedData.mutableBytes) == 0) {
        
        NSMutableData *hash = [NSMutableData dataWithLength:CC_SHA256_DIGEST_LENGTH];
        CC_SHA256(seedData.bytes, (int)seedData.length, hash.mutableBytes);
        
        NSString *checksumBitsString = [hash qw_binaryString];
        
        NSMutableString *seedBitsString = [seedData qw_binaryString].mutableCopy;
        
        for (NSInteger index = 0; index < seedBitsString.length / 32; index++) {
            [seedBitsString appendString:[NSString stringWithFormat:@"%C", [checksumBitsString characterAtIndex:index]]];
        }
        
        NSMutableString *mnemonic = [NSMutableString stringWithCapacity:seedBitsString.length / 11];
        for (NSInteger index = 0; index < seedBitsString.length / 11; index++) {
            NSInteger mnemonicIndex = strtol([seedBitsString substringWithRange:NSMakeRange(index * 11, 11)].UTF8String, NULL, 2);
            [mnemonic appendFormat:@"%@ ", self.wordlist[mnemonicIndex]];
        }
        [mnemonic deleteCharactersInRange:NSMakeRange(mnemonic.length - 1, 1)]; // delete last space
        
        return mnemonic;
        
    } else {
        
        NSAssert(NO, @"Unable to get random data");
        
    }
    
    return nil;
    
}

- (id)privateKeyWithMnemonic:(NSString *)mnemonic coinType:(NSUInteger)coinType {
    return [self privateKeyWithMnemonic:mnemonic coinType:coinType path:nil];
}

- (id)privateKeyWithMnemonic:(NSString *)mnemonic coinType:(NSUInteger)coinType path:(NSString *)path {
    
    if (!path) {
        path = [NSString stringWithFormat:@"44'/%ld'/0'", coinType];
    }
    
    NSArray <NSString *> *paths = [path componentsSeparatedByString:@"/"];
    
    if (coinType != QWWalletCoinTypeBTC) {
        
        uint8_t seeds[512 / 8];
        mnemonic_to_seed([mnemonic cStringUsingEncoding:NSUTF8StringEncoding], "", seeds, nil);
        NSData *seed = [[NSData alloc] initWithBytes:seeds length:512 / 8];
        
        __block HDNode node;
        [seed enumerateByteRangesUsingBlock:^(const void * _Nonnull bytes, NSRange byteRange, BOOL * _Nonnull stop) {
            hdnode_from_seed(bytes, (int)byteRange.length, "secp256k1", &node);
        }];
        
        hdnode_private_ckd_prime(&node, paths[0].integerValue);
        hdnode_private_ckd_prime(&node, paths[1].integerValue);
        hdnode_private_ckd_prime(&node, paths[2].integerValue);
        hdnode_private_ckd(&node, 0);
        hdnode_private_ckd(&node, 0);
        
        return [[NSData alloc] initWithBytes:node.private_key length:256 / 8];
        
    } else {
        NSAssert(path.length, @"path is nonnull for BTC");
        NSString *result = [self.class detectWordlistNamedFromMnemonic:mnemonic];
        BTCMnemonicWordListType wordListType = BTCMnemonicWordListTypeEnglish;
        if ([result isEqualToString:@"chinese_simplified"]) {
            wordListType = BTCMnemonicWordListTypeChineseSimplified;
        } else if ([result isEqualToString:@"chinese_traditional"]) {
            wordListType = BTCMnemonicWordListTypeChineseTraditional;
        } else if (![result isEqualToString:@"english"]) {
            NSLog(@"jazys: detect mnemonic failed!");
            return nil;
        }
        BTCMnemonic *btcMnemonic = [[BTCMnemonic alloc] initWithWords:[mnemonic componentsSeparatedByString:@" "] password:nil wordListType:wordListType];
        BTCKeychain *keychain = [[BTCKeychain alloc] initWithSeed:btcMnemonic.seed network:[paths[1] isEqualToString:@"0'"] ? [BTCNetwork mainnet] : [BTCNetwork testnet]];
        return [keychain derivedKeychainWithPath:[NSString stringWithFormat:@"%@/%@/%@", paths[0], paths[1], paths[2]]];
    }
    
}

- (int)isValidMnemonic:(const char *)mnemonic {
    
    if (!mnemonic) {
        return 0;
    }
    
    uint32_t i, n;
    
    i = 0; n = 0;
    while (mnemonic[i]) {
        if (mnemonic[i] == ' ') {
            n++;
        }
        i++;
    }
    n++;
    // check number of words
    if (n != 12 && n != 18 && n != 24) {
        return 0;
    }
    
    char current_word[20];
    uint32_t j, k, ki, bi;
    uint8_t bits[32 + 1];
    
    memzero(bits, sizeof(bits));
    i = 0; bi = 0;
    while (mnemonic[i]) {
        j = 0;
        while (mnemonic[i] != ' ' && mnemonic[i] != 0) {
            if (j >= sizeof(current_word) - 1) {
                return 0;
            }
            current_word[j] = mnemonic[i];
            i++; j++;
        }
        current_word[j] = 0;
        if (mnemonic[i] != 0) i++;
        k = 0;
        for (;;) {
            if (!self.wordlist[k].UTF8String) { // word not found
                return 0;
            }
            if (strcmp(current_word, self.wordlist[k].UTF8String) == 0) { // word found on index k
                for (ki = 0; ki < 11; ki++) {
                    if (k & (1 << (10 - ki))) {
                        bits[bi / 8] |= 1 << (7 - (bi % 8));
                    }
                    bi++;
                }
                break;
            }
            k++;
        }
    }
    if (bi != n * 11) {
        return 0;
    }
    bits[32] = bits[n * 4 / 3];
    sha256_Raw(bits, n * 4 / 3, bits);
    if (n == 12) {
        return (bits[0] & 0xF0) == (bits[32] & 0xF0); // compare first 4 bits
    } else
        if (n == 18) {
            return (bits[0] & 0xFC) == (bits[32] & 0xFC); // compare first 6 bits
        } else
            if (n == 24) {
                return bits[0] == bits[32]; // compare 8 bits
            }
    return 0;
    
}

- (NSError *)verifyMnemonic:(NSString *)mnemonic {
    
    if ([self isValidMnemonic:mnemonic.UTF8String]) {
        return nil;
    }
    
    return [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidMnemonic localizedDescriptionKey:@"QWKeystore.error.invalidMnemonic"];
    
}

- (NSString *)convertMnemonicUsingCurrentWordlist:(NSString *)mnemonic {
    NSArray *wordlist = [NSJSONSerialization JSONObjectWithData:[NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"Wordlists.bundle/%@", [self.class detectWordlistNamedFromMnemonic:mnemonic]] ofType:@"json"]] options:NSJSONReadingMutableLeaves error:nil];
    NSArray *words = [mnemonic componentsSeparatedByString:@" "];
    NSMutableString *resultMnemonic = [NSMutableString string];
    for (NSString *word in words) {
        [resultMnemonic appendFormat:@"%@ ", self.wordlist[[wordlist indexOfObject:word]]];
    }
    [resultMnemonic deleteCharactersInRange:NSMakeRange(resultMnemonic.length - 1, 1)];
    return resultMnemonic;
}

- (GethAccount *)gethAccountWithKeystoreName:(NSString *)keystoreName {
    
    NSError *error = nil;
    GethAccounts* accounts = [self.gethKeystore getAccounts];
    NSUInteger accountCount = accounts.size;
    GethAccount *gethAccount = nil;
    for(int i=0;i<accountCount;i++){
        GethAccount *account = [accounts get:i error:&error];
        if([[account.getURL lastPathComponent] isEqualToString:keystoreName]){
            gethAccount = account;
            break;
        }
    }
    
    return gethAccount;
    
}

- (NSError *)verifyPasswordForKeystoreName:(NSString *)keystoreName password:(NSString *)password coinType:(QWWalletCoinType)coinType {
    NSError *error = nil;
    if (coinType != QWWalletCoinTypeBTC) {
        if ([self.gethKeystore unlock:[self gethAccountWithKeystoreName:keystoreName] passphrase:password error:&error]) {
            return nil;
        }
    } else {
        NSData *keystoreData = [NSData dataWithContentsOfFile:[QWAccountKeystorePath stringByAppendingPathComponent:keystoreName]];
        NSDictionary *keystore = [NSJSONSerialization JSONObjectWithData:keystoreData options:NSJSONReadingMutableLeaves error:&error];
        BTCKeystore *btcKeystore = [[BTCKeystore alloc] initWithJson:keystore error:&error];
        if ([btcKeystore verifyPasswordWithPassword:password]) {
            return nil;
        }
    }
    return [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidPassword localizedDescriptionKey:@"QWKeystore.error.invalidPassword"];
}

- (NSString *)derivedAddressWithPublicKey:(NSString *)publicKey atIndex:(NSUInteger)index isSegWit:(BOOL)isSegWit isMainnet:(BOOL)isMainnet {
    BTCKeychain *keychain = [[BTCKeychain alloc] initWithExtendedKey:publicKey];
    keychain = [keychain derivedKeychainWithPath:[NSString stringWithFormat:@"/0/%ld", index]];
    if (isMainnet) {
        return isSegWit ? keychain.key.witnessAddress.string : keychain.key.address.string;
    } else {
        return isSegWit ? keychain.key.witnessAddressTestnet.string : keychain.key.addressTestnet.string;
    }
}

- (void)savePrivateKey:(id)privateKey password:(NSString *)password toPath:(NSString *)path coinType:(QWWalletCoinType)coinType completion:(void (^)(NSString *, NSString *, id, NSError *))completion {
    [self savePrivateKey:privateKey password:password toPath:path coinType:coinType params:nil completion:completion];
}

- (void)savePrivateKey:(id)privateKey password:(NSString *)password toPath:(NSString *)path coinType:(QWWalletCoinType)coinType params:(NSDictionary *)params completion:(void(^)(NSString *filePath, NSString *address, id extendedParam, NSError *error))completion {
    if (!privateKey) {
        !completion ?: completion(nil, nil, nil, [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidMnemonic localizedDescriptionKey:@"QWKeystore.error.invalidMnemonic"]);
        return;
    }
    NSString *address = nil;
    id extendedParam = nil;
    NSError *error = nil;
    if (coinType == QWWalletCoinTypeBTC) {
        NSString *wif = nil;
        if ([privateKey isKindOfClass:[BTCKeychain class]]) {
            BTCKeychain *rootKeychain = privateKey;
            BTCKeychain *keychain = [rootKeychain derivedKeychainWithPath:@"/0/0"];
            privateKey = rootKeychain.key.privateKey;
            NSNumber *segWit = params[@"segWit"];
            if (![params[@"testnet"] boolValue]) {
                address = [segWit boolValue] ? keychain.key.witnessAddress.string : keychain.key.address.string;
                wif = rootKeychain.key.privateKeyAddress.string;
            } else {
                address = [segWit boolValue] ? keychain.key.witnessAddressTestnet.string : keychain.key.addressTestnet.string;
                wif = rootKeychain.key.privateKeyAddressTestnet.string;
            }
            extendedParam = @{NSStringFromKeyPath(rootKeychain, extendedPublicKey):segWit.boolValue ? rootKeychain.extendedSegWitPublicKey : rootKeychain.extendedPublicKey, @"segWit":segWit ?: @NO, NSStringFromKeyPath(rootKeychain, extendedPrivateKey):rootKeychain.extendedPrivateKey};
        } else {
            BTCKey *key = nil;
            if ([privateKey isKindOfClass:[NSString class]]) {
                key = [[BTCKey alloc] initWithWIF:privateKey];
            } else if ([privateKey isKindOfClass:[NSData class]]) {
                key = [[BTCKey alloc] initWithPrivateKey:privateKey];
            }
            if (key) {
                if (!key.isPublicKeyCompressed && [params[@"segWit"] boolValue]) {
                    privateKey = nil;
                    error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeSegwitOnlySupportCompressedKey localizedDescriptionKey:@"QWKeystore.error.segWitPrivateKey"];
                } else {
                    if (![params[@"testnet"] boolValue]) {
                        address = [params[@"segWit"] boolValue] ? key.witnessAddress.string : key.address.string;
                        wif = key.privateKeyAddress.string;
                    } else {
                        address = [params[@"segWit"] boolValue] ? key.witnessAddressTestnet.string : key.addressTestnet.string;
                        wif = key.privateKeyAddressTestnet.string;
                    }
                    privateKey = key.privateKey;
                }
            } else {
                error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidPrivateKey localizedDescriptionKey:@"QWKeystore.error.invalidPrivateKey"];
            }
            extendedParam = params;
        }
        if (error) {
            !completion ?: completion(nil, nil, nil, error);
            return;
        }
        BTCKeystore *keystore = [[BTCKeystore alloc] initWithPassword:password wif:wif metadata:@{@"isSegWit":params[@"segWit"] ?: @NO,@"testnet":params[@"testnet"] ?: @NO} id:nil error:&error];
        NSMutableDictionary *QWKeystoreBTCIDMap = [[[NSUserDefaults standardUserDefaults] objectForKey:QWKeystoreBTCIDMapKey] mutableCopy];
        if (QWKeystoreBTCIDMap[address]) {
            error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeDuplicateKeystore localizedDescriptionKey:@"QWKeystore.error.duplicatedKeystore"];
            !completion ?: completion(nil, nil, nil, error);
            return;
        }
        NSDictionary *keystoreJSON = [keystore getJSON];
        if (keystoreJSON) {
            NSData *keystoreJSONData = [NSJSONSerialization dataWithJSONObject:keystoreJSON options:NSJSONWritingPrettyPrinted error:&error];
            NSDateFormatter *formatter = [NSDateFormatter new];
            formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
            formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
            formatter.formatterBehavior = NSDateFormatterBehaviorDefault;
            NSString *keystoreName = [NSString stringWithFormat:@"UTC--%@--%@", [formatter stringFromDate:[NSDate date]], keystore.id];
            if (![[NSFileManager defaultManager] fileExistsAtPath:QWAccountKeystorePath]) {
                [[NSFileManager defaultManager] createDirectoryAtPath:QWAccountKeystorePath withIntermediateDirectories:true attributes:nil error:&error];
            }
            NSString *filePath = [QWAccountKeystorePath stringByAppendingPathComponent:keystoreName];
            if ([keystoreJSONData writeToFile:filePath options:NSDataWritingAtomic error:&error]) {
                if (!QWKeystoreBTCIDMap) {
                    QWKeystoreBTCIDMap = [NSMutableDictionary dictionary];
                }
                QWKeystoreBTCIDMap[address] = keystoreName;
                [[NSUserDefaults standardUserDefaults] setObject:QWKeystoreBTCIDMap forKey:QWKeystoreBTCIDMapKey];
                [[NSUserDefaults standardUserDefaults] synchronize];
                !completion ?: completion(filePath, address, extendedParam, error);
                return;
            }
        }
        if (!error) {
            error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidPrivateKey localizedDescriptionKey:@"QWKeystore.error.invalidPrivateKey"];
        }
        !completion ?: completion(nil, nil, nil, error);
        return;
    }
    GethAccount *account = [self.gethKeystore importECDSAKey:privateKey passphrase:password error:&error];
    if ([error.domain isEqualToString:@"go"]) {
        if (error.code == 1) {
            if ([error.localizedDescription isEqualToString:@"invalid length, need 256 bits"]) {
                error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidPrivateKey localizedDescriptionKey:@"QWKeystore.error.invalidPrivateKey"];
            } else if ([error.localizedDescription isEqualToString:@"account already exists"]) {
                error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeDuplicateKeystore localizedDescriptionKey:@"QWKeystore.error.duplicatedKeystore"];
            }
        }
    }
    if (!address) {
        address = account.getAddress.getHex;
    }
    if (coinType == QWWalletCoinTypeQKC) {
        address = [address newFullShardIdAppended];
    } else if (coinType == QWWalletCoinTypeTRX) {
        if (account) {
            NSData *publicKey = [EthereumCrypto getPublicKeyFrom:privateKey];
            NSData *sha3 = [QWKeystoreSwift SHA3_Keccak_256WithData:[publicKey subdataWithRange:NSMakeRange(1, publicKey.length - 1)]];
            NSMutableData *addressData = [NSData qw_dataWithHexString:@"41"].mutableCopy;
            [addressData appendData:[sha3 subdataWithRange:NSMakeRange(12, 20)]];
            address = [QWKeystoreSwift base58CheckEncodingWithString:[addressData qw_hexString]];
        }
    } else if (coinType == QWWalletCoinTypeONE) {
        address = nil;
    }
    !completion ?: completion(account.getURL, address, extendedParam, error);
}

- (NSData *)privateKeyForKeystore:(NSDictionary *)keystore password:(NSString *)password error:(NSError **)error {
    
    return [self cryptData:nil withCryptoDictionary:keystore[@"crypto"] withPassword:password options:2 error:error];
    
}

- (NSString *)encryptMnemonic:(NSString *)mnemonic forKeystore:(NSData *)keystoreJSON password:(NSString *)password error:(NSError **)error {
    
    NSDictionary *keystore = [NSJSONSerialization JSONObjectWithData:keystoreJSON options:NSJSONReadingMutableLeaves error:error];
    
    if (error && *error) {
        *error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidKeystore localizedDescriptionKey:@"QWKeystore.error.invalidKeystore"];
        return nil;
    }
    
    return [self cryptData:[mnemonic dataUsingEncoding:NSUTF8StringEncoding] withCryptoDictionary:keystore[@"crypto"] withPassword:password options:1 error:error].qw_hexString;
    
}

- (NSString *)decryptMnemonic:(NSString *)mnemonic forKeystore:(NSData *)keystoreJSON password:(NSString *)password error:(NSError **)error {
    
    NSDictionary *keystore = [NSJSONSerialization JSONObjectWithData:keystoreJSON options:NSJSONReadingMutableLeaves error:error];
    
    if (*error) {
        *error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidKeystore localizedDescriptionKey:@"QWKeystore.error.invalidKeystore"];
        return nil;
    }
    
    NSData *decryptData = [self cryptData:[NSData qw_dataWithHexString:mnemonic] withCryptoDictionary:keystore[@"crypto"] withPassword:password options:2 error:error];
    
    if (*error) {
        return nil;
    }
    
    mnemonic = [[NSString alloc] initWithData:decryptData encoding:NSUTF8StringEncoding];
    
    if ([mnemonic hasSuffix:@"\0"]) {
        return [mnemonic stringByReplacingOccurrencesOfString:@"\0" withString:@"" options:NSBackwardsSearch range:NSMakeRange(0, mnemonic.length)];
    }
    
    return mnemonic;
    
}

- (void)verifyPasswordForKeystore:(NSData *)keystoreJSON password:(NSString *)password error:(NSError **)error {
    
    NSDictionary *keystore = [NSJSONSerialization JSONObjectWithData:keystoreJSON options:NSJSONReadingMutableLeaves error:error];
    
    if (*error) {
        return;
    }
    
    [self cryptData:nil withCryptoDictionary:keystore[@"crypto"] withPassword:password options:0 error:error];
    
}

- (void)saveKeystore:(NSData *)keystoreJSON keystorePassword:(NSString *)keystorePassword newPassword:(NSString *)password toPath:(NSString *)path completion:(void(^)(NSString *filePath, NSString *address, NSError *error))completion DEPRECATED_ATTRIBUTE {
    GethKeyStore *keystore = [[GethKeyStore alloc] init:path scryptN:4096 scryptP:6];
    NSError *error;
    GethAccount *account = [keystore importKey:keystoreJSON passphrase:keystorePassword newPassphrase:password error:&error];
    !completion ?: completion(account.getURL, account.getAddress.getHex, error);
}

#pragma mark - Private

/*
 options : 0 verify password only
 options : 1 encrypt
 options : 2 or other decrypt
 */
- (NSData *)cryptData:(NSData *)cryptData withCryptoDictionary:(NSDictionary *)cryptoDictionary withPassword:(NSString *)password options:(NSUInteger)options error:(NSError **)error {
    
    if (![cryptoDictionary[@"kdf"] isEqualToString:@"scrypt"]) {
        *error = [NSError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeUnsupportedKDF userInfo:nil];
        return nil;
    }
    
    NSDictionary *kdfparams = cryptoDictionary[@"kdfparams"];
    
    NSData *derivedKey = [NSData scryptPassword:[password dataUsingEncoding:NSUTF8StringEncoding] usingSalt:[NSData qw_dataWithHexString:kdfparams[@"salt"]] workFactor:[kdfparams[@"n"] unsignedIntegerValue] blockSize:[kdfparams[@"r"] unsignedIntValue] parallelizationFactor:[kdfparams[@"p"] unsignedIntValue] withOutputLength:[kdfparams[@"dklen"] unsignedIntegerValue]];
    
    if (error && *error) {
        return nil;
    }
    
    NSData *cipherData = [NSData qw_dataWithHexString:cryptoDictionary[@"ciphertext"]];
    
    if (!cryptData) {
        cryptData = cipherData;
    }
    
    NSMutableData *mac = [NSMutableData dataWithData:[derivedKey subdataWithRange:NSMakeRange(derivedKey.length - 16, derivedKey.length - 16)]];
    [mac appendData:cipherData];
    
    if (![[QWKeystoreSwift SHA3_Keccak_256WithData:mac] isEqualToData:[NSData qw_dataWithHexString:cryptoDictionary[@"mac"]]]) {
        *error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeInvalidPassword localizedDescriptionKey:@"QWKeystore.error.invalidPassword"];
        return nil;
    }
    
    if (options == 0) {
        return nil;
    }
    
    NSData *iv = [NSData qw_dataWithHexString:cryptoDictionary[@"cipherparams"][@"iv"]];
    
    if ([cryptoDictionary[@"cipher"] isEqualToString:@"aes-128-ctr"]) {
        return [QWKeystoreSwift AES_CTR_CryptWithCipherText:cryptData key:[derivedKey subdataWithRange:NSMakeRange(0, 16)] iv:iv isEncrypt:options == 1 error:error];
    } else if ([cryptoDictionary[@"cipher"] isEqualToString:@"aes-128-cbc"]) {
        return [QWKeystoreSwift AES_CBC_CryptWithCipherText:cryptData key:[derivedKey subdataWithRange:NSMakeRange(0, 16)] iv:iv isEncrypt:options == 1 error:error];
    } else {
        *error = [QWError errorWithDomain:QWKeystoreErrorDomain code:QWKeystoreErrorCodeUnsupportedCipher localizedDescriptionKey:@"QWKeystore.error.invalidKeystore"];
        return nil;
    }
    
}

- (NSData *)signHash:(NSData *)hashData withKeystoreName:(NSString *)keystoreName withPassword:(NSString *)password {
    GethKeyStore *keystore = self.gethKeystore;
    GethAccount *gethAccount = [self gethAccountWithKeystoreName:keystoreName];
    NSError *error = nil;
    if (![keystore unlock:gethAccount passphrase:password error:&error]) {
        return nil;
    }
    NSMutableData *hash = [keystore signHash:[gethAccount getAddress] hash:hashData error:&error].mutableCopy;
    if (hash) {
        int lastByteValue = *(int *)[[hash subdataWithRange:NSMakeRange(64, 1)] bytes];
        lastByteValue += 27;
        [hash replaceBytesInRange:NSMakeRange(64, 1) withBytes:&lastByteValue length:1];
        return hash;
    }
    return nil;
}

@end
