//
//  CollectionView.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/1/30.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import UIKit

class CollectionView: UIView {

  //UIViews properties
  var dateLabel:UILabel!
  var addEventsButton:UIButton!
  var rightSideEdge:(up:UIView,right:UIView)!
  var leftSideEdge:(left:UIView,down:UIView)!
  var doNotHaveEventsLabel:UILabel?
  var rightBlockingView:UIView?
  var leftBlockingView:UIView?
  var dateString:String!
  var date:MonthDay!
//  var firstTimeEditingLastEvent = true

  
  //数据源和UI追踪数组 和代理
  var dataArray: [EventsData] {
    return maincontroller.modal().eventsOnScreenArray[order]
  }
  var eventsViewsArray: [EventsView] = []{
    didSet{
      //更新顺序表
      for (order,eventsViews) in eventsViewsArray.enumerated(){
        eventsViews.order = order
      }
    }
  }
  weak var maincontroller:controllerDelegate!
  
  //其他变量
  var order:Int!

  //MARK: - 主要功能
  convenience init(yPosition:CGFloat,data:[EventsData],order:Int,delegate:controllerDelegate){
    self.init(frame: CGRect(x: 0,
                            y: yPosition,//使用固定默认高度(无事件时候的高度)和屏幕宽度
                            width: UIScreen.main.bounds.size.width,
height: Constants.collectionStratLine+Constants.eventsViewsCellsHeight*0.8+Constants.collectionEndDistance))
    //设置delegate
    self.maincontroller = delegate
    //初始化UI
    dateLabel = UILabel(frame: Constants.dateLabelConstantsFrame)//使用固定frame
    let string = Constants.changeDistanceDayToDateString(distance: order)//获取字符串
    dateLabel.text = string.date
    dateString = string.Mouthday
    dateLabel.font = UIFont(name: "HelveticaNeue", size: 26) //使用25号字体
//    print("dateLabelFontName \(dateLabel.font.fontName)")
    addSubview(dateLabel)
    //addButton初始化
    addEventsButton = UIButton(frame: CGRect(origin:
      CGPoint(x:Constants.screenWidth - Constants.addButtonsSize.width - Constants.distanceBetweenItems,
              y:frame.height - Constants.addButtonsSize.height),
              size: Constants.addButtonsSize))//使用固定size
    //设置图片
    addEventsButton.setImage(#imageLiteral(resourceName: "addNewEventImage"), for: .normal)
    addEventsButton.setImage(#imageLiteral(resourceName: "addNewEventPressedImge"), for: .highlighted)
    addEventsButton.setImage(#imageLiteral(resourceName: "addNewEventPressedImge"), for: .selected)
    //设置动作代理
    addEventsButton.addTarget(self, action: #selector(addNewEvent), for: UIControlEvents.touchDown)
    addSubview(addEventsButton)
    //初始化线段
    initEdgeLine()
    //添加数据
    self.order = order
    let currentDate = Constants.changeDistanceDayToDate(order)
    self.date = currentDate.monthday
    for eventsData in data{
      addEvents(to: eventsViewsArray.endIndex, data: eventsData, animate: false)
    }
    checkNeedToAddNoThingLable()
    
  }
  

  
  func addEvents(to order:Int,data:EventsData?,animate:Bool) {//所有的数据来源于此函数 使用于新建事件和数据添加
    //计算位置 上一个视图的底端为新视图的开端 order的取值为0到indexEnd+1
    let yPosition = order == 0 ? Constants.collectionStratLine : eventsViewsArray[order-1].frame.maxY
    //判断是添加全新的View 还是有数据源可以生成
    let newEventView = EventsView(YPosition: yPosition, order: order, data: data, delegate:self)
    
    //加入UI数组 为下移下部视图做准备
    eventsViewsArray.insert(newEventView, at: order)
    self.checkNeedToAddNoThingLable()//检查无事件图标
    //改变界面
    if !animate{//无动画版本
      self.moveAllEventViews(below: order, moveUp: false, animation: false)
      //添加到屏幕（如果没有数据 自动调出输出过程）
      self.addSubview(newEventView)
    }else{//动画版本一定是添加新视图
      moveAllEventViews(below: order, moveUp: false, animation: true)
      //动画移动所有可见的下视图
      PlanerModel.addSubViewWithFlyInAnimationt(to: self, view: newEventView, delay: 0, closure: nil)
      let _ = newEventView.timeLabel.becomeFirstResponder()//动画结束之前调出键盘
    }
    
    //更新collection
    updateCollectionViewHeight(animation: animate, isDeletingEvent: false)
  }
  
  @objc func addNewEvent() {
//    var purchased:Bool = false 内购代码
//    if self.order <= 1 || maincontroller.checkIAP(){
//      purchased = true
//    } && purchased
    if !maincontroller.isEditing(){
      //在最后的位置增加新事件(空数据)
      addEvents(to: eventsViewsArray.endIndex, data: nil, animate: true)
    }
  }
  
  //MARK: - UI界面的更新
  
  func updateCollectionViewHeight(animation:Bool,isDeletingEvent:Bool){
    
    //更改线 addButton 的位置 和frame.size 和剩下的collection的位置
    //计算新的CollectionView的大小
    let newHeight = (eventsViewsArray.last?.frame.maxY ?? (Constants.collectionStratLine+Constants.eventsViewsCellsHeight*0.8)) + Constants.collectionEndDistance
    frame.size.height = newHeight//更新height的大小
    
    func updateRectEdges(){//更新边框代码
      //更新button的位置
      addEventsButton.frame.origin.y = newHeight - addEventsButton.frame.height
      //更新右边框的高度
      let newHeightOfRightLine = addEventsButton.frame.minY - rightSideEdge.up.frame.maxY - Constants.distanceBetweenItems
//      print("Collection newHeightOfRight \(newHeightOfRightLine)")
      rightSideEdge.right.frame.size.height = newHeightOfRightLine
      //更新下边框的位置
      let newYPostionOfDownLine = addEventsButton.center.y + Constants.distanceBetweenItems
      leftSideEdge.down.frame.origin.y = newYPostionOfDownLine
      //更新左边框的高度
      let newHeightOfLeftLine = leftSideEdge.down.frame.minY - leftSideEdge.left.frame.minY
      leftSideEdge.left.frame.size.height = newHeightOfLeftLine
//      print("leftSideEdge.left.frame.origin.x",leftSideEdge.left.frame.origin.x)
    }
    
    
    func updateBlockingView(){//更新blockingView的代码
      //删除旧的view
      if let oldRightView = self.rightBlockingView , let oldLeftView = self.leftBlockingView{
        oldLeftView.removeFromSuperview()
        oldRightView.removeFromSuperview()
      }
      let newLeftBlockView =  UIView(frame: CGRect(x: 0, y: leftSideEdge.left.frame.minY,
                                                  width: leftSideEdge.left.frame.minX, height: leftSideEdge.left.frame.height))
      newLeftBlockView.backgroundColor = UIColor.white
      self.addSubview(newLeftBlockView)
      //储存视图
      leftBlockingView = newLeftBlockView
      
      let newRightBlockView = UIView(frame: CGRect(x: rightSideEdge.up.frame.maxX,
                                                   y: rightSideEdge.up.frame.minY,
                                                   width: self.frame.width - rightSideEdge.right.frame.maxX,
                                                   height: rightSideEdge.right.frame.height))
      
      newRightBlockView.backgroundColor = UIColor.white
      self.addSubview(newRightBlockView)
      //saved
      rightBlockingView = newRightBlockView
      //将blockingViews放到最前
      if let rightBlockingView = rightBlockingView , let leftBlockingView = leftBlockingView{
        self.bringSubview(toFront: rightBlockingView)
        self.bringSubview(toFront: leftBlockingView)
        self.bringSubview(toFront: rightSideEdge.right)
        self.bringSubview(toFront: leftSideEdge.left)
      }
    }
    
   
    if animation {//判断是否进行动画
      UIView.animate(withDuration: Constants.moveDownAnimationDuration,
                     delay: 0,
                     options: UIViewAnimationOptions.curveEaseInOut,
                     animations: { updateRectEdges()},
                     completion: {(bool) in })
    }else{
      updateRectEdges()
    }
    //更新阻挡Views的位置
    updateBlockingView()
    
    //更新其他collection的位置
    maincontroller.updateMainScrollView(from: order, deletingEvents: isDeletingEvent)
    
    
  }
  
  func moveAllEventViews(below order:Int,moveUp:Bool,animation:Bool) {//将新创建的事件视图加入数组后调用此方法
    //移动所有的下视图
    let order = moveUp ? order-1 : order//向上向下的开始顺序不同
    //仅仅动画移动在界面上显示的eventView就足够了
    var animationStartEventsViewsOrder = 0
    var animationEndEventViewsOrder = 0
    if animation{
      //动画开始的那个view的order
      animationStartEventsViewsOrder = order+1
      //动画结束的那个view的order
      animationEndEventViewsOrder = order+Constants.shouldAnimateEventsView//要是所有需要动画的EventView多过所有拥有的视图也没事
    }
    
    for downViewsOrder in order+1..<eventsViewsArray.endIndex{//注意范围 在末尾添加视图的时候循环不执行
      //找到的要移动的视图的上一个视图
      let lastLine = downViewsOrder-1 < 0 ? Constants.collectionStratLine : eventsViewsArray[downViewsOrder-1].frame.maxY
      
      if animation,
        (animationStartEventsViewsOrder<=downViewsOrder && downViewsOrder <= animationEndEventViewsOrder) {//如果要进行动画在范围内
        UIView.animate(withDuration: Constants.moveDownAnimationDuration,
                       delay: 0,
                       options: UIViewAnimationOptions.curveEaseInOut,
                       animations: {
                       //把要移动的视图的Y坐标更改
                       self.eventsViewsArray[downViewsOrder].frame.origin.y = lastLine
                       },
                       completion: nil)
      }else{//不执行动画
        //把要移动的视图的Y坐标更改
        eventsViewsArray[downViewsOrder].frame.origin.y = lastLine
      }
    }
  }
  
  func checkNeedToAddNoThingLable() {
    if eventsViewsArray.isEmpty{//检查有没有事件
      //添加无事件图标
      doNotHaveEventsLabel = UILabel(frame: CGRect(x: 0, y: self.frame.height/2 - 33/2,
                                                   width: Constants.screenWidth, height: 33))
      doNotHaveEventsLabel!.text = DefaultWords.noDataForCollecitionView
      doNotHaveEventsLabel!.font = UIFont.systemFont(ofSize: 28, weight: UIFont.Weight.regular)
      doNotHaveEventsLabel!.textColor = UIColor.gray
      doNotHaveEventsLabel!.textAlignment = .center//配置所有的属性
      addSubview(doNotHaveEventsLabel!)
      //出现动画
      doNotHaveEventsLabel!.alpha = 0
      UIView.animate(withDuration: Constants.moveDownAnimationDuration*0.1, animations: {
        self.doNotHaveEventsLabel!.alpha = 1
      })
    }else{
      UIView.animate(withDuration: Constants.moveDownAnimationDuration*0.618, animations: {
        self.doNotHaveEventsLabel?.alpha = 0
      }, completion: { (bool) in
        //删除无事件标签
        self.doNotHaveEventsLabel?.removeFromSuperview()
        self.doNotHaveEventsLabel = nil
      })
    }
  }
  
  func initEdgeLine() {
    
    //初始化曲线
    //右边曲线的开始点
    let x1 = dateLabel.text!.width(withConstraintedHeight: dateLabel.frame.height, font: dateLabel.font) + Constants.distanceBetweenItems//字体的宽度 + 固定的距离 = 横坐标
    let y1 = dateLabel.center.y - Constants.widthOfLine/2 //日期标签的中间的纵坐标 - 线条的宽度/2
    //右边曲线的拐点计算宽度
    let width1 = Constants.screenWidth - x1 - Constants.rightGap
    let upLine = UIView(frame: CGRect(x: x1, y: y1, width: width1, height: Constants.widthOfLine))
    upLine.backgroundColor = UIColor.black
    addSubview(upLine)
    //计算开始点
    let x2 = upLine.frame.maxX - Constants.widthOfLine //减去线的宽度
    let y2 = upLine.frame.maxY
    //右边曲线的结束点计算高度
    let height2 = addEventsButton.frame.minY - Constants.distanceBetweenItems - y2//addButton的Y坐标减去upline的Y坐标
    let rightLine = UIView(frame: CGRect(x: x2, y: y2, width: Constants.widthOfLine, height: height2))
    rightLine.backgroundColor = UIColor.black
    addSubview(rightLine)
    //储存
    rightSideEdge = (upLine,rightLine)
    
    //左边边缘的线段
    //开始点
    let x3 = Constants.leftGap
    let y3 = dateLabel.frame.maxY+Constants.distanceBetweenItems
    //拐点计算
    let height = addEventsButton.center.y - y3 + Constants.distanceBetweenItems//Y坐标相减
    let leftLine = UIView(frame: CGRect(x: x3, y: y3, width: Constants.widthOfLine, height: height))
    //配置UIView
    leftLine.backgroundColor = UIColor.black
    addSubview(leftLine)
    //downLine
    let x4 = leftLine.frame.minX
    let y4 = leftLine.frame.maxY - Constants.widthOfLine/2
    let width4 = addEventsButton.frame.minX - x4 - Constants.distanceBetweenItems
    let downLine = UIView(frame: CGRect(x: x4, y: y4, width: width4, height: Constants.widthOfLine))
    //添加线到屏幕上
    downLine.backgroundColor = UIColor.black
    addSubview(downLine)
    //添加数据
    leftSideEdge = (leftLine,downLine)
  }
  
  //MARK: - 选择系统
  
  var touchBeginPoint:CGPoint = CGPoint.zero
  var moveDistance:CGFloat = 0
  var originalFrame:CGRect = CGRect.zero
  //status
  var isEditingCollection:Bool = false
  var canBeDelete:Bool {
    if order != 0 && order == maincontroller.lastCollectionsOrder(){
      return true //今天的colloction无法删除
    }else{
      return false
    }
    
  }
  
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesBegan(touches, with: event)
    if canBeDelete && !maincontroller.isEditing(){
      touchBeginPoint = touches.first!.location(in: self)//储存触摸点在collection上的位置
      if (touchBeginPoint.y<=Constants.collectionStratLine)||(self.frame.height-Constants.collectionEndDistance<=touchBeginPoint.y)||(doNotHaveEventsLabel != nil) {
        //触摸了上半部分 或者下半部分 或者无事件
        isEditingCollection = true
        originalFrame = self.frame
      }
    }
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?){
    super.touchesMoved(touches, with: event)
    if canBeDelete&&isEditingCollection{
      
      //获取移动距离
      let touchPoint = touches.first!.location(in: self)
      let touchPointInScrollView = self.superview!.convert(touchPoint, from: self)
      moveDistance = touchPointInScrollView.x - touchBeginPoint.x
//      print("moveDistance \(moveDistance)")
      // 移动Collection
      self.frame.origin.x = moveDistance
      
    }
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesEnded(touches, with: event)
    if canBeDelete&&isEditingCollection{
//      print("touchesEnded")
      //判断距离是否足够删除
      if -moveDistance > Constants.deleteDistance{
        //删除事件view
        PlanerModel.flyOutAndRemoveView(view: self, closure: nil)
        //删除数据并且更新视图
        maincontroller.deleteLastCollectionViews()
      }else{
        //不足够就恢复视图
        PlanerModel.animteTo(frame: originalFrame, view: self)
      }
      isEditingCollection = false
    }
  }
  
  override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
    super.touchesCancelled(touches, with: event)
    if canBeDelete&&isEditingCollection {
      //恢复视图
      PlanerModel.animteTo(frame: originalFrame, view: self)
      isEditingCollection = false
    }
  }
  
}

protocol CollectionViewDelegate:class {
  func deleteEventsView(order:Int)
  func showEditingMenu(eventsFrame:CGRect,eventsOrder:Int)
  func setScrollviewsOffsetWith(eventsOrder:Int,frameFromCollection:CGRect,distance:CGFloat)
  func checkScrollViewsOffset()
  func updateEventViewsForTextView(eventsOrder:Int,moveDistance:CGFloat)
//  func isThisEventLastEventInScrollView(eventsOrder:Int)->Bool
  func isThisEventLastEventInThisCollectionAndStartAfterNine(eventsOrder:Int)->Bool
  func checkFeasibility(timeData: TimeData,eventsOrder:Int) -> (result:Bool,error:String?)
  func checkOrderAndSaveDataToModelAndCollection(order:Int)
  func show(message: String,completionBlock: @escaping ()->Void)
  func mainControllerDelegete()->controllerDelegate
  func collectionDate()->MonthDay
  func disableViews(order:Int)
}

extension CollectionView: CollectionViewDelegate{
  
  func mainControllerDelegete()->controllerDelegate{
    return self.maincontroller
  }
  
  func collectionDate() -> MonthDay {
    return self.date
  }
  func disableViews(order:Int) {
    maincontroller.disableAllViews(except: self.order, eventViewsOrder: order)
  }
  //MARK:更新UI界面
//  func isThisEventLastEventInScrollView(eventsOrder: Int) -> Bool {
//
//    return false
//  }
  
  func updateEventViewsForTextView(eventsOrder:Int,moveDistance: CGFloat) {
    //更新collectionView和scrollView的frame
    print("updateEventViewsForTextView")
    moveAllEventViews(below: eventsOrder, moveUp: false, animation: true)
    updateCollectionViewHeight(animation: true, isDeletingEvent: false)
    //查看是否是最上面的两个eventView
    let isFirstEventView = (self.order == 0)&&(eventsOrder==0)
    let isSecondEventView = (self.order == 0)&&(eventsOrder==1)
    //如果是最后一个EventView不滚动
    if maincontroller.lastCollectionsOrder() == self.order && eventsOrder == eventsViewsArray.endIndex-1 ,!isFirstEventView{
      let distance:CGFloat = isSecondEventView ? 120 : 250 //如果是第二个View滑动长度变短
      maincontroller.upScrollViewsOffset(distance: distance, aniamtion: false)
    }else{
      //滑动scrollView
      maincontroller.upScrollViewsOffset(distance: moveDistance,aniamtion: true)
    }
  }
  
  func checkScrollViewsOffset() {
    maincontroller.checkIfOffsetOutOfRange()
  }
  
  func setScrollviewsOffsetWith(eventsOrder:Int,frameFromCollection: CGRect, distance: CGFloat) {
    let frameInScrollView = self.superview!.convert(frameFromCollection, from:self)
    print("frameInScrollView \(frameInScrollView)")
    //如果是最后一个EventView不滚动
    maincontroller.setScrollViewsOffSet(frameInScrollView: frameInScrollView, distance: distance)
  }
  //MARK:显示提醒
  func showEditingMenu(eventsFrame: CGRect, eventsOrder: Int) {
    //采集完整数据
    let scrollViewsFrame = self.superview!.convert(eventsFrame, from: self)
//    print("scrollViewsFrame",scrollViewsFrame)
    maincontroller.showEditingMenu(targetFrame: scrollViewsFrame, collectionOrder: self.order, eventOrder: eventsOrder)
  }
  
  
  func show(message: String,completionBlock: @escaping ()->Void) {
    maincontroller.showAlert(with: message, completionBlock: completionBlock)
  }
  
  //MARK:数据更改或确认
  func deleteEventsView(order:Int) {
    //删除数据
    if let data = eventsViewsArray[order].data{
      print("order \(order)and data \(data.name)")
      //在model里删除它
      maincontroller.deleteEventData(data: data, order: self.order)
      //在数组中删除它
//      dataArray.remove(at: dataArray.index(of: data)! )
    }
    //在array里面删除它
    eventsViewsArray.remove(at: order)
    //上移所有下面的view
    moveAllEventViews(below: order, moveUp: true, animation: true)
    //更新Collection的高度
    updateCollectionViewHeight(animation: true,isDeletingEvent:true)
    //检查是否需要增加无事件图标
    checkNeedToAddNoThingLable()
  }
  
  
  

  
  func isThisEventLastEventInThisCollectionAndStartAfterNine(eventsOrder: Int) -> Bool {
    if eventsOrder == 0 {return false}
    if eventsOrder == eventsViewsArray.endIndex-1{
//      大于18点
//      let data = eventsViewsArray[eventsOrder].data
      return true
    }
    return false
  }
  
  func checkFeasibility(timeData: TimeData,eventsOrder:Int) -> (result:Bool,error:String?) {
    print("当前顺序\(eventsOrder)")
    let lastEventsData = eventsOrder-1 < 0 ? nil : dataArray[eventsOrder-1]
    var addtionOrder = 1
    if dataArray.count != eventsViewsArray.count{ addtionOrder = 0 }//判断是否正在增加newEventView
    print("是否正在增加newEventView\(eventsOrder+addtionOrder) \(dataArray.endIndex-1)")
    let nextEventsData = eventsOrder+addtionOrder > dataArray.endIndex-1 ? nil : dataArray[eventsOrder+addtionOrder]
    if let lastData = lastEventsData {
      print("上一个事件的数据\(lastData.time.timeString)")
      let lastPoint:HourMin//上个事件最后的时间
      switch lastData.time{
      case .timeBucket(startPoint: _, endPoint: let endPoint): lastPoint = endPoint
      case .timePoint(point: let point): lastPoint = point
      }
      let startPoint:HourMin//这个事件开始的时间
      switch timeData{
      case .timePoint(point: let point):startPoint = point
      case .timeBucket(startPoint: let start, endPoint: _):startPoint = start
      }
      if (startPoint<lastPoint){
        let name = lastData.name
        let string = DefaultWords.timeErrorConflictWithLast1+lastPoint.string()+DefaultWords.timeErrorConflictWithLast2+name+DefaultWords.timeErrorConflictWithLast3
        return (false,string)
      }
    }
    if let nextData = nextEventsData{
      print("下一个事件的数据\(nextData.time.timeString)")
      let lastPoint:HourMin//这个事件最后的时间
      switch timeData{
      case .timeBucket(startPoint: _, endPoint: let endPoint): lastPoint = endPoint
      case .timePoint(point: let point): lastPoint = point
      }
      let startPoint:HourMin//下个事件开始的时间
      switch nextData.time{
      case .timePoint(point: let point):startPoint = point
      case .timeBucket(startPoint: let start, endPoint: _):startPoint = start
      }
      if (startPoint<lastPoint){
        let name = nextData.name
        let string = DefaultWords.timeErrorConflictWithNext1+startPoint.string()+DefaultWords.timeErrorConflictWithNext2+name+DefaultWords.timeErrorConflictWithNext3
        return (false,string)
      }
    }
//    for (order,data) in dataArray.enumerated() {
//     print("数据数组中的数据 \(order) \(data.name)")
//      if TimeData.haveOther(timeData,and:data.time) && order != eventsOrder{
//        print("EventsViewws 顺序 \(order) \(eventsOrder)")
//        let name = data.name
//        let dateString = data.time.timeString
//        let string = "与安排在 \(dateString)的“\(name)”事件冲突"
//        return (false,string)
//      }
//    }
    return (true,nil)
  }
  
  func checkOrderAndSaveDataToModelAndCollection(order:Int) {
    let eventView = eventsViewsArray[order]
    //保存数据到model
    let data = eventView.data!
    print("checkOrderAndSaveDataToModelAndCollection")
    if !maincontroller.modal().change(event: data){//尝试更改
      //不存在就增加
      maincontroller.modal().add(event: data, collectionOrder: self.order)
    }
    //更改notification的数据
    eventView.changeNotificaionsMessage(newData: data)
//    let newOrder = dataArray.index(of: data)!
//    //确认顺序
//    if newOrder != order{
////      更改视图
//      print("should change view")
//    }
    //检查lampStatus
    maincontroller.checkLampstatus()
//    firstTimeEditingLastEvent = true
  }
  
  
  
}
