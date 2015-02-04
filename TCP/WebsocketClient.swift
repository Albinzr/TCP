//
//  WebsocketClient.swift
//  Stream
//
//  Created by Cameron Pulsford on 2/3/15.
//  Copyright (c) 2015 SMD. All rights reserved.
//

import Foundation

public class WebsocketClient: TCPClient {

    public private(set) var protocols = [String]()
    private var secKey = ""

    public init(url: NSURL, configuration: TCPClientConfiguration, protocols: [String]) {
        super.init(url: url, configuration: configuration)
        self.protocols = protocols
    }

    public override func portForURL(url: NSURL) -> Int {
        var port: Int = super.portForURL(url)

        if let p = url.port {
            port = p.integerValue
        } else if let scheme = url.scheme {
            if scheme == "wss" {
                port = 443;
            }
        }

        return port
    }

    public override func isURLSecure(url: NSURL) -> Bool {
        var secure = super.isURLSecure(url)

        if let scheme = url.scheme {
            if scheme == "wss" {
                secure = true
            }
        }

        return secure
    }

    public override func didConnect() {
        upgrade()
    }

    private func upgrade() {
        let upgrade = NSMutableURLRequest(URL: url)

        let keyBytes = NSMutableData(length: 16)

        if let key = keyBytes {
            SecRandomCopyBytes(kSecRandomDefault, UInt(key.length), UnsafeMutablePointer<UInt8>(key.mutableBytes))
            secKey = key.base64EncodedStringWithOptions(NSDataBase64EncodingOptions(0))
        }

        upgrade.setValue("websocket", forHTTPHeaderField: "Upgrade")
        upgrade.setValue("Upgrade", forHTTPHeaderField: "Connection")
        upgrade.setValue(secKey, forHTTPHeaderField: "Sec-WebSocket-Key")
        upgrade.setValue("13", forHTTPHeaderField: "Sec-WebSocket-Version")
        upgrade.setValue("https://10.0.1.200:9108", forHTTPHeaderField: "Origin")
        upgrade.setValue(", ".join(protocols), forHTTPHeaderField: "Sec-WebSocket-Protocol")

        self.write(URLRequestWriter(request: upgrade))
    }

}
