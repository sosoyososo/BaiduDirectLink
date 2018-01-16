//
//  Manager.swift
//  BaiduDirectLink
//
//  Created by karsa on 2018/1/16.
//  Copyright © 2018年 karsa. All rights reserved.
//

import Foundation
import Alamofire

extension NSError {
    var message : String {
        return ((userInfo as? [String:Any])?["msg"] as? String) ?? localizedDescription
    }
}

class Manager {
    static var token : String? = nil
    static let share = Manager()
    
    func loadHome(_ finish : @escaping ([[String:Any]]?, NSError?)->()) {
        loadList("/", finish: finish)
    }
    
    func loadList(_ path : String, finish : @escaping ([[String:Any]]?, NSError?)->()) {
        if let token = Manager.token {
            let urlStr = "https://pan.baidu.com/api/list?dir=\(path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? "")&stoken=\(token)"
            if urlStr.count > 0, let url = URL.init(string: urlStr) {
                let request = Alamofire.request(url, headers: nil)
                request.responseJSON(completionHandler: { (resp) in
                    if let err = resp.error {
                        finish(nil, err as NSError)
                    } else {
                        if let list = (resp.result.value as? [String:Any])?["list"] as? [[String:Any]] {
                            finish(list, nil)
                        } else {
                            finish(nil, NSError.init(domain: "Server", code: -1, userInfo:["msg":"数据格式解析错误"]))
                        }
                    }
                })
            } else {                
                finish(nil, NSError.init(domain: "Server", code: -1, userInfo:["msg":"url 格式错误"]))
            }
        } else {
            finish(nil, NSError.init(domain: "Server", code: -1, userInfo:["msg":"token"]))
        }
    }
    
    func getDLink(_ path : String, finish : @escaping (String?, NSError?)->()) {
        if let token = Manager.token {
            let parameter = "[\"\(path)\"]".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? ""
            let urlStr = "https://pan.baidu.com/api/filemetas?target=\(parameter)&stoken=\(token)&dlink=1"
            if urlStr.count > 0, let url = URL.init(string: urlStr) {
                let request = Alamofire.request(url, headers: nil)
                request.responseJSON(completionHandler: { (resp) in
                    if let err = resp.error {
                        finish(nil, err as NSError)
                    } else {
                        if let list = (resp.result.value as? [String:Any])?["info"] as? [[String:Any]] {
                            if let dlink = list.first?["dlink"] as? String {
                                finish(dlink, nil)
                            } else {
                                finish(nil, NSError.init(domain: "Server", code: -1, userInfo:["msg":"数据格式解析错误"]))
                            }
                        } else {
                            finish(nil, NSError.init(domain: "Server", code: -1, userInfo:["msg":"数据格式解析错误"]))
                        }
                    }
                })
            } else {
                finish(nil, NSError.init(domain: "Server", code: -1, userInfo:["msg":"url 格式错误"]))
            }
        } else {
            finish(nil, NSError.init(domain: "Server", code: -1, userInfo:["msg":"token"]))
        }

    }
}
