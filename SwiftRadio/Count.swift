//
//  Count.swift
//  SwiftRadio
//
//  Created by Jiang Nan Qing on 10/2/16.
//  Copyright © 2016 CodeMarket.io. All rights reserved.
//

import Foundation

protocol countDelegate: class {
    func didUpdateEverySeconds(_ statusString : String)
    func didUpdateDataUsage(_ dataUsageString : String)
}

class Count :NSObject {
    var timeToStart         : Date
    var timeInterval        : UInt32        //seconds to stop
    var remainTimeString    : String
    var sleepingMode        : Bool
    var timeToStop          : Date
    var playingTimeTotalizer: UInt32        //playing time in seconds
    var sleepTimer = Timer()
    var dataUsageTimer = Timer()
    static let sharedInstance = Count()
    weak var delegate: countDelegate?
    let reachability = Reachability.forInternetConnection()
 
    override init() {
        timeToStart = Date()
        self.timeInterval = 0
        remainTimeString = ""
        sleepingMode = false
        timeToStop = Date()
        playingTimeTotalizer = 0
    }
    
    func checkRemainingTime() ->String {
        let now = Date()
        let dateComponentsFormatter = DateComponentsFormatter()
        dateComponentsFormatter.unitsStyle = DateComponentsFormatter.UnitsStyle.positional
        let interval = self.timeToStop.timeIntervalSince(now)
        if now.compare(self.timeToStop) == ComparisonResult.orderedDescending {
            self.sleepingMode = false
        }
        return dateComponentsFormatter.string(from: interval)!
    }
    
    func checkMode() ->Bool {
        return self.sleepingMode
    }
    
    func startTimer(_ timeIntervalInSeconds:UInt32) {
        self.timeInterval = timeIntervalInSeconds
        self.timeToStart = Date()
        let secondsToAdd = Double(timeIntervalInSeconds)
        self.timeToStop = self.timeToStart.addingTimeInterval(secondsToAdd)
        self.sleepingMode = true
        self.sleepTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(Count.everySecondSleep), userInfo: nil, repeats: true)
    }
    
    func everySecondSleep() {
        let now = Date()
        var resultString = ""
        let dateComponetsFormatter = DateComponentsFormatter()
        dateComponetsFormatter.unitsStyle = DateComponentsFormatter.UnitsStyle.positional
        let interval = self.timeToStop.timeIntervalSince(now)
        if now.compare(self.timeToStop) == ComparisonResult.orderedDescending {
            self.sleepingMode = false
            self.sleepTimer.invalidate()
            resultString = "自动停止"
        }else {
            resultString = dateComponetsFormatter.string(from: interval)!
        }
        self.delegate?.didUpdateEverySeconds(resultString)
    }
    
    func startPlayer() {
        self.dataUsageTimer = Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(Count.dataUsageTotalizer), userInfo: nil, repeats: true)
    }
    
    func stopPlayer() {
        self.dataUsageTimer.invalidate()
    }
    
    func dataUsageTotalizer() {
        if self.checkWifiConnection() {
            self.playingTimeTotalizer += 1
            let dataUsageDouble = Double(self.playingTimeTotalizer * 25)
            var dataUsageString = ""
            let dataUsageDoubleInM = dataUsageDouble/1000
            dataUsageString = String(format: "已用%.1fMb流量", dataUsageDoubleInM)
            self.delegate?.didUpdateDataUsage(dataUsageString)
        }
    }
    
    func checkWifiConnection() -> Bool{
        return self.reachability!.currentReachabilityStatus().rawValue == ReachableViaWWAN.rawValue
    }

}
