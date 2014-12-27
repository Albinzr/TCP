//
//  DataWriter.swift
//  TCP
//
//  Created by Cameron Pulsford on 12/26/14.
//  Copyright (c) 2014 SMD. All rights reserved.
//

import Foundation

public class DataWriter: Writer {

    public var cursor: Int = 0
    public var data: NSData


    public init(data: NSData) {
        self.data = data
    }

    public convenience init(data: NSData, delimiter: LineDelimiter) {
        let mData = NSMutableData(data: data)

        if let delimiterData = delimiter.lineData {
            mData.appendData(delimiterData)
        }
        
        self.init(data: mData)
    }

    public func writeToStream(stream: NSOutputStream) -> (complete: Bool, bytesWritten: Int) {
        let bytesLeft = data.length - self.cursor
        let bytesWritten = stream.write(UnsafeMutablePointer<UInt8>(data.bytes) + cursor, maxLength: bytesLeft)

        if bytesWritten > 0 {
            cursor += bytesWritten
        }

        return (cursor == data.length, bytesWritten)
    }

}
