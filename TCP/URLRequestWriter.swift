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

public class URLRequestWriter: DataWriter {

    var url: NSURLRequest!

    public convenience init(request: NSURLRequest) {

        var method = "GET"

        if let urlMethod = request.HTTPMethod {
            method = urlMethod
        }

        let cfRequest = CFHTTPMessageCreateRequest(nil, method, request.URL, kCFHTTPVersion1_1).takeUnretainedValue()

        var host = ""

        if let address = request.URL.host {
            if let port = request.URL.port {
                host = "\(address):\(port)"
            } else {
                host = address
            }
        }

        CFHTTPMessageSetHeaderFieldValue(cfRequest, "Host", host)

        if let headers = request.allHTTPHeaderFields {
            for (field, value) in headers {
                CFHTTPMessageSetHeaderFieldValue(cfRequest, field as String, value as String)
            }
        }

        self.init(data: CFHTTPMessageCopySerializedMessage(cfRequest).takeUnretainedValue())
        url = request
    }

}
