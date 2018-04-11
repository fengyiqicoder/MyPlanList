//
//  Models.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/1/28.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications


struct keyOfUserDefluatData {
  static let widgeData = "WidgeData"
  static let widgeBundleID = "group.com.fengyiqi.ChartTest-com.fengyiqi.newPlanListNew.widge"
}

class PlanerModel {
  
  init() {//初始化时自动获取储存的数据
    getFinishedEvents()
    getScreenEvents()
  }
  
  //储存显示在屏幕上的事件 每天的Collection为一个[EventsData]数组
  var eventsOnScreenArray:[[EventsData]] = []{
    didSet{//使用之后自动排序 并保存
      for (order,collections) in eventsOnScreenArray.enumerated(){
        eventsOnScreenArray[order] = collections.sorted(by: { (event1, event2) -> Bool in
          return event1.time < event2.time
        })
      }
      saveScreenEvent()
      saveTodaysEventForWidge()
//      print("Saved screen event")
    }
  }
  
  //储存所有做过的事件 为了生成图表储存
  var finishedEventsArray:[EventsData] = []
  
  //获取commonEvent数组
  lazy var commonEventNamesArray:[String] = {
    var array:[(name:String,times:Int,lastDate:MonthDay)] = []
    for oldData in finishedEventsArray {
      //加入commonEvent数组
      var hadThisString = false
      for (order,data) in array.enumerated() {
        if data.name == oldData.name{
          hadThisString = true
          array[order].times += 1
          //比较是否是最新的date
          if oldData.date>data.lastDate {
            array[order].lastDate = oldData.date
          }
        }
      }
      //没有这个字符串
      if !hadThisString{
        //增加新的
        array.append((oldData.name,1,oldData.date))
      }
    }
    //进行排序 新添加的时间就放在前面
    array = array.sorted(by: { (data1, data2) -> Bool in
      if data1.times > data2.times {
        return true
      }else{
        if data1.times == data2.times{
          return data1.lastDate > data2.lastDate
        }
        return false
      }
    })
    for data in array{
      print(data.name," ",data.times)
    }
    return array.map({ (data) -> String in data.name })
  }()
  
  //向某一个collection添加事件   ——— 自动排序
  func add(event:EventsData,collectionOrder:Int) {//输入事件数据和所在集合位置
    if collectionOrder <= eventsOnScreenArray.endIndex-1{//判断是否超过范围
      //存在直接加入
      eventsOnScreenArray[collectionOrder].append(event)
    }else{
      //不存在发出错误
      print("do not exist the collection")
    }
  }
  
  //添加一个新的collcection
  func addANewCollection() {
    eventsOnScreenArray.append([])//添加一个空数组
  }
  
  //删除最下面的collection
  func deleteCollection() {
    eventsOnScreenArray.removeLast()
  }
  
  //删除事件数据
  @discardableResult func delete(event:EventsData,collectionOrder:Int) -> Bool {//指明事件所在的集合
      for (order,events) in eventsOnScreenArray[collectionOrder].enumerated(){
//        print(events.name," ",events)
        if event == events{
          eventsOnScreenArray[collectionOrder].remove(at: order)
          return true
        }
      }
    return false
  }
  
  //改变数据 不需要指定集合
  func change(event:EventsData) -> Bool {
    for (corder,collections) in eventsOnScreenArray.enumerated(){
      for (order,events) in collections.enumerated(){//遍历集合
//        print(events.name)
        if events == event{//找到
          eventsOnScreenArray[corder][order] = event
          return true
        }
      }
    }
    return false
  }
  
  func clearAllOldEventsData() {
    finishedEventsArray.removeAll()
    saveFinishedEvents()
  }
  
  func saveAndClearAllTodaysEvents() {//判断每天的所有事件完成之后执行
    
    //删除今日的事件
    if eventsOnScreenArray.count > 0 {//检查是否有collection
      //将所有屏幕上显示为今日的事件储存
      finishedEventsArray = eventsOnScreenArray[0] + finishedEventsArray //新的数据放在前面
      eventsOnScreenArray.removeFirst()
    }
    //保存事件
    saveFinishedEvents()
  }
  
