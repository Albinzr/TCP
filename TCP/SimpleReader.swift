//
//  SimpleReader.swift
//  TCP
//
//  Created by Cameron Pulsford on 12/24/14.
//  Copyright (c) 2014 SMD. All rights reserved.
//

import Foundation

public class SimpleReader: Reader {

    public weak var client: TCPClient!
    public var callbackQueue = dispatch_get_main_queue()
    public var dataCallbackBlock: ((client: TCPClient!, data: NSData) -> ())!

    public init() {
        
    }

    public func prepare() {

    }

    public func handleData(data: NSData) {
        if callbackQueue != nil && dataCallbackBlock != nil{
            dispatch_async(callbackQueue, {
                self.dataCallbackBlock(client: self.client, data: data)
            })
        }
    }

}
