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
    var animator : ARNTransitionAnimator!
    
    @IBAction func tapButton(sender: UIButton) {
        var storyboard = UIStoryboard(name: "Main", bundle: NSBundle.mainBundle())
        var modalVC: ModalViewController = storyboard.instantiateViewControllerWithIdentifier("ModalViewController") as! ModalViewController
        var navController = UINavigationController(rootViewController: modalVC)
        
        self.animator = ARNTransitionAnimator(operationType: .Present, fromVC: self, toVC: navController)
        if self.dragable {
            self.animator.interactiveType = .Dismiss
        }
      
        let behindViewAlpha: CGFloat = 0.5
        let behindViewScale: CGFloat = 0.9
        
        let title = sender.titleForState(.Normal)
        if title == "Left" {
            self.animator!.direction = .Left
        } else if title == "Right" {
            self.animator!.direction = .Right
        } else  {
            self.animator!.direction = .Bottom
        }
        
        // Present
        
        self.animator.presentationBeforeHandler = { [weak self, weak navController] (containerView: UIView, transitionContext: UIViewControllerContextTransitioning) in
            containerView.addSubview(navController!.view)
            
            navController!.view.layoutIfNeeded()

            var startRect = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds))
            var endRect = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds))
            
            switch self!.animator.direction {
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
            
            self!.animator.presentationAnimationHandler = { (containerView: UIView, percentComplete: CGFloat) in
                self!.view.transform = CGAffineTransformScale(self!.view.transform, behindViewScale, behindViewScale)
                self!.view.alpha = behindViewAlpha
                navController!.view.frame = endRect
            }
        }
        
        // Dismiss
        
        self.animator.dismissalBeforeHandler = { [weak self, weak navController] (containerView: UIView, transitionContext: UIViewControllerContextTransitioning) in
            
            containerView.addSubview(self!.view)
            containerView.bringSubviewToFront(navController!.view)
            
            navController!.view.layoutIfNeeded()
            
            let startRect = navController!.view.frame
            
            let tempTransform = self!.view.transform
            
            self!.animator.dismissalCancelAnimationHandler = { (containerView: UIView) in
                self!.view.transform = tempTransform
                self!.view.alpha = behindViewAlpha
                navController!.view.frame = startRect
            }
            
            self!.animator.dismissalAnimationHandler = { (containerView: UIView, percentComplete: CGFloat) in
                let scale = behindViewScale + ((1.0 - behindViewScale) * percentComplete)
                self!.view.transform = CGAffineTransformMakeScale(scale, scale)
                self!.view.alpha = behindViewAlpha + ((1.0 - behindViewAlpha) * percentComplete)
                
                var updateRect = CGRectMake(0, 0, CGRectGetWidth(navController!.view.frame), CGRectGetHeight(navController!.view.frame))
                switch self!.animator.direction {
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
        }
        
        self.animator.dismissalCompletionHandler = { [weak self] (containerView: UIView, completeTransition: Bool) in
            self!.view.alpha = 1.0
            self!.view.transform = CGAffineTransformIdentity
        }
        
        navController.transitioningDelegate = self.animator
        self.presentViewController(navController, animated: true, completion: nil)
    }
    
    @IBAction func dragableChanged(sender: UISwitch) {
        dragable = sender.on
    }
}

