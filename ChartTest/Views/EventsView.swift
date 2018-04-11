//
//  EventsView.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/1/28.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import UIKit
import UserNotifications

class EventsView: UIView {
  
  var longPressRecognizer: UILongPressGestureRecognizer!
  //UIViews
  @IBOutlet weak var lamp: UIButton!
  @IBOutlet weak var timeLabel: TimeTextField!
  @IBOutlet weak var nameLabel: NameTextField!
  @IBOutlet weak var addDescriptionButton: UIButton!
  var descriTextView:ownTextView?
  var clockButton:UIButton?
  @IBOutlet weak var alarmButton: UIButton!
  
  @IBOutlet weak var lampImageView: UIImageView!
  //status
  var deletingEvent:Bool = false
  var lampStatus:LampStatus = .yellow{
    didSet{
      switch lampStatus {
      case .gray: lampImageView.image = #imageLiteral(resourceName: "grayLamp")
      case .yellow:lampImageView.image = #imageLiteral(resourceName: "yellowLamp")
      case .red:lampImageView.image = #imageLiteral(resourceName: "radLamp")
      }
    }
  }
  //指明在collection中的顺序
  var order:Int!//时间检查有关
  
  //Data 数据源
  var data:EventsData? //每次对data的改变都要改变model并且collection检查时间点（排列顺序）
  var collection:CollectionViewDelegate!
  //三个计算变量方便对界面的改变
  var timeText:String?{
    get{
      return timeLabel.text
    }
    set{
      timeLabel.text = newValue
    }
  }
  var nameText:String?{
    get{
      return nameLabel.text
    }
    set{
      nameLabel.text = newValue
    }
  }
  //可能没有的详细说明
  var descri:String?{
    get{
      return descriTextView?.text
    }
    set{
      if let newText = newValue{//有输入文字
        //创建新的textView 可能需要更改View的高度
        descriTextView = ownTextView(frame: addDescriptionButton.frame)
        descriTextView!.text = newText//输入文字之后计算文字高度
        descriTextView!.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.light)
        descriTextView!.frame.size.height = getAddedHeight(of: descriTextView)!//更新TextView的高度
        descriTextView!.backgroundColor = UIColor.clear
        descriTextView!.textAlignment = .left
        descriTextView!.delegate = self
        descriTextView!.ownDelegate = self
        descriTextView!.returnKeyType = .done
        descriTextView!.textContainer.maximumNumberOfLines = 5
        descriTextView!.textContainer.lineBreakMode = .byTruncatingTail
        //添加textView到屏幕
        view.addSubview(descriTextView!)
        //更新eventView的高度
        let newEventViewsHeight = descriTextView!.frame.maxY
        frame.size.height = newEventViewsHeight
//        print("EventsView newDescripTion\(newText)")
        //关闭按钮操作
        addDescriptionButton.isHidden = true
      }else{//没有文字
        //删除TextView
        descriTextView?.removeFromSuperview()
        //开启按钮操作
        addDescriptionButton.isHidden = false
      }
    }
  }
  var descriptionTextViewsCurrentHeight:CGFloat{//注意使用的时候一定要有 descriTextView
    get{
      if let height = descriTextView?.frame.height{
        return height
      }else{
        return 0
      }
    }
    set{
      descriTextView!.frame.size.height = newValue
    }
  }
  
  
  //MARK: - 主要功能
  
  convenience init(YPosition:CGFloat,order:Int,data:EventsData?,delegate:CollectionViewDelegate) {//输入Y轴位置和屏幕宽度 数据源 还有顺序
    //固定X为0 高度为131 宽度为屏幕宽度？
    self.init(frame:CGRect(x:0,y:YPosition,
                           width:Constants.screenWidth,height:Constants.eventsViewsCellsHeight))
    //设置placeholder
    nameLabel.placeholder = DefaultWords.nameLabelPlaceholder
    timeLabel.placeholder = DefaultWords.timeLabelPlaceholder
    view.frame.size.width = Constants.screenWidth//更改.xib视图的宽度
    view.layoutIfNeeded()//重新计算子视图的frame
    self.order = order//开始数据赋值
    self.data = data//传入数据(可能没有)
    self.collection = delegate
    if let inputData = data{//判断是否是新添加的数据
      //在UI界面上表现数据
      descri = inputData.descri
      nameText = inputData.name
      timeText = inputData.time.timeString
      if inputData.needNotify{alarmButton.isHidden = false}
    }
    //配置gestureRecognizer
    longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGesture(_:)))
    view.addGestureRecognizer(longPressRecognizer)
    //配置 text views
    timeLabel.timeTextDelegate = self
    timeLabel.setAsCustomKeyBoard(delegateForEventView:self)
    nameLabel.delegate = self
    
  }
  
  func checkEventIfCanBeSaved() -> Bool{
    var timeDataIsChecked = false
    //进行时间数据的判断
    let currentTimeString = timeLabel.text!
    let result = currentTimeString.check(midnight: false)//midnight⚠️
    //判断时间格式是否正确
    if let newTimeData = result.data,collection.checkFeasibility(timeData: newTimeData, eventsOrder: self.order).result{
      timeDataIsChecked = true
    }
    print(timeDataIsChecked)
    //进行名称的判断
    var nameTextIsChecked = false
    let currentNameText = nameLabel.text
    if currentNameText != ""{
      nameTextIsChecked = true
    }
    //返回结果
    return timeDataIsChecked&&nameTextIsChecked
  }
  
  @IBAction func pressedDescriptionCreateButton(){
//    print("pressing button")
    if descriTextView == nil,checkEventIfCanBeSaved(){//没有descri
      //创建一个
      descriTextView = ownTextView(frame:addDescriptionButton.frame)
      descriTextView!.font = UIFont.systemFont(ofSize: 18, weight: UIFont.Weight.light)
      descriTextView!.backgroundColor = UIColor.clear
      descriTextView!.textAlignment = .left
      descriTextView!.delegate = self
      descriTextView!.returnKeyType = .done
      descriTextView!.ownDelegate = self
      descriTextView!.textContainer.maximumNumberOfLines = 5
      descriTextView!.textContainer.lineBreakMode = .byTruncatingTail
      //更新TextView的高度
      descriptionTextViewsCurrentHeight = getAddedHeight(of: descriTextView)!
      view.addSubview(descriTextView!)
      //更新eventCell的高度
      let newHeight = descriTextView!.frame.maxY
//      print("newHeight\(newHeight)")
      self.frame.size.height = newHeight
      collection.updateEventViewsForTextView(eventsOrder: self.order,
                                             moveDistance: descriptionTextViewsCurrentHeight-Constants.eventsViewsTextViewsDefaultHeight)
//      print("getAddedHeight \(getAddedHeight(of: descriTextView)!)")
      //隐藏button
      addDescriptionButton.isHidden = true
      //focus descriTextView
      let _ = descriTextView!.becomeFirstResponder()
    }
  }
  
  func getAddedHeight(of textViews:UITextView?) -> CGFloat? {//返回文本高度加上原来的高度
    if let textView = textViews {
      //get the text SIZE
      let sizeThatFitsTextView = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: Constants.eventsViewsCellsHeight))
      let heightOfText = sizeThatFitsTextView.height
      //返回TextView的默认值height加上字体的高度
