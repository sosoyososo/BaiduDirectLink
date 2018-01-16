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
                    self.showDetail(with: data.2)
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
    
    func showDetail(with path : String) {
        let loading = showKCLoading()
        Manager.share.getDLink(path) { [weak self] (link, err) in
            loading.hide()
            if let err = err {
                _=self?.showKCTips(with: err.message, autoHide: (0.5, {}))
            } else {
                if let link = link, link.count > 0 {
                    self?.share(link)
                } else {
                    _=self?.showKCTips(with: link ?? "没有数据", autoHide: (0.5, {}))
                }
            }
        }
    }
    
    func cellData(with data : [String:Any]) -> (Bool, String, String) {
        let isDir = (data["isdir"] as? Bool) == true
        let path = (data["path"] as? String) ?? ""
        let name = path.components(separatedBy: "/").last ?? ""
        return (isDir, name, path)
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
    
    func share(_ dlink : String) {
        let activity = UIActivityViewController.init(activityItems: [UIActivityType.airDrop,
                                                                     UIActivityType.copyToPasteboard,
                                                                     UIActivityType.mail,
                                                                     UIActivityType.message], applicationActivities: [])
        present(activity, animated: true, completion: nil)
    }
}
