//
//  ViewController.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/1/23.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import UIKit
import UserNotifications


class MainController: UIViewController {
  
  //模型
  let model = PlanerModel()
  lazy var IAPcontroller:IAPController = { return IAPController(delegate:self) }()
  
  var isEditingEvent:Bool = false{
    didSet{
      if isEditingEvent {
        scrollView.isScrollEnabled = false
      }else{
        scrollView.isScrollEnabled = true
      }
    }
  }
  
  
  @IBOutlet weak var topView: UIView!
  @IBOutlet weak var timeManagementButton: UIButton!
  @IBOutlet weak var addNewCollectionButton: UIButton!
  
  @IBOutlet weak var titleLabel: UILabel!
  @IBOutlet weak var scrollView: UIScrollView!
  var commonEventView:CommonEventView?
  //collection 视图控制器
  var collectionArray:[CollectionView] = []{
    didSet{
      //更新scrollViews的contentSize
      scrollView.contentSize.height = collectionArray.last?.frame.maxY ?? 0
      print("集合的数量\(collectionArray.count)")
    }
  }
  //MARK: - Lift cycle
  override func viewDidLoad() {
    super.viewDidLoad()
    
    //检查语言
    let language = Locale.preferredLanguages[0]
    let languageCode = language[language.startIndex...language.index(after: language.startIndex)]
    if languageCode == "zh"{
      DefaultWords.changeToChinese()
    }
    //提出请求
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert,.sound,.badge]) { (success,_ ) in
      if success {
        print("User Notification can be used")
      }else{
        print("Notification can't used")
      }
    }
    
  }

  override func viewWillAppear(_ animated: Bool) {
    //words
    titleLabel.text = DefaultWords.planList
    //设置颜色
    topView.backgroundColor = Constants.mainColor
    //设置时间
    
  }

  var unwinding:Bool = false
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    //check first date
    self.checkFirstLaunch()
    //如果是从unwind那么不进行操作
    if !unwinding {
    //配置scrollView的数据
    scrollView.contentSize = CGSize(width:scrollView.frame.size.width,height:0)
    scrollView.canCancelContentTouches = false//固定scrollView
    scrollView.delegate = self
    scrollView.contentInset = UIEdgeInsets.zero
    scrollView.contentInsetAdjustmentBehavior = .never
    changeDatasToViews(data: model.eventsOnScreenArray)
    print("viewDidAppear")
    }
    //addObserver and check
    self.checkTime()
    NotificationCenter.default.addObserver(self,
                                           selector: #selector(self.checkTime),
                                           name: NSNotification.Name.UIApplicationDidBecomeActive,
                                           object: nil)
