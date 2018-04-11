//
//  CustomKeyboard.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/2/6.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import UIKit

class CustomKeyboard: UIView {

  @IBOutlet weak var clearButton: UIButton!
  @IBOutlet weak var deleteButton: UIButton!
  @IBOutlet weak var doneButton: UIButton!
  var textFielddelegate:CustomKeyboardDelegate!
  var eventViewDelegate:CustomKeyboardDelegateForEventView!
  
  @IBAction func keyPressed(sender:UIButton){//输入按钮
    let keyTitle = sender.titleLabel!.text!
    self.textFielddelegate.symbolKeyPressed(symbol: keyTitle)
  }
  
  @IBAction func backspaceKeyPress(){//删除按钮
    self.textFielddelegate.backSpaceKeyPressed()
  }
  
  @IBAction func DoneKeyPressed()  {//下一个按钮
    self.eventViewDelegate.focusOnNameLabelOrFinishEditing()
  }
  
  @IBAction func deleteEventView(){//删除
    self.eventViewDelegate.deleteEventView()
    self.textFielddelegate.doneKeyPressed()
  }
  
  @IBAction func clearAllKey(){
    self.textFielddelegate.clearText()
  }
  
  
  convenience init(frame:CGRect,delegate:CustomKeyboardDelegate,eventViewsDelegate:CustomKeyboardDelegateForEventView){
    self.init(frame: frame)
    self.textFielddelegate = delegate//初始化键盘
    self.eventViewDelegate = eventViewsDelegate
    checkOutDoneKey()
    deleteButton.setTitle(DefaultWords.delete, for: .normal)
    clearButton.setTitle(DefaultWords.clear, for: .normal)
  }
  
  func checkOutDoneKey() {
    //判断确定键的样式
    if eventViewDelegate.isTextInNameLabel() {
      //确定键
      doneButton.setTitle(DefaultWords.done, for: .normal)
      doneButton.setTitleColor(UIColor.white, for: .normal)
      doneButton.setBackgroundImage(#imageLiteral(resourceName: "BlueTallKey"), for: .normal)
    }else{
      //下一个键
      doneButton.setTitle(DefaultWords.next, for: .normal)
      doneButton.setTitleColor(UIColor.black, for: .normal)
      doneButton.setBackgroundImage(#imageLiteral(resourceName: "yellowTallKey"), for: .normal)
    }
  }
  
  //MARK: - get Views from xib
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.getViewsFromXib()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.getViewsFromXib()
  }
  
  func getViewsFromXib() {
    let view = Bundle.main.loadNibNamed("CustomKeyboardView", owner: self, options: nil)![0] as! UIView
    view.frame = self.bounds
    self.addSubview(view)
  }

}

protocol CustomKeyboardDelegate {
  func symbolKeyPressed(symbol:String)
  func backSpaceKeyPressed()
  func doneKeyPressed()
  func clearText()
}

extension UITextField :CustomKeyboardDelegate{
  func symbolKeyPressed(symbol: String){//添加字符串到text中
    let moveToRightDistance:Int = symbol=="00" ? 2 : 1//确定是不是"00"键
    if let selectedRange = self.selectedTextRange {
      print("开始 \(selectedRange.start) 与结束 \(selectedRange.end)")
      let cursorPosition = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
      let stringIndex = String.Index(encodedOffset:cursorPosition)
      self.text!.insert(contentsOf:symbol, at: stringIndex)
      let newPosition = self.position(from: selectedRange.start, offset: moveToRightDistance)!//重新设置光标位置
      self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
      print("cursorPosition\(cursorPosition)")
    }
  }
  func backSpaceKeyPressed() {//删除字符
    if text!.count > 0{
      if let selectedRange = self.selectedTextRange {
        print("开始 \(selectedRange.start) 与结束 \(selectedRange.end)")
        let cursorPosition = self.offset(from: self.beginningOfDocument, to: selectedRange.start)
        if cursorPosition == 0 { return } //如果在最前面不做操作
        self.text!.remove(at:  String.Index(encodedOffset:cursorPosition-1))
        let newPosition = self.position(from: selectedRange.start, offset: -1)!//重新设置光标位置
        self.selectedTextRange = self.textRange(from: newPosition, to: newPosition)
        print("cursorPosition\(cursorPosition)")
      }
    }
  }
  func doneKeyPressed() {//取消键盘
    self.resignFirstResponder()
  }
  //更改任意textField键盘的方法
  func setAsCustomKeyBoard(delegateForEventView:CustomKeyboardDelegateForEventView) {
    let keyBoard = CustomKeyboard(frame: CGRect(origin:CGPoint.zero,
                                                size:CGSize(width: 0,height: Constants.customKeyboardHeight)) ,
                                  delegate: self,
                                  eventViewsDelegate:delegateForEventView)
    self.inputView = keyBoard
  }
  
  func clearText() {
    self.text = ""
  }
}
