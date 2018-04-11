//
//  TimeManagementViewController.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/2/12.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import UIKit
import PieCharts
import SwiftCharts

class TimeManagementViewController: UIViewController {

  @IBOutlet weak var timeBucketChoiceButton: UIButton!
  @IBOutlet weak var timeBucketChoiceButton1: UIButton!
  @IBOutlet weak var timeBucketChoiceButton2: UIButton!
  @IBOutlet weak var timeBucketChoiceButton3: UIButton!
  @IBOutlet weak var doNotHaveAnyData: UILabel!
  @IBOutlet weak var segmentedForChartViews: UISegmentedControl!
  @IBOutlet weak var ChartScrollView: UIScrollView!
  @IBOutlet weak var topView: UIView!
  @IBOutlet weak var unwindButton: UIButton!
  var clearAllButton:UIButton?
  var clearAllData:Bool = false
  
  
  var oldDataArray:[EventsData]!
  
  //MARK: - LifeCycle
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
  }
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    //更新文字
    segmentedForChartViews.setTitle(DefaultWords.percentange, forSegmentAt: 0)
    segmentedForChartViews.setTitle(DefaultWords.quantity, forSegmentAt: 1)
    segmentedForChartViews.setTitle(DefaultWords.trend, forSegmentAt: 2)
    doNotHaveAnyData.text = DefaultWords.noDataForTimeManagement
    unwindButton.setTitle(DefaultWords.unwindButton, for: .normal)
  }
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    //设置button
    setButtonSetup(newSegment: 0)
    segmentControl(segmentedForChartViews)
    //设置颜色
    topView.backgroundColor = Constants.mainColor
//    getDataForBarAndPieChart(timeBucket: .lastWeek)
//    for data in oldDataArray{
//      print("names \(data.name)")
//    }
  }

  var chartsViews:Chart?
  var pieChartView:customPieChart?
  var trendCharts:Chart?
  
  var currentSegmentInt:Int = 2
  
  //MARK: - 控制器
  var isChoicing:Bool = false
  var currentTimeBucket:TimeBucket = TimeBucket.yesterDay
