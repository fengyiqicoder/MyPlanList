//
//  ConstraintsAndKeys.swift
//  newPlanList
//
//  Created by 冯奕琦 on 2018/1/27.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import Foundation
import UIKit

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
  static let eventsDateYear = "eventsDateYear"
  static let havePaid = "havePaid"
}

struct Constants {
  
  static var applicationShowingDate:MonthDay = MonthDay(year: 0, month:0,day:0)
  //固定颜色或者图片
  static let mainColor:UIColor = #colorLiteral(red: 0.9692109227, green: 0.809376061, blue: 0.1438914835, alpha: 1)
  //界面固定距离
  static var keyboardHeight:CGFloat = 0
  static let eventsViewsCellsHeight:CGFloat = 109
  static let screenWidth:CGFloat = UIScreen.main.bounds.size.width
  static let screenHeight:CGFloat = UIScreen.main.bounds.size.height
  static let rightGap = Constants.screenWidth*(10/320)
  static let leftGap = Constants.screenWidth*(5/320)
  static let deleteDistance:CGFloat = 170
  static let customKeyboardHeight:CGFloat = Constants.screenWidth/1.69
  //EventVies Constants
  static let eventsNamePickerHeight:CGFloat = 30//⚠️
  static let eventsViewsTextViewsDefaultHeight:CGFloat = 31
  static let commonEventCellsHeight:CGFloat = 40
  //CollectionViews Constants
  static let dateLabelConstantsFrame:CGRect = CGRect(x: 2, y: 0,
                                                     width: UIScreen.main.bounds.size.width, height: 36)
  static let addButtonsSize:CGSize = CGSize(width: 50, height: 50)
  static let distanceBetweenItems:CGFloat = 5
  static let widthOfLine:CGFloat = 2
  static let collectionStratLine:CGFloat = 60
  static let collectionEndDistance:CGFloat = 42
  //aniamtion duration value
  static var shouldAnimateEventsView:Int{//返回多少个EventView一个屏幕最多可以显示
    let screenHeight = UIScreen.main.bounds.size.height
    if screenHeight > 700{
      return 8 // x & plus
    }
    if screenHeight > 600{
      return 7 // 8
    }
    return 6 // se 5s
  }
  static let moveDownAnimationDuration:TimeInterval = 0.22
  //时间管理系统
  
  //语言常量
  static func changeWeekDayToChinese(weekDay:Int)->String{
    switch weekDay {
    case 1: return DefaultWords.mon
    case 2: return DefaultWords.tue
    case 3: return DefaultWords.wed
    case 4: return DefaultWords.thu
    case 5: return DefaultWords.fri
    case 6: return DefaultWords.sat
    case 7: return DefaultWords.sun
    default: return"WeekDayWrong"
    }
  }
//关于现在时间点的获取
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
  static func getDateBucketBefore(timeBucket:TimeBucket) -> (startDate:MonthDay,endDate:MonthDay){
    var startDate:MonthDay = MonthDay(year: 0, month: 0, day: 0)
    var endDate:MonthDay = MonthDay(year: 0, month: 0, day: 0)
    switch timeBucket {
    case .yesterDay://昨天
      startDate = Constants.changeDistanceDayToDate(-1).monthday
      endDate = startDate
    case .lastWeek:
      //找到上两个周一
      let firstDaysWeekDay = 1
      var startDateDistance = -1//用于计算最后一个日期
      var findedlastfirstday = false
      for dateDistance in 0...16{//遍历之前八天
        let date = Constants.changeDistanceDayToDate(-dateDistance)
        //检查是不是第二个周一
        if date.weekDay == firstDaysWeekDay && findedlastfirstday{
          //记录这个date
          startDate = date.monthday
          startDateDistance = -dateDistance
          break
        }
        //如果是第一个周一
        if date.weekDay == firstDaysWeekDay && !findedlastfirstday {findedlastfirstday = true}
      }
      //计算结束时间
      print("星期 ",startDateDistance)
      let endDateData = Constants.changeDistanceDayToDate(startDateDistance+6)
      endDate =  endDateData.monthday
    case .lastMonth:
      //找到上两个一号
      let firstDaysInMonth = 1
      var startDateDistance = -1//用于计算最后一个日期
      var findedlastfirstday = false
      for dateDistance in 0...62{//遍历之前32天
        let date = Constants.changeDistanceDayToDate(-dateDistance)
        //检查是不是第二个一号
        if date.monthday.day == firstDaysInMonth && findedlastfirstday{
          startDate = date.monthday
          startDateDistance = -dateDistance
          break
        }
        //找到第一个一号
        if date.monthday.day == firstDaysInMonth && !findedlastfirstday { findedlastfirstday = true }
      }
      //计算结束日期
      //计算本月份的天数
      let monthDay = Constants.changeMonthToDaysIn(year: startDate.year, month: startDate.month)-1
      let endDateData = Constants.changeDistanceDayToDate(startDateDistance+monthDay)//加上此月份的天数
      endDate = endDateData.monthday
    case .totally:
      //从最小开始
      let date = Constants.changeDistanceDayToDate(-1)
      endDate = date.monthday
      //到昨天结束
      startDate = MonthDay(year: 0, month: 0, day: 0)
    default:
      print("不能使用getDateBucketBefore函数")
    }
    return (startDate,endDate)
  }
  //转化未来天数成为数据
  static func changeDistanceDayToDate(_ days:Int) -> (monthday:MonthDay,weekDay:Int){
    let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: currentDate)!
    let date = Calendar.current.date(byAdding: .day, value: days, to: noon)!
    let calender = Calendar.current
    let year = calender.component(.year, from: date)
    let month = calender.component(.month, from: date)
    let day = calender.component(.day, from: date)
    let weekDayForSystem = calender.component(.weekday, from: date)
    //get weekDay 中国算法
    var weekDay = (weekDayForSystem-1)%7
    if weekDay == 0 { weekDay = 7 }
    