//    performSegue(withIdentifier: "info", sender: nil)
    
  }
  
  override func viewDidDisappear(_ animated: Bool) {
    print("removeObserver")
    //remove observer when they isn't that view
    NotificationCenter.default.removeObserver(self,
                                              name:  NSNotification.Name.UIApplicationDidBecomeActive,
                                              object: nil)
  }
  
  //MARK:时间检查代码
  func checkFirstLaunch() {
    if !(UserDefaults.standard.bool(forKey: "HasLaunchedOnce")) {
      // This is the first launch ever
      print("my first time launch")
      //set date to today and date value
      UserDefaults.standard.set(true, forKey: "HasLaunchedOnce")//set the launch value
      let todaysDate = Constants.currentDate
      let todaysNoon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: todaysDate)!
      UserDefaults.standard.set(todaysNoon, forKey: "screenShowingDate")
//      UserDefaults.standard.set(Constants.calendarDate.month,forKey: "screenShowingDateMonth")
      UserDefaults.standard.synchronize()
      model.addANewCollection()
      //出现教程
      self.performSegue(withIdentifier: "info", sender: nil)
    }
  }
  @objc func checkTime() {
    //checkDate
    let screenShowingDate = UserDefaults.standard.object(forKey: "screenShowingDate") as! Date
    let daysDistance = Date.distance(from : screenShowingDate)
    print("CheckDate \(daysDistance)")
    if daysDistance > 0{
      //日期更新到00:00
      let todaysDate = Constants.currentDate
      let todaysNoon = Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: todaysDate)!
      UserDefaults.standard.set(todaysNoon, forKey: "screenShowingDate")
      //saveModel
      for _ in 1...daysDistance {
        model.saveAndClearAllTodaysEvents()
      }
      //clear views
      print("some thing")
      self.removeAllViews()
      //检查是否有今天的集合
      if model.eventsOnScreenArray.isEmpty { model.addANewCollection() }
      //creatViews again
      changeDatasToViews(data: model.eventsOnScreenArray)
    }

    self.checkLampstatus()
  }
  
  func checkLampstatus() {
    //checkLampstatus
    for (order,_) in collectionArray.first!.eventsViewsArray.enumerated() {
      //get eventView
      let event = collectionArray.first!.eventsViewsArray[order]
      
      if let timeData = event.data?.time {  //  确认是否有时间数据
        let currentTime = TimeData.timePoint(point: HourMin(hour:Constants.calendarDate.hour,
                                                            min:Constants.calendarDate.min))
        //三种状态
        var status:LampStatus = LampStatus.yellow
        if TimeData.haveOther(currentTime, and: timeData){
          status = .red
          if event.data!.needNotify {//检查是否有闹钟标志
            event.data!.needNotify = false
            event.alarmButton.isHidden = true
          }
        }
        if timeData < currentTime{
          status = .gray
          if event.data!.needNotify {//检查是否有闹钟标志
            event.data!.needNotify = false
            event.alarmButton.isHidden = true
          }      }
        event.lampStatus = status
      }
    }
  }
  
  //MARK : UI界面代码
  
  func removeAllViews() {
    for collections in collectionArray{
      collections.removeFromSuperview()
    }
    collectionArray.removeAll()
  }
  
  //把数据转化为视图的函数
  func changeDatasToViews(data:[[EventsData]]) {
    self.removeAllViews()
    for collections in data {//便利所有日期集合
      print("显示集合")
      //初始化collection
      let yPosition = collectionArray.last?.frame.maxY ?? 0
      let newCollectionView = CollectionView(yPosition: yPosition, data: collections,
                                             order: collectionArray.endIndex,delegate:self)
      scrollView.addSubview(newCollectionView)
      collectionArray.append(newCollectionView)
    }
  }

  //添加新日期操作 Button操作
  @IBAction func addNewDate() {
    if isEditingEvent { return }
    //更改数据
    model.addANewCollection()
    //更改界面
    let yPosition = collectionArray.last?.frame.maxY ?? 0
    let newCollectionView = CollectionView(yPosition: yPosition, data: [], order: collectionArray.endIndex,delegate:self)
    //滑动scrollView到添加的collectionView
    var scrollViewsShowingYPosition = scrollView.contentSize.height - scrollView.frame.height + newCollectionView.frame.height
    //检查有没滑动为负数
    scrollViewsShowingYPosition = scrollViewsShowingYPosition < 0 ? 0 :scrollViewsShowingYPosition
    scrollView.setContentOffset(CGPoint(x:0,y:scrollViewsShowingYPosition), animated: true)
    PlanerModel.addSubViewWithFlyInAnimationt(to: scrollView, view: newCollectionView,delay:0.1, closure: nil)//动画移入 scrollview
    collectionArray.append(newCollectionView)

  }
  
  //MARK:小黑气泡对应代码
  var collectionOrder:Int?
  var newEventsOrder:Int?
  
  
  @objc func addNewEventAbove(){
    if collectionOrder != nil && newEventsOrder != nil{
      collectionArray[collectionOrder!].addEvents(to: newEventsOrder!, data: nil, animate: true)
    }else{
//      print("addEditingViewOrderIsWrong")
    }
  }
  @objc func deleteEventView(){
    if let corder = collectionOrder , let order = newEventsOrder{
      //删除事件
      collectionArray[corder].eventsViewsArray[order].deleteEventView()
    }
  }
  @objc func addNewEventDown(){
    if collectionOrder != nil && newEventsOrder != nil{
      collectionArray[collectionOrder!].addEvents(to: newEventsOrder!+1, data: nil, animate: true)
    }else{
//      print("addEditingViewOrderIsWrong")
    }
  }
  //控制editingMenu有哪些操作
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    

    if !isEditingEvent && (action == #selector(addNewEventAbove) || action == #selector(addNewEventDown) || action == #selector(deleteEventView)){
      return true
    }
    return false
  }
  
  override var canBecomeFirstResponder: Bool{
    print("显示气泡")
    return !self.isEditingEvent
  }
  
  //MARK: Controller之间跳转
  
  @IBAction func unwind(sender:UIStoryboardSegue)  {
    print("unwindBack")
    unwinding = true
    //查看是否需要清除model的所有数据
    if let unwindController = sender.source as? TimeManagementViewController{
      if unwindController.clearAllData{
        model.clearAllOldEventsData()
      }
    }
  }
  
  //左边的barButton对应方法
  @IBAction func showTimeManagingView(){
    if !isEditingEvent {
      self.performSegue(withIdentifier: "timeManagmentView", sender: nil)
    }
  }
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let id = segue.identifier,id == "timeManagmentView"{
      if let timeManagementController = segue.destination as? TimeManagementViewController{
        //传递数据
        print("传递数据")
        timeManagementController.oldDataArray = self.model.finishedEventsArray
      }
    }else{
      print("传递数据失败")
    }
  }
  
}

