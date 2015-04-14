//
//  ViewController.swift
//  ARNModalTransition
//
//  Created by xxxAIRINxxx on 2015/01/11.
//  Copyright (c) 2015 Airin. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    var dragable : Bool = true
    var animator : ARNModalTransitonAnimator?

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func tapButton(sender: UIButton) {
        var storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        var modalVC: ModalViewController = storyboard.instantiateViewControllerWithIdentifier("ModalViewController") as! ModalViewController
        var navController = UINavigationController(rootViewController: modalVC)
        
        self.animator = ARNModalTransitonAnimator(modalViewController: navController)
        self.animator!.behindViewAlpha = 0.5
        self.animator!.behindViewScale = 0.9
        self.animator!.transitionDuration = 0.7
        self.animator!.dragable = dragable
        self.animator!.contentScrollView(modalVC.tableView)
        
        let title = sender.titleForState(.Normal)
        if title == "Left" {
            self.animator!.direction = .Left
        } else if title == "Right" {
            self.animator!.direction = .Right
        } else  {
            self.animator!.direction = .Bottom
        }
        
        navController.transitioningDelegate = self.animator!
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    @IBAction func dragableChanged(sender: UISwitch) {
        dragable = sender.on
    }
}

