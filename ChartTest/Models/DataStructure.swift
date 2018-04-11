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

class EventsData:NSObject,NSCoding {
  
  var time:TimeData//两种不同的数据 或者没有数据
  var date:MonthDay
  var name:String
  var descri:String?
  var notificationString:String?
  var needNotify:Bool
  
  //equatable delegate ⚠️
  static func ==(lData:EventsData,rData:EventsData) -> Bool {
//    print(lData.date, rData.date ,lData.time , rData.time ,lData.name ,rData.name)
    if lData.date == rData.date && lData.time == rData.time && lData.name == rData.name{
      return true
    }
    return false
  }
  
  
  func encode(with aCoder: NSCoder) {//编码函数
    
    aCoder.encode(name, forKey: KeysOfData.eventsName)
    aCoder.encode(descri, forKey: KeysOfData.eventsDescription)
    aCoder.encode(needNotify, forKey: KeysOfData.eventsNotification)
    aCoder.encode(date.day,forKey: KeysOfData.eventsDateDay)
    aCoder.encode(date.month,forKey:KeysOfData.eventsDateMonth)
    aCoder.encode(date.year,forKey:KeysOfData.eventsDateYear)
    aCoder.encode(notificationString,forKey:KeysOfData.eventsNotificationString)
    //encode 除了time之外的数据
    var isTimeBucket:Bool
    switch time {
    case .timeBucket(let startPoint,let endPoint):
      isTimeBucket = true//encode 时间段
      aCoder.encode(startPoint.hour, forKey: KeysOfData.eventsTimeBucketStartHour)
      aCoder.encode(startPoint.min, forKey: KeysOfData.eventsTimeBucketStartMin)
      aCoder.encode(endPoint.hour, forKey: KeysOfData.eventsTimeBucketEndHour)
      aCoder.encode(endPoint.min, forKey: KeysOfData.eventsTimeBucketEndMin)
    case .timePoint(let timePoint):
      isTimeBucket = false//encode 时间点
      aCoder.encode(timePoint.hour, forKey: KeysOfData.eventsTimePointHour)
      aCoder.encode(timePoint.min, forKey: KeysOfData.eventsTimePointMin)
    }//计算time的类型
    aCoder.encode(isTimeBucket, forKey:KeysOfData.eventsIsTimeBucket)
  }
  
  init(name:String,description:String?,notifiction:Bool,date:MonthDay,time:TimeData,notificationString:String?) {
    self.name = name
    self.descri = description
    self.needNotify = notifiction
    self.time = time
    self.date = date
    self.notificationString = notificationString
  }
  
  convenience required init?(coder aDecoder: NSCoder) {
    let name = aDecoder.decodeObject(forKey: KeysOfData.eventsName) as! String
    let descrtprion = aDecoder.decodeObject(forKey: KeysOfData.eventsDescription) as! String?//注意
    let notification = aDecoder.decodeBool(forKey: KeysOfData.eventsNotification)
    let isTimeBucket = aDecoder.decodeBool(forKey: KeysOfData.eventsIsTimeBucket)
    let day = aDecoder.decodeInteger(forKey: KeysOfData.eventsDateDay)
    let month = aDecoder.decodeInteger(forKey: KeysOfData.eventsDateMonth)
    let year = aDecoder.decodeInteger(forKey: KeysOfData.eventsDateYear)
    let notificationString = aDecoder.decodeObject(forKey:KeysOfData.eventsNotificationString) as! String?
    //decode 除了时间以外的数据
    var time :TimeData
    if isTimeBucket {
      let startHour = aDecoder.decodeInteger(forKey: KeysOfData.eventsTimeBucketStartHour)
      let startMin = aDecoder.decodeInteger(forKey: KeysOfData.eventsTimeBucketStartMin)
      let endHour = aDecoder.decodeInteger(forKey: KeysOfData.eventsTimeBucketEndHour)
      let endMin = aDecoder.decodeInteger(forKey: KeysOfData.eventsTimeBucketEndMin)
      time = TimeData.timeBucket(startPoint: HourMin(hour:startHour,min:startMin) , endPoint: HourMin(hour: endHour, min: endMin))
    }else{
      let hour = aDecoder.decodeInteger(forKey: KeysOfData.eventsTimePointHour)
      let min = aDecoder.decodeInteger(forKey: KeysOfData.eventsTimePointMin)
      time = TimeData.timePoint(point: HourMin(hour: hour, min: min))
    }
    //decode 时间
    self.init(name: name, description: descrtprion,
              notifiction: notification,date:MonthDay(year: year, month:month,day:day), time: time,notificationString:notificationString)
  }
  
}

