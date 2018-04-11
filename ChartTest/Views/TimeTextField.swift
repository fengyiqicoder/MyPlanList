//
//  TimeTextField.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/2/6.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import UIKit

class TimeTextField: NameTextField {

  var timeTextDelegate:TimeTextFieldDelegate!
  
//  override var text: String?{
//    didSet{
//      if oldValue != "" {//第一次更改
//       timeTextDelegate.checkForShowTimeDistance(self)
//      }
//    }
//  }
  
  override func becomeFirstResponder() -> Bool {
    let bool = timeTextDelegate.shouldBecomeFirstResponder(self)
    if bool { super.becomeFirstResponder() }
    return bool
  }
  
  override func resignFirstResponder() -> Bool {
    let bool = timeTextDelegate.shouldResignFirstResponder(self)
    if bool { super.resignFirstResponder() }
    return bool
  }
  
}

protocol TimeTextFieldDelegate {
  func shouldBecomeFirstResponder(_ timeTextField: TimeTextField)->Bool
  func shouldResignFirstResponder(_ timeTextField: TimeTextField)->Bool
//  func checkForShowTimeDistance(_ timeTextField:TimeTextField)
}

class NameTextField:UITextField{
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return false
  }
  
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.clipsToBounds = false
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    self.clipsToBounds = false
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    for view in self.subviews {//遍历子视图
      if view is UIScrollView{//如果是scrollView
        let sView:UIScrollView = view as! UIScrollView
        if sView.contentOffset != CGPoint.zero{//更新位置
          sView.contentOffset = CGPoint.zero
        }
      }
    }
  }
}

protocol ownTextViewDelegate {
  func beforeBecameFirstResponder()->Bool
}

class ownTextView: UITextView {
  
  var ownDelegate:ownTextViewDelegate!
  
  override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
    return false
  }
  
  override func becomeFirstResponder() -> Bool {
    if ownDelegate.beforeBecameFirstResponder(){
      super.becomeFirstResponder()
      return true
    }
    return false
  }
}
