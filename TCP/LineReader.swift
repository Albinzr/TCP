//
//  LineReader.swift
//  TCP
//
//  Created by Cameron Pulsford on 12/24/14.
//  Copyright (c) 2014 SMD. All rights reserved.
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

public class LineReader: SimpleReader {

    public var data: NSMutableData!
    public var lineDelimiter = LineDelimiter.CRLF
    public var lineDelimiterData: NSData!
    public var stringEncoding = NSUTF8StringEncoding
    public var stringCallbackBlock: ((string: String) -> ())!

    public override func prepare() {
        data = NSMutableData()
        lineDelimiterData = lineDelimiter.lineData
    }

    public override func handleData(data: NSData) {
        var searchRange = NSMakeRange(0, data.length)

        while searchRange.location < data.length {
            let range = data.rangeOfData(lineDelimiterData, options: NSDataSearchOptions(rawValue: 0), range: searchRange)

            if range.location == NSNotFound {
                self.data.appendData(data)
            } else {
                if callbackQueue != nil && (stringCallbackBlock != nil || dataCallbackBlock != nil) {
                    let lineData = NSData(bytes: data.bytes + searchRange.location, length: range.location - searchRange.location)
                    var allLineData: NSData! = nil

                    if self.data.length > 0 {
                        self.data.appendData(lineData)
                        allLineData = self.data as NSData
                        self.data = NSMutableData()
                    } else {
                        allLineData = lineData
                    }

                    if stringCallbackBlock != nil {
                        if let string = NSString(data: allLineData, encoding: self.stringEncoding) {
                            dispatch_async(callbackQueue, {
                                self.stringCallbackBlock(string: string)
                            })
                        }
                    } else {
                        dispatch_async(callbackQueue, {
                            self.dataCallbackBlock(data: allLineData)
                        })
                    }
                }
            }

            let seek = range.location + range.length
            searchRange.location += seek
            searchRange.length -= seek
        }
    }

}