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
            let urlStr = "https://pan.baidu.com/api/list?dir=\(path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? "")&clienttype=0&web=1&page=1&channel=chunlei&web=1&app_id=250528&stoken=\(token)"
            if urlStr.count > 0, let url = URL.init(string: urlStr) {
                print("====================")
                print(urlStr)
//                if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
//                    print("+++++++++++++++")
//                    cookies.forEach({ (cookie) in
//                        print(cookie)
//                    })
//                }

                let request = Alamofire.request(url, headers: nil)
                request.responseJSON(completionHandler: { (resp) in
                    if let err = resp.error {
                        finish(nil, err as NSError)
                    } else {
                        if let list = (resp.result.value as? [String:Any])?["list"] as? [[String:Any]] {
                            finish(list, nil)
//                            print(list)
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
    
    func getDLink(_ path : [String], finish : @escaping ([String]?, NSError?)->()) {
        if let token = Manager.token {
            let pathes = path.map({ (str) -> String in
                return "\"\(str)\""
            })
            let query = "target=[\(pathes.joined(separator: ","))]&stoken=\(token)&dlink=1&channel=chunlei&web=1&app_id=250528&logid=MTUxNjExMDQyOTg3ODAuNjY0MDEzODg0NjQ0MjM0OQ==&clienttype=0".addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? ""
            let urlStr = "https://pan.baidu.com/api/filemetas?\(query)"
            if urlStr.count > 0, let url = URL.init(string: urlStr) {
                print("====================")
                print(urlStr)
//                if let cookies = HTTPCookieStorage.shared.cookies(for: url) {
//                    print("+++++++++++++++")
//                    cookies.forEach({ (cookie) in
//                        print(cookie)
//                    })
//                }
                let request = Alamofire.request(url, headers: nil)
                request.responseJSON(completionHandler: { (resp) in
                    if let err = resp.error {
                        finish(nil, err as NSError)
                    } else {
                        if let list = (resp.result.value as? [String:Any])?["info"] as? [[String:Any]] {
//                            print(list)
                            let items = list.flatMap({ (item) -> String? in
                                return item["dlink"] as? String
                            })
                            finish(items, nil)
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
