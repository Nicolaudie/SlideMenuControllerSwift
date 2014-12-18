//
//  SlideMenuController.swift
//
//  Created by Yuji Hato on 12/3/14.
//

import Foundation
import UIKit

enum SlideAction {
    case Open,
    Close
}

enum TrackAction {
    case TapOpen
    case TapClose
    case FlickOpen
    case FlickClose
}


struct PanInfo {
    var action: SlideAction
    var shouldBounce: Bool
    var velocity: CGFloat
}

class SlideMenuOption {
    
    let leftViewOverlapWidth: CGFloat = 60.0
    let leftBezelWidth: CGFloat = 16.0
    let contentViewScale: CGFloat = 0.96
    let contentViewOpacity: CGFloat = 0.5
    let shadowOpacity: CGFloat = 0.0
    let shadowRadius: CGFloat = 0.0
    let shadowOffset: CGSize = CGSizeMake(0,0)
    let panFromBezel: Bool = true
    let animationDuration: CGFloat = 0.4
    let rightViewOverlapWidth: CGFloat = 60.0
    let rightBezelWidth: CGFloat = 16.0
    let rightPanFromBezel: Bool = true
    let hideStatusBar: Bool = true
    
    init() {
        
    }
}


class SlideMenuController: UIViewController, UIGestureRecognizerDelegate {

