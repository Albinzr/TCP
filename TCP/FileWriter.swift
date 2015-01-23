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

public class FileWriter: DataWriter {

    public private(set) var url: NSURL
    public var bufferSize = 4096
    private var file: NSInputStream!
    private var attemptToFillBuffer = true

    /**
    Initializes a FileWriter.

    :param: filePath The path of the file you would like to write.

    :returns: An initialized FileWriter, or nil.
    */
    public init?(filePath: NSURL) {
        url = filePath
        super.init(data: NSData())

        if let stream = NSInputStream(URL: filePath) {
            file = stream
            file.open()
            streaming = true
        } else {
            return nil
        }
    }

    public override func nextDataChunk() -> (nextData: NSData?, error: NSError?) {
        var nextData: NSData?
        var error: NSError?

        if file.hasBytesAvailable {
            var buffer = [UInt8](count: bufferSize, repeatedValue: 0)
            let bytesRead = file.read(&buffer, maxLength: bufferSize)

            if bytesRead > 0 {
                nextData = NSData(bytes: buffer, length: bytesRead)
            } else {
                error = posixErrorFromErrno()
            }
        }

        return (nextData, error)
    }

}
