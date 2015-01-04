/*
The MIT License (MIT)

Copyright (c) 2015 Cameron Pulsford

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
*/

import Foundation

public class DataWriter: Writer {

    public var streaming = false
    private var cursor: Int = 0
    private var data: NSData
    private var fillBuffer = true

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

    public func writeToStream(stream: NSOutputStream) -> (complete: Bool, error: NSError?) {
        var error: NSError?

        if streaming && fillBuffer {
            fillBuffer = false
            let (fd, fillError) = nextDataChunk()

            if let fillData = fd {
                data = fillData
            } else {
                data = NSData()
            }

            error = fillError
            cursor = 0
        }

        let bytesLeft = data.length - self.cursor
        var complete = false
        var bytesWritten = 0

        if error == nil && bytesLeft > 0 {
            bytesWritten = stream.write(UnsafeMutablePointer<UInt8>(data.bytes) + cursor, maxLength: bytesLeft)

            if bytesWritten > 0 {
                cursor += bytesWritten
            } else {
                error = posixErrorFromErrno()
            }

            if cursor == data.length {
                if streaming {
                    fillBuffer = true
                } else {
                    complete = true
                }
            }
        } else {
            complete = true
        }

        return (complete, error)
    }

    public func setStreaming(streaming: Bool) {

    }

    public func nextDataChunk() -> (nextData: NSData?, error: NSError?) {
        return (nil, nil)
    }

}