//  {
//    didSet{
//      print(currentTimeBucket.rawValue)
//    }
//  }
  
  func setButtonSetup(newSegment:Int)  {//设置新segemnt之前调用
    if currentSegmentInt != newSegment , currentSegmentInt == 2 {
      //设置为比例格式
      timeBucketChoiceButton.setTitle(TimeBucket.changeEnumToString(TimeBucket.yesterDay), for: UIControlState.normal)
      timeBucketChoiceButton1.setTitle(TimeBucket.changeEnumToString(TimeBucket.lastWeek), for: UIControlState.normal)
      timeBucketChoiceButton2.setTitle(TimeBucket.changeEnumToString(TimeBucket.lastMonth), for: UIControlState.normal)
      timeBucketChoiceButton3.setTitle(TimeBucket.changeEnumToString(TimeBucket.totally), for: UIControlState.normal)
      //设置默认的TimeBucketEnum
      currentTimeBucket = TimeBucket.yesterDay
    }
    if currentSegmentInt != newSegment , newSegment == 2{
      //设置为趋势格式
      timeBucketChoiceButton.setTitle(TimeBucket.changeEnumToString(TimeBucket.last7days), for: UIControlState.normal)
      timeBucketChoiceButton1.setTitle(TimeBucket.changeEnumToString(TimeBucket.last15days), for: UIControlState.normal)
      timeBucketChoiceButton2.setTitle(TimeBucket.changeEnumToString(TimeBucket.last30days), for: UIControlState.normal)
      timeBucketChoiceButton3.setTitle(TimeBucket.changeEnumToString(TimeBucket.last90days), for: UIControlState.normal)
      //设置默认的TimeBucketEnum
      currentTimeBucket = TimeBucket.last7days
    }//默认展示
  }
  
  func move(titleToTop:String){
    var buttonArray = [timeBucketChoiceButton,timeBucketChoiceButton1,timeBucketChoiceButton2,timeBucketChoiceButton3]
    var currentButtomsTitle:[String] = []
    //获取enum的字符串
    if currentSegmentInt == 2 {
      currentButtomsTitle += [TimeBucket.changeEnumToString(TimeBucket.last7days),
                              TimeBucket.changeEnumToString(TimeBucket.last15days),
                              TimeBucket.changeEnumToString(TimeBucket.last30days),
                              TimeBucket.changeEnumToString(TimeBucket.last90days)]
    }else{
      currentButtomsTitle += [TimeBucket.changeEnumToString(TimeBucket.yesterDay),
                              TimeBucket.changeEnumToString(TimeBucket.lastWeek),
                              TimeBucket.changeEnumToString(TimeBucket.lastMonth),
                              TimeBucket.changeEnumToString(TimeBucket.totally)]
    }
    buttonArray.first!!.setTitle(titleToTop, for: .normal)//移到最上面
    buttonArray.removeFirst()
    //找到名字数组中的选中文字
    let order = currentButtomsTitle.index(of: titleToTop)!
    //删除
    currentButtomsTitle.remove(at: order)
    //剩下的数组对应赋值
    for (order,button) in buttonArray.enumerated(){
      button!.setTitle(currentButtomsTitle[order], for: .normal)
    }
  }
  
 @IBAction func timeBucketButtonPressed(sender:UIButton) {
    if isChoicing {
      timeBucketChoiceButton.setBackgroundImage(#imageLiteral(resourceName: "TimeBucketButtonBeforePressed"), for: .normal)
      timeBucketChoiceButton1.isHidden = true
      timeBucketChoiceButton2.isHidden = true
      timeBucketChoiceButton3.isHidden = true
      //更改文字顺序
      let title = sender.title(for: .normal)!
      move(titleToTop: title)
      //更改当前的时间段数据
      let newTimeBucket = TimeBucket.changeStringToEnum(title)!
      if newTimeBucket != currentTimeBucket{
        //更新数据
        currentTimeBucket = newTimeBucket
        //更新Charts
        segmentControl(segmentedForChartViews)
      }
    }else{
      timeBucketChoiceButton.setBackgroundImage(#imageLiteral(resourceName: "TimeBuckedButtomPressedTop"), for: .normal)
      timeBucketChoiceButton1.isHidden = false
      timeBucketChoiceButton2.isHidden = false
      timeBucketChoiceButton3.isHidden = false
    }
    isChoicing = !isChoicing
  }
  
  @IBAction func segmentControl(_ sender: UISegmentedControl) {
    print("绘制图形")
    //更新颜色顺序
    TimeManagementConstant.colorIntForOrder = 0
    //获取时间段数据
    let newSegmentIndex = sender.selectedSegmentIndex
    //更新button文字
    setButtonSetup(newSegment: newSegmentIndex)
    clearChartsView()
    switch newSegmentIndex {
    case 0: creatNewPieChart()
    case 1: creatNowBarsView()
    case 2: creatAndAddTrendChart()
    default: print("segment发生错误")
    }
    currentSegmentInt = newSegmentIndex
    checkForClearAllButton()
  }
  
  func checkForClearAllButton() {
    self.clearAllButton?.removeFromSuperview()
    if self.currentTimeBucket == .totally , self.currentSegmentInt == 1 , doNotHaveAnyData.isHidden{
      //展示清除所有按钮
      let y = ChartScrollView.contentSize.height
      print("清除所有按钮",ChartScrollView.contentSize.height)
      let newButton = UIButton(frame: CGRect(x: 0, y: y-50, width: Constants.screenWidth, height: 50))
      newButton.setTitle(DefaultWords.deleteAllOldDataString, for: .normal)
      newButton.titleLabel?.font = TimeManagementConstant.barsChartFont
      newButton.setTitleColor(UIColor.red, for: .normal)
      //连接操作
      newButton.addTarget(self, action: #selector(clearAllDataButtonPressed), for: .touchDown)
      //显示
      ChartScrollView.addSubview(newButton)
      self.clearAllButton = newButton
    }
  }
  
  @objc func clearAllDataButtonPressed(){
    clearAllData = true
    //返回主界面
    performSegue(withIdentifier: "unwindToMain", sender: self)
  }
  
  func clearChartsView()  {
    //清除charts
    chartsViews?.clearView()
    pieChartView?.removeFromSuperview()
    trendCharts?.clearView()
    chartsViews = nil
    pieChartView = nil
    trendCharts = nil
    //更新scrollView的contentSize
    ChartScrollView.contentSize = ChartScrollView.frame.size
  }
  //MARK: - getData
  func getDataForTrendChart(timeBucket:TimeBucket) -> [(name:String,data:[(Int,Double)])] {
    var result:[(name:String,data:[(Int,Double)],totalTime:Double,maxTime:Double)] = [] //返回数据
    //获取时间段
    let dateBucket:(startDistance:Int,endDistance:Int)
    //到昨天结束
    dateBucket.endDistance = -1
    //获取开始时间段
    switch timeBucket {
    case .last7days: dateBucket.startDistance = -7
    case .last15days: dateBucket.startDistance = -15
    case .last30days: dateBucket.startDistance = -30
    case .last90days: dateBucket.startDistance = -90
    default: dateBucket.startDistance = 0
    }
    //数据 6个最多的事件 范围最大的放在最前面             -7...-1
    for everyDateDistance in dateBucket.startDistance...dateBucket.endDistance{
      //遍历所有日期
      let date = Constants.changeDistanceDayToDate(everyDateDistance).monthday
      //遍历所有事件
      var testTimes = 0
      for eventsData in oldDataArray{
//        print("之前日期\(date) 事件日期\(eventsData.date)")
        if date == eventsData.date{
//          print("应该被收入的事件名称\(eventsData.name)")
          //加入chart数据数组
          var isThisEventInTheResult :Bool = false
          for (order,events) in result.enumerated(){
            testTimes += 1
            print("循环次数\(testTimes)")
            if eventsData.name == events.name{
              //找到了这个event
              isThisEventInTheResult = true
              //加入到event对应的dataArray之中
              if let spendTime = eventsData.time.spend {
                //计算时间Double
                let hours = spendTime.hourDouble()
                //最大值
                 var maxTime = hours
                //检查有没有今日的事件
                var hadThisDateEvent:Bool = false
                //时间段加入ChartData
                for (torder,timeData) in result[order].data.enumerated(){
                  if timeData.0 == -everyDateDistance {
                    //加入到这天的事件里
                    result[order].data[torder].1 += hours
                    //更新最大值
                    maxTime = result[order].data[torder].1
                    //更改Bool值
                    hadThisDateEvent = true
                  }
                }
                if !hadThisDateEvent {
                  result[order].data = [(-everyDateDistance,hours)] + events.data
                }
                //时间段加入总时间
                result[order].totalTime += hours
                //与最大时间比较
                result[order].maxTime = result[order].maxTime < maxTime ? maxTime : result[order].maxTime
              }
            }else{
              if eventsData.date < date { break }
            }
          }
          //如果没有加入过数组 新建一个项目
          if !isThisEventInTheResult {
//            print("新建项目")
            if let spendTime = eventsData.time.spend {//不是时间点
              let hours = spendTime.hourDouble()
              let newData = (eventsData.name,[(-everyDateDistance,hours)],hours,hours)
              result.append(newData)
            }
          }
        }else{
          //计算次数控制
          if eventsData.date < date{ break }
        }
      }
    }
    for data in result {
      print(data.name)
      print(data.maxTime)
      print(data.totalTime)
      for events in data.data{
        print(events.0," ",events.1)
      }
    }
    //对于result进行加工 没有发生的日期添加0
    for (rorder,_) in result.enumerated(){
      for order in (-dateBucket.endDistance)...(-dateBucket.startDistance) {
        //检查是否有发生
//        print("数据 \(result[rorder].data[order-1].0) \(order)")
        if order-1 == result[rorder].data.count || result[rorder].data[order-1].0 != order {//没有发生
          //增加数据为0的时间
          result[rorder].data.insert((order,0), at: order-1)
        }
      }
    }
    
    //对总时间进行排序
    result = result.sorted(by: { (data1, data2) -> Bool in
      return data1.totalTime>data2.totalTime
    })
    //删除到仅仅剩下六项
    while result.count > 6 {
      result.removeLast()
    }
    //对最大时间进行排序
    result = result.sorted(by: { (data1, data2) -> Bool in
      return data1.maxTime>data2.maxTime
    })
    return result.map({ (data) -> (String,[(Int,Double)]) in return (data.name,data.data) })
  }
  
  func getDataForBarAndPieChart(timeBucket:TimeBucket) -> [(title:String,times:Int)] {
    var result:[(title:String,times:Int)] = []
    let timeBucket = Constants.getDateBucketBefore(timeBucket: timeBucket)
    //数据 (已经排序完成) 从小到大 极小的数据不显示
    for oldData in oldDataArray{
//      print(timeBucket.startDate," ",oldData.date," ",timeBucket.endDate)
      if timeBucket.startDate <= oldData.date && oldData.date <= timeBucket.endDate {//在范围内
        //加入数组
        var hadEventInArray = false
        for (order,datas) in result.enumerated(){
          if datas.title == oldData.name {//名字要是相同
            hadEventInArray = true
            //检查是不是时间段
            if let mins = oldData.time.spend?.minInt() {
              result[order].times += mins
            }
          }
        }
        if !hadEventInArray {
          //添加新的event
          if let mins = oldData.time.spend?.minInt() {
            let newEvent = (oldData.name,mins)
            result.append(newEvent)
          }
        }
      }
    }
    //从小到大进行排序
    result = result.sorted(by: { (data1, data2) -> Bool in
      return data1.times<data2.times
    })
    //名字长度进行控制 待修改
    let longestStringDistance = Constants.screenWidth/4
    for (order,data) in result.enumerated(){
      var titlesLength = data.title.width(withConstraintedHeight: 20, font: TimeManagementConstant.barsChartFont)
      var titlesDoNotBeyond = true
      //超过最大宽度
      while titlesLength > longestStringDistance {
        titlesDoNotBeyond = false
        result[order].title.removeLast()//裁剪
        titlesLength = result[order].title.width(withConstraintedHeight: 20, font: TimeManagementConstant.barsChartFont)
      }
      //增加省略号
      if !titlesDoNotBeyond {
        result[order].title += ".."
      }
    }
    return result
  }
  
  
//MARK: creatTrendChartFictions

  func creatAndAddTrendChart() {
    //数据 6个最多的事件 范围最大的放在最前面
//    let dataArray:[(name:String,data:[(Int,Double)])] = [
//      ("工作",[(2, 14), (3, 6), (5, 1), (6, 7), (8, 6), (9, 7), (10, 3), (13, 6), (15, 25), (16, 7)]),
//     ("休息",[(2, 2), (3, 1), (5, 9), (6, 7), (8, 10), (9, 9), (10, 15), (13, 8), (15, 20), (16, 17)]),
//     ("吃饭",[(2, 4), (3, 15), (5, 19), (6, 17), (8, 13), (9, 5), (10, 5), (13, 18), (15, 0), (16, 5)]),
//    ]
    let dataArray:[(name:String,data:[(Int,Double)])] = getDataForTrendChart(timeBucket: currentTimeBucket)
    //转化成为chartsView 和标签
    if let newTrendCharts = change(dataArray: dataArray) {
      //隐藏无数据提醒
      doNotHaveAnyData.isHidden = true
      //增加新视图
      trendCharts = newTrendCharts
      ChartScrollView.addSubview(trendCharts!.view)
    }else{
      //出现无数据提醒
      doNotHaveAnyData.isHidden = false
    }
    
  }
  
  func change(dataArray:[(name:String,data:[(Int,Double)])])-> Chart?{//第一个chart增加数轴
    
    let labelSettings = ChartLabelSettings(font: UIFont.systemFont(ofSize: 10))
    
    //检查是否有数据
    if dataArray.isEmpty {return nil}
    let chartPointsMax = dataArray[0].data.map { (arg) -> ChartPoint in
      let (x,y) = arg
      return ChartPoint(x: ChartAxisValueInt(x), y: ChartAxisValueDouble(y))
    }
    
    let xValues = ChartAxisValuesStaticGenerator.generateXAxisValuesWithChartPoints(chartPointsMax, minSegmentCount: 5, maxSegmentCount: 15, multiple: 1, axisValueGenerator: {ChartAxisValueDouble($0, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
    let yValues = ChartAxisValuesStaticGenerator.generateYAxisValuesWithChartPoints(chartPointsMax, minSegmentCount: 2, maxSegmentCount: 40, multiple: 0.5, axisValueGenerator: {ChartAxisValueDouble($0, labelSettings: labelSettings)}, addPaddingSegmentIfEdge: false)
    
    let xModel = ChartAxisModel(axisValues: xValues, axisTitleLabel: ChartAxisLabel(text: DefaultWords.daysAges, settings: labelSettings))
    let yModel = ChartAxisModel(axisValues: yValues, axisTitleLabel: ChartAxisLabel(text: DefaultWords.spendHours, settings: labelSettings.defaultVertical()))
    //frame
    let chartFrame = CGRect(origin: CGPoint.zero, size: ChartScrollView.frame.size)
    
    var chartSettings = TimeManagementConstant.iPhoneChartSettings // for now no zooming and panning here until ChartShowCoordsLinesLayer is improved to not scale the lines during zooming.
    chartSettings.trailing = 20
    chartSettings.leading = 0
    chartSettings.top = 10
    chartSettings.bottom = 40 //⚠️
    chartSettings.labelsToAxisSpacingX = 10
    chartSettings.labelsToAxisSpacingY = 10
    chartSettings.axisStrokeWidth = 1
    let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
    let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
    
//    print("坐标系的frame \(coordsSpace.chartInnerFrame)")
    
    let labelWidth: CGFloat = 70
    let labelHeight: CGFloat = 30
    
    let showCoordsTextViewsGenerator = {(chartPointModel: ChartPointLayerModel, layer: ChartPointsLayer, chart: Chart) -> UIView? in
      let (chartPoint, screenLoc) = (chartPointModel.chartPoint, chartPointModel.screenLoc)
      let text = chartPoint.description
      let font = UIFont.systemFont(ofSize: 10)
      let x = min(screenLoc.x + 5, chart.bounds.width - text.width(font) - 5)
      let view = UIView(frame: CGRect(x: x, y: screenLoc.y - labelHeight, width: labelWidth, height: labelHeight))
      let label = UILabel(frame: view.bounds)
      label.text = text
      label.font = UIFont.systemFont(ofSize: 10)
      view.addSubview(label)
      view.alpha = 0
      
      UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut, animations: {
        view.alpha = 1
      }, completion: nil)
      
      return view
    }
    
    
    let showCoordsLinesLayer = ChartShowCoordsLinesLayer<ChartPoint>(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, chartPoints: chartPointsMax)
    
    let showCoordsTextLayer = ChartPointsSingleViewLayer<ChartPoint, UIView>(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, innerFrame: innerFrame, chartPoints: chartPointsMax, viewGenerator: showCoordsTextViewsGenerator, mode: .custom, keepOnFront: true)
    // To preserve the offset of the notification views from the chart point they represent, during transforms, we need to pass mode: .custom along with this custom transformer.
    showCoordsTextLayer.customTransformer = {(model, view, layer) -> Void in
      guard let chart = layer.chart else {return}
      
      let text = model.chartPoint.description
      
      let screenLoc = layer.modelLocToScreenLoc(x: model.chartPoint.x.scalar, y: model.chartPoint.y.scalar)
      let x = min(screenLoc.x + 5, chart.bounds.width - text.width(UIFont.systemFont(ofSize: 10)) - 5)
      
      view.frame.origin = CGPoint(x: x, y: screenLoc.y - labelHeight)
    }
    
    //创建labelCollectionView
    let y = ChartScrollView.frame.size.height - 40
    let labelCollection = UIScrollView(frame: CGRect(x: 0, y: y, width: ChartScrollView.frame.width, height: 40))
    labelCollection.showsHorizontalScrollIndicator = false
    var lastLabel:UIView?
    

    func addNewLabel(name:String,color:UIColor){
      var startX:CGFloat = 18
      if let lastView = lastLabel{
        startX = lastView.frame.maxX
      }
      //增加颜色标志
      let colorView = UIView(frame: CGRect(x: startX, y: 10, width: 18, height: 18))
      colorView.backgroundColor = color
      labelCollection.addSubview(colorView)
      //增加名字标志 储存为最后一个view
      let nameLabel = UILabel()
      nameLabel.frame.origin.y = colorView.frame.origin.y
      nameLabel.frame.origin.x = colorView.frame.maxX + 5
      nameLabel.frame.size.height = 18
      let namesWidth = name.width(withConstraintedHeight: 10,
                                  font: UIFont.systemFont(ofSize: 12,weight:UIFont.Weight.medium))
      nameLabel.frame.size.width = namesWidth + 5
      nameLabel.font = UIFont.systemFont(ofSize: 12,weight:UIFont.Weight.medium)
      nameLabel.text = name
      labelCollection.addSubview(nameLabel)
      lastLabel = nameLabel
      //更新ScrollView的contentSize
      labelCollection.contentSize = CGSize(width: lastLabel!.frame.maxX, height: 40)
    }
    
    //制作所有的lineModel
    var lineModelsArray:[ChartLineModel] = [] as! [ChartLineModel]
    for data in dataArray{
      //转化为chartPoints数组
      let chartPoints = data.data.map { (arg) -> ChartPoint in
        let (x,y) = arg
        return ChartPoint(x: ChartAxisValueInt(x), y: ChartAxisValueDouble(y))
      }
      //获取颜色
      let color = TimeManagementConstant.getAOrderColor
      let newLineModel = ChartLineModel(chartPoints: chartPoints, lineColor:color, lineWidth: 2, animDuration: 0.7, animDelay: 0)
      //增加label到labelCollection
      addNewLabel(name: data.name, color: color)
      lineModelsArray.append(newLineModel)
    }
    let chartPointsLineLayer = ChartPointsLineLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, lineModels: lineModelsArray)
    
    let settings = ChartGuideLinesDottedLayerSettings(linesColor: UIColor.lightGray, linesWidth: 1)
    let guidelinesLayer = ChartGuideLinesDottedLayer(xAxisLayer: xAxisLayer, yAxisLayer: yAxisLayer, settings: settings)
    
    let chart = Chart(
      frame: chartFrame,
      innerFrame: innerFrame,
      settings: chartSettings,
      layers: [
        xAxisLayer,
        yAxisLayer,
        guidelinesLayer,
        showCoordsLinesLayer,
        chartPointsLineLayer,
      ]
    )
    //添加collectionView
    chart.view.addSubview(labelCollection)
    return chart
  }
  
  
//MARK: creatBarChartFictions

  func creatNowBarsView() {
    //getEventDataOf
    //数据 (已经排序完成) 从小到大 极小的数据不显示  进行字数限制三个字以上的截取
//    var barValues:[(title:String,times:Int)] = [
//      ("工作",20),("休息",19),("午睡",17),("锻炼",15),("午饭",13),("电影",11),("晚饭",9),("聊天",5)
//    ]

    var barValues:[(title:String,times:Int)] = getDataForBarAndPieChart(timeBucket: currentTimeBucket)
    
    //检查是否有数据
    if barValues.isEmpty {
      //出现无数据提醒
      doNotHaveAnyData.isHidden = false
      return
    }else{
      //隐藏无数据提醒
      doNotHaveAnyData.isHidden = true
    }
    barValues = barValues.sorted(by: { (value1,value2 ) -> Bool in
      return value1.times < value2.times
    })
    
  
    //数字转化为ChartAxisValue
    let chartPoints =  barValues.enumerated().map { (arg) -> ChartPoint in
      let (index, value) = arg
      return ChartPoint(x: ChartAxisValueInt(value.times), y: ChartAxisValueInt(index))
    }
    
    //Label字体设置
    let labelSettings = ChartLabelSettings(font: UIFont.systemFont(ofSize: 20))
    
    
    //最大值
    var generatorX:Double = 10
    var maxXAxiesValue:Double = 20
    if let maxValue = barValues.last?.times {
      generatorX = Double(maxValue)/4
      maxXAxiesValue = generatorX*4.8
    }
    
    //label生成器
    let labelsGenerator = ChartAxisLabelsGeneratorFunc {scalar in
      return ChartAxisLabel(text: "\(scalar)", settings: labelSettings)
    }
    let xGenerator = ChartAxisGeneratorMultiplier(generatorX)//⚠️跟最大值有关
    
    
    //xy的数据源   最大的数值
    let xModel = ChartAxisModel(firstModelValue: 0, lastModelValue: maxXAxiesValue, axisTitleLabels: [ChartAxisLabel(text: "Axis title", settings: labelSettings)], axisValuesGenerator: xGenerator, labelsGenerator: labelsGenerator)
    
    //y名称的数组
    let yValues:[ChartAxisValueString] = [ChartAxisValueString(order: -1)] +
      barValues.enumerated().map{(arg)->ChartAxisValueString in
      let (index, value) = arg
      return ChartAxisValueString(value.title, order: index, labelSettings: labelSettings)}
      + [ChartAxisValueString(order: barValues.count)]
  
    let yModel = ChartAxisModel(axisValues: yValues)
    
    //barView生成器
    let barViewGenerator = {(chartPointModel: ChartPointLayerModel, layer: ChartPointsViewsLayer, chart: Chart) -> UIView? in
      //转化位置
      let bottomLeft = layer.modelLocToScreenLoc(x: 0, y: 0)
      //宽度
      let barWidth: CGFloat =  TimeManagementConstant.barWidth
      //动画时间设置
      let settings = ChartBarViewSettings(animDuration: 0.43)
      
      //位置
      let (p1, p2): (CGPoint, CGPoint) = {
        return (CGPoint(x: bottomLeft.x, y: chartPointModel.screenLoc.y), CGPoint(x: chartPointModel.screenLoc.x, y: chartPointModel.screenLoc.y))
      }()
      //颜色
      return ChartPointViewBar(p1: p1, p2: p2, width: barWidth, bgColor: TimeManagementConstant.getAOrderColor, settings: settings)
    }
    //通过数据的数量计算frame
    let distance:CGFloat = TimeManagementConstant.barsDistance//bar的高度加上距离
    let height = (distance+TimeManagementConstant.barWidth)*CGFloat(barValues.count)
    let widht = ChartScrollView.frame.width
    //最外层的frame
    let chartFrame = CGRect(origin: CGPoint(x:0,y:-TimeManagementConstant.barsChartCuttedDistance), size: CGSize(width: widht, height: height))
    //设置是否可以伸缩
    let chartSettings:ChartSettings = TimeManagementConstant.iPhoneChartSettings
    
    //自动生成坐标系
    let coordsSpace = ChartCoordsSpaceLeftBottomSingleAxis(chartSettings: chartSettings, chartFrame: chartFrame, xModel: xModel, yModel: yModel)
    let (xAxisLayer, yAxisLayer, innerFrame) = (coordsSpace.xAxisLayer, coordsSpace.yAxisLayer, coordsSpace.chartInnerFrame)
    //生成可以使用的常量
    let chartPointsLayer = ChartPointsViewsLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, chartPoints: chartPoints, viewGenerator: barViewGenerator)
    
    //标签
    
    let labelToBarSpace: CGFloat = 30 // domain units
    let labelChartPoints = chartPoints.map {bar in
      ChartPoint(x: bar.x, y: bar.y)
    }
    let formatter = NumberFormatter()
    formatter.maximumFractionDigits = 2
    let labelsLayer = ChartPointsViewsLayer(xAxis: xAxisLayer.axis, yAxis: yAxisLayer.axis, chartPoints: labelChartPoints, viewGenerator: {(chartPointModel, layer, chart) -> UIView? in
      let label = HandlingLabel()
      
//      let pos = chartPointModel.chartPoint.y.scalar > 0
      //时间 名称赋值
      label.text = "\(barValues[chartPointModel.index].times.changeToSpendTimeString()) "
      label.font = TimeManagementConstant.barsChartFont
      label.textAlignment = .right
      label.textColor = UIColor.black
      label.sizeToFit()
//      label.center = CGPoint(x: chartPointModel.screenLoc.x, y: pos ? innerFrame.origin.y : innerFrame.origin.y + innerFrame.size.height)
      label.alpha = 0
      label.center.y = chartPointModel.screenLoc.y
      label.center.x = labelToBarSpace
      
      label.movedToSuperViewHandler = {[weak label] in
        UIView.animate(withDuration: 0.3, animations: {
          label?.alpha = 1
        })
      }
      return label
      
    }, displayDelay: 0.25, mode: .translate) // show after bars animation
    
   chartsViews = Chart(
      frame: chartFrame,
      innerFrame: innerFrame,
      settings: chartSettings,
      layers: [
        yAxisLayer,
        labelsLayer,
        chartPointsLayer
      ])
    //在屏幕上显示
    ChartScrollView.contentSize = chartsViews!.frame.size
    ChartScrollView.contentSize.height -= TimeManagementConstant.barsChartCuttedDistance
    ChartScrollView.addSubview(chartsViews!.view)
  }
  
  //MARK: creatPieChartFictions
  
  func creatNewPieChart() {
    
    let newPieChart:customPieChart!
    
    //数据 (不需要排序完成)
//    let values:[(title:String,times:Int)] = [
//      ("工作",20),("休息",19),("午睡",17),("锻炼",15),("午饭",13),("看电影",11),("晚饭",9),("聊天",5),("空白",1)
//    ]
    
    let values:[(title:String,times:Int)] = getDataForBarAndPieChart(timeBucket: currentTimeBucket).sorted{ (data1, data2) -> Bool in
      return data1.times > data2.times
    }
    
    func createModels() -> [PieSliceModel] {
      //数据赋值
      let sliceModelArray = values.map{(arg)-> PieSliceModel in
        let (_,times) = arg
        return PieSliceModel(value: Double(times), color: TimeManagementConstant.getAOrderColor)
      }
      
      return sliceModelArray
    }
    
    //文字大小
    func createTextLayer() -> PiePlainTextLayer {
      let textLayerSettings = PiePlainTextLayerSettings()
      textLayerSettings.viewRadius = TimeManagementConstant.pieChartPercentLabelRadius
      textLayerSettings.hideOnOverflow = false
      //      textLayerSettings.label.font = UIFont.systemFont(ofSize: 14)
      //      textLayerSettings.label.textColor = UIColor.white
      
      let formatter = NumberFormatter()
//      formatter.maximumFractionDigits = 2
      formatter.minimumFractionDigits = 2
      textLayerSettings.label.textGenerator = {slice in
        return formatter.string(from: slice.data.percentage * 100 as NSNumber).map{"\($0)%"} ?? ""
      }
      
      textLayerSettings.label.labelGenerator = {(slice) -> UILabel in
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16, weight: UIFont.Weight.regular)
        label.textColor = UIColor.white
        label.frame.size.width = 30
        //formatters to get string
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        let string = formatter.string(from: slice.data.percentage * 100 as NSNumber).map{"\($0)%"} ?? ""
        let documentoryItem = (label,string)
        newPieChart.labelsDocumentory[slice.data.id] = documentoryItem//储存在字典里
        return label
      }
      
      let textLayer = PiePlainTextLayer()
      textLayer.settings = textLayerSettings
      return textLayer
    }
    
    //文字大小
    func createNameTextLayer() -> PiePlainTextLayer {
      let textLayerSettings = PiePlainTextLayerSettings()
      textLayerSettings.viewRadius = TimeManagementConstant.pieChartEventNameRadius
      textLayerSettings.hideOnOverflow = false
      textLayerSettings.label.font = UIFont.systemFont(ofSize: 16)
      textLayerSettings.label.textColor = UIColor.black
      textLayerSettings.label.textGenerator = { (slice) -> String in
        return values[slice.data.id].title
      }
      
      
      let textLayer = PiePlainTextLayer()
      textLayer.settings = textLayerSettings
      return textLayer
    }
    
    //检查是否有数据
    if values.isEmpty {
      //出现无数据提醒
      doNotHaveAnyData.isHidden = false
      return
    }else{
      //隐藏无数据提醒
      doNotHaveAnyData.isHidden = true
    }
    //开始创建PieView 和总计label
    let size = ChartScrollView.frame.size
    newPieChart = customPieChart(frame: CGRect(origin: CGPoint(x:0,y:-TimeManagementConstant.pieChartMoveUpDistance) , size: size))
    newPieChart.layers = [ createTextLayer(),createNameTextLayer()]
    newPieChart.outerRadius = TimeManagementConstant.pieChartDiameter
    newPieChart.innerRadius = 1
    newPieChart.selectedOffset = TimeManagementConstant.pieChartSelecedOffset
    newPieChart.labelsDocumentory.removeAll()//清空字典
    newPieChart.models = createModels() // order is important - models have to be set at the end
    newPieChart.pieSliceValues = values//传入数据
    //创建总计标签
    var totalInt = 0
    for value in values{
      totalInt += value.times
    }
    let totoalLabel = UILabel()
    totoalLabel.font = UIFont.systemFont(ofSize: 21, weight: UIFont.Weight.regular)
    totoalLabel.text = "\(DefaultWords.total) \(totalInt/60):\(totalInt%60)"
    totoalLabel.frame.origin.x = newPieChart.center.x-70
    totoalLabel.frame.origin.y = newPieChart.frame.maxY-TimeManagementConstant.pieChartDistanceToTotalLabel
    totoalLabel.frame.size = CGSize(width: 150, height: 40)
    totoalLabel.textAlignment = .center
    newPieChart.addSubview(totoalLabel)
    //显示在屏幕上并且储存引用
    ChartScrollView.addSubview(newPieChart)
    pieChartView = newPieChart
  }
  

}


class customPieChart:PieChart{
  
  var labelsDocumentory:[Int:(UILabel,String)] = [:]
  var pieSliceValues:[(String,Int)]!
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //重写点击方法
    if let touch = touches.first {
      let point = touch.location(in: self)
      if let slice = (slices.filter{$0.view.contains(point)}).first {
        for slices in super.slices{
          if slices.view.selected && slice != slices{
            slices.view.selected = false
            labelsDocumentory[slices.data.id]!.0.text = labelsDocumentory[slices.data.id]!.1
          }
        }
        slice.view.selected = !slice.view.selected
        
        if labelsDocumentory[slice.data.id]!.0.text! == labelsDocumentory[slice.data.id]!.1 {
          //展示数字
          labelsDocumentory[slice.data.id]!.0.text = "\(pieSliceValues[slice.data.id].1.changeToSpendTimeString())"
        }else{
          //展示百分比
          labelsDocumentory[slice.data.id]!.0.text! = labelsDocumentory[slice.data.id]!.1
        }
      }
    }
  }
}


