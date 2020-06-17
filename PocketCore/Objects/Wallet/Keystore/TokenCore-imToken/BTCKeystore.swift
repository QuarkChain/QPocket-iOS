//
//  BTCKeystore.swift
//  token
//
//  Created by xyz on 2018/1/3.
//  Copyright © 2018 ConsenLabs. All rights reserved.
//

import Foundation
//import CoreBitcoin

public extension BTCKey {
  public func address(on network: Network?, segWit: Bool) -> BTCAddress {
    if segWit {
      if isMainnet(network) {
        return witnessAddress
      } else {
        return witnessAddressTestnet
      }
    } else {
      if isMainnet(network) {
        return address
      } else {
        return addressTestnet
      }
    }
  }

  private func isMainnet(_ network: Network?) -> Bool {
    if let network = network {
      return network.isMainnet
    }
    return true
  }
}


@objc class BTCKeystore: NSObject, Keystore, WIFCrypto {
  @objc let id: String
  let version = 3
  @objc var address: String
  let crypto: Crypto
    var meta:[String:Any] = [:]

  // Import with private key (WIF).
    @objc init(password: String, wif: String, metadata: [String: Any], id: String? = nil) throws {
        var network = Network.mainnet
        if let testnet = metadata["testnet"] {
            if testnet as! Bool {
                network = Network.testnet
            }
        }
    let privateKey = try PrivateKeyValidator(wif, on: .btc, network: network, requireCompressed: metadata["isSegWit"] as! Bool).validate()

    let key = BTCKey(wif: wif)!
    address = key.address(on: network, segWit: metadata["isSegWit"] as! Bool).string

    crypto = Crypto(password: password, privateKey: privateKey.tk_toHexString())
    self.id = id ?? BTCKeystore.generateKeystoreId()
    meta = metadata
  }

  // MARK: - JSON
  @objc init(json: JSONObject) throws {
    guard
      let cryptoJson = (json["crypto"] as? JSONObject) ?? (json["Crypto"] as? JSONObject),
      json["version"] as? Int == version
    else {
      throw KeystoreError.invalid
    }

    id = (json["id"] as? String) ?? BTCKeystore.generateKeystoreId()
    address = json["address"] as? String ?? ""
    crypto = try Crypto(json: cryptoJson)

//    if let metaJSON = json[WalletMeta.key] as? JSONObject {
//      meta = try WalletMeta(json: metaJSON)
//    } else {
//      meta = WalletMeta(chain: .btc, source: .keystore)
//    }
  }

  func decryptWIF(_ password: String) -> String {
    let wif = crypto.privateKey(password: password).tk_fromHexString()
    let key = BTCKey(wif: wif)!
    if let testnet = meta["testnet"] {
        if testnet as! Bool {
            return key.wifTestnet
        }
    }
    return key.wif
  }

  func serializeToMap() -> [String: Any] {
    return [
      "id": id,
      "address": address,
      "createdAt": (meta["timestamp"] as! Int),
      "source": "KEYSTORE",
      "chainType": "BITCOIN",
        "segWit": meta["isSegWit"] as! Bool ? "P2WPKH" : "NONE"
    ]
  }
    
    @objc func getJSON() -> [String:Any] {
        return self.toJSON()
    }
    @objc func verifyPassword(password: String) -> Bool {
        return self.verify(password:password)
    }
}
