//
//  StreamReadParser.swift
//  TCP
//
//  Created by Cameron Pulsford on 12/24/14.
//  Copyright (c) 2014 SMD. All rights reserved.
//

import Foundation

public protocol Reader {

    func prepare()

    func handleData(data: NSData)

}