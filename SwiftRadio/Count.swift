//
//  Count.swift
//  SwiftRadio
//
//  Created by Jiang Nan Qing on 10/2/16.
//  Copyright © 2016 CodeMarket.io. All rights reserved.
//

import Foundation

class Count :NSObject {
    var timeToStart         : NSDate
    var timeInterval        : UInt32        //seconds to stop
    var remainTimeString    : String
    var sleepingMode        : Bool
    var timeToStop          : NSDate
 
    init (timeinterval: UInt32){
        self.timeInterval = timeinterval
        self.remainTimeString = ""
        self.timeToStart = NSDate()
        self.sleepingMode = true
        
        let secondsToAdd: NSTimeInterval = Double(timeinterval)
        self.timeToStop = self.timeToStart.dateByAddingTimeInterval(secondsToAdd)
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
    
    
    
    
}