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
        test()
        return true
    }

    func test() {
        if let url = NSURL(string: "http://127.0.0.1:9000") {
            let reader = LineReader()
            reader.stringCallbackBlock = { client, string in
                client.write(FileWriter(filePath: NSBundle.mainBundle().URLForResource("testfile", withExtension: "txt")!)!)
            }

            client = TCPClient(url: url, configuration: TCPClientConfiguration(reader: reader))
            client.delegate = self
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

