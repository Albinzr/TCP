//
//  AppDelegate.swift
//  Stream
//
//  Created by Cameron Pulsford on 12/26/14.
//  Copyright (c) 2015 SMD. All rights reserved.
//

import UIKit
import TCP

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, TCPClientDelegate {

    var window: UIWindow?
    var client: TCPClient!

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        window?.rootViewController = ViewController()
        window?.makeKeyAndVisible()
        echo()
        return true
    }

    func echo() {
        if let url = NSURL(string: "wss://10.0.1.200:9108") {
            let reader = LineReader()
            reader.stringCallbackBlock = { client, data in
                println("'\(data)'")
            }

            client = WebsocketClient(url: url, configuration: TCPClientConfiguration(reader: reader), protocols: ["rpm-protocol"])
            client.delegate = self
            client.allowInvalidCertificates = true
            client.connect()
        }
    }

    func tcpClientDidConnect(client: TCPClient) {
        println("client did connect")
    }

    func tcpClientDidDisconnectWithError(client: TCPClient, streamError: NSError?) {
        println("client did disconnect with error \(streamError)")
    }

}