enum TimeBucket {
  case last7days
  case last15days
  case last30days
  case last90days
  case yesterDay
  case lastWeek
  case lastMonth
  case totally
  
  static func changeEnumToString(_ time:TimeBucket)->String{
    switch time {
    case .last7days: return DefaultWords.last7days
    case .last15days: return DefaultWords.last15days
    case .last30days: return DefaultWords.last30days
    case .last90days : return DefaultWords.last90days
    case .yesterDay : return DefaultWords.yesterDay
    case .lastWeek : return DefaultWords.lastWeek
    case .lastMonth : return DefaultWords.lastMonth
    case .totally : return DefaultWords.totally
    }
  }
  static func changeStringToEnum(_ string:String)->TimeBucket?{
    switch string {
    case DefaultWords.last7days: return .last7days
    case DefaultWords.last15days: return .last15days
    case DefaultWords.last30days: return .last30days
    case DefaultWords.last90days: return .last90days
    case DefaultWords.yesterDay : return .yesterDay
    case DefaultWords.lastWeek : return .lastWeek
    case DefaultWords.lastMonth : return .lastMonth
    case DefaultWords.totally : return .totally
    default: return nil
    }
  }
}
//struct timeBucke {
//
//  static var last7days = DefaultWords.last7days
//  static var last15days = DefaultWords.last15days
//  static var last30days = DefaultWords.last30days
//  static var last90days = DefaultWords.last90days
//  static var yesterDay = DefaultWords.yesterDay
//  static var lastWeek = DefaultWords.lastWeek
//  static var lastMonth = DefaultWords.lastMonth
//  static var totally = DefaultWords.totally
//}

