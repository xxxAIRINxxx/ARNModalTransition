//
//  ARNModalTransitonAnimator.swift
//  ARNModalTransition
//
//  Created by xxxAIRINxxx on 2015/01/13.
//  Copyright (c) 2015 Airin. All rights reserved.
//

import UIKit
import UIKit.UIGestureRecognizerSubclass

public enum ModalTransitonDirection: Int {
    case Bottom
    case Left
    case Right
}

public class ARNModalTransitonAnimator: UIPercentDrivenInteractiveTransition, UIViewControllerAnimatedTransitioning, UIViewControllerTransitioningDelegate, UIGestureRecognizerDelegate {

    public var dragable : Bool {
        get {
            return self.gesture != nil
        }
        set {
            if newValue == true {
                self.gesture = ARNDetectScrollViewEndGestureRecognizer(target: self, action:"handlePan:")
                self.gesture!.delegate = self
                self.gesture!.direction = self.direction
                self.modalController!.view.addGestureRecognizer(self.gesture!)
            } else {
                if let gesture = self.gesture {
                    if let modalController = self.modalController {
                        modalController.view.removeGestureRecognizer(gesture)
                    }
                    gesture.delegate = nil
                }
                self.gesture = nil
            }
        }
    }
    
    public var direction : ModalTransitonDirection {
        get {
            return self.currentDirection
        }
        set {
            self.currentDirection = newValue
            if let gesture = self.gesture {
                gesture.direction = newValue
            }
        }
    }
    
    public var bounces : Bool = true
    public var currentDirection : ModalTransitonDirection = .Bottom
    public var behindViewScale : CGFloat = 0.9
    public var behindViewAlpha : CGFloat = 1.0
    public var transitionDuration : NSTimeInterval = 1.8
    public var usingSpringWithDamping : CGFloat = 0.8
    public var initialSpringVelocity : CGFloat = 0.1
    public var presentedViewStartAlpha : CGFloat = 0.5
    
    var modalController : UIViewController?
    var gesture : ARNDetectScrollViewEndGestureRecognizer?
    var transitionContext : UIViewControllerContextTransitioning?
    var tempTransform : CATransform3D?
    var isDismiss : Bool = false
    var isInteractive : Bool = false
    var panLocationStart : CGFloat = 0.0

    deinit {
        self.dragable = false
        UIDevice.currentDevice().endGeneratingDeviceOrientationNotifications()
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    public init(modalViewController: UIViewController) {
        super.init()
        
        self.modalController = modalViewController
        self.modalController!.modalPresentationStyle = .Custom
        self.dragable = false
        
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
        
        weak var weakSelf = self
        NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationDidChangeStatusBarFrameNotification,
            object: nil,
            queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
                if let weakSelf = weakSelf {
                    if let backViewController = weakSelf.modalController?.presentingViewController {
                        backViewController.view.layer.transform = CATransform3DScale(
                            backViewController.view.layer.transform,
                            weakSelf.behindViewScale,
                            weakSelf.behindViewAlpha,
                            1
                        )
                    }
                }
        }
    }
    
    public func contentScrollView(scrollView: UIScrollView) {
        if let gesture = self.gesture {
            gesture.scrollView = scrollView
        }
    }
    
