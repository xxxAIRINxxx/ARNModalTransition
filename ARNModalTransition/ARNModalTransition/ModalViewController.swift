//
//  ModalViewController.swift
//  ARNModalTransition
//
//  Created by xxxAIRINxxx on 2015/01/17.
//  Copyright (c) 2015 xxxAIRINxxx. All rights reserved.
//

import UIKit

class ModalViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var tapCloseButtonHandler : (ModalViewController -> Void)?
    var tableView : UITableView = UITableView(frame: CGRectZero, style: .Plain)
    let cellIdentifier : String = "Cell"
    
    deinit {
        print("deinit ModalViewController")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.frame = self.view.bounds
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.registerClass(UITableViewCell.classForCoder(), forCellReuseIdentifier: self.cellIdentifier)
        self.view.addSubview(self.tableView)
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: #selector(ModalViewController.tapCloseButton))
        self.navigationItem.rightBarButtonItem?.tintColor = UIColor.whiteColor()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("ModalViewController viewWillAppear")
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        print("ModalViewController viewWillDisappear")
    }
    
    func tapCloseButton() {
        self.tapCloseButtonHandler?(self)
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.cellIdentifier, forIndexPath: indexPath) 
        
        return cell
    }
    
    // MARK: UITableViewDelegate
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
}