//      print("textViews height \(textView.frame.height)")
      return heightOfText+Constants.eventsViewsTextViewsDefaultHeight
    }else{
      print("Dont have descriptionView")
      return nil
    }
    
  }
  
  func showSpendTimeForTimeTextFeild(time:HourMin){
    //在timeTextField上创建
    let showingTextLabel = UILabel(frame: timeLabel.frame)
    showingTextLabel.text = "\(time.hour)\(DefaultWords.hours)\(time.min)\(DefaultWords.mins)"
    showingTextLabel.font = timeLabel.font
    showingTextLabel.textAlignment = .center
    showingTextLabel.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
    showingTextLabel.alpha = 0
    view.addSubview(showingTextLabel)
    UIView.animate(withDuration: Constants.moveDownAnimationDuration*0.7,
                   delay: 0, options: [UIViewAnimationOptions.curveEaseInOut,UIViewAnimationOptions.beginFromCurrentState],
                   animations: {showingTextLabel.alpha = 1}, completion: nil)
    UIView.animate(withDuration: Constants.moveDownAnimationDuration*0.7,
                   delay: Constants.moveDownAnimationDuration*1.5,
                   options: [UIViewAnimationOptions.curveEaseInOut,UIViewAnimationOptions.beginFromCurrentState],
                   animations: {showingTextLabel.alpha = 0},
                   completion: {(bool) in showingTextLabel.removeFromSuperview()})
  }
  
  var newTimeData:TimeData?
  var newNameData:String?
  var newDescriptionData:String?
  
  func saveNewData() {
    if let timeData = newTimeData,let nameData = newNameData{
      let newData = EventsData(name: nameData , description: newDescriptionData,
                               notifiction: false, date: collection.collectionDate(),
                               time: timeData, notificationString: nil)
      //赋值给data并且储存
      self.data = newData
      collection.checkOrderAndSaveDataToModelAndCollection(order: self.order)
    }
  }
  //MARK: - 通知系统
  var notificationString:String {
    if let oldString = data?.notificationString{
      return oldString//如果有之前的idtentify就使用之前的
    }else{
     //生成新的独一无二的idtenify 第一次添加提醒才会生成
     let newNotifictionString = String(Constants.currentDate.timeIntervalSince1970)
     //储存到data中并且保存 ⚠️
      data?.notificationString = newNotifictionString
     return newNotifictionString
    }
  }
  
  @IBAction func changeNotificaitonStatus() {//有事件数据之后调用(锁定系统)
    //如果正在修改不执行操作
    if collection.mainControllerDelegete().isEditing() {return }
    if let data = data ,!data.needNotify{//检查是否可以add notification
      let timePoint:HourMin
      switch data.time{//时间段提醒开始时间
      case .timeBucket(startPoint: let point, endPoint: _):timePoint = point
      case .timePoint(point: let point):timePoint = point
      }
      //如果时间在现在时间之后
      if collection.mainControllerDelegete().addNotification(with: data.name, date: data.date,
                                                             at: timePoint, id: notificationString){
        //更改界面
        alarmButton.alpha = 0
        UIView.animate(withDuration: 0.12, animations: {
          self.alarmButton.alpha = 1
        }, completion: { (bool) in self.alarmButton.isHidden = false})
        self.data!.needNotify = true
        collection.checkOrderAndSaveDataToModelAndCollection(order: self.order)
      }
    }else{//删除notification
      //更改界面
      alarmButton.alpha = 1
      UIView.animate(withDuration: 0.12, animations: {
        self.alarmButton.alpha = 0
      }, completion: { (bool) in self.alarmButton.isHidden = true})
      //remove notification
      collection.mainControllerDelegete().removeNotification(id: [notificationString])
      data!.needNotify = false
      collection.checkOrderAndSaveDataToModelAndCollection(order: self.order)
    }
    //checkNotification Center
    PlanerModel.checkNotification(forID:notificationString)
  }
  
  func changeNotificaionsMessage(newData data:EventsData)  {
    
    if data.needNotify {
      //remove notification
      collection.mainControllerDelegete().removeNotification(id: [notificationString])
      //add notification
      let timePoint:HourMin
      switch data.time{//时间段提醒开始时间
      case .timeBucket(startPoint: let point, endPoint: _):timePoint = point
      case .timePoint(point: let point):timePoint = point
      }
      if collection.mainControllerDelegete().addNotification(with: data.name, date: data.date,
                                                             at: timePoint, id: notificationString){
        //更改界面
        alarmButton.isHidden = false
      }else{
        //更改的时间超过现在时间
        alarmButton.isHidden = true
        //更改数据
        self.data!.needNotify = false
      }
      //checkNotification Center
      PlanerModel.checkNotification(forID:notificationString)
    }
  }
  
  
  //MARK: - 键盘监听
  
  var distanceBetweenKeyboardAndTextField:CGFloat = 0
  var originFrameForScrollView:CGRect = CGRect.zero
  var showCommonEventView:Bool = false
  
  func addKeyBoardObservers() {
    //添加键盘的监听
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(EventsView.keyboardWillShow),
      name: NSNotification.Name.UIKeyboardWillShow,
      object: nil
    )

  }
  
  func removeKeyBoardObservers()  {
    //移除键盘的监听
    NotificationCenter.default.removeObserver(self,
    name: NSNotification.Name.UIKeyboardWillShow, object: nil)
  }
  
  //键盘显示或者高度更改的时候进行
  @objc func keyboardWillShow(_ notification: Notification) {
    //获取键盘高度
    if let keyboardFrame: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
      let keyboardRectangle = keyboardFrame.cgRectValue
      let keyboardHeight = keyboardRectangle.height
      Constants.keyboardHeight = keyboardHeight
      //移动scrollView
      let frameFromCollectionView = self.superview!.convert(originFrameForScrollView, from: view)
      print("KeyboardWillShow\(frameFromCollectionView)")
      collection.setScrollviewsOffsetWith(eventsOrder: self.order, frameFromCollection: frameFromCollectionView,
                                          distance: distanceBetweenKeyboardAndTextField+keyboardHeight)
      //检查是否需要增加commonEventView
      if showCommonEventView {
        
        collection.mainControllerDelegete().removeCommonEventView()
        collection.mainControllerDelegete().addCommonEventView(heightOfKeyBoard:keyboardHeight,
                                                               nameTextView:nameLabel)
      }
    }
  }
  //MARK: - 选择系统
  
  @objc func longPressGesture(_ sender: UILongPressGestureRecognizer) {
    if sender.state == .began {
      collection.showEditingMenu(eventsFrame: self.frame, eventsOrder: self.order)//frame储存在self里面
    }
  }
  var startPoint:CGPoint = CGPoint.zero
  var originFrame:CGRect = CGRect.zero
  var moveDistance:CGFloat = 0
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//    print("touchBegan")
    let touchPoint = touches.first!.location(in: self)
    startPoint = touchPoint //保存开始的点
    originFrame = self.frame//保存最开始的frame
  }
  
  override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
    let touchPoint = touches.first!.location(in: self)
    let touchPointInColloction = self.superview!.convert(touchPoint, from: self)
    moveDistance = touchPointInColloction.x - startPoint.x
    self.frame.origin.x = moveDistance
  }
  
  override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
    if -moveDistance > Constants.deleteDistance{//距离足够
      self.deleteEventView()
      //结束锁定 并且结束其他
      collection.mainControllerDelegete().enableAllViews()
      removeKeyBoardObservers()
      collection.checkScrollViewsOffset()
    }else{//不足够
      //恢复视图
      PlanerModel.animteTo(frame: originFrame, view: self)
    }
  }
  
  //MARK: - 获取xib中的数据
  
  var view:UIView!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
    
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
    
  }
  
  func setup() { //加入xib中的view
    view = loadXibView()
    addSubview(view)
  }
  
  func loadXibView() -> UIView { //获取view
    let bundle = Bundle(for: type(of:self))
    let file = UINib(nibName: "EventsView", bundle: bundle)//修改bundle
    let view = file.instantiate(withOwner: self, options: nil)[0] as! UIView
    return view
  }

}

