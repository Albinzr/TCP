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

/**
*  This Reader implementation will parse all received data by the given line delimiter and call either the stringCallbackBlock or dataCallbackBlock. If both are set, stringCallbackBlock will be preferred.
*/
public class LineReader: SimpleReader {

    /// Set the desired LineDelimiter. The default is LineDelimiter.CRLF.
    public var lineDelimiter = LineDelimiter.CRLF

    /// Set the desired NSStringEncoding. The default is NSUTF8StringEncoding.
    public var stringEncoding = NSUTF8StringEncoding

    /// Set the stringCallbackBlock. This callback block will be preffered over the dataCallbackBlock if both are set.
    public var stringCallbackBlock: ((client: TCPClient!, string: String) -> ())!

    public var buffer: NSMutableData!
    public var lineDelimiterData: NSData!

    public override func prepare() {
        buffer = NSMutableData()
        lineDelimiterData = lineDelimiter.lineData
    }

    public override func handleData(data: NSData) {
        var searchRange = NSMakeRange(0, data.length)

        while searchRange.location < data.length {
            let rangeOfLineDelimiter = data.rangeOfData(lineDelimiterData, options: NSDataSearchOptions(rawValue: 0), range: searchRange)

            if rangeOfLineDelimiter.location == NSNotFound {
                buffer.appendBytes(data.bytes + searchRange.location, length: searchRange.length)
            } else {
                let location = searchRange.location
                let length = rangeOfLineDelimiter.location - location

                let callbackQueue = client.delegateQueue
                
                if callbackQueue != nil && (stringCallbackBlock != nil || dataCallbackBlock != nil) {
                    let lineData = NSData(bytes: data.bytes + location, length: length)
                    var allLineData: NSData! = nil

                    if buffer.length > 0 {
                        buffer.appendData(lineData)
                        allLineData = buffer
                        buffer = NSMutableData()
                    } else {
                        allLineData = lineData
                    }

                    if stringCallbackBlock != nil {
                        if let string = NSString(data: allLineData, encoding: self.stringEncoding) {
                            dispatch_async(callbackQueue) {
                                self.stringCallbackBlock(client: self.client, string: string)
                            }
                        }
                    } else {
                        dispatch_async(callbackQueue) {
                            self.dataCallbackBlock(client: self.client, data: allLineData)
                        }
                    }
                }
            }

            let offset = rangeOfLineDelimiter.location + rangeOfLineDelimiter.length
            searchRange.location = offset
            searchRange.length = data.length - offset
        }
    }
    
}