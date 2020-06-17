//
//  ViewController.m
//  PocketCore
//
//  Created by Jazys on 2020/6/16.
//  Copyright © 2020 QuarkChain. All rights reserved.
//

#import "ViewController.h"
#import "QWWalletManager+Keystore.h"
#import "QWKeystore.h"
#import "QWWalletManager+Account.h"
#import "QWETHClient.h"
#import <Geth/Geth.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [[QWWalletManager defaultManager] createWalletWithPassword:@"abcd1234" completion:^(QWWallet *wallet, NSError *error) {
        
    }];
    
    [[QWWalletManager defaultManager] createWalletWithPhrase:@"bottom update bamboo screen lion citizen mountain hint pottery ivory safe curve" withPassword:@"abcd1234" completion:^(QWWallet *account, NSError *error) {
        
    }];
    
    [[QWWalletManager defaultManager] createWalletWithPrivateKey:@"0x3f03a9560a73440dce5be1681a97fcab2ea892915d4198246f1d3d7d603b284e" withPassword:@"abcd1234" type:QWWalletCoinTypeETH completion:^(QWWallet *account, NSError *error) {
        
    }];
    
    [[QWWalletManager defaultManager] createWalletWithAddress:@"0x38590A2fDCBbfABaa763002A0AF322e1471B67CD" type:QWWalletCoinTypeETH completion:^(QWWallet *wallet, NSError *error) {
        
    }];
    
//    [[QWWalletManager defaultManager] exportPhraseForWallet:<#(QWWallet *)#> withPassword:@"abcd1234" completion:^(NSString *phrase, NSError *error) {
//
//    }];
    
    /*
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
    */
}


@end
