//
//  TransactionUtils.swift
//  GethTest
//
//  Created by zhuqiang on 2018/8/6.
//  Copyright © 2018 freedostudio. All rights reserved.
//

import Foundation
import BigInt
import CryptoSwift

@objc public final class TransactionUtils: NSObject {
    
    @objc public static func oneRawTransactionRLP(items: [String: Any], signature: Data) -> Data?{
        guard let nonceString = items["nonce"] as? String else { return nil}
        guard let gasPriceString = items["gasPrice"] as? String else { return nil}
        guard let gasLimitString = items["gasLimit"] as? String else { return nil}
        guard let to = items["to"] as? Data else { return nil}
        guard let valueString = items["value"] as? String else { return nil}
        guard let data = items["data"] as? Data else { return nil}
        var chainID = items["chainID"] as? Int
        if (chainID == nil) {
            chainID = -1
        }
        guard let shardID = items["shardID"] as? Int else {return nil}
        guard let toShardID = items["toShardID"] as? Int else {return nil}
        
        let (r,s,v) = values(signature: signature, chainId: chainID!)
        let nonce = BigInt(nonceString)
        let gasPrice = BigInt(gasPriceString)
        let gasLimit = BigInt(gasLimitString)
        let value = BigInt(valueString)
        let elements: [Any?] = [nonce, gasPrice, gasLimit, shardID, toShardID, to, value, data, v, r, s]
        let rawTx = RLP.encode(elements)!
        return rawTx;
    }
    
    @objc public static func oneRLPHash(items: [String: Any], sha3:Bool) -> Data?{
           guard let nonceString = items["nonce"] as? String else { return nil}
           guard let gasPriceString = items["gasPrice"] as? String else { return nil}
           guard let gasLimitString = items["gasLimit"] as? String else { return nil}
           guard let to = items["to"] as? Data else { return nil}
           guard let valueString = items["value"] as? String else { return nil}
           guard let data = items["data"] as? Data else { return nil}
           guard let chainID = items["chainID"] as? Int else {return nil}
        guard let shardID = items["shardID"] as? Int else {return nil}
        guard let toShardID = items["toShardID"] as? Int else {return nil}
           
           let nonce = BigInt(nonceString)
           let gasPrice = BigInt(gasPriceString)
           let gasLimit = BigInt(gasLimitString)
           let value = BigInt(valueString)
           
           let elements: [Any?] = [nonce, gasPrice, gasLimit, shardID, toShardID, to, value, data, chainID, 0, 0]
           let sha3Object = SHA3(variant: .keccak256)
           guard let encoded = RLP.encode(elements) else {
               return nil
           }
           if sha3 == true {
               return Data(bytes: sha3Object.calculate(for: encoded.bytes))
           } else {
               return Data(bytes: encoded.bytes)
           }
       }
       
       @objc public static func oneRLPHash(items: [String: Any]) -> Data?{
           oneRLPHash(items: items, sha3: true)
       }
    
    @objc public static func ethRLPHash(items: [String: Any], sha3:Bool) -> Data?{
        guard let nonceString = items["nonce"] as? String else { return nil}
        guard let gasPriceString = items["gasPrice"] as? String else { return nil}
        guard let gasLimitString = items["gasLimit"] as? String else { return nil}
        guard let to = items["to"] as? Data else { return nil}
        guard let valueString = items["value"] as? String else { return nil}
        guard let data = items["data"] as? Data else { return nil}
        guard let chainID = items["chainID"] as? Int else {return nil}
        
        let nonce = BigInt(nonceString)
        let gasPrice = BigInt(gasPriceString)
        let gasLimit = BigInt(gasLimitString)
        let value = BigInt(valueString)
        
        let elements: [Any?] = [nonce, gasPrice, gasLimit, to, value, data, chainID, 0, 0]
        let sha3Object = SHA3(variant: .keccak256)
        guard let encoded = RLP.encode(elements) else {
            return nil
        }
        if sha3 == true {
            return Data(bytes: sha3Object.calculate(for: encoded.bytes))
        } else {
            return Data(bytes: encoded.bytes)
        }
    }
    
    @objc public static func ethRLPHash(items: [String: Any]) -> Data?{
        ethRLPHash(items: items, sha3: true)
    }
    
    @objc public static func qkcRLPHash(items: [String: Any]) -> Data?{
        guard let nonceString = items["nonce"] as? String else { return nil}
        guard let gasPriceString = items["gasPrice"] as? String else { return nil}
        guard let gasLimitString = items["gasLimit"] as? String else { return nil}
        guard let to = items["to"] as? Data else { return nil}
        guard let valueString = items["value"] as? String else { return nil}
        guard let data = items["data"] as? Data else { return nil}
        guard let fromFullShardIdString = items["fromFullShardId"] as? String else { return nil}
        guard let toFullShardIdString = items["toFullShardId"] as? String else { return nil}
        guard let networkIdString = items["networkId"] as? String else { return nil}
        guard let gasTokenIdString = items["gasTokenId"] as? String else { return nil }
        guard let transferTokenIdString = items["transferTokenId"] as? String else { return nil }
        
        let nonce = BigInt(nonceString)
        let gasPrice = BigInt(gasPriceString)
        let gasLimit = BigInt(gasLimitString)
        let value = BigInt(valueString)
        let fromFullShardId = serializeFullShardId(fullShardId:BigUInt(fromFullShardIdString)!)
        let toFullShardId = serializeFullShardId(fullShardId:BigUInt(toFullShardIdString)!)
        let networkId = BigInt(networkIdString)
        let gasTokenId = BigInt(gasTokenIdString, radix:16)
        let transferTokenId = BigInt(transferTokenIdString, radix:16)
        
        let elements: [Any?] = [nonce, gasPrice, gasLimit, to, value, data, networkId, fromFullShardId, toFullShardId, gasTokenId, transferTokenId]

        let sha3 = SHA3(variant: .keccak256)
        guard let encoded = RLP.encode(elements) else {
            return nil
        }
        return Data(bytes: sha3.calculate(for: encoded.bytes))
    }
    
