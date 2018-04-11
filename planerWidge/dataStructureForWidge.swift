//
//  DataStructure.swift
//  newPlanList
//
//  Created by 冯奕琦 on 2018/1/27.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//
// 事件的数据结构
// 功能 -> 可以储存 可比较 可变动

import Foundation

struct DefaultWords {
  static var happening = "In progress "
  static var willHappen = " will happen "
  static var hour = "h"
  static var min = "m"
  static var none = " None "
  static var ended = " last"
  static var noneWillHappen = "will happen"
  
  static func changeToChinese() {
    DefaultWords.happening = "正在"
    DefaultWords.willHappen = "后要"
    DefaultWords.hour = "时"
    DefaultWords.min = "分"
    DefaultWords.none = " 无 "
    DefaultWords.ended = "后结束"
    DefaultWords.noneWillHappen = "之后要"
  }
}

struct keyOfUserDefluatData {
  static let widgeData = "WidgeData"
  static let widgeBundleID = "group.com.fengyiqi.ChartTest-com.fengyiqi.newPlanListNew.widge"
}

struct KeysOfData {
  static let eventsName = "eventsName"
  static let eventsDescription = "eventsDescription"
  static let eventsTimePointHour = "eventsTimePointHour"
  static let eventsTimePointMin = "eventsTimePointMin"
  static let eventsTimeBucketStartHour = "eventsTimeBucketStartHour"
  static let eventsTimeBucketStartMin = "eventsTimeBucketStartMin"
  static let eventsTimeBucketEndHour = "eventsTimeBucketEndHour"
  static let eventsTimeBucketEndMin = "eventsTimeBucketEndMin"
  static let eventsNotification = "notification"
  static let eventsNotificationString = "eventsNotificationString"
  static let eventsIsTimeBucket = "timePoint"
  static let eventsDateDay = "eventsDateDay"
  static let eventsDateMonth = "eventsMonth"
}

class EventsData:NSObject {
  
  var time:TimeData//两种不同的数据 或者没有数据
  var name:String
  
init(name:String,time:TimeData) {
    self.name = name
    self.time = time
  }
  

}

enum TimeData {
  
  static  var currentDate :Date{ return Date() }
  static var calendarDate:(year:Int,month:Int,day:Int,hour:Int,min:Int,weekDay:Int){
    let calendar = Calendar.current
    let day = calendar.component(.day,from:currentDate)
    let month = calendar.component(.month, from: currentDate)
    let year = calendar.component(.year, from: currentDate)
    let hour = calendar.component(.hour, from: currentDate)
    let min = calendar.component(.minute, from: currentDate)
    let weekDay = calendar.component(.weekday, from: currentDate)
    return (year,month,day,hour,min,weekDay)
  }
  //数据结构
  case timePoint(point:HourMin)
  case timeBucket(startPoint:HourMin,endPoint:HourMin)
  //返回给eventView使用的字符串（时间段）
  var timeString:String{
    switch self {
    case .timePoint(point: let point):
      return point.string()
    case .timeBucket(startPoint: let startPoint, endPoint: let endPoint):
      return "\(startPoint.string())～\(endPoint.string())"
    }
  }
  //返回所用时间 (时间点的话为nil)
  var spend:HourMin?{
    switch self {
    case .timePoint(_):
      return nil
    case .timeBucket(let startPoint,let endPoint):
      return endPoint - startPoint
    }
  }
  //定义比较方法
  static func >(time1:TimeData,time2:TimeData)->Bool{
    switch (time1,time2) {
    //第一种情况 2:00 > 1:00
    case (.timePoint(let timePoint1),.timePoint(let timePoint2)):
      return timePoint1 > timePoint2
    //第二种情况 1:00 ～ 3:00 > 0:30
    case (.timeBucket(let startPoint1,_),.timePoint(let timePoint2)):
      return startPoint1 > timePoint2
    //第三种情况 0:30 > 0:03 ~ 0:07
    case (.timePoint(let timePoint1),.timeBucket(_,let endPoint2)):
      return timePoint1>endPoint2
    //第四种情况 5:37 ~ 6:23 > 4:23 ~ 5:09
    case (.timeBucket(let startPoint1,_),.timeBucket(let startPoint2,_)):
      return startPoint1 > startPoint2
    }
  }
  static func <(time1:TimeData,time2:TimeData)->Bool{
    switch (time1,time2) {
    //第一种情况 2:00 < 3:00
    case (.timePoint(let timePoint1),.timePoint(let timePoint2)):
      return timePoint1 < timePoint2
    //第二种情况 1:00 ～ 3:00 < 4:30
    case (.timeBucket(_,let endPoint),.timePoint(let timePoint2)):
      return endPoint < timePoint2
    //第三种情况 0:01 < 0:03 ~ 0:07
    case (.timePoint(let timePoint1),.timeBucket(let startPoint, _)):
      return timePoint1<startPoint
    //第四种情况 5:37 ~ 6:23 < 4:23 ~ 5:09
    case (.timeBucket(_,let endPoint),.timeBucket(let startPoint2,_)):
      return endPoint<startPoint2
    }
  }
  static func ==(time1:TimeData,time2:TimeData)->Bool{
    switch (time1,time2) {
    //第一种情况 2:00 == 2:00
    case (.timePoint(let timePoint1),.timePoint(let timePoint2)):
      return timePoint1 == timePoint2
    //第二种情况 1:00 ～ 3:00 == 0:30
    case (.timeBucket(_,_),.timePoint(_)):
      return false
    //第三种情况 0:30 == 0:03 ~ 0:07
    case (.timePoint(_),.timeBucket(_,_)):
      return false
    //第四种情况 5:37 ~ 6:23 == 4:23 ~ 5:09
    case (.timeBucket(let startPoint1,let endPoint1),.timeBucket(let startPoint2,let endPoint2)):
      return (startPoint1==startPoint2)&&(endPoint1==endPoint2)
    }
  }
  
