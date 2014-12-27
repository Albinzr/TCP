//
//  DuplexStream.swift
//  TCP
//
//  Created by Cameron Pulsford on 12/24/14.
//  Copyright (c) 2014 SMD. All rights reserved.
//

import Foundation

public class TCPClient: NSObject, NSStreamDelegate {

    public weak var delegate: TCPClientDelegate?
    public private(set) var host: String
    public private(set) var port: Int
    public private(set) var configuration: TCPClientConfiguration
    public private(set) var open = false

    var inputStream: NSInputStream!
    var outputStream: NSOutputStream!
    var writers: [Writer]!

    private var opensCompleted = 0

    public init(host: String, port: Int, configuration: TCPClientConfiguration) {
        self.host = host
        self.port = port
        self.configuration = configuration
    }

    public func connect() -> Bool {
        var success = false

        if !open {
            success = createStreams()

            if success {
                success = configureStreams()
            }

            if success {
                openStreams()
                prepareForOpenStreams()
                success = true
                open = true
            }
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
            writers = nil
        }
    }

    public func write(writer: Writer) {
        if open {
            writers.append(writer)
            write()
        }
    }

    public func writeData(data: NSData) {
        write(DataWriter(data: data))
    }

    func createStreams() -> Bool {
        var iStream: NSInputStream?
        var oStream: NSOutputStream?
        NSStream.getStreamsToHostWithName(host, port: port, inputStream: &iStream, outputStream: &oStream)

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

    func configureStreams() -> Bool {
        return true
    }

    func prepareForOpenStreams() {
        configuration.reader.client = self
        configuration.reader.prepare()
        opensCompleted = 0
        writers = [Writer]()
    }

    func openStreams() {
        let runLoop = NSRunLoop.currentRunLoop()
        let mode = NSDefaultRunLoopMode
        inputStream.scheduleInRunLoop(runLoop, forMode: mode)
        outputStream.scheduleInRunLoop(runLoop, forMode: mode)
        inputStream.open()
        outputStream.open()
    }

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
            delegate?.tcpClientDidDisconnectWithError?(self, streamError: error)
        default:
            break
        }
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

    func didConnect() {
        delegate?.tcpClientDidConnect?(self)
    }

}
