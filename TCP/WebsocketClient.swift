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
  
    public func send(#string :String) {
        if let data = string.dataUsingEncoding(NSUTF8StringEncoding) {
            send(data, opCode:.TextFrame)
        } else {
            //TODO: Deal with encoding error.
        }
    }
    
    public func send(#data :NSData) {
        send(data, opCode:.BinaryFrame)
    }
    
    private func send(data:NSData, opCode:OpCode) {
        
        var payloadLength = data.length
        
        let frameDataOptional = NSMutableData(capacity: payloadLength + 32)
        if frameDataOptional == nil {
            // TODO: message too big
            return;
        }
        let frameData = frameDataOptional!
        
        var byteHolder:Byte
        
        // set fin
        byteHolder = FinMask | opCode.rawValue
        frameData.appendBytes(&byteHolder, length: 1)
        byteHolder = 0

        let useMask = true
        
        if useMask {
            byteHolder |= MaskMask
        }
        
        var unmasked_payload = data
        
        if payloadLength < 126 {
            byteHolder =  byteHolder | Byte(payloadLength)
        } else if Int32(payloadLength) <= UINT16_MAX {
            byteHolder |= 126
            frameData.appendBytes(&byteHolder, length: 1)
            var payloadLengthUint16 = UInt16(payloadLength).bigEndian
            frameData.appendBytes(&payloadLengthUint16, length: sizeof(UInt16))
        } else {
            byteHolder |= 127
            frameData.appendBytes(&byteHolder, length: 1)
            var payloadLengthUint64 = UInt64(payloadLength).bigEndian
            frameData.appendBytes(&payloadLengthUint64, length: sizeof(UInt64))
        }
        
        if !useMask {
            frameData.appendData(unmasked_payload)
        } else {
            var maskKeyBytes:[Byte] = [Byte](count: 4, repeatedValue: 0)
            SecRandomCopyBytes(kSecRandomDefault, 4, &maskKeyBytes)
            
            frameData.appendBytes(&maskKeyBytes, length:maskKeyBytes.count)
            
            for i in 0..<payloadLength {
                var aByte:Byte = UnsafePointer<Byte>(unmasked_payload.bytes)[i] as Byte ^ maskKeyBytes[i % 4] as Byte
                frameData.appendBytes(&aByte, length:1)
            }
        }
        
        println("sending bytes \(frameData)")
        
        write(frameData)
    }
    
    private enum OpCode : Byte {
        case TextFrame = 0x1
        case BinaryFrame = 0x2
        //3-7Reserved
        case ConnectionClose = 0x8
        case Ping = 0x9
        case Pong = 0xA
        //B-F reserved
    }
    
    private enum StatusCode : Int {
        case Normal = 1000
        case GoingAway = 1001
        case ProtocolError = 1002
        case UnhandledType = 1003
        // 1004 reserved
        case NoStatusReceived = 1005
        // 1004-1006 reserved
        case InvalidUTF8 = 1007
        case PolicyViolated = 1008
        case MessageTooBig = 1009
    }
    
    let FinMask:Byte          = 0x80
    let OpCodeMask:Byte       = 0x0F
    let RsvMask:Byte          = 0x70
    let MaskMask:Byte         = 0x80
    let PayloadLenMask:Byte   = 0x7F

}
