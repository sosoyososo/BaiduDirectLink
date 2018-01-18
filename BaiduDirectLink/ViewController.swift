//
//  ViewController.swift
//  BaiduDirectLink
//
//  Created by karsa on 2018/1/16.
//  Copyright © 2018年 karsa. All rights reserved.
//

import UIKit
import KCBlockUIKit

class ViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView : UIWebView?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let url = URL.init(string: "http://pan.baidu.com") {
            webView?.loadRequest(URLRequest.init(url: url))
        }
        webView?.delegate = self
        setNavRightItem("首页", image: nil, titleColor: nil, font: nil) { [unowned self] in
            self.showHome()
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url?.absoluteString.contains("stoken") == true {
            var stoken = ""
            if let list = request.url?.absoluteString.components(separatedBy: "&") {
                for i in 0..<list.count {
                    let strS = list[i].components(separatedBy: "=")
                    if strS.first?.lowercased() == "stoken", strS.count >= 2 {
                        stoken = strS[1]                        
                        Manager.token = stoken
                    } else if strS.first?.lowercased() == "logid", strS.count >= 2 {
                        Manager.logId = strS[1]
                    }
                }
            }
        }
        return true
    }
    
    func showHome() {
        let controller = ListViewController()
        controller.isHome = true
        present(UINavigationController.init(rootViewController: controller), animated: true, completion: nil)
    }
}