    return(MonthDay(year:year,month:month,day:day),weekDay)
  }
  
  static func changeDistanceDayToDateString(distance:Int) -> (date:String,Mouthday:String){//直接把顺序转化为字符串
    let dateData = changeDistanceDayToDate(distance)
    var string = "\(dateData.monthday.month)\(DefaultWords.month)\(dateData.monthday.day)\(DefaultWords.day) \(Constants.changeWeekDayToChinese(weekDay: dateData.weekDay))"//中英文问题 对应字符还没添加
    var mouthDay:String = "\(distance)\(DefaultWords.daysAgoa)"
    if distance >= 10 {
      mouthDay = "\(dateData.monthday.month)\(DefaultWords.month)\(dateData.monthday.day)\(DefaultWords.day)"
    }
    if distance == 0{ string = string+" \(DefaultWords.today)" ; mouthDay = "\(DefaultWords.today)" } //添加今日标志
    if distance == 1{ string = string+" \(DefaultWords.tomorrow)" ; mouthDay = "\(DefaultWords.tomorrow)"}
    if distance == 2{//检查有没有文字
      string = string+" \(DefaultWords.dayAfterTomorrow)"
      if DefaultWords.dayAfterTomorrow == ""{
        mouthDay = "2 days later"
      }else{
        mouthDay = "\(DefaultWords.dayAfterTomorrow)"
      }
    }
    return (string,mouthDay)
  }
  
  static func changeMonthToDaysIn(year:Int,month:Int)->Int{
    var monthDays:Int = 0
    switch month {
    case 1,3,5,7,8,10,12:
      monthDays = 31
    case 4,6,9,11:
      monthDays = 30
    case 2:
      monthDays = 28
      if year % 4 == 0 {monthDays = 29}//闰年
    default:
      print("month is crazy")
    }//大小月份
    
    return monthDays
  }

}

extension String {//计算字符的高度
  
  func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
    let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
    let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
    
    return ceil(boundingBox.height)
  }
  
  func width(withConstraintedHeight height: CGFloat, font: UIFont) -> CGFloat {
    let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
    let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [NSAttributedStringKey.font: font], context: nil)
    
    return ceil(boundingBox.width)
  }
  
  func size(_ font: UIFont) -> CGSize {
    return NSAttributedString(string: self, attributes: [.font: font]).size()
  }
  
  func width(_ font: UIFont) -> CGFloat {
    return size(font).width
  }
  
  func height(_ font: UIFont) -> CGFloat {
    return size(font).height
  }
}

extension Date {
  static func distance(from date:Date) -> Int{
    let daysSecond:TimeInterval = 86400
    let curreentDate = Date()
    let noon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: curreentDate)!
    let timeInterval = noon.timeIntervalSince(date)
    return Int(timeInterval/daysSecond)
  }
}
