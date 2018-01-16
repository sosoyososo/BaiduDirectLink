//
//  ViewController.swift
//  BaiduDirectLink
//
//  Created by karsa on 2018/1/16.
//  Copyright © 2018年 karsa. All rights reserved.
//

import UIKit
import KCBlockUIKit

let tokenKey = "baidu_token"
var token : String? = nil

class ViewController: UIViewController, UIWebViewDelegate {
    
    @IBOutlet var webView : UIWebView?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        token = UserDefaults.standard.value(forKey: tokenKey) as? String
        Manager.token = token
        if let url = URL.init(string: "http://pan.baidu.com") {
            webView?.loadRequest(URLRequest.init(url: url))
        }
        webView?.delegate = self

        if token != nil {
            KCDeferMainQueueAction(1, { [unowned self] in
                self.showHome()
            })
        }
    }
    
    func webView(_ webView: UIWebView, shouldStartLoadWith request: URLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if request.url?.absoluteString.contains("stoken") == true {
            var stoken = ""
            if let list = request.url?.absoluteString.components(separatedBy: "&") {
                for i in 0..<list.count {
                    let strS = list[i].components(separatedBy: "=")
                    if strS.first == "stoken", strS.count >= 2 {
                        stoken = strS[1]
                        UserDefaults.standard.set(stoken, forKey: tokenKey)
                        token = stoken
                        Manager.token = stoken
                        showHome()
                        break
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