    private static func serializeFullShardId(fullShardId: BigUInt) -> Data {
        
        let byteCount = (fullShardId.bitWidth + 7) / 8
        
        var dataLength = byteCount
        
        if dataLength < 4 {
            dataLength = 4;
        }
        
        var data = Data(count: dataLength)
        
        data.resetBytes(in: 0..<dataLength)
        
        data.withUnsafeMutableBytes { (p: UnsafeMutablePointer<UInt8>) -> Void in
            var i = dataLength - 1
            for var word in fullShardId.words {
                for _ in 0 ..< UInt.bitWidth / 8 {
                    p[i] = UInt8(word & 0xFF)
                    word >>= 8
                    if i == 0 {
                        assert(word == 0)
                        break
                    }
                    i -= 1
                }
            }
        }
        return data
    }
    
    @objc public static func ethRawTransactionRLP(items: [String: Any], signature: Data) -> Data?{
        guard let nonceString = items["nonce"] as? String else { return nil}
        guard let gasPriceString = items["gasPrice"] as? String else { return nil}
        guard let gasLimitString = items["gasLimit"] as? String else { return nil}
        guard let to = items["to"] as? Data else { return nil}
        guard let valueString = items["value"] as? String else { return nil}
        guard let data = items["data"] as? Data else { return nil}
        var chainID = items["chainID"] as? Int
        if (chainID == nil) {
            chainID = -1
        }
        
        let (r,s,v) = values(signature: signature, chainId: chainID!)
        let nonce = BigInt(nonceString)
        let gasPrice = BigInt(gasPriceString)
        let gasLimit = BigInt(gasLimitString)
        let value = BigInt(valueString)
        let elements: [Any?] = [nonce, gasPrice, gasLimit, to, value, data, v, r, s]
        let rawTx = RLP.encode(elements)!
        return rawTx;
    }
    
    @objc public static func qkcRawTransactionRLP(items: [String: Any], signature: Data) -> String?{
        guard let nonceString = items["nonce"] as? String else { return nil}
        guard let gasPriceString = items["gasPrice"] as? String else { return nil}
        guard let gasLimitString = items["gasLimit"] as? String else { return nil}
        guard let to = items["to"] as? Data else { return nil}
        guard let valueString = items["value"] as? String else { return nil}
        guard let data = items["data"] as? Data else { return nil}
        guard let fromFullShardIdString = items["fromFullShardId"] as? String else { return nil}
        guard let toFullShardIdString = items["toFullShardId"] as? String else { return nil}
        guard let networkIdString = items["networkId"] as? String else { return nil}
        guard let gasTokenIdString = items["gasTokenId"] as? String else { return nil }
        guard let transferTokenIdString = items["transferTokenId"] as? String else { return nil }
        
        let nonce = BigInt(nonceString)
        let gasPrice = BigInt(gasPriceString)
        let gasLimit = BigInt(gasLimitString)
        let value = BigInt(valueString)
        let fromFullShardId = serializeFullShardId(fullShardId: BigUInt(fromFullShardIdString)!)
        let toFullShardId = serializeFullShardId(fullShardId: BigUInt(toFullShardIdString)!)
        let networkId = BigInt(networkIdString)
        let version = BigInt("0")
        let gasTokenId = BigInt(gasTokenIdString, radix:16)
        let transferTokenId = BigInt(transferTokenIdString, radix:16)

        let (r,s,v) = values(signature: signature, chainId: 0)

        let elements: [Any?] = [nonce, gasPrice, gasLimit, to, value, data, networkId, fromFullShardId, toFullShardId, gasTokenId, transferTokenId, version, v, r, s]
        let rawTx = RLP.encode(elements)!
        return rawTx.hexEncoded;
    }

    @objc public static func transactionId(rawTxRLP: Data) -> String{
        return rawTxRLP.sha3(.keccak256).hexEncoded

    }
    
    private static func values(signature: Data, chainId: Int) -> (r: BigInt, s: BigInt, v: BigInt) {
        let r = BigInt(sign: .plus, magnitude: BigUInt(Data(signature[..<32])))
        let s = BigInt(sign: .plus, magnitude: BigUInt(Data(signature[32..<64])))
        var v = BigInt(signature[64])
        if chainId == -1 {
            
        } else {
            v += 27
            if chainId > 0 {
                v = BigInt(signature[64]) + 35 + BigInt(chainId) + BigInt(chainId)
            }
        }
        return (r,s,v)
    }
    
    @objc public static func getRSVFromData(data: Data) -> Dictionary<String, Any> {
        let (r,s,v) = values(signature: data, chainId: 0)
        return ["r":String(r, radix:16), "s":String(s, radix:16), "v":String(v, radix:16)]
    }
    
    @objc public static func dataFromUIntString(string: String) -> Data {
        let bigUInt = BigUInt(string)!;
        return bigUInt.serialize();
    }
    
}