enum TimeData {
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
    case (.timePoint(let timePoint1),.timeBucket(let startPoint1,_)):
      return timePoint1>startPoint1
    //第四种情况 5:37 ~ 6:23 > 4:23 ~ 5:09
    case (.timeBucket(let startPoint1,let endPoint1),.timeBucket(let startPoint2,let endPoint2)):
      if startPoint1 == endPoint2 { return true }
      if endPoint1 == startPoint2 { return false }
      return endPoint1 > startPoint2
    }
  }
  static func <(time1:TimeData,time2:TimeData)->Bool{
    switch (time1,time2) {
    //第一种情况 2:00 < 3:00
    case (.timePoint(let timePoint1),.timePoint(let timePoint2)):
      return timePoint1 < timePoint2
    //第二种情况 1:00 ～ 3:00 < 4:30
    case (.timeBucket(let startPoint,let endPoint),.timePoint(let timePoint2)):
      if startPoint < timePoint2 {
        if timePoint2 < endPoint || timePoint2 == endPoint {//在endPoint中间
          return false
        }
        return true
      }else{
        return false
      }
    //第三种情况 0:01 < 0:03 ~ 0:07
    case (.timePoint(let timePoint1),.timeBucket(let startPoint,_)):
//      print("对比\(timePoint1)  \(startPoint):\(endPoint)")
      if startPoint < timePoint1 {
        return false
      }else{
        return true
      }
    //第四种情况 5:37 ~ 6:23 < 4:23 ~ 5:09
    case (.timeBucket(let startPoint1,let endPoint1),.timeBucket(let startPoint2,let endPoint2)):
      if startPoint1 == endPoint2 { return false }
      if endPoint1 == startPoint2 { return true }
      return endPoint1 < startPoint2
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
      return (startPoint<timePoint&&timePoint<endPoint)||startPoint==timePoint||endPoint==timePoint
    //第三种情况 0:30 == 0:03 ~ 0:07
    case (.timePoint(let timePoint),.timeBucket(let startPoint,let endPoint)):
      return (startPoint<timePoint&&timePoint<endPoint)||startPoint==timePoint||endPoint==timePoint
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
  func minInt() -> Int {
    return self.hour*60+min
  }
  func hourDouble() -> Double {
    return Double(self.hour)+Double(self.min)/60
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

extension Int {
  func changeToSpendTimeString() -> String {
    let hour = self/60
    let min = self%60
    return HourMin(hour: hour, min: min).string()
  }
}

struct MonthDay {
  var year:Int
  var month:Int
  var day:Int
  
  static func == (lDate:MonthDay,rDate:MonthDay) -> Bool{
    if lDate.day == rDate.day && lDate.month == rDate.month && lDate.year == rDate.year{
      return true
    }
    return false
  }
  
  static func < (lDate:MonthDay,rDate:MonthDay) -> Bool{
    if lDate.year < rDate.year {
      return true
    }else
    if lDate.year == rDate.year {
      if lDate.month < rDate.month {
        return true
      }else
        if lDate.month == rDate.month {
          return lDate.day < rDate.day
      }
      return false
    }
    return false
  }
  
  static func <= (lDate:MonthDay,rDate:MonthDay) -> Bool{
    if lDate.year < rDate.year {
      return true
    }else
      if lDate.year == rDate.year {
        if lDate.month < rDate.month {
          return true
        }else
          if lDate.month == rDate.month {
            return lDate.day <= rDate.day
        }
        return false
    }
    return false
  }
  
  static func > (lDate:MonthDay,rDate:MonthDay) -> Bool{
    if lDate.year > rDate.year {
      return true
    }else
      if lDate.year == rDate.year {
        if lDate.month > rDate.month {
          return true
        }else
          if lDate.month == rDate.month {
            return lDate.day > rDate.day
        }
        return false
    }
    return false
  }
  
  static func >= (lDate:MonthDay,rDate:MonthDay) -> Bool{
    if lDate.year > rDate.year {
      return true
    }else
      if lDate.year == rDate.year {
        if lDate.month > rDate.month {
          return true
        }else
          if lDate.month == rDate.month {
            return lDate.day >= rDate.day
        }
        return false
    }
    return false
  }
  
}

extension String{
  
  func check(midnight:Bool)->(error:String?,data:TimeData?){
    
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
      if colonIndex <= string.startIndex{return (DefaultWords.timeErrorForInputNumber1,nil)}
      let firstInt = Int(string[string.startIndex..<colonIndex])!
      if string.endIndex <= string.index(after: colonIndex) {return (DefaultWords.timeErrorForInputNumber1,nil)}
      let secondInt = Int(string[string.index(after: colonIndex)..<string.endIndex])!
      if firstInt < 24 && secondInt < 60{
        return (nil,TimeData.timePoint(point: HourMin(hour: firstInt, min: secondInt)))
      }else{
        return (DefaultWords.timeErrorForBeyondRange,nil)
      }
    }
    
    //00:00 ~ 00:00
    if colonOrders.count == 2 && dashOrders.count == 1{
      if colonOrders[0] < dashOrders[0] && dashOrders[0] < colonOrders[1]{//确定位置
        let firstColonIndex = String.Index(encodedOffset: colonOrders[0])
        let secondColonIndex = String.Index(encodedOffset: colonOrders[1])
        let dashIndex = String.Index(encodedOffset: dashOrders[0])
        if firstColonIndex <= string.startIndex{return(DefaultWords.timeErrorForInputNumber2,nil)}
        let firstInt = Int(string[string.startIndex..<firstColonIndex])!
        if  dashIndex<=string.index(after: firstColonIndex){return(DefaultWords.timeErrorForInputNumber3,nil)}
        let secondInt = Int(string[string.index(after: firstColonIndex)..<dashIndex])!
        if  secondColonIndex<=string.index(after: dashIndex) {return(DefaultWords.timeErrorForInputNumber4,nil)}
        let thirdInt = Int(string[string.index(after: dashIndex)..<secondColonIndex])!
        if  string.endIndex<=string.index(after: secondColonIndex) {return(DefaultWords.timeErrorForInputNumber5,nil)}
        let fourInt = Int(string[string.index(after: secondColonIndex)..<string.endIndex])!
//        print(firstInt,secondInt,thirdInt,fourInt)
        if firstInt < 24 && secondInt < 60 && thirdInt < 24 && fourInt < 60{
          let startTimePoint = HourMin(hour: firstInt, min: secondInt)
          let endTImePoint = HourMin(hour: thirdInt, min: fourInt)
          if startTimePoint < endTImePoint || midnight{
            return (nil,TimeData.timeBucket(startPoint: startTimePoint, endPoint: endTImePoint))
          }else{
            return (DefaultWords.timeErrorOrder,nil)
          }
        }else{
          return (DefaultWords.timeErrorForBeyondRange,nil)
        }
      }
    }
    
    return (DefaultWords.timeErrorForFormat,nil)
  }
}
