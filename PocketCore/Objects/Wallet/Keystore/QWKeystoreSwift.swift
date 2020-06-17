//
//  QWSwiftBridging.swift
//  QuarkWallet
//
//  Created by Jazys on 2018/8/13.
//  Copyright © 2018 QuarkChain. All rights reserved.
//

import Foundation
import CryptoSwift
//import EthereumCrypto

@objc public class QWKeystoreSwift : NSObject {
    
    @objc class public func MD5(data: Data) -> Data {
        return Data(bytes: Digest.md5(data.bytes))
    }
    
    @objc class public func SHA3_Keccak_256(data: Data) -> Data {
        return Data(bytes: Digest.sha3(data.bytes, variant: .keccak256))
    }
    
    @objc class func AES_CTR_Crypt(cipherText: Data, key: Data, iv: Data, isEncrypt: Bool) throws -> Data {
        let aesCipher = try AES(key: key.bytes, blockMode: CTR(iv: iv.bytes), padding: Padding.noPadding)
        return Data(bytes: try !isEncrypt ? aesCipher.decrypt(cipherText.bytes) : aesCipher.encrypt(cipherText.bytes))
    }
    
    @objc class func AES_CBC_Crypt(cipherText: Data, key: Data, iv: Data, isEncrypt: Bool) throws -> Data {
        let aesCipher = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes), padding: Padding.noPadding)
        return Data(bytes: try !isEncrypt ? aesCipher.decrypt(cipherText.bytes) : aesCipher.encrypt(cipherText.bytes))
    }
    
    @objc class func checksumStringEIP55(string: String) -> String {
        return Address.computeEIP55String(for: Data(hex: string))
    }
    
    @objc class func checksumStringQKC(string: String) -> String {
        let _string = string.replacingOccurrences(of: "0x", with: "")
        let stringIndex = _string.index(_string.startIndex, offsetBy: 40)
        var mainAddress = self.checksumStringEIP55(string: _string.substring(to: stringIndex))
        var fullShardId = _string.substring(from: stringIndex)
        let hashFullShardId = EthereumCrypto.hash(fullShardId.lowercased().data(using: .ascii)!).toHexString()
        fullShardId = ""
        for index in 40 ..< 48 {
            
            var strIndex = hashFullShardId.index(hashFullShardId.startIndex, offsetBy: index)
            // the nth letter should be uppercase if the nth digit of casemap is 1
            let hashInt = UInt8(String(hashFullShardId[strIndex]), radix: 16)!
            
            strIndex = _string.index(_string.startIndex, offsetBy: index);
            
            if (hashInt > 7) {
                fullShardId += String(_string[strIndex]).uppercased()
            } else {
                fullShardId += String(_string[strIndex]).lowercased()
            }
            
        }
        return mainAddress + fullShardId
    }
    
    @objc class func base58CheckEncoding(string: String) -> String {
        return String(base58CheckEncoding: Data(hex: string))
    }
    
    @objc class func base58CheckDecoding(string: String) -> Data? {
        return Data(base58CheckDecoding: string)
    }
    
    @objc class func sha256(data: Data) -> Data {
        return data.sha256()
    }
    
    @objc class func sha512(data: Data) -> Data {
        return data.sha512();
    }

}
