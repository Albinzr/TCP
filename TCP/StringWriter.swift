//
//  StringWriter.swift
//  TCP
//
//  Created by Cameron Pulsford on 12/26/14.
//  Copyright (c) 2014 SMD. All rights reserved.
//

import Foundation

public class StringWriter: DataWriter {

    public convenience init?(string: String, encoding: NSStringEncoding) {
        if let data = string.dataUsingEncoding(encoding, allowLossyConversion: true) {
            self.init(data: data)
        } else {
            self.init(data: NSData())
            return nil
        }
    }

}