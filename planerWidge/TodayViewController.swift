//
//  TodayViewController.swift
//  planerWidge
//
//  Created by 冯奕琦 on 2018/2/13.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import UIKit
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
        
  @IBOutlet weak var happeningEvent: UILabel!
  @IBOutlet weak var willHappenEvent: UILabel!
  @IBOutlet weak var timeLabel: UILabel!
  @IBOutlet weak var happeningLabel: UILabel!
  
  var happeningEventsName:String?
  var willHappenEventName:String?
  var timeString:String?
  
  var eventsArray:[EventsData] = []
  
  override func viewDidLoad() {
    super.viewDidLoad()
    //检查语言
    let language = Locale.preferredLanguages[0]
    let languageCode = language[language.startIndex...language.index(after: language.startIndex)]
    if languageCode == "zh"{
      DefaultWords.changeToChinese()
    }
    happeningLabel.text = DefaultWords.happening
    //get todaysEventsData 获得NSData类型 转换成[EventData]类型
    print("widgeViewDidLoad")
    
    if let dataString = UserDefaults(suiteName: keyOfUserDefluatData.widgeBundleID)?.string(forKey: keyOfUserDefluatData.widgeData){
      eventsArray = []//清空数组
      var startSymbel = dataString.startIndex
      var endSymbel = dataString.endIndex
      for (order,character) in dataString.enumerated(){
        //找到坐标
        if character == "!"{
          endSymbel = String.Index(encodedOffset:order)
          //单个事件的string
          let eventdataString = dataString[startSymbel..<endSymbel]
          let nameEndSymbol = eventdataString.index(of: "|")!
          let name = eventdataString[eventdataString.startIndex..<nameEndSymbol]
          let timeString = eventdataString[eventdataString.index(after: nameEndSymbol)..<eventdataString.endIndex]
          //转化为数据
          let event = EventsData(name: String(name), time: String(timeString).check())
          eventsArray.append(event)
          startSymbel = dataString.index(after: endSymbel)
        }
      }
      checkEvents(array: eventsArray)//check data
      
      
      if let string = happeningEventsName{
        happeningEvent.text = string
      }else{
        happeningEvent.text = DefaultWords.none
      }
      
      if let string = willHappenEventName{
        willHappenEvent.text = string
        timeLabel.text = timeString!
      }else{
        willHappenEvent.text = DefaultWords.none
        timeLabel.text = DefaultWords.noneWillHappen
      }
      
    }else{
      print("无数组")
      happeningEvent.text = DefaultWords.none
      willHappenEvent.text = DefaultWords.none
      timeLabel.text = DefaultWords.noneWillHappen
    }
    
  }
  
  
  func checkEvents(array eventsViewsArray:[EventsData]){
    //checkLampstatus
    for event in eventsViewsArray {
      //get eventView
      let timeData = event.time
      let currentHourMin = HourMin(hour:TimeData.calendarDate.hour,
                                   min:TimeData.calendarDate.min)
      let currentTime = TimeData.timePoint(point: currentHourMin)
      print(timeData.timeString , " " ,currentTime.timeString)
      //三种状态
      if TimeData.haveOther(currentTime, and: timeData){
        //正在发生
        happeningEventsName = event.name
        switch timeData{
        case.timeBucket(startPoint: _, endPoint: let currentEventEndTime):
          let endTimeDistance = currentEventEndTime-currentHourMin
          happeningEventsName! += " (\(endTimeDistance.hour)\(DefaultWords.hour)\(endTimeDistance.min)\(DefaultWords.min)\(DefaultWords.ended)）"
        default:
          print("error")
        }
      }
      if timeData > currentTime{
        //将要发生
        willHappenEventName = event.name
        //获取时间
        var timeDistanve :HourMin
        switch timeData{
        case .timeBucket(startPoint: let startTime, endPoint: _):
          timeDistanve = startTime - currentHourMin
        case .timePoint(point: let point):
          timeDistanve = point - currentHourMin
        }
        timeString = "\(timeDistanve.hour)\(DefaultWords.hour)\(timeDistanve.min)\(DefaultWords.min)\(DefaultWords.willHappen)"
        break
      }
    }
  }
  
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        print("widgetPerformUpdate")
        completionHandler(NCUpdateResult.newData)
    }
  
  @IBAction func openButtonPressed() -> Void {
    let url : URL = URL.init(string: "WidgeData://open")!
    self.extensionContext?.open(url, completionHandler: {(isSucces) in
      print("点击了open按钮，来唤醒APP，是否成功 : \(isSucces)")
    })
  }
  
}
