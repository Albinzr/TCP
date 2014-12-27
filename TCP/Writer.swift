//
//  StreamWriter.swift
//  TCP
//
//  Created by Cameron Pulsford on 12/26/14.
//  Copyright (c) 2014 SMD. All rights reserved.
//

import Foundation

public protocol Writer {

    func writeToStream(stream: NSOutputStream) -> (complete: Bool, bytesWritten: Int)

}
