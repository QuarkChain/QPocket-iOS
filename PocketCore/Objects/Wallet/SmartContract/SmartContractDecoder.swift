//
//  SmartContractDecoder.swift
//  GethTest
//
//  Created by zhuqiang on 2018/8/13.
//  Copyright © 2018 freedostudio. All rights reserved.
//

import Foundation
import BigInt
@objc class SmartContractDecoder : NSObject {
    
    @objc public static func decodeReturnedString(response: String) throws -> String {
        let data = Data(hex: response)
        let decoder = ABIDecoder(data: data)
        try decoder.decodeUInt()
        return try decoder.decodeString()
    }
    
    @objc public static func decodeReturnedValuesForGetNativeTokenInfo(response: String) throws -> Dictionary<String, Any> {
        let data = Data(hex: response)
        let decoder = ABIDecoder(data: data)
        let createTime = try decoder.decode(type: .uint(bits: 64)).nativeValue as! BigUInt
        let owner = try decoder.decodeAddress()
        let totalSupply = try decoder.decode(type: .uint(bits: 256)).nativeValue as! BigUInt
        return ["createTime":createTime.description, "owner":owner.description, "totalSupply":totalSupply.description]
   }
    
    @objc public static func decodeReturnedValuesForGasReserves(response: String) throws -> Dictionary<String, Any> {
        let data = Data(hex: response)
        let decoder = ABIDecoder(data: data)
        let admin = try decoder.decodeAddress()
        let refundPercentage = try decoder.decode(type: .uint(bits: 64)).nativeValue as! BigUInt
        let components = try decoder.decodeTuple(types: [.uint(bits: 128), .uint(bits:128)])
        let numerator = components[0].nativeValue as! BigUInt
        let denominator = components[1].nativeValue as! BigUInt
        return ["admin":admin.description, "refundPercentage":refundPercentage.description, "numerator":numerator.description, "denominator":denominator.description]
    }
    
    @objc public static func decodeReturnedValuesForGasReserveBalance(response: String) throws -> Dictionary<String, Any> {
        let data = Data(hex: response)
        let decoder = ABIDecoder(data: data)
        let gasReserveBalance = try decoder.decode(type: .uint(bits: 256)).nativeValue as! BigUInt
        return ["gasReserveBalance":gasReserveBalance.description]
    }
    
    @objc public static func decodeReturnedUint256(response: String) throws -> String {
        let data = Data(hex: response)
        let decoder = ABIDecoder(data: data)
        let ret = try decoder.decodeUInt()
        return ret.description
    }
    
    @objc public static func decodeTransfer(response: String) throws -> Dictionary<String, Any> {
        let data = Data(hex: response)
        let decoder = ABIDecoder(data: data)
        let function = Function(name: "transfer", parameters: [.address, .uint(bits: 256)])
        let (_, params) = try decoder.decode(function: function).nativeValue as! (Function, [ABIValue])
        return ["address":(params[0].nativeValue as! Address).eip55String, "amount":String((params[1].nativeValue as! BigUInt))]
    }
    
}