  static func haveOther(_ time1:TimeData,and time2:TimeData)->Bool{
    switch (time1,time2) {
    //第一种情况 2:00 == 2:00
    case (.timePoint(let timePoint1),.timePoint(let timePoint2)):
      return timePoint1 == timePoint2
    //第二种情况 1:00 ～ 3:00 == 0:30
    case (.timeBucket(let startPoint,let endPoint),.timePoint(let timePoint)):
      return (startPoint<timePoint&&timePoint<endPoint)
    //第三种情况 0:30 == 0:03 ~ 0:07
    case (.timePoint(let timePoint),.timeBucket(let startPoint,let endPoint)):
      return (startPoint<timePoint&&timePoint<endPoint)
    //第四种情况 5:37 ~ 6:23 == 4:23 ~ 5:09
    case (.timeBucket(let startPoint1,let endPoint1),.timeBucket(let startPoint2,let endPoint2)):
      let startPoint1InTimeBucket2 = (startPoint2<startPoint1&&startPoint1<endPoint2)
      let endPoint1InTimeBucket2 = (startPoint2<endPoint1&&endPoint1<endPoint2)
      let timeBucket2InTimeBucket1 = (startPoint1<startPoint2&&endPoint2<endPoint1)
      return startPoint1InTimeBucket2||endPoint1InTimeBucket2||timeBucket2InTimeBucket1
    }
  }
}


struct HourMin {//小时分钟结构
  var hour:Int
  var min:Int
  
  //重写加法
  static func +(time1:HourMin,time2:HourMin) -> HourMin {
    var time = HourMin(hour: 0, min: 0)
    time.min = (time1.min + time2.min)%60
    time.hour = time1.hour + time2.hour + ((time1.min + time2.min)/60)
    return time
  }
  static func - (time1:HourMin,time2:HourMin) -> HourMin{
    let minTime1 = time1.hour*60+time1.min
    let minTime2 = time2.hour*60+time2.min
    return HourMin(hour: (minTime1 - minTime2)/60, min: (minTime1 - minTime2)%60)
  }
  //重新比较
  static func < (time1:HourMin,time2:HourMin)-> Bool{
    if time1.hour < time2.hour{
      return true
    }else{
      if time1.hour == time2.hour{
        return time1.min < time2.min
      }
      return false
    }
  }
  static func > (time1:HourMin,time2:HourMin)-> Bool{
    if time1.hour > time2.hour{
      return true
    }else{
      if time1.hour == time2.hour{
        return time1.min > time2.min
      }
      return false
    }
  }
  static func ==(time1:HourMin,time2:HourMin)->Bool{
    if time1.hour == time2.hour && time1.min == time2.min {
      return true
    }
    return false
  }
  
  static func Change(_ time:(Int,Int)) -> HourMin{
    return HourMin(hour: time.0, min: time.1)
  }
  //转化成文字
  func string()->String{
    if min < 10{
      return "\(hour):0\(min)"
    }else{
      return "\(hour):\(min)"
    }
  }
}

struct MonthDay {
  var month:Int
  var day:Int
  
  static func == (lDate:MonthDay,rDate:MonthDay) -> Bool{
    if lDate.day == rDate.day && lDate.month == rDate.month {
      return true
    }
    return false
  }
}

extension String{
  
  func check()->TimeData{
    
    let string = self
    var colonOrders :[Int] = []
    var dashOrders:[Int] = []
    
    for (order,characters) in string.enumerated(){
      if characters == ":"{ colonOrders.append(order) }
      if characters == "～"{ dashOrders.append(order) }
    }
    
    //00:00
    if colonOrders.count == 1 && dashOrders.isEmpty{
      
      let colonIndex = String.Index(encodedOffset: colonOrders[0])
      let firstInt = Int(string[string.startIndex..<colonIndex])!
      let secondInt = Int(string[string.index(after: colonIndex)..<string.endIndex])!
      if firstInt < 24 && secondInt < 60{
        return (TimeData.timePoint(point: HourMin(hour: firstInt, min: secondInt)))
      }else{
      }
    }
    
    //00:00 ~ 00:00
    if colonOrders.count == 2 && dashOrders.count == 1{
      if colonOrders[0] < dashOrders[0] && dashOrders[0] < colonOrders[1]{//确定位置
        let firstColonIndex = String.Index(encodedOffset: colonOrders[0])
        let secondColonIndex = String.Index(encodedOffset: colonOrders[1])
        let dashIndex = String.Index(encodedOffset: dashOrders[0])
        let firstInt = Int(string[string.startIndex..<firstColonIndex])!
        let secondInt = Int(string[string.index(after: firstColonIndex)..<dashIndex])!
        let thirdInt = Int(string[string.index(after: dashIndex)..<secondColonIndex])!
        let fourInt = Int(string[string.index(after: secondColonIndex)..<string.endIndex])!
        //        print(firstInt,secondInt,thirdInt,fourInt)
        if firstInt < 24 && secondInt < 60 && thirdInt < 24 && fourInt < 60{
          let startTimePoint = HourMin(hour: firstInt, min: secondInt)
          let endTImePoint = HourMin(hour: thirdInt, min: fourInt)
          if startTimePoint < endTImePoint {
            return (TimeData.timeBucket(startPoint: startTimePoint, endPoint: endTImePoint))
          }
        }
      }
    }
    
    return TimeData.timePoint(point: HourMin(hour: 99, min: 99))
  }
}


