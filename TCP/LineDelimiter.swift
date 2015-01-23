//
//  LineDelimiter.swift
//  Stream
//
//  Created by Cameron Pulsford on 1/23/15.
//  Copyright (c) 2015 SMD. All rights reserved.
//

import Foundation

public enum LineDelimiter {
    case None
    case CR
    case LF
    case CRLF
    case Custom(NSData)
}

public extension LineDelimiter {

    public var lineData: NSData? {
        get {
            switch self {
            case .None:
                return nil
            case .CR:
                return NSData(bytes: "\r", length: 1)
            case .LF:
                return NSData(bytes: "\n", length: 1)
            case .CRLF:
                return NSData(bytes: "\r\n", length: 2)
            case .Custom(let data):
                return data
            }
        }
    }
    
}
