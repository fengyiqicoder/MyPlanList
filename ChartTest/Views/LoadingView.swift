//
//  LoadingView.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/2/28.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import Foundation
import UIKit

class LoadingView: UIView {
  
  var indicator: UIActivityIndicatorView!
  var loadingLabel:UILabel!
  
  override init(frame: CGRect) {
    super.init(frame: frame)
    self.indicator = self.getIndicatorView(frame)
    self.indicator.activityIndicatorViewStyle = .white
    self.indicator.color = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    self.addSubview(self.indicator)
    self.indicator.startAnimating()
    self.backgroundColor = UIColor(white: 0.0, alpha: 0)
    self.isUserInteractionEnabled = true // 吃事件
    self.loadingLabel = getLabel()
    self.addSubview(loadingLabel)
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)!
  }
  
  func getIndicatorView(_ frame: CGRect) -> UIActivityIndicatorView{
    let indicator: UIActivityIndicatorView = UIActivityIndicatorView()
    indicator.color = UIColor.black
    indicator.alpha = 1
    indicator.transform = CGAffineTransform(scaleX: 1.5, y: 1.5)
    indicator.center = CGPoint(x: frame.size.width / 2, y: frame.size.height / 2)
    return indicator
  }
  
  func getLabel() -> UILabel {
    let y = indicator.frame.maxY+15
    let width = Constants.screenWidth
    let height:CGFloat = 30
    let label = UILabel(frame: CGRect(x: 0, y: y,
                                      width: width,
                                      height: height))
    label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
    label.text = DefaultWords.IAPConnectingMessage
    label.textAlignment = .center
    label.backgroundColor = UIColor.clear
    label.textColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
    return label
  }
  
  deinit {
    self.indicator.stopAnimating()
  }
  
}