enum LampStatus{
  case gray
  case red
  case yellow
  
  //返回对应的图片
  func changeToImage() -> UIImage {
    return UIImage()
  }
}

//MARK: - 输入框代理
//名字输入框
extension EventsView:UITextFieldDelegate{
  //要开始更改之前
  func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
    print("textFieldShouldBeginEditing")
    return true
  }
  func textFieldDidBeginEditing(_ textField: UITextField) {
    print("textFieldDidBeginEditing")
    //通过键盘监听移动视图到可见位置
    distanceBetweenKeyboardAndTextField = Constants.eventsViewsCellsHeight
    originFrameForScrollView = nameLabel.frame
    showCommonEventView = true
    removeKeyBoardObservers()
    addKeyBoardObservers()
    //开始锁定
    collection.disableViews(order: self.order)
  }
  
  //点击return按钮
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    removeKeyBoardObservers()
    textField.resignFirstResponder()
    print("textFieldShouldReturn")
    collection.checkScrollViewsOffset()
    //结束锁定
    collection.mainControllerDelegete().enableAllViews()
    return true
  }
  
  func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
    print("textFieldShouldEndEditing")
    //储存数据
    if nil != self.data{
      data!.name = nameText!
      collection.checkOrderAndSaveDataToModelAndCollection(order: self.order)
    }else{
      newNameData = nameText!
      self.saveNewData()
    }
    showCommonEventView = false
    collection.mainControllerDelegete().removeCommonEventView()
    return true
  }
  
  func textFieldDidEndEditing(_ textField: UITextField) {
    print("textFieldDidEndEditing")
    //更新更改状态
//    userIsEditing = false
  }
  
}

