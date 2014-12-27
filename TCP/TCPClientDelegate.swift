//
//  TCPClientDelegate.swift
//  Stream
//
//  Created by Cameron Pulsford on 12/26/14.
//  Copyright (c) 2014 SMD. All rights reserved.
//

import Foundation

@objc public protocol TCPClientDelegate {

    optional func tcpClientDidConnect(client: TCPClient)

    optional func tcpClientDidDisconnectWithError(client: TCPClient, streamError: NSError?)

}