  func find(event:EventsData) -> (collection:Int,order:Int)? {//在所有的collection中寻找
    for (cOrder,collections) in eventsOnScreenArray.enumerated(){
      for (order,events) in collections.enumerated(){
        if events == event{
          return (cOrder,order)
        }
      }
    }
    return nil
      
  }
  //test Notification
  static func checkNotification(forID string:String?){
    if let id = string{
      UNUserNotificationCenter.current().getPendingNotificationRequests { (pendingRequests) in
        for request in pendingRequests{//check notification array
          print("id \(id) and request \(request.identifier)")
          if request.identifier == id{
            print("have request \(id) in UserNotificationCenter")
          }
        }
      }
    }
  }
  
  //MARK: Widge Event
  
  func saveTodaysEventForWidge() {
    var todaysDataString = ""
    if let todaysEvent = eventsOnScreenArray.first {
      for eventData in todaysEvent{
        let dataString = "\(eventData.name)|\(eventData.time.timeString)!"
        todaysDataString += dataString
      }
      //use string
      let userDefault = UserDefaults.init(suiteName: keyOfUserDefluatData.widgeBundleID)
      userDefault?.set(todaysDataString, forKey: keyOfUserDefluatData.widgeData)
      userDefault?.synchronize()
    }
  }
  
  
  
  //MARK: Save and get function
  
  static let documentsDirectory = FileManager().urls(for: .documentDirectory, in: .userDomainMask).first!
  let ArchiveURLForScreenEvents = documentsDirectory.appendingPathComponent("EventsOnScreen")
  let ArchiveURLForOldEvents = documentsDirectory.appendingPathComponent("OldEvents")
  
  private func saveScreenEvent()  {
    NSKeyedArchiver.archiveRootObject(eventsOnScreenArray, toFile: ArchiveURLForScreenEvents.path)
  }
  
   func saveFinishedEvents(){
    NSKeyedArchiver.archiveRootObject(finishedEventsArray, toFile: ArchiveURLForOldEvents.path)
  }
  
  @discardableResult func getScreenEvents() -> Bool {
    if let oldData =  NSKeyedUnarchiver.unarchiveObject(withFile: ArchiveURLForScreenEvents.path) as? [[EventsData]]{
      eventsOnScreenArray = oldData
      return true
    }else{
      return false
    }
  }
  
  @discardableResult func getFinishedEvents() -> Bool {
    if let oldData = NSKeyedUnarchiver.unarchiveObject(withFile: ArchiveURLForOldEvents.path) as? [EventsData]{
      finishedEventsArray = oldData
      return true
    }else{
      return false
    }
  }
  
}

extension PlanerModel{//动画添加视图固定操作
  static func addSubViewWithFlyInAnimationt(to bigview:UIView,view:UIView,delay:TimeInterval,closure:(()->Void)?){
    let finalFrame = view.frame
    let animationStartFrame = view.frame.offsetBy(dx: bigview.frame.width, dy: 0)
//    print("Origin before animate \(animationStartFrame.origin) origin after animate \(finalFrame.origin) ")
    view.frame = animationStartFrame
    bigview.addSubview(view)
    UIView.animate(withDuration: Constants.moveDownAnimationDuration,
                   delay: delay,
                   options: UIViewAnimationOptions.curveEaseInOut,
                   animations: {
                   view.frame.origin = finalFrame.origin
    }, completion: {(bool) in
      if let actuclClosure = closure{
        actuclClosure()
      }
    })
  }
  static func flyOutAndRemoveView(view:UIView,closure:(()->Void)?){
//    print("FlyOutAnimation")
    let removeDistance = view.frame.width
    UIView.animate(withDuration: Constants.moveDownAnimationDuration,
                   animations: {
                   view.frame.origin.x = -removeDistance
    }) { (bool) in
      view.removeFromSuperview()
      //进行额外的操作
      if let actuclClosure = closure{
        actuclClosure()
      }
    }
  }
  static func animteTo(frame:CGRect,view:UIView){
    UIView.animate(withDuration: Constants.moveDownAnimationDuration) {
      view.frame = frame
    }
  }
  
}



