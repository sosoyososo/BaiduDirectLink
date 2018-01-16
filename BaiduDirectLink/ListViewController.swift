//
//  ListViewController.swift
//  BaiduDirectLink
//
//  Created by karsa on 2018/1/16.
//  Copyright © 2018年 karsa. All rights reserved.
//

import Foundation
import SnapKit
import KCBlockUIKit

class ListViewController : UIViewController {
    private var table = KCBlockTableView()
    
    var isHome : Bool = false
    var path : String? = nil
    
    private var items : [[String:Any]]? = nil {
        didSet {
            if let cellItems = items?.map({ (item) -> (String,Any,Float) in
                return ("cell", item, Float(50.0))
            }) {
                table.items = [cellItems]
            }
        }
    }
    
    override func loadView() {
        super.loadView()
        
        if isHome {
            title = "首页"
        } else {
            title = path?.components(separatedBy: "/").last ?? ""
        }
        
        if isHome {
            setNavLeftItem("切换账号", image: nil, titleColor: nil, font: nil) { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }
        }
        setNavRightItem("文件全选", image: nil, titleColor: nil, font: nil) { [unowned self] in
            self.showDetail(with: self.getAllFiles())
        }
        
        view.addSubview(table)
        table.snp.makeConstraints({ (make) in
            make.edges.equalToSuperview()
        })
        
        table.cellGeneration = { table, indexPath in
            var cell : UITableViewCell? = nil
            if let item = (table as? KCBlockTableView)?.item(at: indexPath) as? (String,Any,Float) {
                cell = table.dequeueReusableCell(withIdentifier: item.0)
            }
            if cell == nil {
                cell = UITableViewCell.init(style: UITableViewCellStyle.subtitle, reuseIdentifier: "")
            }
            return cell!
        }
        table.cellConfig = { [unowned self] cell, indexPath in
            if let item = self.table.item(at: indexPath) as? (String,[String:Any],Float) {
                let data = self.cellData(with: item.1)
                cell.detailTextLabel?.text = data.0 ? "文件夹" : "文件"
                cell.textLabel?.text = data.1
            }
        }
        
        table.cellHeight = { [unowned self] indexPath in
            if let item = self.table.item(at: indexPath) as? (String,Any,Float) {
                return CGFloat(item.2)
            }
            return 44
        }
        
        table.indexPathSelected = { [unowned self] _, indexPath in
            if let item = self.table.item(at: indexPath) as? (String,[String:Any],Float) {
                let data = self.cellData(with: item.1)
                if data.0 {
                    self.showNext(with: data.2)
                } else {
                    self.showDetail(with: [data.2])
                }
            }
        }
        
        loadData()
    }
    
    func showNext(with path : String) {
        let controller = ListViewController()
        controller.path = path
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    func cellData(with data : [String:Any]) -> (Bool, String, String) {
        let isDir = (data["isdir"] as? Bool) == true
        let path = (data["path"] as? String) ?? ""
        let name = (data["server_filename"] as? String) ?? ""
        return (isDir, name, path)
    }
    
    func getAllFiles() -> [String] {
        return items?.flatMap { (data) -> String? in
            let item = self.cellData(with: data)
            if item.0 == false {
                return item.2
            }
            return nil
        } ?? []
    }
    
    func showDetail(with pathes : [String]) {
        if pathes.count == 0 {
            return
        }
        let loading = showKCLoading()
        Manager.share.getDLink(pathes) { [weak self] (linkes, err) in
            loading.hide()
            if let err = err {
                _=self?.showKCTips(with: err.message, autoHide: (0.5, {}))
            } else {
                if let link = linkes, link.count > 0 {
                    self?.share(link)
                } else {
                    _=self?.showKCTips(with:  "没有数据", autoHide: (0.5, {}))
                }
            }
        }
    }
    
    func loadData() {
        if isHome {
            let loading = showKCLoading()
            Manager.share.loadHome({ [weak self] (items, err) in
                loading.hide()
                if let err = err {
                    _=self?.showKCTips(with: err.message, autoHide: (0.5, {}))
                } else {
                    self?.items = items
                    self?.table.reloadData()
                }
            })
        } else if let path = path {
            let loading = showKCLoading()
            Manager.share.loadList(path, finish: { [weak self] (items, err) in
                loading.hide()
                if let err = err {
                    _=self?.showKCTips(with: err.message, autoHide: (0.5, {}))
                } else {
                    self?.items = items
                    self?.table.reloadData()
                }
            })
        }
    }
    
    func share(_ dlink : [String]) {        
        let activity = UIActivityViewController.init(activityItems: [dlink.joined(separator: ",")], applicationActivities: [])
        present(activity, animated: true, completion: nil)
    }
}
