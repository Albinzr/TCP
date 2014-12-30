//
//  AppDelegate.swift
//  Stream
//
//  Created by Cameron Pulsford on 12/26/14.
//  Copyright (c) 2014 SMD. All rights reserved.
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

        if let url = NSURL(string: "https://173.194.68.139:443") {
            let reader = LineReader()
            reader.dataCallbackBlock = { client, data in
                client.write(DataWriter(data: data, delimiter: LineDelimiter.CRLF))
            }

            client = TCPClient(url: url, configuration: TCPClientConfiguration(reader: reader))
            client.delegate = self
            client.secure = true
            client.connect()

            if let string = StringWriter(string: "Hello, world! 1") {
                client.write(string)
            }
        }

        return true
    }

    func tcpClientDidConnect(client: TCPClient) {
        println("client did connect")

        if let string = StringWriter(string: "Hello, world! 2") {
            client.write(string)
        }
    }

    func tcpClientDidDisconnectWithError(client: TCPClient, streamError: NSError?) {
        println("client did disconnect with error \(streamError)")
    }

}