//时间label
extension EventsView:TimeTextFieldDelegate{
  
  func shouldBecomeFirstResponder(_ timeTextField: TimeTextField) -> Bool {
    print("shouldBecomeFirstResponder")
      //开始锁定
      collection.disableViews(order: self.order)
      //检查键盘的完成键
      let customKeyboard = timeTextField.inputView as! CustomKeyboard
      customKeyboard.checkOutDoneKey()
      //通过键盘监听移动视图到可见位置
      originFrameForScrollView = timeLabel.frame
      distanceBetweenKeyboardAndTextField = Constants.eventsViewsCellsHeight
      removeKeyBoardObservers()
      addKeyBoardObservers()
      return true
  }
  
  func shouldResignFirstResponder(_ timeTextField: TimeTextField) -> Bool {
    print("shouldResignFirstResponder")
    //判定是否在删除事件
    if deletingEvent {
      removeKeyBoardObservers()
      collection.checkScrollViewsOffset()
      deletingEvent = false
      //结束锁定
      collection.mainControllerDelegete().enableAllViews()
      return true
    }
    //判定是否要展示花费时间动画
    let currentTimeString = timeTextField.text!
    let result = currentTimeString.check(midnight: false)//midnight⚠️
    if let newTimeData = result.data{//是时间段
      if let spendTime = newTimeData.spend{//有花费时间
        self.showSpendTimeForTimeTextFeild(time:spendTime)
      }
    }
    //判断时间格式是否正确等等
    if let newTimeData = result.data,collection.checkFeasibility(timeData: newTimeData, eventsOrder: self.order).result{
      //正确
      //数据储存
      if nil != self.data {//如果有数据源
        self.data!.time = newTimeData
        collection.checkOrderAndSaveDataToModelAndCollection(order: self.order)
      }else{
        //重新添加
        self.newTimeData = newTimeData
      }
      removeKeyBoardObservers()
      collection.checkScrollViewsOffset()
      //结束锁定
      collection.mainControllerDelegete().enableAllViews()
      //更改状态
//      userIsEditing = false
      return true
    }else{
      //显示错误原因
      var error:String = "输入错误"
      if let errorString = result.error{
        error = errorString
      }
      if let timeData = result.data{//查看原因是否是时间段被占用
        if let errorString = collection.checkFeasibility(timeData: timeData, eventsOrder: self.order).error{
          error = errorString
        }
      }
      //提醒结束之后重新打开键盘
      collection.show(message: error, completionBlock: {let _ =  self.shouldBecomeFirstResponder(self.timeLabel)})
      return true
    }
    
  }
  
}

