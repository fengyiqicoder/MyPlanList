//
//  InfoViewController.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/2/28.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import UIKit

class InfoViewController: UIViewController {

  @IBOutlet weak var infoScrollView: UIScrollView!
  var exitButton = UIButton()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view.
    
  }
  
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    for (order,image) in DefaultWords.infoImageArray.enumerated(){
      let newImageView = UIImageView(frame: CGRect(origin:
        CGPoint(x:CGFloat(order)*infoScrollView.frame.width,
                y:0),
                                                   size: infoScrollView.frame.size))
      newImageView.contentMode = .scaleAspectFill
      newImageView.image = image
      infoScrollView.addSubview(newImageView)
    }
    infoScrollView.contentSize = CGSize(width: infoScrollView.frame.width*4,
                                        height: infoScrollView.frame.height)
  }



  
}
