/*
The MIT License (MIT)

Copyright (c) 2014 Cameron Pulsford

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
