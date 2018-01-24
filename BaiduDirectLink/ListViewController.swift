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

let systemBlueColor = UIColor.init(red: 80/255.0, green: 150/255.0, blue: 1, alpha: 1)

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
    
    private var tableEditing : Bool = false {
        didSet {
            self.table.isEditing = tableEditing
            if tableEditing {
                table.snp.updateConstraints({ (make) in
                    make.bottom.equalToSuperview().inset(50)
                })
            } else {
                table.snp.updateConstraints({ (make) in
                    make.bottom.equalToSuperview()
                })
            }
            UIView.animate(withDuration: 0.35) {
                self.view.layoutIfNeeded()
            }
            
            if tableEditing {
                updateEditToolBar()
            }
        }
    }
    
    private var editToolBar = UIView()
    
    override func loadView() {
        super.loadView()
        
        if isHome {
            title = "首页"
        } else {
            title = path?.components(separatedBy: "/").last ?? ""
        }
        
        if isHome {
            setNavLeftItem("切换账号", image: nil, titleColor: systemBlueColor, font: nil) { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            }
        }
        
        setNavRightItem("选择", image: nil, titleColor: systemBlueColor, font: nil) { [unowned self] in
            self.tableEditing = self.tableEditing == false
            
            guard let items = self.navigationItem.rightBarButtonItems else {
                return
            }
            guard items.count > 0 else {
                return
            }
            guard let btn = items[0].customView as? UIButton else {
                return
            }
            btn.setTitle(self.tableEditing == true ? "完成" : "选择", for: .normal)
        }
        if let rightItem1 = navigationItem.rightBarButtonItem {
            setNavRightItem("下载所有文件", image: nil, titleColor: systemBlueColor, font: nil) { [unowned self] in
                self.showDetail(with: self.getAllFiles())
                self.tableEditing = false
            }
            if let rightItem2 = navigationItem.rightBarButtonItem {
                navigationItem.rightBarButtonItems = [rightItem1, rightItem2]
            }
        }
        view.addSubview(table)
        table.snp.makeConstraints({ (make) in
            make.left.right.top.equalToSuperview()
            make.bottom.equalToSuperview()
        })
        
        view.addSubview(editToolBar)
        editToolBar.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.top.equalTo(self.table.snp.bottom)
            make.left.right.equalToSuperview()
        }
        editToolBar.backgroundColor = .white
        
        _=editToolBar.addSeparator(UIColor.lightGray, separatorType: UIView.KCUIViewSeparatorType.top)
        let btn1 = UIButton.init(type: .system)
        btn1.setTitle("全选", for: .normal)
        editToolBar.addSubview(btn1)
        btn1.snp.makeConstraints { (make) in
            make.left.top.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
        }
        _=btn1.rx.tap.subscribe(onNext: { [unowned self] () in
            if self.isAllSelected() {
                self.table.indexPathsForVisibleRows?.forEach({ [unowned self] (indexPath) in
                    self.table.deselectRow(at: indexPath, animated: false)
                })
            } else {
                guard let count = self.items?.count else {
                    return
                }
                for i in 0..<count {
                    self.table.selectRow(at: IndexPath.init(row: i, section: 0), animated: false, scrollPosition: UITableViewScrollPosition.none)
                }
            }
            self.updateEditToolBar()
        })
        
        let btn2 = UIButton.init(type: .system)
        btn2.setTitle("下载", for: .normal)
        editToolBar.addSubview(btn2)
        btn2.snp.makeConstraints { (make) in
            make.right.top.bottom.equalToSuperview()
            make.width.equalToSuperview().dividedBy(2)
        }
        _=btn2.rx.tap.subscribe(onNext: { [unowned self] () in
            self.getSelectedPathes()
        })
        
        table.canEditIndexPath = { _ in
            return true
        }
        
        table.editStyleForIndexPath = { indexPath in
            if let item = self.table.item(at: indexPath) as? (String,[String:Any],Float) {
                let data = self.cellData(with: item.1)
                if data.0  {
                    return UITableViewCellEditingStyle.none
                }
            }
            return UITableViewCellEditingStyle.init(rawValue: UITableViewCellEditingStyle.delete.rawValue | UITableViewCellEditingStyle.insert.rawValue)!
        }
        
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
            if self.tableEditing {
                self.updateEditToolBar()
            } else if let item = self.table.item(at: indexPath) as? (String,[String:Any],Float) {
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
    
    func isAllSelected() -> Bool {
        guard let count = table.indexPathsForSelectedRows?.count else {
            return false
        }
        guard let itemCount = self.items?.count else {
            return false
        }
        return count >= itemCount
    }
    
    func updateEditToolBar() {
        let count = self.editToolBar.subviews.count
        if count > 1 {
            if let btn = self.editToolBar.subviews[1] as? UIButton {
                if self.isAllSelected() {
                    btn.setTitle("全不选", for: .normal)
                } else {
                    btn.setTitle("全选", for: .normal)
                }
            }
        }
        if count > 2 {
            if let btn = self.editToolBar.subviews[2] as? UIButton {
                btn.setTitle("下载(\(self.table.indexPathsForSelectedRows?.count ?? 0))", for: .normal)
            }
        }
    }
    
    func getSelectedPathes() {
        if let indexPathes = table.indexPathsForSelectedRows {
            var pathes : [String] = []
            indexPathes.forEach({ (indexPath) in
                if let item = self.table.item(at: indexPath) as? (String,[String:Any],Float) {
                    let data = self.cellData(with: item.1)
                    if data.0 == false {
                        pathes.append(data.2)
                    }
                }
            })
            showDetail(with: pathes)
        }
        self.tableEditing = false
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
        let urls = dlink.flatMap { (link) -> URL? in
            return URL.init(string: link)
        }
        let activity = UIActivityViewController.init(activityItems: urls, applicationActivities: [])
        present(activity, animated: true, completion: nil)
    }
}
