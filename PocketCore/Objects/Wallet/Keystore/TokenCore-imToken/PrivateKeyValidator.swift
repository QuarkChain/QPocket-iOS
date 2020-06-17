//
//  PrivateKeyValidator.swift
//  token
//
//  Created by James Chen on 2016/10/08.
//  Copyright © 2016 imToken PTE. LTD. All rights reserved.
//

import Foundation
//import CoreBitcoin

public enum GenericError: String, Error {
  case importFailed = "import_failed"
  case generateFailed = "generate_failed"
  case deleteWalletFailed = "delete_wallet_failed"
  case walletNotFound = "wallet_not_found"
  case operationUnsupported = "operation_unsupported"
  case unknownError = "unknown_error"
  case unsupportedChain = "unsupported_chain"
  case storeWalletFailed = "store_wallet_failed"
  case paramError = "param_error"
  case wifWrongNetwork = "wif_wrong_network"
  case insufficientFunds = "insufficient_funds"
  case amountLessThanMinimum = "amount_less_than_minimum"
}

public enum PrivateKeyError: String, Error {
  case invalid = "privatekey_invalid"
  case wifInvalid = "wif_invalid"
  case publicKeyNotCompressed = "segwit_needs_compress_public_key"
}

protocol Validator {
  associatedtype Result

  var isValid: Bool { get }
  func validate() throws -> Result
}

public enum ChainType: String {
  case eth = "ETHEREUM"
  case btc = "BITCOIN"
  case eos = "EOS"

//  public var privateKeySource: WalletMeta.Source {
//    if self == .eth {
//      return .privateKey
//    }
//    return .wif
//  }
}

public enum Network: String {
  case mainnet = "MAINNET"
  case testnet = "TESTNET"

  var isMainnet: Bool {
    return self == .mainnet
  }
}

public struct PrivateKeyValidator: Validator {
  public typealias Result = String
  let privateKey: String
  private let chain: ChainType
  private let network: Network?
  private let requireCompressed: Bool

  public init(_ privateKey: String, on chain: ChainType, network: Network? = nil, requireCompressed: Bool = false) {
    self.privateKey = privateKey
    self.chain = chain
    self.network = network
    self.requireCompressed = requireCompressed
  }

  public var isValid: Bool {
    switch chain {
    case .btc:
      do {
        _ = try validateBtc()
        return true
      } catch {
        return false
      }
    case .eth:
      do {
        _ = try validateEth()
        return true
      } catch {
        return false
      }
    case .eos:
      do {
        _ = try validateEos()
        return true
      } catch {
        return false
      }
    }
  }

  public func validate() throws -> Result {
    switch chain {
    case .btc:
      return try validateBtc()
    case .eth:
      return try validateEth()
    case .eos:
      return try validateEos()
    }
  }

  private func validateBtc() throws -> Result {
    guard let key = BTCKey(wif: privateKey), key.privateKey != nil else {
      throw PrivateKeyError.wifInvalid
    }

    if requireCompressed && !key.isPublicKeyCompressed {
      throw PrivateKeyError.publicKeyNotCompressed
    }

    let wif = (network != nil && network!.isMainnet) ? key.wif : key.wifTestnet
    if wif != privateKey {
      throw GenericError.wifWrongNetwork
    }

    return privateKey
  }

  private func validateEth() throws -> Result {
    guard Encryptor.Secp256k1().verify(key: privateKey) else {
      throw PrivateKeyError.invalid
    }
    let pubKeyBytes = BTCKey(privateKey: privateKey.tk_dataFromHexString()).publicKey!
    let pubStr = (pubKeyBytes as Data).tk_toHexString()
    let stringToEncrypt = pubStr.tk_substring(from: 2)
    let isPubKeyValid = !stringToEncrypt.isEmpty
    if !isPubKeyValid {
      throw PrivateKeyError.invalid
    }
    return privateKey
  }

  private func validateEos() throws -> Result {
    guard let key = BTCKey(wif: privateKey), key.privateKey != nil else {
      throw PrivateKeyError.invalid
    }

    return privateKey
  }
}
