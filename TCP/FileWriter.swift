//
//  FileWriter.swift
//  Stream
//
//  Created by Cameron Pulsford on 1/1/15.
//  Copyright (c) 2015 SMD. All rights reserved.
//

import Foundation

public class FileWriter: Writer {

    public private(set) var url: NSURL
    public var bufferSize = 4096
    private var file: NSInputStream!
    private var cursor = 0

    public init?(filePath: NSURL) {
        url = filePath

        if let stream = NSInputStream(URL: filePath) {
            file = stream
            file.open()
        } else {
            return nil
        }
    }

    public func writeToStream(stream: NSOutputStream) -> (complete: Bool, bytesWritten: Int) {

        var bytesWritten = 0
        var complete = false

        if file.hasBytesAvailable {
            var buffer = [UInt8](count: bufferSize, repeatedValue: 0)
            let bytesRead = file.read(&buffer, maxLength: bufferSize)

            if bytesRead > 0 {
                bytesWritten = stream.write(&buffer, maxLength: bytesRead)
            } else if bytesRead == 0 {
                complete = true
            } else {
                // TODO: Write an error handler
                println("file read error")
            }
        } else {
            complete = true
        }

        return (complete, bytesWritten)
    }

}
