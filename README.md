# PocketCore
PocketCore is the main code of QPocket with the logic part of the UI removed. Based on the Realm database, that allows you to manage your wallets and sign transactions in BTC, ETH, TRX and QKC chains simultaneously, Notes: "phrase" also known as "mnemonic" in the code.

## Installation
Download this repository, cd into the download path using terminal, then

```
pod install
```

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


## Copyright and License

```
  Copyright 2019 QuarkChain PTE. LTD.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
```