//MARK: - 输入视图代理

extension EventsView:ownTextViewDelegate{
  
  func beforeBecameFirstResponder() -> Bool {
    //通过键盘监听移动视图到可见位置
    distanceBetweenKeyboardAndTextField = Constants.eventsViewsCellsHeight
    originFrameForScrollView = addDescriptionButton.frame
    //如果是最后一个EventView那么就不进行更新
    removeKeyBoardObservers()
    addKeyBoardObservers()
    print("testViewBecameFirstResponder")
    return true
  }
  
}

extension EventsView:UITextViewDelegate{
  
  func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
    //是否可以进行更改
    print("textViewShouldBeginEditing")
      return true
  }
  
  func textViewDidBeginEditing(_ textView: UITextView) {
    print("textViewDidBeginEditing")
    
    //开始锁定
    collection.disableViews(order: self.order)
  }
  
  
  func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
    //检查高度
    let currentHeightTextViewShouldBe = self.getAddedHeight(of: descriTextView)
    if  currentHeightTextViewShouldBe != descriptionTextViewsCurrentHeight {//最后一个EventView不滚动
      //获取moveDistance
      let moveDistance = currentHeightTextViewShouldBe! - descriptionTextViewsCurrentHeight
      //更改frame
      descriptionTextViewsCurrentHeight = getAddedHeight(of: descriTextView)!
      //更改eventViewsFrame
      let newHeight = descriTextView!.frame.maxY
      self.frame.size.height = newHeight
      //更改collection scrollView
      collection.updateEventViewsForTextView(eventsOrder: self.order,
                                             moveDistance: moveDistance)
    }
    if text == "\n"{//点击换行
      //结束输入
      //检查是否有字符 没有的话删除textView
      let trimmedString = textView.text.trimmingCharacters(in: .whitespaces)
      if trimmedString.isEmpty{
        print("删除")
        //删除TextView
        descriTextView?.removeFromSuperview()
        descriTextView = nil
        //开启按钮操作
        addDescriptionButton.isHidden = false
        addDescriptionButton.frame.size.height = Constants.eventsViewsTextViewsDefaultHeight
        //更改eventViewsFrame
        let newHeight = addDescriptionButton!.frame.maxY
        self.frame.size.height = newHeight
        //更改collection scrollView
        collection.updateEventViewsForTextView(eventsOrder: self.order,
                                                      moveDistance: 0)
      }
      textView.resignFirstResponder()//隐藏键盘
      //保存数据 添加description的时候一定拥有数据
      let description = descriTextView?.text
      self.data!.descri = description
      collection.checkOrderAndSaveDataToModelAndCollection(order: self.order)
      removeKeyBoardObservers()
      print("textViewShouldEndEditing \(description ?? "nil")")
      collection.checkScrollViewsOffset()
      //结束锁定
      collection.mainControllerDelegete().enableAllViews()
    }
    return true
  }
  
  func textViewShouldEndEditing(_ textView: UITextView) -> Bool {
    return true
  }
  
  func textViewDidEndEditing(_ textView: UITextView) {
    
  }
}

//MARK: - 键盘代理

protocol CustomKeyboardDelegateForEventView {
  func focusOnNameLabelOrFinishEditing()
  func deleteEventView()
  func isTextInNameLabel()->Bool
}

extension EventsView:CustomKeyboardDelegateForEventView{
  
  func focusOnNameLabelOrFinishEditing() {
    print("EventViewNameText \(nameText!)")
    if nameText! != ""{
      //检查时间的正确性和顺序
      let _ = self.timeLabel.resignFirstResponder()
    }else{//继续输入
      let _ = self.timeLabel.resignFirstResponder()
      nameLabel.becomeFirstResponder()
    }
  }
  
  func deleteEventView() {
    //删除通知
    collection.mainControllerDelegete().removeNotification(id: [notificationString])
    //通知重写resignFirstResrponder方法
    deletingEvent = true
    //动画删除视图
    PlanerModel.flyOutAndRemoveView(view:self, closure: {
      //动画结束后collection中删除视图(进行更新动画)
      self.collection.deleteEventsView(order: self.order)
    })
  }
  
  func isTextInNameLabel() -> Bool {
//    print("isTextInNameLabel \(nameText != "")")
    return nameText! != ""
  }
}