    var opacityView = UIView()
    var mainContainerView = UIView()
    var leftContainerView = UIView()
    var rightContainerView =  UIView()
    var mainViewController: UIViewController?
    var leftViewController: UIViewController?
    var leftPanGesture: UIPanGestureRecognizer?
    var leftTapGetsture: UITapGestureRecognizer?
    var rightViewController: UIViewController?
    var rightPanGesture: UIPanGestureRecognizer?
    var rightTapGesture: UITapGestureRecognizer?
    var options = SlideMenuOption()

    
    override init() {
        super.init()
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    convenience init(mainViewController: UIViewController, leftMenuViewController: UIViewController) {
        self.init()
        self.mainViewController = mainViewController
        self.leftViewController = leftMenuViewController
        self.initView()
    }
    
    convenience init(mainViewController: UIViewController, rightMenuViewController: UIViewController) {
        self.init()
        self.mainViewController = mainViewController
        self.rightViewController = rightMenuViewController
        self.initView()
    }
    
    convenience init(mainViewController: UIViewController, leftMenuViewController: UIViewController, rightMenuViewController: UIViewController) {
        self.init()
        self.mainViewController = mainViewController
        self.leftViewController = leftMenuViewController
        self.rightViewController = rightMenuViewController
        self.initView()
    }
    
    deinit { }
    
    func initView() {
        mainContainerView = UIView(frame: self.view.bounds)
        mainContainerView.backgroundColor = UIColor.clearColor()
        mainContainerView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        self.view.insertSubview(mainContainerView, atIndex: 0)

        var opacityframe: CGRect = self.view.bounds
        var opacityOffset: CGFloat = 0
        opacityframe.origin.y = opacityframe.origin.y + opacityOffset
        opacityframe.size.height = opacityframe.size.height - opacityOffset
        opacityView = UIView(frame: opacityframe)
        opacityView.backgroundColor = UIColor.blackColor()
        opacityView.autoresizingMask = UIViewAutoresizing.FlexibleHeight | UIViewAutoresizing.FlexibleWidth
        opacityView.layer.opacity = 0.0
        self.view.insertSubview(opacityView, atIndex: 1)
        
        var leftFrame: CGRect = self.view.bounds
        leftFrame.size.width = CGRectGetWidth(self.view.bounds) - self.options.leftViewOverlapWidth
        //leftFrame.size.width = 320.0 - self.options.leftViewOverlapWidth
        leftFrame.origin.x = self.minLeftOrigin();
        var leftOffset: CGFloat = 0
        leftFrame.origin.y = leftFrame.origin.y + leftOffset
        leftFrame.size.height = leftFrame.size.height - leftOffset
        leftContainerView = UIView(frame: leftFrame)
        leftContainerView.backgroundColor = UIColor.clearColor()
        leftContainerView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        self.view.insertSubview(leftContainerView, atIndex: 2)
        
        var rightFrame: CGRect = self.view.bounds
        rightFrame.size.width = CGRectGetWidth(self.view.bounds) - self.options.rightViewOverlapWidth
        //rightFrame.size.width = 320.0 - self.options.rightViewOverlapWidth
        rightFrame.origin.x = self.minRightOrigin()
        var rightOffset: CGFloat = 0
        rightFrame.origin.y = rightFrame.origin.y + rightOffset;
        rightFrame.size.height = rightFrame.size.height - rightOffset
        rightContainerView = UIView(frame: rightFrame)
        rightContainerView.backgroundColor = UIColor.clearColor()
        rightContainerView.autoresizingMask = UIViewAutoresizing.FlexibleHeight
        self.view.insertSubview(rightContainerView, atIndex: 3)
        
        
        self.addGestures()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.edgesForExtendedLayout = UIRectEdge.None
    }
    
    override func viewWillLayoutSubviews() {
        // topLayoutGuideの値が確定するこのタイミングで各種ViewControllerをセットする
        self.setUpViewController(self.mainContainerView, targetViewController: self.mainViewController)
        self.setUpViewController(self.leftContainerView, targetViewController: self.leftViewController)
        self.setUpViewController(self.rightContainerView, targetViewController: self.rightViewController)
    }
    
    // Notification func for view close
    func handleWillEnterForegroundNotification(notif: NSNotification) {
        self.closeLeft()
        self.closeRight()
    }
    
    override func openLeft() {
        self.setOpenWindowLevel()
        
        //leftViewControllerのviewWillAppearを呼ぶため
        self.leftViewController?.beginAppearanceTransition(self.isLeftHidden(), animated: true)
        self.openLeftWithVelocity(0.0)
        
        self.track(TrackAction.TapOpen)
    }
    
    override func openRight() {
        self.setOpenWindowLevel()
        
        //menuViewControllerのviewWillAppearを呼ぶため
        self.rightViewController?.beginAppearanceTransition(self.isRightHidden(), animated: true)
        self.openRightWithVelocity(0.0)
    }
    
    override func closeLeft() {
        self.closeLeftWithVelocity(0.0)
        self.setCloseWindowLebel()
    }
    
    override func closeRight() {
        self.closeRightWithVelocity(0.0)
        self.setCloseWindowLebel()
    }
    
    
    func addGestures() {
    
        if (self.leftViewController != nil) {
            if self.leftPanGesture == nil {
                self.leftPanGesture = UIPanGestureRecognizer(target: self, action: "handleLeftPanGesture:")
                self.leftPanGesture!.delegate = self
                self.view.addGestureRecognizer(self.leftPanGesture!)
            }
            
            if self.leftTapGetsture == nil {
                self.leftTapGetsture = UITapGestureRecognizer(target: self, action: "toggleLeft")
                self.leftTapGetsture!.delegate = self
                self.view.addGestureRecognizer(self.leftTapGetsture!)
            }
        }
        
        if (self.rightViewController != nil) {
            if self.rightPanGesture == nil {
                self.rightPanGesture = UIPanGestureRecognizer(target: self, action: "handleRightPanGesture:")
                self.rightPanGesture!.delegate = self
                self.view.addGestureRecognizer(self.rightPanGesture!)
            }
            
            if self.rightTapGesture == nil {
                self.rightTapGesture = UITapGestureRecognizer(target: self, action: "toggleRight")
                self.rightTapGesture!.delegate = self
                self.view.addGestureRecognizer(self.rightTapGesture!)
            }
        }

    }
    
    func removeGestures() {
        
        if self.leftPanGesture != nil {
            self.view.removeGestureRecognizer(self.leftPanGesture!)
            self.leftPanGesture = nil
        }
        
        if self.rightPanGesture != nil {
            self.view.removeGestureRecognizer(self.rightPanGesture!)
            self.rightPanGesture = nil
        }
    
        if self.leftTapGetsture != nil {
            self.view.removeGestureRecognizer(self.leftTapGetsture!)
            self.leftTapGetsture = nil
        }
    
        if self.rightTapGesture != nil {
            self.view.removeGestureRecognizer(self.rightTapGesture!)
            self.rightTapGesture = nil
        }
    }
    
    func isTagetViewController() -> Bool {
        // Function to determine the target ViewController
        // Please to override it if necessary
        return true
    }
    
    func track(trackAction: TrackAction) {
        // function is for tracking
        // Please to override it if necessary
    }
    
    func handleLeftPanGesture(panGesture: UIPanGestureRecognizer) {
        if let url = NSURL(fileURLWithPath: "xxx") {
            if NSFileManager.defaultManager().fileExistsAtPath(url.path!) {
                
            }
        }
        
        if !self.isTagetViewController() {
            return
        }
        
        if self.isRightOpen() {
            return
        }
        
        var menuFrameAtStartOfPan: CGRect = self.leftContainerView.frame
        var startPointOfPan: CGPoint = panGesture.locationInView(self.view)
        var menuWasOpenAtStartOfPan: Bool = self.isLeftOpen()
        var menuWasHiddenAtStartOfPan: Bool = self.isLeftHidden()

        switch panGesture.state {
            case UIGestureRecognizerState.Began:
                
                menuFrameAtStartOfPan = self.leftContainerView.frame
                startPointOfPan = panGesture.locationInView(self.view)
                menuWasOpenAtStartOfPan = self.isLeftOpen()
                menuWasHiddenAtStartOfPan = self.isLeftHidden()
                self.leftViewController?.beginAppearanceTransition(menuWasHiddenAtStartOfPan, animated: true)
                self.addShadowToView(self.leftContainerView)
                self.setOpenWindowLevel()
            case UIGestureRecognizerState.Changed:
                
                var translation: CGPoint = panGesture.translationInView(panGesture.view!)
                self.leftContainerView.frame = self.applyLeftTranslation(translation, toFrame: menuFrameAtStartOfPan)
                self.applyLeftOpacity()
                self.applyLeftContentViewScale()
            case UIGestureRecognizerState.Ended:
                
                self.leftViewController?.beginAppearanceTransition(!menuWasHiddenAtStartOfPan, animated: true)
                var velocity:CGPoint = panGesture.velocityInView(panGesture.view)
                var panInfo: PanInfo = self.panLeftResultInfoForVelocity(velocity)
                
                if panInfo.action == SlideAction.Open {
                    self.openLeftWithVelocity(panInfo.velocity)
                    self.track(TrackAction.FlickOpen)
                    
                } else {
                    self.closeLeftWithVelocity(panInfo.velocity)
                    self.setCloseWindowLebel()
                    
                    self.track(TrackAction.FlickClose)

                }
            break
        default:
            break
        }
        
    }
    
    func handleRightPanGesture(panGesture: UIPanGestureRecognizer) {
        
        if !self.isTagetViewController() {
            return
        }
        
        if self.isLeftOpen() {
            return
        }
        
        var rightViewFrameAtStartOfPan: CGRect = self.rightContainerView.frame
        var startPointOfPan: CGPoint = panGesture.locationInView(self.view)
        var rightViewWasOpenAtStartOfPan: Bool =  self.isRightOpen()
        var rightViewWasHiddenAtStartOfPan: Bool = self.isRightHidden()
        
        switch panGesture.state {
        case UIGestureRecognizerState.Began:
            
            rightViewFrameAtStartOfPan = self.rightContainerView.frame
            startPointOfPan = panGesture.locationInView(self.view)
            rightViewWasOpenAtStartOfPan = self.isRightOpen()
            rightViewWasHiddenAtStartOfPan = self.isRightHidden()
            self.rightViewController?.beginAppearanceTransition(rightViewWasHiddenAtStartOfPan, animated: true)
            self.addShadowToView(self.rightContainerView)
            self.setOpenWindowLevel()
        case UIGestureRecognizerState.Changed:
            
            var translation: CGPoint = panGesture.translationInView(panGesture.view!)
            self.rightContainerView.frame = self.applyRightTranslation(translation, toFrame: rightViewFrameAtStartOfPan)
            self.applyRightOpacity()
            self.applyRightContentViewScale()
            
        case UIGestureRecognizerState.Ended:
            
            self.rightViewController?.beginAppearanceTransition(!rightViewWasHiddenAtStartOfPan, animated: true)
            var velocity: CGPoint = panGesture.velocityInView(panGesture.view)
            var panInfo: PanInfo = self.panRightResultInfoForVelocity(velocity)
            
            if panInfo.action == SlideAction.Open {
                self.openRightWithVelocity(panInfo.velocity)
            } else {
                self.closeRightWithVelocity(panInfo.velocity)
                self.setCloseWindowLebel()
            }
        default:
            break
        }
    }
    
    func openLeftWithVelocity(velocity: CGFloat) {
        var xOrigin: CGFloat = self.leftContainerView.frame.origin.x
        var finalXOrigin: CGFloat = 0.0
        
        var frame = self.leftContainerView.frame;
        frame.origin.x = finalXOrigin;
        
        var duration: NSTimeInterval = Double(self.options.animationDuration)
        if velocity != 0.0 {
            duration = Double(fabs(xOrigin - finalXOrigin) / velocity)
            duration = Double(fmax(0.1, fmin(1.0, duration)))
        }
        
        self.addShadowToView(self.leftContainerView)
        
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.leftContainerView.frame = frame
            self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
            self.mainContainerView.transform = CGAffineTransformMakeScale(self.options.contentViewScale, self.options.contentViewScale)
        }) { (Bool) -> Void in
            self.disableContentInteraction()
        }
    }
    
    func openRightWithVelocity(velocity: CGFloat) {
        var xOrigin: CGFloat = self.rightContainerView.frame.origin.x
    
        //	CGFloat finalXOrigin = self.options.rightViewOverlapWidth;
        var finalXOrigin: CGFloat = CGRectGetWidth(self.view.bounds) - self.rightContainerView.frame.size.width
        
        var frame = self.rightContainerView.frame
        frame.origin.x = finalXOrigin
    
        var duration: NSTimeInterval = Double(self.options.animationDuration)
        if velocity != 0.0 {
            duration = Double(fabs(xOrigin - CGRectGetWidth(self.view.bounds)) / velocity)
            duration = Double(fmax(0.1, fmin(1.0, duration)))
        }
    
        self.addShadowToView(self.rightContainerView)
    
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.rightContainerView.frame = frame
            self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
            self.mainContainerView.transform = CGAffineTransformMakeScale(self.options.contentViewScale, self.options.contentViewScale)
            }) { (Bool) -> Void in
                self.disableContentInteraction()
        }
    }
    
    func closeLeftWithVelocity(velocity: CGFloat) {
        
        var xOrigin: CGFloat = self.leftContainerView.frame.origin.x
        var finalXOrigin: CGFloat = self.leftMinOrigin()
        
        var frame: CGRect = self.leftContainerView.frame;
        frame.origin.x = finalXOrigin
    
        var duration: NSTimeInterval = Double(self.options.animationDuration)
        if velocity != 0.0 {
            duration = Double(fabs(xOrigin - finalXOrigin) / velocity)
            duration = Double(fmax(0.1, fmin(1.0, duration)))
        }
        
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.leftContainerView.frame = frame
            self.opacityView.layer.opacity = 0.0
            self.mainContainerView.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }) { (Bool) -> Void in
                self.removeShadow(self.leftContainerView)
                self.enableContentInteraction()
        }
    }
    
    
    func closeRightWithVelocity(velocity: CGFloat) {
    
        var xOrigin: CGFloat = self.rightContainerView.frame.origin.x
        var finalXOrigin: CGFloat = CGRectGetWidth(self.view.bounds)
    
        var frame: CGRect = self.rightContainerView.frame
        frame.origin.x = finalXOrigin
    
        var duration: NSTimeInterval = Double(self.options.animationDuration)
        if velocity != 0.0 {
            duration = Double(fabs(xOrigin - CGRectGetWidth(self.view.bounds)) / velocity)
            duration = Double(fmax(0.1, fmin(1.0, duration)))
        }
    
        UIView.animateWithDuration(duration, delay: 0.0, options: UIViewAnimationOptions.CurveEaseInOut, animations: { () -> Void in
            self.rightContainerView.frame = frame
            self.opacityView.layer.opacity = 0.0
            self.mainContainerView.transform = CGAffineTransformMakeScale(1.0, 1.0)
            }) { (Bool) -> Void in
                self.removeShadow(self.rightContainerView)
                self.enableContentInteraction()
        }
    }
    
    
    override func toggleLeft() {
        if self.isLeftOpen() {
            self.closeLeft()
            self.setCloseWindowLebel()
            // closeMenuはメニュータップ時にも呼ばれるため、closeタップのトラッキングはここに入れる
            
            self.track(TrackAction.TapClose)
        } else {
            self.openLeft()
        }
    }
    
    func isLeftOpen() -> Bool {
        return self.leftContainerView.frame.origin.x == 0.0
    }
    
    func isLeftHidden() -> Bool {
        return self.leftContainerView.frame.origin.x <= self.leftMinOrigin()
    }
    
    override func toggleRight() {
        if self.isRightOpen() {
            self.closeRight()
            self.setCloseWindowLebel()
        } else {
            self.openRight()
        }
    }
    
    func isRightOpen() -> Bool {
        return self.rightContainerView.frame.origin.x == CGRectGetWidth(self.view.bounds) - self.rightContainerView.frame.size.width
    }
    
    func isRightHidden() -> Bool {
        return self.rightContainerView.frame.origin.x >= CGRectGetWidth(self.view.bounds)
    }
    
    func changeMainViewController(mainViewController: UIViewController,  close: Bool) {
    
        self.mainViewController = mainViewController
        if (close) {
            self.closeLeft()
            self.closeRight()
        }
    }
    
    func changeLeftViewController(leftViewController: UIViewController, closeLeft:Bool) {
        self.leftViewController = leftViewController
        if (closeLeft) {
            self.closeLeft()
        }
    }
    
    func changeRightViewController(rightViewController: UIViewController, closeRight:Bool) {
        self.rightViewController = rightViewController;
        if (closeRight) {
            self.closeRight()
        }
    }
    
    private func leftMinOrigin() -> CGFloat {
        //return  -320.0 + self.options.leftViewOverlapWidth
        return -(CGRectGetWidth(self.view.bounds) - self.options.leftViewOverlapWidth)
    }
    
    private func rightMinOrigin() -> CGFloat {
        return CGRectGetWidth(self.view.bounds)
    }
    
    
    private func panLeftResultInfoForVelocity(velocity: CGPoint) -> PanInfo {
        
        var thresholdVelocity: CGFloat = 450.0
        var pointOfNoReturn: CGFloat = CGFloat(floor(self.leftMinOrigin() / 2.0))
        var leftOrigin: CGFloat = self.leftContainerView.frame.origin.x
        
        var panInfo: PanInfo = PanInfo(action: SlideAction.Close, shouldBounce: false, velocity: 0.0)
        
        panInfo.action = leftOrigin <= pointOfNoReturn ? SlideAction.Close : SlideAction.Open;
        
        if velocity.x >= thresholdVelocity {
            panInfo.action = SlideAction.Open
            panInfo.velocity = velocity.x
        } else if velocity.x <= (-1.0 * thresholdVelocity) {
            panInfo.action = SlideAction.Close
            panInfo.velocity = velocity.x
        }
        
        return panInfo
    }
    
    private func panRightResultInfoForVelocity(velocity: CGPoint) -> PanInfo {
        
        var thresholdVelocity: CGFloat = -450.0
        var pointOfNoReturn: CGFloat = CGFloat(floor((self.rightMinOrigin() - self.rightContainerView.frame.size.width) + self.rightContainerView.frame.size.width / 2.0))
        var rightOrigin: CGFloat = self.rightContainerView.frame.origin.x
        
        var panInfo: PanInfo = PanInfo(action: SlideAction.Close, shouldBounce: false, velocity: 0.0)
        
        panInfo.action = rightOrigin >= pointOfNoReturn ? SlideAction.Close : SlideAction.Open
        
        if velocity.x <= thresholdVelocity {
            panInfo.action = SlideAction.Open
            panInfo.velocity = velocity.x
        } else if (velocity.x >= (-1.0 * thresholdVelocity)) {
            panInfo.action = SlideAction.Close
            panInfo.velocity = velocity.x
        }
        
        return panInfo
    }
    
    private func applyLeftTranslation(translation: CGPoint, toFrame:CGRect) -> CGRect {
        
        var newOrigin: CGFloat = toFrame.origin.x
        newOrigin += translation.x
        
        var minOrigin: CGFloat = self.leftMinOrigin()
        var maxOrigin: CGFloat = 0.0
        var newFrame: CGRect = toFrame
        
        if newOrigin < minOrigin {
            newOrigin = minOrigin
        } else if newOrigin > maxOrigin {
            newOrigin = maxOrigin
        }
        
        newFrame.origin.x = newOrigin
        return newFrame
    }
    
    private func applyRightTranslation(translation: CGPoint, toFrame: CGRect) -> CGRect {
        
        var  newOrigin: CGFloat = toFrame.origin.x
        newOrigin += translation.x
        
        var minOrigin: CGFloat = self.rightMinOrigin()
        //        var maxOrigin: CGFloat = self.options.rightViewOverlapWidth
        var maxOrigin: CGFloat = self.rightMinOrigin() - self.rightContainerView.frame.size.width
        var newFrame: CGRect = toFrame
        
        if newOrigin > minOrigin {
            newOrigin = minOrigin
        } else if newOrigin < maxOrigin {
            newOrigin = maxOrigin
        }
        
        newFrame.origin.x = newOrigin
        return newFrame
    }
    
    private func getOpenedLeftRatio() -> CGFloat {
        
        var width: CGFloat = self.leftContainerView.frame.size.width
        var currentPosition: CGFloat = self.leftContainerView.frame.origin.x - self.leftMinOrigin()
        return currentPosition / width
    }
    
    private func getOpenedRightRatio() -> CGFloat {
        
        var width: CGFloat = self.rightContainerView.frame.size.width
        var currentPosition: CGFloat = self.rightContainerView.frame.origin.x
        return -(currentPosition - CGRectGetWidth(self.view.bounds)) / width
    }
    
    private func applyLeftOpacity() {
        
        var openedLeftRatio: CGFloat = self.getOpenedLeftRatio()
        var opacity: CGFloat = self.options.contentViewOpacity * openedLeftRatio
        self.opacityView.layer.opacity = Float(opacity)
    }
    
    
    private func applyRightOpacity() {
        var openedRightRatio: CGFloat = self.getOpenedRightRatio()
        var opacity: CGFloat = self.options.contentViewOpacity * openedRightRatio
        self.opacityView.layer.opacity = Float(opacity)
    }
    
    private func applyLeftContentViewScale() {
        var openedLeftRatio: CGFloat = self.getOpenedLeftRatio()
        var scale: CGFloat = 1.0 - ((1.0 - self.options.contentViewScale) * openedLeftRatio);
        self.mainContainerView.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
    private func applyRightContentViewScale() {
        var openedRightRatio: CGFloat = self.getOpenedRightRatio()
        var scale: CGFloat = 1.0 - ((1.0 - self.options.contentViewScale) * openedRightRatio)
        self.mainContainerView.transform = CGAffineTransformMakeScale(scale, scale)
    }
    
    private func addShadowToView(targetContainerView: UIView) {
        targetContainerView.layer.masksToBounds = false
        targetContainerView.layer.shadowOffset = self.options.shadowOffset
        targetContainerView.layer.shadowOpacity = Float(self.options.shadowOpacity)
        targetContainerView.layer.shadowRadius = self.options.shadowRadius
        targetContainerView.layer.shadowPath = UIBezierPath(rect: targetContainerView.bounds).CGPath
    }
    
    private func removeShadow(targetContainerView: UIView) {
        targetContainerView.layer.masksToBounds = true
        self.mainContainerView.layer.opacity = 1.0
    }
    
    private func removeContentOpacity() {
        self.opacityView.layer.opacity = 0.0
    }
    

    private func addContentOpacity() {
        self.opacityView.layer.opacity = Float(self.options.contentViewOpacity)
    }
    
    private func disableContentInteraction() {
        self.mainContainerView.userInteractionEnabled = false
    }
    
    private func enableContentInteraction() {
        self.mainContainerView.userInteractionEnabled = true
    }
    
    private func setOpenWindowLevel() {
        if (self.options.hideStatusBar) {
            dispatch_async(dispatch_get_main_queue(), {
                if let window = UIApplication.sharedApplication().keyWindow {
                    window.windowLevel = UIWindowLevelStatusBar + 1
                }
            })
        }
    }
    
    private func setCloseWindowLebel() {
        if (self.options.hideStatusBar) {
            dispatch_async(dispatch_get_main_queue(), {
                if let window = UIApplication.sharedApplication().keyWindow {
                    window.windowLevel = UIWindowLevelNormal
                }
            })
        }
    }
    
    private func setUpViewController(taretView: UIView, targetViewController: UIViewController?) {
        if let viewController = targetViewController {
            self.addChildViewController(viewController)
            viewController.view.frame = taretView.bounds
            taretView.addSubview(viewController.view)
            viewController.didMoveToParentViewController(self)
        }
    }
    
    
    private func removeViewController(viewController: UIViewController?) {
        if let _viewController = viewController {
            _viewController.willMoveToParentViewController(nil)
            _viewController.view.removeFromSuperview()
            _viewController.removeFromParentViewController()
        }
    }
    
    private func minLeftOrigin() -> CGFloat{
        //return  -320.0 + self.options.leftViewOverlapWidth
        return  self.options.leftViewOverlapWidth - CGRectGetWidth(self.view.bounds)
    }
    
    private func minRightOrigin() -> CGFloat {
        return CGRectGetWidth(self.view.bounds)
    }
    
    //TODO NonAnimation IF
    func closeRightNonAnimation (){
        var finalXOrigin: CGFloat = CGRectGetWidth(self.view.bounds)
        var frame: CGRect = self.rightContainerView.frame
        frame.origin.x = finalXOrigin
        self.rightContainerView.frame = frame
        self.opacityView.layer.opacity = 0.0
        self.mainContainerView.transform = CGAffineTransformMakeScale(1.0, 1.0)
        self.removeShadow(self.rightContainerView)
        self.enableContentInteraction()
    }
    
    //pragma mark – UIGestureRecognizerDelegate
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
    
        var point: CGPoint = touch.locationInView(self.view)
        
        if gestureRecognizer == self.leftPanGesture {
            return self.slideLeftForGestureRecognizer(gestureRecognizer, point: point)
        } else if gestureRecognizer == self.rightPanGesture {
            return self.slideRightViewForGestureRecognizer(gestureRecognizer, withTouchPoint: point)
        } else if gestureRecognizer == self.leftTapGetsture {
            return self.isLeftOpen() && !self.isPointContainedWithinLeftRect(point)
        } else if gestureRecognizer == self.rightTapGesture {
            return self.isRightOpen() && !self.isPointContainedWithinRightRect(point)
        }
        
        return true
    }
    
    private func slideLeftForGestureRecognizer( gesture: UIGestureRecognizer, point:CGPoint) -> Bool{
        
        var slide = self.isLeftOpen()
        slide |= self.options.panFromBezel && self.isLeftPointContainedWithinBezelRect(point)
        return slide
    }
    
    private func isLeftPointContainedWithinBezelRect(point: CGPoint) -> Bool{
        var leftBezelRect: CGRect = CGRectZero
        var tempRect: CGRect = CGRectZero
        var bezelWidth: CGFloat = self.options.leftBezelWidth
        
        CGRectDivide(self.view.bounds, &leftBezelRect, &tempRect, bezelWidth, CGRectEdge.MinXEdge)
        return CGRectContainsPoint(leftBezelRect, point)
    }
    
    private func isPointContainedWithinLeftRect(point: CGPoint) -> Bool {
        return CGRectContainsPoint(self.leftContainerView.frame, point)
    }
    
    
    
    private func slideRightViewForGestureRecognizer(gesture: UIGestureRecognizer, withTouchPoint point: CGPoint) -> Bool {
        
        var slide: Bool = self.isRightOpen()
        slide |= self.options.rightPanFromBezel && self.isRightPointContainedWithinBezelRect(point)
        return slide
    }
    
    private func isRightPointContainedWithinBezelRect(point: CGPoint) -> Bool {
        var rightBezelRect: CGRect = CGRectZero
        var tempRect: CGRect = CGRectZero
        //CGFloat bezelWidth = self.rightContainerView.frame.size.width;
        var bezelWidth: CGFloat = CGRectGetWidth(self.view.bounds) - self.options.rightBezelWidth
        
        CGRectDivide(self.view.bounds, &tempRect, &rightBezelRect, bezelWidth, CGRectEdge.MinXEdge)
        
        return CGRectContainsPoint(rightBezelRect, point)
    }
    
    private func isPointContainedWithinRightRect(point: CGPoint) -> Bool {
        return CGRectContainsPoint(self.rightContainerView.frame, point)
    }
    
}


