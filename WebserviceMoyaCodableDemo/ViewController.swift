//
//  ViewController.swift
//  WebserviceMoyaCodableDemo
//
//  Created by sioeye on 2022/1/12.
//

import UIKit

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        LXWebServiceHelper<String>().requestJSONModel(TestRequestType.baidu, progressBlock: nil) { container in
//                   print(container.value)
//               } exceptionHandle: { error in
//                   print(error)
//               }
        
        LXWebServiceHelper<UserInfo>().requestJSONModel(TestRequestType.baidu, progressBlock: nil) { container in
                   print(container.value?.trueName)
               } exceptionHandle: { error in
                   print(error)
               }
               
       //        LXWebServiceHelper<LXBaseModel>().requestJSONModel(TestRequestType.baidu, progressBlock: nil) { container in
       //            print(container.originObject)
       //        } exceptionHandle: { error in
       //            print(error)
       //        }
               
        
        //字典解析 关键在与userinfo 字段是字典还是数组
//        let path = Bundle.main.path(forResource: "jsonDic", ofType: "json")
//        let url = URL(fileURLWithPath: path!)
//        // 带throws的方法需要抛异常
//        do {
//            /*
//             * try 和 try! 的区别
//             * try 发生异常会跳到catch代码中
//             * try! 发生异常程序会直接crash
//             */
//            let data = try Data(contentsOf: url)
//            let jsonData:Any = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
//
//            let container = LXRequestResultContainer<UserInfo>(jsonObject: jsonData)
//            print(container.value?.trueName)
//
//            if let dic = container.value?.convertToJSONObject() {
//                print(dic)
//            }
//        } catch {
//            print("读取本地数据出现错误!",error)
//        }
        
        // 数组解析
//        let path = Bundle.main.path(forResource: "jsonArray", ofType: "json")
//        let url = URL(fileURLWithPath: path!)
//        // 带throws的方法需要抛异常
//        do {
//            /*
//             * try 和 try! 的区别
//             * try 发生异常会跳到catch代码中
//             * try! 发生异常程序会直接crash
//             */
//            let data = try Data(contentsOf: url)
//            let jsonData:Any = try JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableContainers)
//
//            let container = LXRequestResultContainer<[UserInfo]>(jsonObject: jsonData)
//            print(container.value)
//        } catch {
//            print("读取本地数据出现错误!",error)
//        }
        // Do any additional setup after loading the view.
    }


}