struct TimeManagementConstant {
  
  static let barWidth:CGFloat = 38
  static let barsDistance:CGFloat = 35
  static let barsChartCuttedDistance:CGFloat = 16
  static let pieChartDiameter:CGFloat = 0.38*Constants.screenWidth
  static let pieChartEventNameRadius:CGFloat = TimeManagementConstant.pieChartDiameter*1.2
  static let pieChartPercentLabelRadius:CGFloat = TimeManagementConstant.pieChartDiameter*0.8
  static let pieChartSelecedOffset:CGFloat = 15
  static let pieChartMoveUpDistance:CGFloat = Constants.screenHeight*0.11
  static let pieChartDistanceToTotalLabel:CGFloat = Constants.screenHeight*(-0.04)
  static let barsChartFont:UIFont = UIFont.systemFont(ofSize: 20,weight:UIFont.Weight.light)
  
  fileprivate static var iPhoneChartSettings: ChartSettings {
    var chartSettings = ChartSettings()
    chartSettings.leading = 4
    chartSettings.top = 0
    chartSettings.trailing = 20
    chartSettings.bottom = 0
    chartSettings.labelsToAxisSpacingX = 5
    chartSettings.labelsToAxisSpacingY = 5
    chartSettings.axisTitleLabelsToLabelsSpacing = 4
    chartSettings.axisStrokeWidth = 0
    chartSettings.spacingBetweenAxesX = 8
    chartSettings.spacingBetweenAxesY = 8
    chartSettings.labelsSpacing = 0
//    chartSettings.clipInnerFrame = false
    return chartSettings
  }
  
  static let chartsColor = [#colorLiteral(red: 0.2619540691, green: 0.631634295, blue: 0.9995002151, alpha: 1),#colorLiteral(red: 0.3786362708, green: 0.8500594497, blue: 0.2139517963, alpha: 1),#colorLiteral(red: 0.9705690742, green: 0.7317094207, blue: 0, alpha: 1),#colorLiteral(red: 0.9563795924, green: 0.1465377212, blue: 0.01141931582, alpha: 1),#colorLiteral(red: 0.7604554296, green: 0.2827201486, blue: 0.5219334364, alpha: 1),#colorLiteral(red: 0.3725149632, green: 0.372571528, blue: 0.3724971414, alpha: 1)]
  static var colorIntForOrder = 0
  static var getAOrderColor:UIColor {
    let color = chartsColor[colorIntForOrder%6]
    colorIntForOrder += 1
//    print("颜色顺序\(colorIntForOrder)")
    return color
  }
}

