//
//  ViewController.swift
//  Stream
//
//  Created by Cameron Pulsford on 12/26/14.
//  Copyright (c) 2015 SMD. All rights reserved.
//

import UIKit
import TCP

class ViewController: UIViewController, TCPClientDelegate {
  var helloButton:UIButton!
  var client: WebsocketClient!
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.whiteColor()
    helloButton = UIButton.buttonWithType(UIButtonType.System) as UIButton
    helloButton.setTitle("Hello", forState: .Normal)
    view.addSubview(helloButton)
    helloButton.frame = CGRectMake(100, 100, 100, 100)
    helloButton.addTarget(self, action: Selector("helloButtonPressed"), forControlEvents: UIControlEvents.TouchUpInside)
    echo()
  }

  func helloButtonPressed() {
    client.send(string:"Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
  }
  
  override func didReceiveMemoryWarning() {
      super.didReceiveMemoryWarning()
      // Dispose of any resources that can be recreated.
  }
  
  func echo() {
    if let url = NSURL(string: "wss://echo.websocket.org") {
      let reader = SimpleReader()
      reader.dataCallbackBlock = { client, data in
        if let string = NSString(data: data, encoding:NSUTF8StringEncoding) {
          println("string from client: \(string)")
        } else {
            println("data from client: \(data)")
        }
        //client.write(data)
      }
      
      client = WebsocketClient(url: url, configuration: TCPClientConfiguration(reader: reader), protocols:[])
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

