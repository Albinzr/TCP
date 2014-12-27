//
//  DuplexStreamConfiguration.swift
//  TCP
//
//  Created by Cameron Pulsford on 12/24/14.
//  Copyright (c) 2014 SMD. All rights reserved.
//

import Foundation

public class TCPClientConfiguration {

    public var openTimeout = 60
    public var readSize = 4096
    public var reader: Reader

    public init(reader: Reader) {
        self.reader = reader
    }

}