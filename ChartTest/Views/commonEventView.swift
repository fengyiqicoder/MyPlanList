//
//  commonEventView.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/2/23.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import Foundation
import UIKit

class CommonEventView: UIScrollView {
  
  //model
  var stringsArray:[String]!
  var nameTextField:NameTextField!
  
  //override  init functions
  override init(frame: CGRect) {
    super.init(frame: frame)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  }
  
  convenience init(frame:CGRect,strings:[String],nameTextField:NameTextField) {
    self.init(frame: frame)
    self.stringsArray = strings
    //控制string数量 最多20
    while stringsArray.count >= 20 {
      stringsArray.removeLast()
    }
    self.nameTextField = nameTextField
    self.backgroundColor = UIColor.white
    self.showsHorizontalScrollIndicator = false
    creatButtons()
  }
  
  //UI functions
  let font = UIFont.systemFont(ofSize: 24, weight: UIFont.Weight.light)
  let gap:CGFloat = 15
  func creatButtons() {
    //查看是否有数据
    if stringsArray.isEmpty {
      let noneDataLabel = UILabel(frame: CGRect(origin:CGPoint.zero,size:self.frame.size))
      noneDataLabel.font = font
      noneDataLabel.textAlignment = .center
      noneDataLabel.textColor = UIColor.lightGray
      noneDataLabel.text = DefaultWords.noDataForCommontEvent
      self.addSubview(noneDataLabel)
      self.contentSize = self.frame.size
    }else{
      let height = self.frame.height
      var lastViewsX:CGFloat = 0
      for text in stringsArray{
        let width = text.width(withConstraintedHeight: height, font: font)
        let originX = lastViewsX + gap
        let newButton = UIButton(frame: CGRect(x: originX, y: 0, width: width, height: height))
        //配置button
        newButton.setTitle(text, for: .normal)
        newButton.setTitleColor(#colorLiteral(red: 0, green: 0, blue: 0, alpha: 1), for: .normal)
        newButton.titleLabel?.font = font
        newButton.addTarget(self, action: #selector(commontEventButtonPressed(sender:)), for: .touchDown)
        lastViewsX = newButton.frame.maxX
        //显示
        self.addSubview(newButton)
      }
      //更新contentSize
      self.contentSize = CGSize(width: lastViewsX, height: height)
    }
    let lineView = UIView(frame:CGRect(origin: CGPoint(x:-self.frame.width,y:0) ,
                                         size: CGSize(width: self.contentSize.width+self.frame.width*2, height: 1)))
    lineView.backgroundColor = UIColor.lightGray
    addSubview(lineView)
  }
  
  @objc func commontEventButtonPressed(sender:UIButton){
    nameTextField.text = "\(sender.title(for: .normal)!)"
  }
  
}

