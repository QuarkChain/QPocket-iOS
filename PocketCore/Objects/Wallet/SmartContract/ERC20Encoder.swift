// Copyright © 2017-2018 Trust.
//
// This file is part of Trust. The full Trust copyright notice, including
// terms governing use, modification, and redistribution, is contained in the
// file LICENSE at the root of the source code distribution tree.

import BigInt
import Foundation

/// Encodes ERC20 function calls.
@objc public final class ERC20Encoder : NSObject{
    /// Encodes a function call to `totalSupply`
    ///
    
    @objc public static func encodeFunctionName(name: String) -> String {
        let function = Function(name: name, parameters: [])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [])
        return encoder.data.hexEncoded
    }
    
    /// Solidity function: `function totalSupply() public constant returns (uint);`
    @objc public static func encodeTotalSupply() -> String {
        return self.encodeFunctionName(name: "totalSupply")
    }

    /// Encodes a function call to `name`
    ///
    /// Solidity function: `string public constant name = "Token Name";`
    @objc public static func encodeName() -> String {
        return self.encodeFunctionName(name: "name")
    }

    /// Encodes a function call to `symbol`
    ///
    /// Solidity function: `string public constant symbol = "SYM";`
    @objc public static func encodeSymbol() -> String {
        return self.encodeFunctionName(name: "symbol")
    }

    /// Encodes a function call to `decimals`
    ///
    /// Solidity function: `uint8 public constant decimals = 18;`
    @objc public static func encodeDecimals() -> String {
        return self.encodeFunctionName(name: "decimals")
    }
    
    /// Encodes a function call to `buyRate`
    ///
    /// Solidity function: `uint256 public buyRate`
    @objc public static func encodeBuyRate() -> String {
        return self.encodeFunctionName(name: "buyRate")
    }

    /// Encodes a function call to `buy`
    ///
    /// Solidity function: `function buy() payable public`
    @objc public static func encodeBuy() -> Data {
        let function = Function(name: "buy", parameters: [])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [])
        return encoder.data
    }

    /// Encodes a function call to `balanceOf`
    ///
    /// Solidity function: `function balanceOf(address tokenOwner) public constant returns (uint balance);`
    @objc public static func encodeBalanceOf(addressString: String) -> String {
        let address : Address = Address(string: addressString)!
        let function = Function(name: "balanceOf", parameters: [.address])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [address])
        return encoder.data.hexEncoded
    }

    /// Encodes a function call to `allowance`
    ///
    /// Solidity function: `function allowance(address tokenOwner, address spender) public constant returns (uint remaining);`
    public static func encodeAllowance(owner: Address, spender: Address) -> Data {
        let function = Function(name: "allowance", parameters: [.address, .address])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [owner, spender])
        return encoder.data
    }

    /// Encodes a function call to `transfer`
    ///
    /// Solidity function: `function transfer(address to, uint tokens) public returns (bool success);`
    @objc public static func encodeTransfer(toString: String, tokensString: String) -> Data {
        let to : Address = Address(string: toString)!
        let tokens : BigUInt = BigUInt(tokensString, radix:10)!
        let function = Function(name: "transfer", parameters: [.address, .uint(bits: 256)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [to, tokens])
        return encoder.data
    }

    /// Encodes a function call to `approve`
    ///
    /// Solidity function: `function approve(address spender, uint tokens) public returns (bool success);`
    public static func encodeApprove(spender: Address, tokens: BigUInt) -> Data {
        let function = Function(name: "approve", parameters: [.address, .uint(bits: 256)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [spender, tokens])
        return encoder.data
    }

    /// Encodes a function call to `transferFrom`
    ///
    /// Solidity function: `function transferFrom(address from, address to, uint tokens) public returns (bool success);`
    public static func encodeTransfer(from: Address, to: Address, tokens: BigUInt) -> Data {
        let function = Function(name: "transferFrom", parameters: [.address, .address, .uint(bits: 256)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [from, to, tokens])
        return encoder.data
    }
    
    @objc public static func encodeStringAsBigUInt(string: String) -> Data {
        let bigUInt = BigUInt(string)!
        let encoder = ABIEncoder()
        try! encoder.encode(bigUInt)
        return encoder.data
    }
    
    @objc public static func encodeStringAsBigInt(string: String) -> Data {
        let bigInt = BigInt(string)!
        let encoder = ABIEncoder()
        try! encoder.encode(bigInt)
        return encoder.data
    }
    
    @objc public static func encodeArgumentsBalanceOf(addressString: String) -> Data {
        let address : Address = Address(string: addressString)!
        let function = Function(name: "balanceOf", parameters: [.address])
        let encoder = ABIEncoder()
        try! encoder.encodeArguments(function: function, arguments: [address])
        return encoder.data
    }
    
    @objc public static func encodeArgumentsTransfer(toString: String, tokensString: String) -> Data {
        let to : Address = Address(string: toString)!
        let tokens : BigUInt = BigUInt(tokensString, radix:10)!
        let function = Function(name: "transfer", parameters: [.address, .uint(bits: 256)])
        let encoder = ABIEncoder()
        try! encoder.encodeArguments(function: function, arguments: [to, tokens])
        return encoder.data
    }
    
    @objc public static func encodeGetNativeTokenInfo(tokenId: String) -> String {
        let function = Function(name: "getNativeTokenInfo", parameters: [.uint(bits: 128)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [BigUInt(tokenId, radix: 16)!])
        return encoder.data.hexEncoded
    }
    
    @objc public static func encodeGasReserves(tokenId: String) -> String {
        let function = Function(name: "gasReserves", parameters: [.uint(bits: 128)])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [BigUInt(tokenId, radix: 16)!])
        return encoder.data.hexEncoded
    }
    
    @objc public static func encodeGasReserveBalance(tokenId: String, owner: String) -> String {
        let function = Function(name: "gasReserveBalance", parameters: [.uint(bits: 128), .address])
        let encoder = ABIEncoder()
        try! encoder.encode(function: function, arguments: [BigUInt(tokenId, radix: 16)!, Address(string: owner)!])
        return encoder.data.hexEncoded
    }
    
}
