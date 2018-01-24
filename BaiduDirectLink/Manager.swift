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
    var message: String {
        return ((userInfo as? [String: Any])?["msg"] as? String) ?? localizedDescription
    }
}

let tokenKey = "baidu_token"
let logIdKey = "baidu_logId"
class Manager {
    static var token: String? = nil {
        didSet {
            if let value = token {
                UserDefaults.standard.setValue(value, forKey: tokenKey)
            } else {
                UserDefaults.standard.removeSuite(named: tokenKey)
            }
        }
    }
    static var logId: String? = nil {
        didSet {
            if let value = logId {
                UserDefaults.standard.setValue(value, forKey: logIdKey)
            } else {
                UserDefaults.standard.removeSuite(named: logIdKey)
            }
        }
    }
    static let share = Manager()

    init() {
        Manager.token = UserDefaults.standard.value(forKey: tokenKey) as? String
        Manager.logId = UserDefaults.standard.value(forKey: logIdKey) as? String
    }

    func loadHome(_ finish : @escaping ([[String: Any]]?, NSError?) -> Void) {
        loadList("/", finish: finish)
    }

    func loadList(_ path: String, finish : @escaping ([[String: Any]]?, NSError?) -> Void) {
        if let token = Manager.token {
            var urlStr = "https://pan.baidu.com/api/list?"
            urlStr += "dir=\(path.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlHostAllowed) ?? "")"
            urlStr += "&clienttype=0&web=1&page=1&channel=chunlei&web=1&app_id=250528&stoken=\(token)"
            if urlStr.count > 0, let url = URL.init(string: urlStr) {
                let request = Alamofire.request(url, headers: nil)
                request.responseJSON(completionHandler: { (resp) in
                    if let err = resp.error {
                        finish(nil, err as NSError)
                    } else {
                        if let list = (resp.result.value as? [String: Any])?["list"] as? [[String: Any]] {
                            finish(list, nil)
                        } else {
                            finish(nil, NSError.init(domain: "Server", code: -1, userInfo: ["msg": "数据格式解析错误"]))
                        }
                    }
                })
            } else {
                finish(nil, NSError.init(domain: "Server", code: -1, userInfo: ["msg": "url 格式错误"]))
            }
        } else {
            finish(nil, NSError.init(domain: "Server", code: -1, userInfo: ["msg": "token"]))
        }
    }

    func getDLink(_ path: [String], finish : @escaping ([String]?, NSError?) -> Void) {
        if let token = Manager.token {
            let pathes = path.map({ (str) -> String in
                return "\"\(str)\""
            })
            var target = "[\(pathes.joined(separator: ","))]"
            target = target.addingPercentEncoding(withAllowedCharacters: CharacterSet()) ?? ""
            var query = "target=\(target)&stoken=\(token)&"
            query += "dlink=1&channel=chunlei&web=1&app_id=250528&clienttype=0&logid=\(Manager.logId ?? "")"
            let urlStr = "https://pan.baidu.com/api/filemetas?\(query)"
            if urlStr.count > 0, let url = URL.init(string: urlStr) {
                let request = Alamofire.request(url, headers: nil)
                request.responseJSON(completionHandler: { (resp) in
                    if let err = resp.error {
                        finish(nil, err as NSError)
                    } else {
                        if let list = (resp.result.value as? [String: Any])?["info"] as? [[String: Any]] {
                            let items = list.flatMap({ (item) -> String? in
                                return item["dlink"] as? String
                            })
                            print("====================")
                            print(items)
                            finish(items, nil)
                        } else {
                            finish(nil, NSError.init(domain: "Server", code: -1, userInfo: ["msg": "数据格式解析错误"]))
                        }
                    }
                })
            } else {
                finish(nil, NSError.init(domain: "Server", code: -1, userInfo: ["msg": "url 格式错误"]))
            }
        } else {
            finish(nil, NSError.init(domain: "Server", code: -1, userInfo: ["msg": "token"]))
        }

    }
}
