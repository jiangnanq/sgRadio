//
//  Count.swift
//  SwiftRadio
//
//  Created by Jiang Nan Qing on 10/2/16.
//  Copyright © 2016 CodeMarket.io. All rights reserved.
//

import Foundation

protocol countDelegate: class {
    func didUpdateEverySeconds(statusString : String)
}

class Count :NSObject {
    var timeToStart         : NSDate
    var timeInterval        : UInt32        //seconds to stop
    var remainTimeString    : String
    var sleepingMode        : Bool
    var timeToStop          : NSDate
    var sleepTimer = NSTimer()
    static let sharedInstance = Count()
    weak var delegate: countDelegate?
 
    override init() {
        timeToStart = NSDate()
        self.timeInterval = 0
        remainTimeString = ""
        sleepingMode = false
        timeToStop = NSDate()
    }
    
    func checkRemainingTime() ->String {
        let now = NSDate()
        let dateComponentsFormatter = NSDateComponentsFormatter()
        dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Positional
        let interval = self.timeToStop.timeIntervalSinceDate(now)
        if now.compare(self.timeToStop) == NSComparisonResult.OrderedDescending {
            self.sleepingMode = false
        }
        return dateComponentsFormatter.stringFromTimeInterval(interval)!
    }
    
    func checkMode() ->Bool {
        return self.sleepingMode
    }
    
    func startTimer(timeIntervalInSeconds:UInt32) {
        self.timeInterval = timeIntervalInSeconds
        self.timeToStart = NSDate()
        let secondsToAdd = Double(timeIntervalInSeconds)
        self.timeToStop = self.timeToStart.dateByAddingTimeInterval(secondsToAdd)
        self.sleepingMode = true
        self.sleepTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "everySecond", userInfo: nil, repeats: true)
    }
    
    func everySecond() {
        let now = NSDate()
        var resultString = ""
        let dateComponetsFormatter = NSDateComponentsFormatter()
        dateComponetsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyle.Positional
        let interval = self.timeToStop.timeIntervalSinceDate(now)
        if now.compare(self.timeToStop) == NSComparisonResult.OrderedDescending {
            self.sleepingMode = false
            self.sleepTimer.invalidate()
            resultString = "Sleep"
        }else {
            resultString = dateComponetsFormatter.stringFromTimeInterval(interval)!
        }
        self.delegate?.didUpdateEverySeconds(resultString)
    }
    
    
}