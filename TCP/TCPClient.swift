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

public class TCPClient: NSObject, NSStreamDelegate {

    /// Set and retrieve your connection delegate.
    public weak var delegate: TCPClientDelegate?

    /// Set and retrieve your delegate queue. The default is the main queue.
    lazy public var delegateQueue = dispatch_get_main_queue()

    /// Returns a copy of the NSURL that was used to initialize the connection.
    public private(set) var url: NSURL

    /// Returns a copy of the TCPClientConfiguration that was used to initialize the connection.
    public private(set) var configuration: TCPClientConfiguration

    /// Returns true if the connection is open; otherwise, false.
    public private(set) var open = false

    /// Set this property to true to enable SSL on the connection. This property defaults to false but will be implicitly set to true if the scheme of the initializing NSURL is "https".
    public var secure = false

    /// Set this property to true to ignore invalid SSL certificates. The property defaults to false. This property is ignored if secure is set to false.
    public var allowInvalidCertificates = false

    private var writers = [Writer]()
    private var inputStream: NSInputStream!
    private var outputStream: NSOutputStream!
    lazy private var workQueue = dispatch_queue_create("com.smd.tcp.tcpClientQueue", DISPATCH_QUEUE_SERIAL)
    private var opensCompleted = 0

    /**
    Initializes a new TCPClient with the given NSURL and TCPClientConfiguration.

    :param: url           The NSURL to connect to. This property is copied in.
    :param: configuration The TCPClientConfiguration. This property is copied in.

    :returns: An initialized TCPClient that is ready to connect.
    */
    public init(url: NSURL, configuration: TCPClientConfiguration) {
        self.url = url.copy() as NSURL
        self.configuration = configuration.copy() as TCPClientConfiguration
        super.init()
        self.secure = isURLSecure(url)
    }

    /**
    Connect to the initialzing NSURL.

    :returns: true if the connection opened properly; otherwise, false if the stream could not connect or is already connected.
    */
    public func connect() -> Bool {
        objc_sync_enter(self)
        
        var success = false

        if !open && createStreams() && configureStreams(inputStream: inputStream, outputStream: outputStream) {
            prepareForOpenStreams()
            openStreams()
            success = true
            open = true
        }

        if !success {
            disconnect()
        }

        objc_sync_exit(self)

        return success
    }

    /**
    Disconnect the connection. The tcpClientDidDisconnectWithError method will not be called.
    */
    public func disconnect() {
        objc_sync_enter(self)

        if open {
            open = false
            
            dispatch_async(workQueue) {
                self.inputStream.delegate = nil
                self.outputStream.delegate = nil
                self.inputStream.close()
                self.outputStream.close()
                self.inputStream = nil
                self.outputStream = nil
                self.open = false
                self.writers.removeAll(keepCapacity: false)
            }
        }

        objc_sync_exit(self)
    }

    // MARK: Writing

    /**
    Add a new writer. If the connection is not currently open, this write will be queued.

    :param: writer The writer.
    */
    public func write(writer: Writer) {
        dispatch_async(workQueue) {
            self.writers.append(writer)

            if self.open {
                self.write()
            }
        }
    }

    /**
    Write raw data. If the connection is not currently open, this write will be queued.

    :param: data The data.
    */
    public func write(data: NSData) {
        write(DataWriter(data: data))
    }

    /**
    Write raw data and a line delimiter. If the connection is not currently open, this write will be queued.

    :param: data      The data.
    :param: delimiter The line delimiter.
    */
    public func write(data: NSData, delimiter: LineDelimiter) {
        write(DataWriter(data: data, delimiter: delimiter))
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
            dispatch_async(workQueue) {
                self.read()
            }
        case NSStreamEvent.HasSpaceAvailable:
            writeInBackground()
        case NSStreamEvent.ErrorOccurred:
            fallthrough
        case NSStreamEvent.EndEncountered:
            let error = aStream.streamError
            disconnectWithError(error)
        default:
            break
        }
    }

    // MARK: Methods to subclass

    /**
    Return the port for the given NSURL. If a port is present it will be used, otherwise it will return 80. Additionally, if no port is provided, port 443 will be returned if the scheme of the NSURL is "https".

    :param: url The NSURL with which to determine a port.

    :returns: The port to connect to given an NSURL.
    */
    public func portForURL(url: NSURL) -> Int {
        var port: Int = 80

        if let p = url.port {
            port = p.integerValue
        } else if let scheme = url.scheme {
            if scheme == "https" {
                port = 443;
            }
        }

        return port
    }

    /**
    Checks the scheme of the given NSURL and returns true if is "https". Override this method as necessary.

    :param: url The NSURL.

    :returns: true if the connection should start in secure mode; otherwise, false.
    */
    public func isURLSecure(url: NSURL) -> Bool {
        var secure = false

        if let scheme = url.scheme {
            if scheme == "https" {
                secure = true
            }
        }

        return secure
    }

    /**
    Called when the connection connects. This method will call the appropriate delegate method and attempt to kick the write queue. Override this method to insert any additional logic and be sure to call super.
    */
    public func didConnect() {
        dispatch_async(delegateQueue) {
            var _ = self.delegate?.tcpClientDidConnect?(self)
        }

        writeInBackground()
    }

    /**
    Called when the connection disconnects. This method will call the appropriate delegate method. Override this method to insert any additional logic and be sure to call super.

    :param: error The error that caused the stream to disconnect, or nil.
    */
    public func didDisconnectWithError(error: NSError?) {
        dispatch_async(delegateQueue) {
            var _ = self.delegate?.tcpClientDidDisconnectWithError?(self, streamError: error)
        }
    }

    /**
    This method is called as a part of opening the connection. It sets up SSL support. Override this method to configure additional properties as needed, and be sure to call super.

    :param: inputStream  The inputStream.
    :param: outputStream The outputStream.

    :returns: true if configuration was successful; otherwise, false. If false, the connect method will also return false.
    */
    public func configureStreams(#inputStream: NSInputStream!, outputStream: NSOutputStream!) -> Bool {
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

    /**
    This method is called before the streams open, and after configureStreams. Prepare any other data structures you may need and be sure to call super.
    */
    public func prepareForOpenStreams() {
        configuration.reader.client = self
        configuration.reader.prepare()
        opensCompleted = 0
        writers.removeAll(keepCapacity: false)
    }

    // MARK: Private

    private func host() -> String {
        return url.host!
    }

    private func disconnectWithError(error: NSError?) {
        disconnect()
        didDisconnectWithError(error)
    }

    private func createStreams() -> Bool {
        var iStream: NSInputStream?
        var oStream: NSOutputStream?
        NSStream.getStreamsToHostWithName(host(), port: portForURL(url), inputStream: &iStream, outputStream: &oStream)

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

    private func writeInBackground() {
        dispatch_async(workQueue) {
            self.write()
        }
    }

    private func write() {
        while self.open && self.writers.count > 0 && self.outputStream.hasSpaceAvailable {
            let writer = self.writers[0]
            let (complete, error) = writer.writeToStream(self.outputStream)

            if complete {
                self.writers.removeAtIndex(0)
            }

            if let e = error {
                self.disconnectWithError(e)
                break
            }
        }
    }

}
