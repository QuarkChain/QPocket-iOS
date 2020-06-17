# PocketCore
PocketCore is the main code of QPocket with the logic part of the UI removed. Based on the Realm database, that allows you to manage your wallets and sign transactions in BTC, ETH, TRX and QKC chains simultaneously, Notes: "phrase" also known as "mnemonic" in the code.

## Getting Started
1. Download the Xcode 11 release.
2. Clone this repository.
3. Run `pod install` to install tools and dependencies.

## Features

With the QPocket Wallet you can send and receive QuarkChain,Ethereum,Tron,Bitcoins using your mobile phone.

 - HD enabled - manage multiple accounts and never reuse addresses ([Bip32](https://github.com/bitcoin/bips/blob/master/bip-0032.mediawiki)/[Bip44](https://github.com/bitcoin/bips/blob/master/bip-0044.mediawiki) compatible)
 - Masterseed based - make one backup and be safe for ever. ([Bip39](https://github.com/bitcoin/bips/blob/master/bip-0039.mediawiki))
 - 100% control over your private keys, they never leave your device unless you export them
 - Watch-only addresses (single or xPub) & private key import for secure cold-storage integration
 - Secure your wallet with a PIN

Please note: while we make sure to adhere to the highest standards of software craftsmanship we can not exclude that the software contains bugs. Please make sure you have backups of your private keys and do not use this for more than you are willing to lose.

More features:

 - Sources [available for review](https://github.com/QuarkChain/QPocket-iOS)
 - Multiple HD accounts, private keys,keystore accounts or external xPub accounts
 - HD Wallet supports creating unlimited sub wallets
 - Transaction history with detailed information and local stored comments
 - Export private-, keystore- or mnemonic
 - Sign Messages using your private keys

## Some API examples
### Create a new HD Wallet(QKC, BTC, TRX, ETH)
```objc
[[QWWalletManager defaultManager] createWalletWithPassword:@"abcd1234" completion:^(QWWallet *wallet, NSError *error) {
        
    }];
```
### Import a HD wallet using phrase
```objc
[[QWWalletManager defaultManager] createWalletWithPhrase:@"bottom update bamboo screen lion citizen mountain hint pottery ivory safe curve" withPassword:@"abcd1234" completion:^(QWWallet *account, NSError *error) {
        
    }];
```
### Import a wallet by private key
```objc
[[QWWalletManager defaultManager] createWalletWithPrivateKey:@"0x3f03a9560a73440dce5be1681a97fcab2ea892915d4198246f1d3d7d603b284e" withPassword:@"abcd1234" type:QWWalletCoinTypeETH completion:^(QWWallet *account, NSError *error) {
        
    }];
```
### Watch an address
```objc
[[QWWalletManager defaultManager] createWalletWithAddress:@"0x38590A2fDCBbfABaa763002A0AF322e1471B67CD" type:QWWalletCoinTypeETH completion:^(QWWallet *wallet, NSError *error) {
        
    }];
```
### Export a wallet's phrase
```objc
[[QWWalletManager defaultManager] exportPhraseForWallet:<#(QWWallet *)#> withPassword:@"abcd1234" completion:^(NSString *phrase, NSError *error) {
        
    }];
```

### Send & Sign a transaction
```objc
GethKeyStore *keystore = [QWWalletManager defaultManager].keystore.gethKeystore;
    GethAccount *account = [[QWWalletManager defaultManager].keystore gethAccountWithKeystoreName:[QWWalletManager defaultManager].currentAccount.keystoreName];
    [[QWWalletManager defaultManager].network.ethClient sendTransactionSignedByKeyStore:keystore
                                                                            fromAddress:keystore.getAddress
                                                                                  nonce:transactionParams[@"nonce"]
                                                                               gasPrice:transactionParams[@"gasPrice"]
                                                                               gasLimit:transactionParams[@"gasLimit"]
                                                                                     to:transactionParams[@"to"]
                                                                                  value:transactionParams[@"value"]
                                                                                   data:transactionParams[@"data"]
                                                                                success:^(NSString *transactionId) {
        
    } failure:^(NSError *error) {

    }];
```