extension MainController:UIScrollViewDelegate{
  
  //更新标题文字
  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    
    let offSetY = scrollView.contentOffset.y
    for collectionViews in collectionArray{
      if !scrollView.isVisible(frame: collectionViews.frame) { continue }//跳过不显示的colloction
      if (collectionViews.frame.minY+Constants.collectionStratLine<=offSetY)&&(offSetY<=collectionViews.frame.maxY-Constants.collectionEndDistance){//在范围内
        let newTitle = collectionViews.dateString!
        if titleLabel.text != newTitle{ titleLabel.text = newTitle }//更改视图
        return
      }
    }
    titleLabel.text = DefaultWords.planList
//    print("scrollViews offset \(scrollView.contentOffset.y)")
  }
}


protocol controllerDelegate:class {//collection 使用的方法
  func updateMainScrollView(from collectionOrder:Int,deletingEvents:Bool)
  func lastCollectionsOrder()->Int
  func deleteLastCollectionViews()
  func deleteEventData(data:EventsData,order:Int)
  func showEditingMenu(targetFrame:CGRect,collectionOrder:Int,eventOrder:Int)
  func setScrollViewsOffSet(frameInScrollView:CGRect,distance:CGFloat)
  func checkIfOffsetOutOfRange()
  func upScrollViewsOffset(distance: CGFloat,aniamtion:Bool)
  func showAlert(with string:String,completionBlock: @escaping ()->Void)
  func addNotification(with title:String,date:MonthDay,at time:HourMin,id:String)->Bool
  func removeNotification(id:[String])
  func modal()->PlanerModel
  func disableAllViews(except collectionOrder:Int,eventViewsOrder:Int)
  func enableAllViews()
  func checkLampstatus()
  func isEditing()->Bool
  func addCommonEventView(heightOfKeyBoard:CGFloat,nameTextView:NameTextField)
  func removeCommonEventView()
  func checkIAP() -> Bool
}

extension MainController:controllerDelegate{
  //使用在collection 上的方法
  func modal() -> PlanerModel {
    return self.model
  }
  
  func lastCollectionsOrder() -> Int {
    return collectionArray.endIndex - 1
  }
  //MARK: 锁定系统
  
  func isEditing()->Bool{
    return self.isEditingEvent
  }

  
  func disableAllViews(except collectionOrder:Int,eventViewsOrder:Int) {
    if self.isEditingEvent {return}
    self.isEditingEvent = true
    for (corder,_) in collectionArray.enumerated() {
      for (order,_) in collectionArray[corder].eventsViewsArray.enumerated(){
//        print("fuckers order \(corder) \(order)")
        if corder == collectionOrder && order == eventViewsOrder{
//          print(" order \(collectionOrder) \(eventViewsOrder)")
          //doNothing
        }else{
          //disable it
          collectionArray[corder].eventsViewsArray[order].isUserInteractionEnabled = false
        }
      }
    }
  }
  
  func enableAllViews() {
    self.isEditingEvent = false
    for (corder,_) in collectionArray.enumerated() {
      for (order,_) in collectionArray[corder].eventsViewsArray.enumerated(){
        //enable it
        collectionArray[corder].eventsViewsArray[order].isUserInteractionEnabled = true
      }
    }
  }
  
  //MARK: ScrollViews move
  
  func upScrollViewsOffset(distance: CGFloat,aniamtion:Bool) {
    //    scrollView.contentOffset.y += distance
//    print("upScrollViewsOffset")
    var newOffset = scrollView.contentOffset.y+distance
    if newOffset < 0 {newOffset = 0}
    scrollView.setContentOffset(CGPoint(x:0,y:newOffset), animated: aniamtion)
  }
  