    func checkVC(transitionContext: UIViewControllerContextTransitioning) -> Bool {
        if let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey) {
            if let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey) {
                return true
            }
        }
        return false
    }
    
    // MARK: UIViewControllerAnimatedTransitioning
    
    public func animationEnded(transitionCompleted: Bool) {
        self.isInteractive = false
        self.transitionContext = nil
    }
    
    // MARK: UIViewControllerAnimatedTransitioning
    
    public func transitionDuration(transitionContext: UIViewControllerContextTransitioning) -> NSTimeInterval {
        return self.transitionDuration
    }
    
    public func animateTransition(transitionContext: UIViewControllerContextTransitioning) {
        if self.isInteractive == true {
            return
        }
        
        if checkVC(transitionContext) == false { return }
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        var containerView = transitionContext.containerView()
        
        if self.isDismiss == false {
            // Present ViewController
            
            containerView.addSubview(toVC.view)
            toVC.view.autoresizingMask = .FlexibleWidth | .FlexibleHeight
            
            var startRect = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds))
            var endRect = CGRectMake(0, 0, CGRectGetWidth(containerView.bounds), CGRectGetHeight(containerView.bounds))
            
            switch self.direction {
            case .Bottom:
                startRect.origin.y = CGRectGetHeight(containerView.frame)
            case .Left:
                startRect.origin.x = -CGRectGetWidth(containerView.frame)
            case .Right:
                startRect.origin.x = CGRectGetWidth(containerView.frame)
            }
            let transformPoint = CGPointApplyAffineTransform(startRect.origin, toVC.view.transform)
            startRect.origin.x = transformPoint.x
            startRect.origin.y = transformPoint.y
            toVC.view.frame = startRect
            
            UIView.animateWithDuration(
                self.transitionDuration(transitionContext),
                delay: 0,
                usingSpringWithDamping: self.usingSpringWithDamping,
                initialSpringVelocity: self.initialSpringVelocity,
                options: .CurveEaseOut,
                animations: { () -> Void in
                    fromVC.view.transform = CGAffineTransformScale(fromVC.view.transform, self.behindViewScale, self.behindViewScale)
                    fromVC.view.alpha = self.behindViewAlpha
                    toVC.view.frame = endRect
                    toVC.view.alpha = 1.0
            }, completion: { (Bool) -> Void in
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        } else {
            // Dismiss ViewController
            
            containerView.bringSubviewToFront(fromVC.view)
            
            toVC.view.alpha = self.behindViewAlpha
            
            var endRect = CGRectMake(0, 0, CGRectGetWidth(fromVC.view.frame), CGRectGetHeight(fromVC.view.frame))
            switch self.direction {
            case .Bottom:
                endRect.origin.y = CGRectGetHeight(fromVC.view.bounds)
            case .Left:
                endRect.origin.x = -CGRectGetWidth(fromVC.view.bounds)
            case .Right:
                endRect.origin.x = CGRectGetWidth(fromVC.view.bounds)
            }
            let transformPoint = CGPointApplyAffineTransform(endRect.origin, fromVC.view.transform)
            endRect.origin.x = transformPoint.x
            endRect.origin.y = transformPoint.y
            
            UIView.animateWithDuration(
                self.transitionDuration(transitionContext),
                delay: 0,
                usingSpringWithDamping: self.usingSpringWithDamping,
                initialSpringVelocity: self.initialSpringVelocity,
                options: .CurveEaseOut,
                animations: { () -> Void in
                    var scaleBack = 1.0 / self.behindViewScale
                    toVC.view.layer.transform = CATransform3DScale(toVC.view.layer.transform, scaleBack, scaleBack, 1)
                    toVC.view.alpha = 1.0
                    fromVC.view.frame = endRect
                },
                completion: { (Bool) -> Void in
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled())
            })
        }
    }
    
    // MARK: UIViewControllerContextTransitioning override
    
    public override func startInteractiveTransition(transitionContext: UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        
        if checkVC(transitionContext) == false { return }
        let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
        let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
        
        self.tempTransform = toVC.view.layer.transform
        
        toVC.view.alpha = self.behindViewAlpha
        transitionContext.containerView().bringSubviewToFront(fromVC.view)
    }
    
    public override func updateInteractiveTransition(percentComplete: CGFloat) {
        if let transitionContext = self.transitionContext {
            var newPercentComplete = percentComplete
            if self.bounces == false && percentComplete < 0.0 {
                newPercentComplete = 0.0
            }
            
            if checkVC(transitionContext) == false { return }
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
            
            let transform = CATransform3DMakeScale(
                1.0 + (((1.0 / self.behindViewScale) - 1.0) * newPercentComplete),
                1.0 + (((1.0 / self.behindViewScale) - 1.0) * newPercentComplete),
                1.0
            )
            toVC.view.layer.transform = CATransform3DConcat(self.tempTransform!, transform)
            toVC.view.alpha = self.behindViewAlpha + ((1.0 - self.behindViewAlpha) * newPercentComplete)
            
            var updateRect = CGRectMake(0, 0, CGRectGetWidth(fromVC.view.frame), CGRectGetHeight(fromVC.view.frame))
            switch self.direction {
            case .Bottom:
                updateRect.origin.y = CGRectGetHeight(fromVC.view.bounds) * newPercentComplete
                if updateRect.origin.y < 0.0 {
                    updateRect.origin.y = 0.0
                }
            case .Left:
                updateRect.origin.x = -CGRectGetWidth(fromVC.view.bounds) * newPercentComplete
                if updateRect.origin.x > 0.0 {
                    updateRect.origin.x = 0.0
                }
            case .Right:
                updateRect.origin.x = CGRectGetWidth(fromVC.view.bounds) * newPercentComplete
                if updateRect.origin.x < 0.0 {
                    updateRect.origin.x = 0.0
                }
            }
            
            if isnan(updateRect.origin.x) || isinf(updateRect.origin.x) {
                updateRect.origin.x = 0
            }
            if isnan(updateRect.origin.y) || isinf(updateRect.origin.y) {
                updateRect.origin.y = 0
            }
            
            let transformPoint = CGPointApplyAffineTransform(updateRect.origin, fromVC.view.transform)
            updateRect.origin.x = transformPoint.x
            updateRect.origin.y = transformPoint.y
            fromVC.view.frame = updateRect
        }
    }
    
    public override func finishInteractiveTransition() {
        if let transitionContext = self.transitionContext {
            if checkVC(transitionContext) == false { return }
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
            
            var endRect = CGRectMake(0, 0, CGRectGetWidth(fromVC.view.frame), CGRectGetHeight(fromVC.view.frame))
            switch self.direction {
            case .Bottom:
                endRect.origin.y = CGRectGetHeight(fromVC.view.bounds)
            case .Left:
                endRect.origin.x = -CGRectGetWidth(fromVC.view.bounds)
            case .Right:
                endRect.origin.x = CGRectGetWidth(fromVC.view.bounds)
            }
            let transformPoint = CGPointApplyAffineTransform(endRect.origin, fromVC.view.transform)
            endRect.origin.x = transformPoint.x
            endRect.origin.y = transformPoint.y
            
            UIView.animateWithDuration(
                self.transitionDuration(transitionContext),
                delay: 0,
                usingSpringWithDamping: self.usingSpringWithDamping,
                initialSpringVelocity: self.initialSpringVelocity,
                options: .CurveEaseOut,
                animations: { () -> Void in
                    var scaleBack = 1.0 / self.behindViewScale
                    toVC.view.layer.transform = CATransform3DScale(self.tempTransform!, scaleBack, scaleBack, 1)
                    toVC.view.alpha = 1.0
                    fromVC.view.frame = endRect
                },
                completion: { (Bool) -> Void in
                    transitionContext.completeTransition(true)
                    self.modalController = nil
            })
        }
    }
    
    public override func cancelInteractiveTransition() {
        if let transitionContext = self.transitionContext {
            
            if checkVC(transitionContext) == false { return }
            let fromVC = transitionContext.viewControllerForKey(UITransitionContextFromViewControllerKey)!
            let toVC = transitionContext.viewControllerForKey(UITransitionContextToViewControllerKey)!
            
            UIView.animateWithDuration(
                0.4,
                delay: 0,
                usingSpringWithDamping: self.usingSpringWithDamping,
                initialSpringVelocity: self.initialSpringVelocity,
                options:.CurveEaseOut,
                animations: { () -> Void in
                    toVC.view.layer.transform = self.tempTransform!
                    toVC.view.alpha = self.behindViewAlpha
                    fromVC.view.frame = CGRectMake(0, 0, CGRectGetWidth(fromVC.view.frame), CGRectGetHeight(fromVC.view.frame))
                }, completion: { (Bool) -> Void in
                    transitionContext.completeTransition(false)
            })
        }
    }
    
    // MARK: UIViewControllerTransitioning Delegate
    
    public func animationControllerForPresentedController(presented: UIViewController, presentingController presenting: UIViewController, sourceController source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isDismiss = false
        return self
    }
    
    public func animationControllerForDismissedController(dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        self.isDismiss = true
        return self
    }
    
    public func interactionControllerForPresentation(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return nil
    }
    
    public func interactionControllerForDismissal(animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if self.isInteractive == true && self.dragable == true {
            self.isDismiss = true
            return self
        }
        return nil
    }
    
    // MARK: Gesture Delegate
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.direction == .Bottom {
            return true
        }
        return false
    }
    
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailByGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if self.direction == .Bottom {
            return true
        }
        return false
    }
    
    // MARK: Gesture
    
    public func handlePan(recognizer: UIPanGestureRecognizer) {
        var location = recognizer.locationInView(self.modalController?.view.window)
        location = CGPointApplyAffineTransform(location, CGAffineTransformInvert(recognizer.view!.transform))
        var velocity = recognizer .velocityInView(self.modalController?.view.window)
        velocity = CGPointApplyAffineTransform(velocity, CGAffineTransformInvert(recognizer.view!.transform))
        
        if recognizer.state == .Began {
            self.isInteractive = true
            if self.direction == .Bottom {
                self.panLocationStart = location.y
            } else {
                self.panLocationStart = location.x
            }
            if let modalController = self.modalController {
                modalController.dismissViewControllerAnimated(true, completion: nil)
            }
        } else if recognizer.state == .Changed {
            if let modalController = self.modalController {
                var animationRatio: CGFloat = 0.0
                switch self.direction {
                case .Bottom:
                    animationRatio = (location.y - self.panLocationStart) / CGRectGetHeight(modalController.view.bounds)
                case .Left:
                    animationRatio = (self.panLocationStart - location.x) / CGRectGetWidth(modalController.view.bounds)
                case .Right:
                    animationRatio = (location.x - self.panLocationStart) / CGRectGetWidth(modalController.view.bounds)
                }
                self.updateInteractiveTransition(animationRatio)
            }
        } else if recognizer.state == .Ended {
            var velocityForSelectedDirection: CGFloat = 0.0
            if self.direction == .Bottom {
                velocityForSelectedDirection = velocity.y
            } else {
                velocityForSelectedDirection = velocity.x
            }
            
            if velocityForSelectedDirection > 100.0 && (self.direction == .Right || self.direction == .Bottom) {
                self.finishInteractiveTransition()
            } else if velocityForSelectedDirection < -100.0 && self.direction == .Left {
                self.finishInteractiveTransition()
            } else {
                self.cancelInteractiveTransition()
            }
            
            self.isInteractive = false
        }
    }
}

// MARK: UIPanGestureRecognizer

class ARNDetectScrollViewEndGestureRecognizer: UIPanGestureRecognizer {
    weak var scrollView : UIScrollView?
    var isFail :Bool?
    var direction : ModalTransitonDirection = .Bottom
    
    override func touchesMoved(touches: NSSet!, withEvent event: UIEvent!) {
        super.touchesMoved(touches, withEvent: event)
        
        if let scrollView = self.scrollView {
            
            if self.state == .Failed { return }
            
            if let isFail = self.isFail {
                if isFail == true {
                    self.state = .Failed
                }
                return
            }
            
            let touch = touches.anyObject() as UITouch
            let nowPoint = touch.locationInView(self.view)
            let prevPoint = touch.previousLocationInView(self.view)
            let topVerticalOffset = -scrollView.contentInset.top
            
            if self.direction == .Bottom {
                if nowPoint.y > prevPoint.y && scrollView.contentOffset.y <= topVerticalOffset {
                    self.isFail = false
                } else if scrollView.contentOffset.y >= topVerticalOffset {
                    self.isFail = true
                } else {
                    self.isFail = false
                }
            }
        }
    }
    
    override func reset() {
        super.reset()
        self.isFail = nil
    }
}
