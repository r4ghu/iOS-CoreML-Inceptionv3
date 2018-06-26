//
//  LogUtils.swift
//  ImageRecognition
//
//  Created by Sri Raghu Malireddi on 19/06/18.
//  Copyright © 2018 Sri Raghu Malireddi. All rights reserved.
//

// Code taken with inspiration from
// Source: https://stackoverflow.com/questions/2129794/how-to-log-a-methods-execution-time-exactly-in-milliseconds
import Foundation

var startTime = NSDate()

func TICK() {
    startTime = NSDate()
}

func TOCK(function: String = #function, file: String = #file, line: Int = #line) {
    print("\(function) Time: \(-startTime.timeIntervalSinceNow) Line: \(line) File: \(file)\n")
}