  func updateMainScrollView(from collectionOrder: Int,deletingEvents:Bool) {
    //更新所有的collection的位置
    let collectionOrder = collectionOrder+1 > collectionArray.endIndex ?
      collectionArray.endIndex-1 : collectionOrder//判断是否是在添加新的collection
    
    for collectionBelowsOrder in collectionOrder+1..<collectionArray.endIndex{//添加新的collection的时候不进行循环
      //自动判断需不需要进行动画
      let collectionView = collectionArray[collectionBelowsOrder]//获取view
      let lastCollectioViewOrder = collectionBelowsOrder-1 //最小值为0
      //为了向上移动的效果增加判定的区域
      let frameUpOneCell = CGRect(x: collectionView.frame.origin.x,
                                  y: collectionView.frame.origin.y - Constants.eventsViewsCellsHeight,
                                  width: collectionView.frame.width,
                                  height: collectionView.frame.height+Constants.eventsViewsCellsHeight)
      if scrollView.isVisible(frame: frameUpOneCell){//判断是否可见
        UIView.animate(withDuration: Constants.moveDownAnimationDuration,
                       delay: 0,
                       options: UIViewAnimationOptions.curveEaseInOut,
                       animations: {
                        collectionView.frame.origin.y = self.collectionArray[lastCollectioViewOrder].frame.maxY
        }, completion: {(bool) in
          //动画之后再一次更新scrollViews的contentSize
          self.scrollView.contentSize.height = self.collectionArray.last?.frame.maxY ?? 0
          //          print("self.scrollView.contentSize.height \(self.scrollView.contentSize.height)")
        })
      }else{
        //更改视图
        collectionView.frame.origin.y = collectionArray[lastCollectioViewOrder].frame.maxY
      }
    }
    
    //要是正在删除事件判断需不需要进行额外动画 再进行更新
    let distance = (scrollView.contentOffset.y+scrollView.frame.height) - (scrollView.contentSize.height - Constants.eventsViewsCellsHeight)
    if distance > 0 && deletingEvents{//会进行不丝滑的跳动
      UIView.animate(withDuration: Constants.moveDownAnimationDuration, animations: {//先进行动画
        if self.scrollView.contentOffset.y >= Constants.eventsViewsCellsHeight{
          self.scrollView.contentOffset.y -= Constants.eventsViewsCellsHeight
        }else{
          self.scrollView.contentOffset.y = 0
        }
      })
    }else{
      //更新scrollViews的contentSize 不管是不是最后一个CollectionView
      scrollView.contentSize.height = collectionArray.last?.frame.maxY ?? 0
      //      print("self.scrollView.contentSize.height \(self.scrollView.contentSize.height)")
    }
  }
  
  func setScrollViewsOffSet(frameInScrollView:CGRect,distance:CGFloat){
    let framesYShouldBe = scrollView.contentOffset.y+scrollView.frame.height-distance
    let shouldUpDistance = frameInScrollView.minY - framesYShouldBe//计算多高
        print("framesYShouldBe\(framesYShouldBe)"," shouldUpDistance\(shouldUpDistance)")
    var newOffsetY = scrollView.contentOffset.y + shouldUpDistance//新的位置
    newOffsetY = newOffsetY < 0 ? 0 : newOffsetY //检查有没有小于0
    scrollView.setContentOffset(CGPoint(x:0,y:newOffsetY), animated: true)
        print("scrollView.contentOffset.y \(scrollView.contentOffset.y)")
  }
  func checkIfOffsetOutOfRange() {//在键盘消失的时候检查
    var maxContenOffSetY = scrollView.contentSize.height-scrollView.frame.height
    if maxContenOffSetY <= 0 {maxContenOffSetY = 0}
    if scrollView.contentOffset.y > maxContenOffSetY {
      scrollView.setContentOffset(CGPoint(x:0,y:maxContenOffSetY), animated: true)
    }
//    print("检查Offset是否超过 \( maxContenOffSetY) \(scrollView.contentOffset.y)")
  }
  
  //MARK: 显示提醒
  func showAlert(with string:String,completionBlock: @escaping ()->Void){
    let alertController = UIAlertController(title: string, message: nil, preferredStyle: UIAlertControllerStyle.alert)
    let alertAction = UIAlertAction(title: DefaultWords.OK, style: UIAlertActionStyle.default, handler: nil)
    alertController.addAction(alertAction)
    self.present(alertController, animated: true, completion: completionBlock)
  }
  
