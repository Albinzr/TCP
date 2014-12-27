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

public class StringWriter: DataWriter {

    public convenience init?(string: String, encoding: NSStringEncoding, allowLossyConversion: Bool, delimiter: LineDelimiter) {
        if let data = string.dataUsingEncoding(encoding, allowLossyConversion: allowLossyConversion) {
            self.init(data: data, delimiter: delimiter)
        } else {
            self.init(data: NSData())
            return nil
        }
    }

    public convenience init?(string: String, encoding: NSStringEncoding, allowLossyConversion: Bool) {
        self.init(string: string, encoding: encoding, allowLossyConversion: false, delimiter: LineDelimiter.CRLF)
    }

    public convenience init?(string: String, encoding: NSStringEncoding, delimiter: LineDelimiter) {
        self.init(string: string, encoding: encoding, allowLossyConversion: false, delimiter: delimiter)
    }

    public convenience init?(string: String, encoding: NSStringEncoding) {
        self.init(string: string, encoding: encoding, delimiter: LineDelimiter.CRLF)
    }

    public convenience init?(string: String, delimiter: LineDelimiter) {
        self.init(string: string, encoding: NSUTF8StringEncoding, delimiter: delimiter)
    }

    public convenience init?(string: String) {
        self.init(string: string, delimiter: LineDelimiter.CRLF)
    }

}