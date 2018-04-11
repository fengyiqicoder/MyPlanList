//
//  IAPController.swift
//  ChartTest
//
//  Created by 冯奕琦 on 2018/2/28.
//  Copyright © 2018年 冯奕琦. All rights reserved.
//

import Foundation

import UIKit
import StoreKit

class IAPController :NSObject,SKProductsRequestDelegate,SKPaymentTransactionObserver{
  
  var isProgress: Bool = false // 是否有交易正在進行中
  var lodingView: LoadingView?
  var productID:[String] = ["planlist"]
  var product:SKProduct!
  
  init(delegate:IAPDelegate) {
    self.delegate = delegate
  }
  
  var delegate:IAPDelegate
  //计算属性
  var havePaid:Bool {
    if let havePaidValue = delegate.getHavePaidInUserDefault() {
      return havePaidValue
    }else{
      delegate.setHavePaidValueInUserDefault(false)
      return false
    }
  }
  
  func checkPurchased() -> Bool {
//    if havePaid {
//
      return true
//    }else{
//      self.showingBuySheet(price: DefaultWords.IAPPrice)
//      return false
//    }
//    return true
  }
  
  func showingBuySheet(price:String) {
    
    let activateString = DefaultWords.IAPActivate
    let cancelString = DefaultWords.IAPCancel
    let title = DefaultWords.IAPTitle
    let message = price //获取当地价钱
    //点击购买
    let buyAction = UIAlertAction(title: activateString, style: UIAlertActionStyle.default){ (action) -> Void in
      //获取信息
      self.requestProductInfoAndStartPurchase()
      //添加loadingView
      self.lodingView = LoadingView(frame: UIScreen.main.bounds)
      self.delegate.getCurrentViewcontroller().view.addSubview(self.lodingView!)
     
    }
    //点击恢复激活
    let reStoreAction = UIAlertAction(title: DefaultWords.IAPRestore,
                                      style: UIAlertActionStyle.default) { (action) -> Void in
      if SKPaymentQueue.canMakePayments() {
        // 設定交易流程觀察者，會在背景一直檢查交易的狀態，成功與否會透過 protocol 得知
        SKPaymentQueue.default().add(self)
        //恢复购买
        SKPaymentQueue.default().restoreCompletedTransactions()
        self.isProgress = true
        
        // 開始執行購買產品的動作
        self.lodingView = LoadingView(frame: UIScreen.main.bounds)
        self.delegate.getCurrentViewcontroller().view.addSubview(self.lodingView!)
      }
    }
    
    //取消操作
    let cancelAction = UIAlertAction(title: cancelString, style: UIAlertActionStyle.cancel, handler: nil)
    
    let actionSheetController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.actionSheet)
    
    actionSheetController.addAction(buyAction)
    actionSheetController.addAction(cancelAction)
    actionSheetController.addAction(reStoreAction)
    
    delegate.getCurrentViewcontroller().present(actionSheetController, animated: true){
      //删除loading view
      if self.lodingView != nil {
        self.lodingView?.removeFromSuperview()
      }
    }
  }
  
  // 發送請求以用來取得內購的產品資訊
  func requestProductInfoAndStartPurchase() {
    if SKPaymentQueue.canMakePayments() {
      // 取得所有在 iTunes Connect 所建立的內購項目
      let productIdentifiers: Set<String> = NSSet(array: self.productID) as! Set<String>
      let productRequest: SKProductsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
      
      productRequest.delegate = self
      productRequest.start() //開始請求內購產品
    } else {
      print("取不到任何內購的商品...")
    }
  }
  
  func show(message:String) {
    
    let title = DefaultWords.IAPHint
    let confirmTitle = DefaultWords.OK
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let confirm = UIAlertAction(title: confirmTitle, style: .default, handler: nil)
    alertController.addAction(confirm)
    self.delegate.getCurrentViewcontroller().present(alertController, animated: true, completion: nil)
  }
  
  //MARK: - delegate
  
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    
    if response.products.count != 0 {
      // 將取得的 IAP 產品放入 product 裡
      product = response.products[0]
      //进行购买
      if SKPaymentQueue.canMakePayments() {
        // 設定交易流程觀察者，會在背景一直檢查交易的狀態，成功與否會透過 protocol 得知
        SKPaymentQueue.default().add(self)
        // 取得內購產品并开始购买
        self.isProgress = true
        // 取得內購產品
        let payment = SKPayment(product: self.product)
        // 購買消耗性、非消耗性動作將會開始在背景執行(updatedTransactions delegate 會接收到兩次)
        SKPaymentQueue.default().add(payment)
      }
    }else{
      print("取不到任何商品...")
    }
    
  }
  
  func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
    
    for transaction in transactions{
      switch transaction.transactionState {
      case .purchased,.restored:
        print("交易成功...")
        // 必要的機制
        SKPaymentQueue.default().finishTransaction(transaction)
        self.isProgress = false
        // 移除觀查者
        SKPaymentQueue.default().remove(self)
        // 跟 ViewController
        delegate.setHavePaidValueInUserDefault(true)
        //删除loading view
        if self.lodingView != nil {
          self.lodingView?.removeFromSuperview()
        }
        show(message: DefaultWords.IAPCompleteActive)
      case .failed:
        print("交易失败")
        if let error = transaction.error as? SKError {
          switch error.code {
          case .paymentCancelled:
            // 輸入 Apple ID 密碼時取消
            print("Transaction Cancelled: \(error.localizedDescription)")
          case .paymentInvalid:
            print("Transaction paymentInvalid: \(error.localizedDescription)")
          case .paymentNotAllowed:
            print("Transaction paymentNotAllowed: \(error.localizedDescription)")
          default:
            print("Transaction: \(error.localizedDescription)")
            show(message: "\(error.localizedDescription)")
          }
          
        }
        if self.lodingView != nil {
          self.lodingView?.removeFromSuperview()
        }
        SKPaymentQueue.default().finishTransaction(transaction)
        self.isProgress = false
      default:
        print(transaction.transactionState.rawValue)
//        print("交易在界面上失败")
      }
    }
  }
  
  // 復原購買失敗
  func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
    print("復原購買失敗...")
    if self.lodingView != nil {
      self.lodingView?.removeFromSuperview()
    }
    print(error.localizedDescription)
  }
  
  // 回復購買成功(若沒實作該 delegate 會有問題產生)
  func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    print("復原購買成功...")
  }
  
}


protocol IAPDelegate {
  func getHavePaidInUserDefault() -> Bool?
  func setHavePaidValueInUserDefault(_ value:Bool)
  func getCurrentViewcontroller() -> UIViewController
}



extension SKProduct {
  
  func localizedPrice() -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = self.priceLocale
    return formatter.string(from: self.price)!
  }
  
}
