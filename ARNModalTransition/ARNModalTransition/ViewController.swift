//
//  ViewController.swift
//  ARNModalTransition
//
//  Created by xxxAIRINxxx on 2015/01/11.
//  Copyright (c) 2015 xxxAIRINxxx. All rights reserved.
//

import UIKit
import ARNTransitionAnimator

var animator : ARNTransitionAnimator!

class ViewController: UIViewController {
    
    var dragable : Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: Selector("handleDidChangeStatusBarFrameNotification"),
            name: UIApplicationDidChangeStatusBarFrameNotification,
            object: nil
        )
    }
    
    func handleDidChangeStatusBarFrameNotification() {
        self.navigationController!.view.frame = UIScreen.mainScreen().applicationFrame
        if let _topLayoutGuide = self.navigationController?.topLayoutGuide {
            self.navigationController!.view.frame.origin.y -= _topLayoutGuide.length
            self.navigationController!.view.frame.size.height += _topLayoutGuide.length
        }
    }
    
    @IBAction func tapButton(sender: UIButton) {
        let storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        let modalVC: ModalViewController = storyboard.instantiateViewControllerWithIdentifier("ModalViewController") as! ModalViewController
        let navController = UINavigationController(rootViewController: modalVC)
        
        animator = ARNTransitionAnimator(operationType: .Present, fromVC: self.navigationController!, toVC: navController)
        animator.usingSpringWithDamping = 0.8
        
        if self.dragable {
            animator.interactiveType = .Dismiss
        }
      
        let behindViewAlpha: CGFloat = 0.5
        let behindViewScale: CGFloat = 0.9
        
        let title = sender.titleForState(.Normal)
        if title == "Left" {
            animator!.direction = .Left
        } else if title == "Right" {
            animator!.direction = .Right
        } else  {
            animator!.direction = .Bottom
        }
        
        // Present
        
        animator.presentationBeforeHandler = { [weak self, weak navController] (containerView: UIView, transitionContext: UIViewControllerContextTransitioning) in
            let fcomView = self!.navigationController!.view
            
            containerView.addSubview(navController!.view)
            
            navController!.view.layoutIfNeeded()

            var startRect = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds))
            let endRect = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds))
            
            switch animator.direction {
            case .Bottom:
                startRect.origin.y = CGRectGetHeight(containerView.frame)
            case .Left:
                startRect.origin.x = -CGRectGetWidth(containerView.frame)
            case .Right:
                startRect.origin.x = CGRectGetWidth(containerView.frame)
            case .Top:
                break
            }
            let transformPoint = CGPointApplyAffineTransform(startRect.origin, navController!.view.transform)
            startRect.origin.x = transformPoint.x
            startRect.origin.y = transformPoint.y
            navController!.view.frame = startRect
            
            animator.presentationAnimationHandler = { (containerView: UIView, percentComplete: CGFloat) in
                fcomView.transform = CGAffineTransformScale(fcomView.transform, behindViewScale, behindViewScale)
                fcomView.alpha = behindViewAlpha
                navController!.view.frame = endRect
            }
            
            animator.presentationCompletionHandler = { (containerView: UIView, completeTransition: Bool) in
                fcomView.alpha = 1.0
                fcomView.transform = CGAffineTransformIdentity
            }
        }
        
        // Dismiss
        
        animator.dismissalBeforeHandler = { [weak self, weak navController] (containerView: UIView, transitionContext: UIViewControllerContextTransitioning) in
            let fcomView = self!.navigationController!.view
            
            containerView.addSubview(fcomView)
            containerView.bringSubviewToFront(navController!.view)
            
            navController!.view.layoutIfNeeded()
            
            let startRect = navController!.view.frame
            
            fcomView.transform = CGAffineTransformMakeScale(behindViewScale, behindViewScale)
            
            animator.dismissalCancelAnimationHandler = { (containerView: UIView) in
                fcomView.transform = CGAffineTransformMakeScale(behindViewScale, behindViewScale)
                fcomView.alpha = behindViewAlpha
                navController!.view.frame = startRect
            }
            
            animator.dismissalAnimationHandler = { (containerView: UIView, percentComplete: CGFloat) in
                let scale = behindViewScale + ((1.0 - behindViewScale) * percentComplete)
                fcomView.transform = CGAffineTransformMakeScale(scale, scale)
                fcomView.alpha = behindViewAlpha + ((1.0 - behindViewAlpha) * percentComplete)
                
                var updateRect = CGRectMake(0, 0, CGRectGetWidth(navController!.view.frame), CGRectGetHeight(navController!.view.frame))
                switch animator.direction {
                case .Bottom:
                    updateRect.origin.y = CGRectGetHeight(navController!.view.bounds) * percentComplete
                    if updateRect.origin.y < 0.0 {
                        updateRect.origin.y = 0.0
                    }
                case .Left:
                    updateRect.origin.x = -CGRectGetWidth(navController!.view.bounds) * percentComplete
                    if updateRect.origin.x > 0.0 {
                        updateRect.origin.x = 0.0
                    }
                case .Right:
                    updateRect.origin.x = CGRectGetWidth(navController!.view.bounds) * percentComplete
                    if updateRect.origin.x < 0.0 {
                        updateRect.origin.x = 0.0
                    }
                case .Top:
                    break
                }
                
                if isnan(updateRect.origin.x) || isinf(updateRect.origin.x) {
                    updateRect.origin.x = 0
                }
                if isnan(updateRect.origin.y) || isinf(updateRect.origin.y) {
                    updateRect.origin.y = 0
                }
                
                let transformPoint = CGPointApplyAffineTransform(updateRect.origin, navController!.view.transform)
                updateRect.origin.x = transformPoint.x
                updateRect.origin.y = transformPoint.y
                navController!.view.frame = updateRect
            }
            
            animator.dismissalCompletionHandler = { (containerView: UIView, completeTransition: Bool) in
                fcomView.alpha = 1.0
                fcomView.transform = CGAffineTransformIdentity
                if completeTransition {
                    UIApplication.sharedApplication().keyWindow!.addSubview(fcomView)
                }
            }
        }
        
        navController.transitioningDelegate = animator
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    @IBAction func dragableChanged(sender: UISwitch) {
        dragable = sender.on
    }
}

