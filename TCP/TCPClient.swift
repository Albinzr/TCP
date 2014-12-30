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

public class TCPClient: NSObject, NSStreamDelegate {

    public weak var delegate: TCPClientDelegate?
    public private(set) var url: NSURL
    public private(set) var configuration: TCPClientConfiguration
    public private(set) var open = false
    public var secure = false
    public var allowInvalidCertificates = false

    var inputStream: NSInputStream!
    var outputStream: NSOutputStream!
    var writers = [Writer]()

    private var opensCompleted = 0

    public init(url: NSURL, configuration: TCPClientConfiguration) {
        self.url = url
        self.configuration = configuration
    }

    public func connect() -> Bool {
        var success = false

        if !open && createStreams() && configureStreams() {
            prepareForOpenStreams()
            openStreams()
            success = true
            open = true
        }

        if !success {
            disconnect()
        }

        return success
    }

    public func disconnect() {
        if open {
            inputStream.delegate = nil
            outputStream.delegate = nil
            inputStream.close()
            outputStream.close()
            inputStream = nil
            outputStream = nil
            open = false
            writers.removeAll(keepCapacity: false)
        }
    }

    // MARK: Writing

    public func write(writer: Writer) {
        writers.append(writer)

        if open {
            write()
        }
    }

    // MARK: NSStreamDelegate methods

    public func stream(aStream: NSStream, handleEvent eventCode: NSStreamEvent) {
        switch eventCode {
        case NSStreamEvent.OpenCompleted:
            opensCompleted++

            if opensCompleted == 2 {
                didConnect()
            }
        case NSStreamEvent.HasBytesAvailable:
            read()
        case NSStreamEvent.HasSpaceAvailable:
            write()
        case NSStreamEvent.ErrorOccurred:
            fallthrough
        case NSStreamEvent.EndEncountered:
            let error = aStream.streamError
            disconnect()
            didDisconnectWithError(error)
        default:
            break
        }
    }

    // MARK: Methods to subclass

    public func host() -> String {
        return url.host!
    }

    public func port() -> Int {
        return url.port!.integerValue
    }

    public func didConnect() {
        delegate?.tcpClientDidConnect?(self)
        write()
    }

    public func didDisconnectWithError(error: NSError?) {
        delegate?.tcpClientDidDisconnectWithError?(self, streamError: error)
    }

    public func configureStreams() -> Bool {
        if secure {
            outputStream.setProperty(kCFStreamSocketSecurityLevelNegotiatedSSL, forKey: kCFStreamPropertySocketSecurityLevel)

            var sslOptions = [String:AnyObject]()

            if allowInvalidCertificates {
                sslOptions[kCFStreamSSLValidatesCertificateChain as String] = false
            }

            outputStream.setProperty(sslOptions, forKey: kCFStreamPropertySSLSettings)
        }

        return true
    }

    public func prepareForOpenStreams() {
        configuration.reader.client = self
        configuration.reader.prepare()
        opensCompleted = 0
        writers.removeAll(keepCapacity: false)
    }

    // MARK: Private

    private func createStreams() -> Bool {
        var iStream: NSInputStream?
        var oStream: NSOutputStream?
        NSStream.getStreamsToHostWithName(host(), port: port(), inputStream: &iStream, outputStream: &oStream)

        if iStream != nil && oStream != nil {
            inputStream = iStream!
            outputStream = oStream!
            inputStream.delegate = self
            outputStream.delegate = self
            return true
        } else {
            return false
        }
    }

    private func openStreams() {
        let runLoop = NSRunLoop.currentRunLoop()
        let mode = NSDefaultRunLoopMode
        inputStream.scheduleInRunLoop(runLoop, forMode: mode)
        outputStream.scheduleInRunLoop(runLoop, forMode: mode)
        inputStream.open()
        outputStream.open()
    }

    private func read() {
        var buffer = [UInt8](count: configuration.readSize, repeatedValue: 0)

        while inputStream.hasBytesAvailable {
            let bytesRead = inputStream.read(&buffer, maxLength: configuration.readSize)
            configuration.reader.handleData(NSData(bytes: &buffer, length: bytesRead))
        }
    }

    private func write() {
        if open {
            while writers.count > 0 && outputStream.hasSpaceAvailable {
                let writer = writers[0]
                let (complete, bytesWritten) = writer.writeToStream(outputStream)

                // TODO: Figure out interaction here with the stream event handler.
                // Just break and print errno for now
                if bytesWritten <= 0 {
                    println("error \(errno)")
                    break
                }

                if complete {
                    writers.removeAtIndex(0)
                }
            }
        }
    }

}