  func showEditingMenu(targetFrame:CGRect,collectionOrder:Int,eventOrder:Int) {
    
    let menu = UIMenuController.shared
    //配置按钮
    menu.menuItems = [UIMenuItem(title: DefaultWords.addNewEventAbove,
                                 action: #selector(addNewEventAbove)),
                      UIMenuItem(title: DefaultWords.delete ,
                                 action:#selector(deleteEventView)),
                      UIMenuItem(title: DefaultWords.addNewEventBelow,
                                 action: #selector(addNewEventDown))]
    //向Controller传入数据
    self.collectionOrder = collectionOrder
    self.newEventsOrder = eventOrder
    //对应frame的转化到最上层的View
    let frame = view.convert(targetFrame, from: scrollView)
    menu.setTargetRect(frame, in: self.view)
    menu.setMenuVisible(true, animated: true)
    becomeFirstResponder()
  }
  
  
  
  //MARK: 删除方法
  func deleteLastCollectionViews() {//删除collection只使用此方法
    model.deleteCollection()
    //下滑动画
    let lastViewsHeight = collectionArray.last!.frame.height//获取下滑的距离
    UIView.animate(withDuration: Constants.moveDownAnimationDuration,
                   delay: 0,
                   options: UIViewAnimationOptions.curveEaseInOut,
                   animations: {
                    if self.scrollView.contentSize.height-lastViewsHeight >= self.scrollView.frame.height{
                        self.scrollView.contentOffset.y -= lastViewsHeight//下滑scrollView
                    }else{
                      self.scrollView.contentOffset.y = 0
                    }
    }) { (bool) in
      self.collectionArray.removeLast()//更改contentSize
      //更新scrollViews的contentSize 不管是不是最后一个CollectionView
      self.scrollView.contentSize.height = self.collectionArray.last?.frame.maxY ?? 0
    }
  }
  
  func deleteEventData(data: EventsData,order:Int) {
    let _ = model.delete(event: data, collectionOrder: order)
//    print("Delete result \(bool)")
  }
  //MARK: 常用事件栏
  
  func addCommonEventView(heightOfKeyBoard:CGFloat,nameTextView:NameTextField){
    let height = Constants.commonEventCellsHeight
    let originY = Constants.screenHeight - (heightOfKeyBoard+height)
    let frame = CGRect(x: 0, y: Constants.screenHeight, width: Constants.screenWidth, height: height)
    let newCommonEventView = CommonEventView(frame: frame, strings: model.commonEventNamesArray, nameTextField: nameTextView)
    //显示并且储存
    self.view.addSubview(newCommonEventView)
    commonEventView = newCommonEventView
    UIView.animate(withDuration: 0.23) { self.commonEventView!.frame.origin.y = originY }
  }
  
  func removeCommonEventView()  {
    if let oldCommonEventView = commonEventView {
      oldCommonEventView.removeFromSuperview()
      commonEventView = nil
    }
  }
  
  //MARK:Notificaiton Center
  func addNotification(with title:String,date:MonthDay,at time:HourMin,id:String)->Bool{
    //date notification DAYS!
    let content = UNMutableNotificationContent()
    content.title = title
    content.sound = UNNotificationSound.default()//声音
    //set trigger with date
    let currentHour = Constants.calendarDate.hour
    let currentMin = Constants.calendarDate.min
    let currentDate = MonthDay(year: Constants.calendarDate.year, month: Constants.calendarDate.month, day: Constants.calendarDate.day)
    if (time.hour > currentHour)||(time.hour == currentHour && currentMin < time.min) || !(date==currentDate){//检查添加时间是否在现在的时间之后
      var notificaitonDateComponents = DateComponents()
      notificaitonDateComponents.month = date.month
      notificaitonDateComponents.day = date.day
      notificaitonDateComponents.hour = time.hour
      notificaitonDateComponents.minute = time.min//输入提醒时间点
      let trigger = UNCalendarNotificationTrigger(dateMatching: notificaitonDateComponents, repeats: false)
      let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
      UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
      return true
    }else{
      print("can't add notification")
      return false
    }
    
  }
  
  func removeNotification(id:[String]){
    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: id)
  }
  //MARK: IAP
  func checkIAP() -> Bool {
    return IAPcontroller.checkPurchased()
  }
}

extension MainController:IAPDelegate{
  
  func getHavePaidInUserDefault() -> Bool? {
    if UserDefaults.standard.object(forKey: KeysOfData.havePaid) == nil{
      return nil
    }else{
      return UserDefaults.standard.bool(forKey: KeysOfData.havePaid)
    }
  }
  
  func setHavePaidValueInUserDefault(_ value: Bool) {
    UserDefaults.standard.set(value, forKey: KeysOfData.havePaid)
  }
  
  func getCurrentViewcontroller() -> UIViewController {
    return self
  }
}

extension UIScrollView{
  func isVisible(frame:CGRect) -> Bool {
    let visibleStartLine = self.contentOffset.y
    let visibleEndLine = visibleStartLine + self.frame.height
    if (visibleStartLine<=frame.minY&&frame.minY<=visibleEndLine)||(visibleStartLine<=frame.maxY&&frame.maxY<=visibleEndLine)||(frame.minY<=visibleStartLine&&visibleEndLine<=frame.maxY){//是否在范围内
      return true
    }else{
      return false
    }
  }
}

