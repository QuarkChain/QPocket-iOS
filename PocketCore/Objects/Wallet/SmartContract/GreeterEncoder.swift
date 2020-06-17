//
//  GreeterEncoder.swift
//  GethTest
//
//  Created by zhuqiang on 2018/8/8.
//  Copyright © 2018 freedostudio. All rights reserved.
//

import Foundation

@objc public final class GreeterEncoder : NSObject{
    public static func greet() -> String {
        let function = Function(name: "greet", parameters: [])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [])
        return encoder.data.hexEncoded
    }
    public static func setGreeting() -> Data {
        let function = Function(name: "setGreeting", parameters: [.string])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: ["lala"])
        return encoder.data
    }
}
