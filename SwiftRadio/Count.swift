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
    func didUpdateDataUsage(dataUsageString : String)
}

class Count :NSObject {
    var timeToStart         : NSDate
    var timeInterval        : UInt32        //seconds to stop
    var remainTimeString    : String
    var sleepingMode        : Bool
    var timeToStop          : NSDate
    var playingTimeTotalizer: UInt32        //playing time in seconds
    var sleepTimer = NSTimer()
    var dataUsageTimer = NSTimer()
    static let sharedInstance = Count()
    weak var delegate: countDelegate?
    let reachability = Reachability.reachabilityForInternetConnection()
 
    override init() {
        timeToStart = NSDate()
        self.timeInterval = 0
        remainTimeString = ""
        sleepingMode = false
        timeToStop = NSDate()
        playingTimeTotalizer = 0
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
        self.sleepTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "everySecondSleep", userInfo: nil, repeats: true)
    }
    
    func everySecondSleep() {
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
    
    func startPlayer() {
        self.dataUsageTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: "dataUsageTotalizer", userInfo: nil, repeats: true)
    }
    
    func stopPlayer() {
        self.dataUsageTimer.invalidate()
    }
    
    func dataUsageTotalizer() {
        if self.checkWifiConnection() {
            self.playingTimeTotalizer++
            let dataUsageDouble = Double(self.playingTimeTotalizer * 25)
            var dataUsageString = ""
            let dataUsageDoubleInM = dataUsageDouble/1000
            dataUsageString = String(format: "已经用了%.1fMb流量", dataUsageDoubleInM)
            self.delegate?.didUpdateDataUsage(dataUsageString)
        }
    }
    
    func checkWifiConnection() -> Bool{
        return self.reachability.currentReachabilityStatus().rawValue == ReachableViaWWAN.rawValue
    }

}