extension UIViewController {

    func slideMenuController() -> SlideMenuController? {
        var viewController: UIViewController? = self
        while viewController != nil {
            if viewController is SlideMenuController {
                return viewController as? SlideMenuController
            }
            viewController = viewController?.parentViewController
        }
        return nil;
    }
    
    func addLeftBarButtonWithImage(buttonImage: UIImage) {
        var leftButton: UIBarButtonItem = UIBarButtonItem(image: buttonImage, style: UIBarButtonItemStyle.Bordered, target: self, action: "toggleLeft")
        self.navigationItem.leftBarButtonItem = leftButton;
    }
    
    func addRightBarButtonWithImage(buttonImage: UIImage) {
        var rightButton: UIBarButtonItem = UIBarButtonItem(image: buttonImage, style: UIBarButtonItemStyle.Bordered, target: self, action: "toggleRight")
        self.navigationItem.rightBarButtonItem = rightButton;
    }
    
    func toggleLeft() {
        self.slideMenuController()?.toggleLeft()
    }

    func toggleRight() {
        self.slideMenuController()?.toggleRight()
    }
    
    func openLeft() {
        self.slideMenuController()?.openLeft()
    }
    
    func openRight() {
        self.slideMenuController()?.openRight()    }
    
    func closeLeft() {
        self.slideMenuController()?.closeLeft()
    }
    
    func closeRight() {
        self.slideMenuController()?.closeRight()
    }
}
