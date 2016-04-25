//
//  DVAlertViewController.swift
//  Discussions
//
//  Created by Moin Uddin on 4/15/15.
//  Copyright (c) 2015 Moin Uddin. All rights reserved.
//

import UIKit

enum DVAlertViewControllerStyle: Int{
    case Popup = 0, ActionSheet
}

enum DVAlertViewControllerCellType: Int {
    case Default = 0, Date, DateTime, Picker
}

class DVAlertViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    private var popoverVC: UIViewController!
    var parentController: UIViewController!
    private var popoverView: UIView?
    var style: DVAlertViewControllerStyle!
    override var title: String?{
        didSet{
            if titleLabel != nil{
                titleLabel.text = self.title
            }
        }
    }
    var cancelTitle: String = "Cancel"{
        didSet{
            if cancelButton != nil{
                cancelButton.setTitle(cancelTitle, forState: UIControlState.Normal)
            }
        }
    }
    var doneTitle: String = "Done"{
        didSet{
            if createButton != nil{
                createButton.setTitle(doneTitle, forState: UIControlState.Normal)
            }
        }
    }
    private var actionSheetBottomConstraint: NSLayoutConstraint!
    private let actionSheetHeight: CGFloat = 250
    
    private var containerView: UIView!
    private var containerViewHeightCns: NSLayoutConstraint!
    private var contentView: UIView!
    private var contentSize: CGSize? = nil
    var titleLabel: UILabel!
    var cancelButton: UIButton!
    var createButton: UIButton!
    private var buttonsContainer: UIView!
    private var toolbar: UIView!
    private var _bgLayer: CAShapeLayer!
    private var tableView: UITableView?
    var tableRowHeight: CGFloat = 44.0
    var tableData: [String] = [String]()
    private var selectedIndexPath: NSIndexPath?
    private var prevSelectedIndexPath: NSIndexPath?
    var shouldReturnSelectionOnDismiss: Bool = true
    var selectedIndex: Int?{
        didSet{
            selectedIndexPath = NSIndexPath(forRow: selectedIndex!, inSection: 0)
        }
    }
    
    // For table with dictionary data, picker and datepicker
    private var pickerIndexPath: NSIndexPath?
    private var pickerCellRowHeight: CGFloat = 150//216
    
    var pickerDataValues: [String] = [String]()
    private var selectedPickerValue: String?
    
    var dateFormatter: NSDateFormatter = {
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return dateFormatter
    }()
    var dateTimeFormatter: NSDateFormatter = {
        let dateTimeFormatter = NSDateFormatter()
        dateTimeFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return dateTimeFormatter
    }()
    var tableDictionaryData: NSMutableArray = NSMutableArray()
    // Example array structure
    /*[
        [
            "title": "Select Date Picker",
            "type": DVAlertViewControllerCellType.Date.rawValue,
            "value": NSDate()
        ],
        [
            "title": "Select DateTime Picker",
            "type": DVAlertViewControllerCellType.DateTime.rawValue,
            "value": NSDate()
        ],
        [
            "title": "Select Picker",
            "type": DVAlertViewControllerCellType.Picker.rawValue,
            "options": ["Add", "Sub"],
            "selectedValue": "Sub"
        ]
    ]*/
    
    // End of table with dictionary
    
    private var inputFields: [AnyObject]?
    var inputFieldHeight: CGFloat = 30.0
    private var selectedTextView: UITextView?
    private var selectedTextField: UITextField?
    private var kbHeight: CGFloat = 0
    
    var hiddenControl: Bool = false{
        didSet{
            if self.hiddenControl{
                buttonsContainer.hidden = true
                if contentViewBottomCns != nil{
                    containerView.needsUpdateConstraints()
                    containerView.addConstraint(contentViewBottomCns!)
                    self.containerView.layoutIfNeeded()
                }
            }else{
                buttonsContainer.hidden = false
                if contentViewBottomCns != nil{
                    containerView.needsUpdateConstraints()
                    containerView.removeConstraint(contentViewBottomCns!)
                    self.containerView.layoutIfNeeded()
                }
            }
            updateTableScrollEnabled()
        }
    }
    
    var hiddenToolbar: Bool = false{
        didSet{
            if self.hiddenToolbar{
                toolbar.hidden = true
                if contentViewTopCns != nil{
                    containerView.needsUpdateConstraints()
                    containerView.addConstraint(contentViewTopCns!)
                    self.containerView.layoutIfNeeded()
                }
            }else{
                toolbar.hidden = false
                if contentViewTopCns != nil{
                    containerView.needsUpdateConstraints()
                    containerView.removeConstraint(contentViewTopCns!)
                    self.containerView.layoutIfNeeded()
                }
            }
            updateTableScrollEnabled()
        }
    }
    
    var shouldRemoveControl: Bool?{
        didSet{
            if self.shouldRemoveControl == true{
                hiddenToolbar = true
                hiddenControl = true
            }else{
                if self.shouldRemoveControl == true{
                    hiddenToolbar = false
                    hiddenControl = false
                }
            }
        }
    }
    
    var contentViewTopCns: NSLayoutConstraint?
    var contentViewBottomCns: NSLayoutConstraint?
    
    private var fromView: UIView?
    private var fromViewPoint: CGPoint?
    
    private var shouldShowInCenterY: Bool = true
    private var shouldShowInTop: Bool = false
    private var shouldShowInBottom: Bool = false
    private var shouldShowInLeft: Bool = false
    private var shouldShowInRigth: Bool = false
    private var fromViewHeight: CGFloat = 0
    private var fromViewWidth: CGFloat = 0
    
    var cancelBlock : (() -> Void)?
    var doneBlock : ((index: Int?) -> Void)?
    
    convenience init(parentController: UIViewController, popoverView: UIView, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil){
        self.init()
        
        self.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.parentController = parentController
        self.popoverVC = nil
        self.popoverView = popoverView
        self.style = style
        self.contentSize = contentSize != nil ? contentSize : self.isPad() ? CGSizeMake(400, 300) : CGSizeMake(280, 220)
        
        self.view.userInteractionEnabled = true
        self.view.multipleTouchEnabled = true
        
        self.createPopupContents()
    }
    
    convenience init(parentController: UIViewController, popoverVC: UIViewController?, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil){
        self.init()
        
        self.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.parentController = parentController
        self.popoverVC = popoverVC
        self.style = style
        self.contentSize = contentSize != nil ? contentSize : self.isPad() ? CGSizeMake(400, 300) : CGSizeMake(280, 220)
        
        self.view.userInteractionEnabled = true
        self.view.multipleTouchEnabled = true
        
        self.createPopupContents()
    }
    
    convenience init(inputFields: [AnyObject], popoverVC: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil) {
        
        self.init(parentController: popoverVC, popoverVC: nil, style: style, contentSize: contentSize)
        
        self.inputFields = inputFields
    }
    
    convenience init(parentController: UIViewController, popoverVC: UIViewController?, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView){
        self.init()
        
        self.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.parentController = parentController
        self.popoverVC = popoverVC
        self.style = style
        self.contentSize = contentSize != nil ? contentSize : self.isPad() ? CGSizeMake(400, 300) : CGSizeMake(280, 220)
        self.fromView = fromView
        
        self.view.userInteractionEnabled = true
        self.view.multipleTouchEnabled = true
        
        self.createPopupContents()
    }
    
    convenience init(parentController: UIViewController, popoverVC: UIViewController?, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromPoint: CGPoint){
        self.init()
        
        self.modalPresentationStyle = UIModalPresentationStyle.OverCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.CrossDissolve
        
        self.parentController = parentController
        self.popoverVC = popoverVC
        self.style = style
        self.contentSize = contentSize != nil ? contentSize : self.isPad() ? CGSizeMake(400, 300) : CGSizeMake(280, 220)
        self.fromViewPoint = fromPoint
        //print(fromViewPoint)
        self.view.userInteractionEnabled = true
        self.view.multipleTouchEnabled = true
        
        self.createPopupContents()
    }
    
    convenience init(title: String, parentController: UIViewController, popoverVC: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView){
        
        self.init(parentController: parentController, popoverVC: popoverVC, style: style, contentSize: contentSize, fromView: fromView)
        
        self.title = title
    }
    
    convenience init(data: [String], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView) {
        
        self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromView: fromView)
        
        self.tableData = data
    }
    
    convenience init(data: NSMutableArray, parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView) {
        
        self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromView: fromView)
        
        self.tableDictionaryData = data
    }
    
    convenience init(data: [String], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromPoint: CGPoint) {
        
        self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromPoint: fromPoint)
        
        self.tableData = data
    }
    
    convenience init(data: NSMutableArray, parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromPoint: CGPoint) {
        
        self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromPoint: fromPoint)
        
        self.tableDictionaryData = data
    }
    
    convenience init(inputFields: [AnyObject], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromPoint: CGPoint) {
        
        self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromPoint: fromPoint)
        
        self.inputFields = inputFields
    }
    
    convenience init(inputFields: [AnyObject], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView) {
        
        self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromView: fromView)
        
        self.inputFields = inputFields
    }
    
    func createPopupContents(){
        self.view.backgroundColor = UIColor.blackColor().colorWithAlphaComponent(0.2)
        
        // create container view
        containerView = UIView()
        containerView.backgroundColor = UIColor.whiteColor()
        if self.style == DVAlertViewControllerStyle.Popup{
            containerView.layer.cornerRadius = 4
        }
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(containerView)
        
        var height: CGFloat = self.contentSize != nil ? self.contentSize!.height + 16 : self.contentSize!.height + 99
        
        if (fromViewPoint != nil || fromView != nil) && height >= parentController.view.bounds.size.height - 110{
           height = parentController.view.bounds.size.height - 150
        }
        
        var width: CGFloat = self.contentSize != nil ? self.contentSize!.width : 280
        
        if width >= parentController.view.bounds.size.width{
            width = parentController.view.bounds.size.width - 20
        }
        if self.style == DVAlertViewControllerStyle.ActionSheet{
            height = actionSheetHeight
            width = UIScreen.mainScreen().bounds.width
        }
        contentSize = CGSizeMake(width, height)
        //print("fromViewPoint before = \(fromViewPoint)")
        if let pvc: UIViewController = fromView?.parentViewController{
            fromViewPoint = pvc.view.convertPoint(CGPointMake(0, 0), fromView: fromView)
        }
        //print("fromViewPoint after = \(fromViewPoint)")
        
        if fromViewPoint != nil{
            if fromView != nil{
                fromViewHeight = fromView!.bounds.size.height
                fromViewWidth = fromView!.bounds.size.width
            }
            if parentController.view.bounds.size.height - (fromViewPoint!.y + fromViewHeight + 15) >= height{
                shouldShowInCenterY = false
                shouldShowInBottom = true
            }else if fromViewPoint!.y - 79 >= height{
                shouldShowInCenterY = false
                shouldShowInTop = true
            }
            
            if fromView != nil{
                if (fromViewPoint!.x + fromView!.frame.size.width / 2) > 15 && fromViewPoint!.x - parentController.view.bounds.size.width/2 < 0 && parentController.view.bounds.size.width - fromViewPoint!.x >= width{
                    shouldShowInLeft = true
                }else if fromViewPoint!.x - parentController.view.bounds.size.width/2 > 0 && parentController.view.bounds.size.width - 15 >= width{
                    shouldShowInRigth = true
                }
            }else{
                if fromViewPoint!.x > 15 && fromViewPoint!.x - parentController.view.bounds.size.width/2 < 0 && parentController.view.bounds.size.width - fromViewPoint!.x >= width{
                    shouldShowInLeft = true
                }else if fromViewPoint!.x - parentController.view.bounds.size.width/2 > 0 && parentController.view.bounds.size.width - 15 >= width{
                    shouldShowInRigth = true
                }
            }
        }
        
        if UIApplication.sharedApplication().userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.RightToLeft || NSLocale.preferredLanguages()[0].hasPrefix("ar"){
            shouldShowInCenterY = true
        }
        
        if shouldShowInCenterY{
            shouldShowInRigth = false
            shouldShowInLeft = false
        }
        
        //print("fromViewPoint after = \(fromViewPoint)")
        //print("shouldShowInCenterY = \(shouldShowInCenterY)")
        //print("shouldShowInBottom = \(shouldShowInBottom)")
        //print("shouldShowInTop = \(shouldShowInTop)")
        //print("shouldShowInLeft = \(shouldShowInLeft)")
        //print("shouldShowInRigth = \(shouldShowInRigth)")
        
        // containerView constraints
        containerViewHeightCns = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: height)
        self.view.addConstraint(containerViewHeightCns)
        let centerX: NSLayoutConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0)
        self.view.addConstraint(centerX)
        
        if self.style == DVAlertViewControllerStyle.Popup{
            self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: width))
            if shouldShowInCenterY{
                let centerYCns: NSLayoutConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0)
                centerYCns.priority = 750
                self.view.addConstraint(centerYCns)
            }else if shouldShowInBottom{
                //print("bottom")
                self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: (fromViewPoint!.y + fromViewHeight + 10)))
                
            }else if shouldShowInTop{
                //print("top")
                self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: (fromViewPoint!.y - (height + 5))))
            }
            
            if shouldShowInRigth{
                self.view.removeConstraint(centerX)
                self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: (parentController.view.bounds.size.width - (width + 10))))
            }else if shouldShowInLeft{
                self.view.removeConstraint(centerX)
                //print("shouldShowInLeft = \(shouldShowInLeft)")
                
                var constant: CGFloat = fromViewPoint!.x - 10
                if fromView != nil && fromViewPoint!.x < 15{
                    constant = fromViewPoint!.x + (fromView!.frame.size.width / 2) - 10
                }
                
                //print("constant = \(constant)")
                self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: constant))
            }
        }else if self.style == DVAlertViewControllerStyle.ActionSheet{
            self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0))
            
            actionSheetBottomConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.view, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: height)
            self.view.addConstraint(actionSheetBottomConstraint)
        }
        
        // toolbar
        toolbar = UIView()
        //toolbar.backgroundColor = UIColor.purpleColor()
        toolbar.clipsToBounds = true
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(toolbar)
        
        // toolbar constraints
        containerView.addConstraint(NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: toolbar, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 40))
        
        // titleLabel
        titleLabel = UILabel()
        //titleLabel.backgroundColor = UIColor.grayColor()
        titleLabel.text = self.title
        titleLabel.textAlignment = NSTextAlignment.Center
        titleLabel.font = UIFont.boldSystemFontOfSize(18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(titleLabel)
        
        // titleLable constraints
        toolbar.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.Equal, toItem: toolbar, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0))
        toolbar.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: toolbar, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0))
        
        // bottom buttons container
        buttonsContainer = UIView()
        let borderView: UIView = UIView()
        
        if self.style == DVAlertViewControllerStyle.Popup && self.isPhone(){
            //buttonsContainer.backgroundColor = UIColor.grayColor()
            buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(buttonsContainer)
            
            containerView.addConstraint(NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 41))
            containerView.addConstraint(NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0))
            containerView.addConstraint(NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0))
            containerView.addConstraint(NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
            
            borderView.backgroundColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1)
            borderView.translatesAutoresizingMaskIntoConstraints = false
            
            buttonsContainer.addSubview(borderView)
            
            buttonsContainer.addConstraint(NSLayoutConstraint(item: borderView, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 1))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: borderView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: borderView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: borderView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 0))
        }
        
        cancelButton = UIButton()
        //cancelButton.backgroundColor = UIColor.redColor()
        cancelButton.setTitle(cancelTitle, forState: UIControlState.Normal)
        cancelButton.setTitleColor(UIColor(rgba: "616161"), forState: UIControlState.Normal)
        cancelButton.titleLabel?.font = UIFont.systemFontOfSize(16)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        if self.style == DVAlertViewControllerStyle.Popup && self.isPhone(){
            cancelButton.setBackgroundImage(UIColor.imageWithColor(UIColor(rgba: "dfdfe2"), size: nil), forState: UIControlState.Highlighted)
            buttonsContainer.addSubview(cancelButton)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 260 * Int64(NSEC_PER_MSEC)), dispatch_get_main_queue()){
                let bottomLeftBorder: UIBezierPath = UIBezierPath(roundedRect: self.cancelButton.bounds, byRoundingCorners: UIRectCorner.BottomLeft, cornerRadii: CGSizeMake(4,4))
                let cancelButtonMask: CAShapeLayer = CAShapeLayer()
                cancelButtonMask.frame = self.cancelButton.bounds
                cancelButtonMask.path = bottomLeftBorder.CGPath
                self.cancelButton.layer.mask = cancelButtonMask
            }
        }else if self.style == DVAlertViewControllerStyle.ActionSheet || self.isPad(){
            cancelButton.setTitleColor(UIColor(rgba: "8a8a8a"), forState: UIControlState.Highlighted)
            cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
            toolbar.addSubview(cancelButton)
        }
        cancelButton.addTarget(self, action: "cancelTap:", forControlEvents: .TouchUpInside)
        
        createButton = UIButton()
        //createButton.backgroundColor = UIColor.redColor()
        createButton.setTitle(doneTitle, forState: UIControlState.Normal)
        createButton.setTitleColor(UIColor(rgba: "34bdf5"), forState: UIControlState.Normal)
        createButton.titleLabel?.font = UIFont.boldSystemFontOfSize(16)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        if self.style == DVAlertViewControllerStyle.Popup && self.isPhone(){
            createButton.setBackgroundImage(UIColor.imageWithColor(UIColor(rgba: "dfdfe2"), size: nil), forState: UIControlState.Highlighted)
            buttonsContainer.addSubview(createButton)
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 260 * Int64(NSEC_PER_MSEC)), dispatch_get_main_queue()){
                let bottomRightBorder: UIBezierPath = UIBezierPath(roundedRect: self.createButton.bounds, byRoundingCorners: UIRectCorner.BottomRight, cornerRadii: CGSizeMake(4,4))
                let createButtonMask: CAShapeLayer = CAShapeLayer()
                createButtonMask.frame = self.createButton.bounds
                createButtonMask.path = bottomRightBorder.CGPath
                self.createButton.layer.mask = createButtonMask
            }
        }else if self.style == DVAlertViewControllerStyle.ActionSheet || self.isPad(){
            createButton.setTitleColor(UIColor(rgba: "6bc8ee"), forState: UIControlState.Highlighted)
            createButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Right
            toolbar.addSubview(createButton)
        }
        createButton.addTarget(self, action: "createTap:", forControlEvents: .TouchUpInside)
        
        if self.style == DVAlertViewControllerStyle.Popup && self.isPhone(){
            let buttonSeperatorBorder: UIView = UIView()
            buttonSeperatorBorder.backgroundColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1)
            buttonSeperatorBorder.translatesAutoresizingMaskIntoConstraints = false
            buttonsContainer.addSubview(buttonSeperatorBorder)
            
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 40))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Width, multiplier: 0.5, constant: -0.5))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: borderView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
            
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 40))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Width, multiplier: 0.5, constant: -0.5))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: borderView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
            
            buttonsContainer.addConstraint(NSLayoutConstraint(item: buttonSeperatorBorder, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 1))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: buttonSeperatorBorder, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: borderView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: buttonSeperatorBorder, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: buttonsContainer, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: buttonSeperatorBorder, attribute: NSLayoutAttribute.CenterX, relatedBy: NSLayoutRelation.GreaterThanOrEqual, toItem: buttonsContainer, attribute: NSLayoutAttribute.CenterX, multiplier: 1.0, constant: 0))
        }else if self.style == DVAlertViewControllerStyle.ActionSheet || self.isPad(){
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 30))
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 70))
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: toolbar, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0))
            
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: toolbar, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 8))
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: titleLabel, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: -8))
            
            toolbar.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: 30))
            toolbar.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.Width, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Width, multiplier: 1.0, constant: 70))
            toolbar.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: toolbar, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0))
            
            toolbar.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: titleLabel, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 8))
            toolbar.addConstraint(NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: createButton, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 8))
        }
        
        contentView = UIView()
        contentView.backgroundColor = UIColor.clearColor()
        //contentView.backgroundColor = UIColor.greenColor()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        
        containerView.addConstraint(NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.Leading, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Leading, multiplier: 1.0, constant: 8))
        containerView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Trailing, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.Trailing, multiplier: 1.0, constant: 8))
        let cns1 = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: toolbar, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 8)
        cns1.priority = 750
        containerView.addConstraint(cns1)
        
        let cns2 = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 8)
        cns2.priority = 750
        containerView.addConstraint(cns2)
        
        contentViewTopCns = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: containerView, attribute: NSLayoutAttribute.Top, multiplier: 1.0, constant: 8)
        contentViewTopCns?.priority = 1000
        
        if self.style == DVAlertViewControllerStyle.Popup && self.isPhone(){
            let cns3 = NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.Top, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 8)
            cns3.priority = 750
            containerView.addConstraint(cns3)
            
            let cns4 = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 8)
            cns4.priority = 750
            containerView.addConstraint(cns4)
            
            contentViewBottomCns = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 8)
            contentViewBottomCns?.priority = 1000
        }else if self.style == DVAlertViewControllerStyle.ActionSheet || self.isPad(){
            containerView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: contentView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: 8))
        }
        
        if fromViewPoint != nil{
            hiddenControl = true
            hiddenToolbar = true
            /*buttonsContainer.removeFromSuperview()
            toolbar.removeFromSuperview()*/
        }
        
    }
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch: UITouch = touches.first{
            let location = touch.locationInView(self.view)
            let fingerRect: CGRect = CGRectMake(location.x-5, location.y-5, 10, 10)
            if !CGRectIntersectsRect(fingerRect, containerView.frame){
                if (tableData.count > 0 || tableDictionaryData.count > 0) && shouldReturnSelectionOnDismiss{
                    self.createButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
                }else{
                    self.hide()
                }
            }
        }
    }
    
    func cancelTap(sender: AnyObject){
        if self.cancelBlock != nil{
            self.cancelBlock?()
        }else{
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func createTap(sender: AnyObject){
        if self.doneBlock != nil{
            if tableData.count > 0 && selectedIndexPath != nil{
                self.doneBlock?(index: selectedIndexPath?.row)
            }else{
                self.doneBlock?(index: nil)
            }
            self.hide()
        }else{
            self.dismissViewControllerAnimated(true, completion: nil)
        }
    }
    
    func show(){
        if popoverVC != nil{
            popoverVC.view.frame = contentView.bounds
            contentView.addSubview(popoverVC.view)
            
            self.addChildViewController(popoverVC)
            popoverVC.didMoveToParentViewController(self)
        }else if popoverView != nil{
            popoverView!.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(popoverView!)
            contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[popoverView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["popoverView": popoverView!]))
            contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[popoverView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["popoverView": popoverView!]))
        }else if tableData.count > 0 || tableDictionaryData.count > 0{
            tableView = UITableView(frame: self.contentView.bounds)
            //tableView.backgroundColor = UIColor.redColor()
            tableView?.delegate = self
            tableView?.dataSource = self
            tableView?.separatorStyle = .None
            self.updateTableScrollEnabled()
            tableView?.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(tableView!)
            
            self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[table]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["table": tableView!]))
            self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[table]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["table": tableView!]))
        }else if inputFields != nil{
            var contentViewHeight: CGFloat = CGFloat(inputFields!.count) * inputFieldHeight
            var topView: UIView? = nil
            for (index, field) in inputFields!.enumerate(){
                if field.isKindOfClass(UITextField.self) || field.isKindOfClass(UITextView.self){
                    var textField: UIView!
                    
                    if let textfield: UITextField = field as? UITextField{
                        textfield.delegate = self
                        textfield.returnKeyType = UIReturnKeyType.Done
                        textField = textfield
                    }else if let textView: UITextView = field as? UITextView{
                        textView.delegate = self
                        textField = textView
                    }
                    
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    contentView.addSubview(textField)
                    
                    self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[textField]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["textField": textField]))
                    
                    if inputFields?.count == 1{
                        self.contentView.addConstraint(NSLayoutConstraint(item: textField, attribute: NSLayoutAttribute.Height, relatedBy: NSLayoutRelation.Equal, toItem: nil, attribute: NSLayoutAttribute.Height, multiplier: 1.0, constant: inputFieldHeight))
                        self.contentView.addConstraint(NSLayoutConstraint(item: textField, attribute: NSLayoutAttribute.CenterY, relatedBy: NSLayoutRelation.Equal, toItem: self.contentView, attribute: NSLayoutAttribute.CenterY, multiplier: 1.0, constant: 0))
                    }else{
                        if topView == nil{
                            if index < inputFields!.count - 1{
                                self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[textField(height)]", options: NSLayoutFormatOptions(), metrics: ["height": inputFieldHeight], views: ["textField": textField]))
                            }else{
                                self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[textField(height)]-(>=0)-|", options: NSLayoutFormatOptions(), metrics: ["height": inputFieldHeight], views: ["textField": textField]))
                            }
                        }else{
                            if index < inputFields!.count - 1{
                                self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[topView]-0-[textField(height)]", options: NSLayoutFormatOptions(), metrics: ["height": inputFieldHeight], views: ["textField": textField, "topView": topView!]))
                            }else{
                                self.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[topView]-0-[textField(height)]-(>=0)-|", options: NSLayoutFormatOptions(), metrics: ["height": inputFieldHeight], views: ["textField": textField, "topView": topView!]))
                            }
                        }
                    }
                    
                    topView = textField
                }
            }
            
            
            
            if !hiddenControl && !hiddenToolbar{
                contentViewHeight = contentViewHeight + 81.0 + 16.0
            }else if !hiddenControl || !hiddenToolbar{
                contentViewHeight = contentViewHeight + 41.0 + 16.0
            }else if hiddenControl && hiddenToolbar{
                contentViewHeight = contentViewHeight + 16.0
            }
            
            if contentViewHeight > contentSize?.height{
                containerView.removeConstraint(containerViewHeightCns)
                self.view.needsUpdateConstraints()
                containerViewHeightCns.constant = contentViewHeight
                containerView.addConstraint(containerViewHeightCns)
                self.view.layoutIfNeeded()
            }
        }
        
        if self.style == DVAlertViewControllerStyle.Popup{
            var shouldAnimate: Bool = true
            if !self.shouldShowInCenterY{
                containerView.alpha = 0
                shouldAnimate = false
            }
            parentController.presentViewController(self, animated: shouldAnimate){ () -> Void in
                if !self.shouldShowInCenterY{
                    if self._bgLayer != nil{
                        self._bgLayer.removeFromSuperlayer()
                    }else{
                        self._bgLayer = CAShapeLayer()
                    }
                    var centerX: CGFloat = self.fromViewPoint!.x
                    centerX = self.fromViewPoint!.x - self.view.convertPoint(CGPointMake(0, 0), fromView: self.containerView).x
                    //print("centerX = \(centerX)")
                    if self.fromView != nil{
                        if self.contentSize?.width <= centerX + self.fromViewWidth/2 + 10{
                            centerX = centerX + self.contentSize!.width/2 - 5
                        }else{
                            centerX = centerX + self.fromViewWidth/2
                        }
                    }
                    //print("centerX1 = \(centerX)")
                    var path: CGPathRef = self.newBubble(CGPointMake(centerX - 5, 0), y: CGPointMake(centerX + 5, 0), z: CGPointMake(centerX, -10))
                    if self.shouldShowInTop{
                        path = self.newBubble(CGPointMake(centerX - 5, self.containerView.frame.size.height), y: CGPointMake(centerX + 5, self.containerView.frame.size.height), z: CGPointMake(centerX, self.containerView.frame.size.height + 10))
                    }
                    //print("shouldShowInLeft = \(self.shouldShowInLeft)")
                    //print("shouldShowInRigth = \(self.shouldShowInRigth)")
                    self._bgLayer.path = path
                    
                    self._bgLayer.fillColor = UIColor.whiteColor().CGColor
                    
                    
                    
                    self.containerView.layer.insertSublayer(self._bgLayer, atIndex: 0)
                }
                UIView.animateWithDuration(0.25, animations: { 
                    self.containerView.alpha = 1
                })
            }
        }else if self.style == DVAlertViewControllerStyle.ActionSheet{
            parentController.presentViewController(self, animated: false) { () -> Void in
                self.containerView.layoutIfNeeded()
                
                self.actionSheetBottomConstraint.constant = 0
                UIView.animateWithDuration(0.2, animations: { () -> Void in
                    self.containerView.layoutIfNeeded()
                })
            }
        }
    }
    
    func hide(animation: Bool? = false){
        UIView.animateWithDuration(0.2, animations: { () -> Void in
            self.view.alpha = 0
            }) { (success: Bool) -> Void in
                self.dismissViewControllerAnimated(animation!, completion: nil)
        }
    }
    
    
    func updateTableScrollEnabled(){
        if !hiddenControl && !hiddenToolbar{
            //print("here !! = \(contentSize!.height - CGFloat(96.0)), \(CGFloat(CGFloat(tableData.count) * tableRowHeight))")
            if contentSize!.height - CGFloat(96.0) >= CGFloat(CGFloat(tableData.count) * tableRowHeight){
                tableView?.scrollEnabled = false
            }else{
                tableView?.scrollEnabled = true
            }
        }else if !hiddenControl || !hiddenToolbar{
            //print("here ! = \(contentSize!.height - CGFloat(48.0)), \(CGFloat(CGFloat(tableData.count) * tableRowHeight))")
            if contentSize!.height - CGFloat(48.0) >= CGFloat(CGFloat(tableData.count) * tableRowHeight){
                tableView?.scrollEnabled = false
            }else{
                tableView?.scrollEnabled = true
            }
        }else if hiddenControl && hiddenToolbar{
            //print("here && = \(contentSize!.height - CGFloat(16.0)), \(CGFloat(CGFloat(tableData.count) * tableRowHeight))")
            if contentSize!.height - CGFloat(16.0) >= CGFloat(CGFloat(tableData.count) * tableRowHeight){
                tableView?.scrollEnabled = false
            }else{
                tableView?.scrollEnabled = true
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableDictionaryData.count > 0{
            if self.pickerIndexPath != nil{
                // we have a date picker, so allow for it in the number of rows in this section
                return tableDictionaryData.count + 1
            }
            return tableDictionaryData.count
        }
        return tableData.count
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if pickerIndexPath == indexPath{
            return self.pickerCellRowHeight
        }
        return tableRowHeight
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        if tableDictionaryData.count > 0{
            var cellData: NSDictionary!
            
            if indexPath.row < tableDictionaryData.count{
                cellData = tableDictionaryData[indexPath.row] as! NSDictionary
            }
            
            if pickerIndexPath?.section == indexPath.section && indexPath.row >= pickerIndexPath?.row{
                cellData = tableDictionaryData[indexPath.row - 1] as! NSDictionary
            }
            
            let cellType: Int? = cellData.objectForKey("type") as? Int
            
            if pickerIndexPath != nil{
                if cellType == DVAlertViewControllerCellType.Date.rawValue || cellType == DVAlertViewControllerCellType.DateTime.rawValue{
                    var datePickerCell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("datePicker")
                    if datePickerCell == nil{
                        datePickerCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "datePicker")
                        let datepicker: UIDatePicker = UIDatePicker()
                        //datepicker.setValue(UIFont.systemFontOfSize(14), forKey: "font")
                        //datepicker.setValue(UIColor.redColor(), forKey: "textColor")
                        datepicker.datePickerMode = UIDatePickerMode.Date
                        if cellType == DVAlertViewControllerCellType.DateTime.rawValue{
                            datepicker.datePickerMode = UIDatePickerMode.DateAndTime
                        }
                        
                        datepicker.date = NSDate()
                        if let date: NSDate = cellData.objectForKey("value") as? NSDate{
                            datepicker.date = date
                        }
                        datepicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), forControlEvents: UIControlEvents.ValueChanged)
                        
                        datepicker.translatesAutoresizingMaskIntoConstraints = false
                        datePickerCell?.contentView.addSubview(datepicker)
                        datePickerCell!.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[datepicker]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["datepicker": datepicker]))
                        datePickerCell!.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[datepicker]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["datepicker": datepicker]))
                    }
                    
                    cell = datePickerCell
                }else if cellType == DVAlertViewControllerCellType.Picker.rawValue{
                    var uiPickerCell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("uiPicker")
                    if uiPickerCell == nil{
                        uiPickerCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "uiPicker")
                        let pickerView: UIPickerView = UIPickerView()
                        
                        if let options: [String] = cellData.objectForKey("options") as? [String]{
                            pickerDataValues = options
                            pickerView.delegate = self
                            pickerView.dataSource = self
                            
                            if let selectedValue: String = cellData.objectForKey("selectedValue") as? String{
                                selectedPickerValue = selectedValue
                                pickerView.selectRow(pickerDataValues.indexOf(selectedValue)!, inComponent: 0, animated: false)
                            }
                            
                        }
                        
                        
                        pickerView.translatesAutoresizingMaskIntoConstraints = false
                        uiPickerCell?.contentView.addSubview(pickerView)
                        uiPickerCell!.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[pickerView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["pickerView": pickerView]))
                        uiPickerCell!.contentView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[pickerView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["pickerView": pickerView]))
                    }
                    
                    cell = uiPickerCell
                }
            }else{
                if cellType == DVAlertViewControllerCellType.Date.rawValue || cellType == DVAlertViewControllerCellType.DateTime.rawValue || cellType == DVAlertViewControllerCellType.Picker.rawValue{
                    var pickerCell: UITableViewCell? = tableView.dequeueReusableCellWithIdentifier("pickerCell")
                    
                    if pickerCell == nil{
                        pickerCell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "pickerCell")
                    }
                    
                    pickerCell?.textLabel?.text = cellData.objectForKey("title") as? String
                    
                    if cellType == DVAlertViewControllerCellType.Date.rawValue{
                        if let date: NSDate = cellData.objectForKey("value") as? NSDate{
                            pickerCell?.textLabel?.text = self.dateFormatter.stringFromDate(date)
                        }
                    }else if cellType == DVAlertViewControllerCellType.DateTime.rawValue{
                        if let date: NSDate = cellData.objectForKey("value") as? NSDate{
                            pickerCell?.textLabel?.text = self.dateTimeFormatter.stringFromDate(date)
                        }
                    }else if cellType == DVAlertViewControllerCellType.Picker.rawValue{
                        if let selectedValue: String = cellData.objectForKey("selectedValue") as? String{
                            pickerCell?.textLabel?.text = selectedValue
                        }
                    }
                    
                    cell = pickerCell
                }
            }
        }else{
            cell = tableView.dequeueReusableCellWithIdentifier("cell")
            
            if cell == nil{
                cell = UITableViewCell(style: UITableViewCellStyle.Default, reuseIdentifier: "cell")
            }
            cell?.textLabel?.text = tableData[indexPath.row]
            cell?.textLabel?.font = UIFont.systemFontOfSize(14)
            
            cell?.selectionStyle = .None
            /*cell?.layoutMargins = UIEdgeInsetsZero
            cell?.preservesSuperviewLayoutMargins = false
            cell?.separatorInset = UIEdgeInsetsZero*/
        }
        
        if selectedIndexPath == indexPath && cell?.reuseIdentifier != "pickerCell"{
            cell?.accessoryType = .Checkmark
        }else{
            cell?.accessoryType = .None
        }
        
        return cell!
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        prevSelectedIndexPath = selectedIndexPath
        selectedIndexPath = indexPath
        
        let cell: UITableViewCell = tableView.cellForRowAtIndexPath(indexPath) as UITableViewCell!
        
        if hiddenControl{
            //print("here \(indexPath.row)")
            createButton.sendActionsForControlEvents(UIControlEvents.TouchUpInside)
            return
        }else{
            if prevSelectedIndexPath != nil{
                if let prevcell: UITableViewCell = tableView.cellForRowAtIndexPath(prevSelectedIndexPath!) as UITableViewCell!{
                    prevcell.accessoryType = .None
                }
            }
            if cell.reuseIdentifier != "pickerCell"{
                cell.accessoryType = .Checkmark
            }
        }
        
        
        if cell.reuseIdentifier == "pickerCell"{
            displayPicker(indexPath)
        }else{
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
        }
    }
    
    func displayPicker(indexPath: NSIndexPath){
        var shouldShowPicker: Bool = true
        //check if previously displayed picker is above selected indexPath
        var before: Bool = false
        // check for previusly displayed picker
        if self.pickerIndexPath != nil{
            before = self.pickerIndexPath!.row < indexPath.row
            //println("before picker delete")
            
            self.tableView?.beginUpdates()
            
            let nIndexPath: NSIndexPath = NSIndexPath(forRow: self.pickerIndexPath!.row, inSection: self.pickerIndexPath!.section)
            // if previously selected row match with current row
            if self.pickerIndexPath!.row - 1 == indexPath.row{
                shouldShowPicker = false
                //println("before same picker delete")
                self.pickerIndexPath = nil
                self.tableView?.deleteRowsAtIndexPaths([nIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }else{
                //print("before different picker delete")
                self.pickerIndexPath = nil
                self.tableView?.deleteRowsAtIndexPaths([nIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
            }
            self.tableView?.endUpdates()
            
            // println("after picker delete")
        }
        
        //println("before picker add")
        self.tableView?.beginUpdates()
        if shouldShowPicker{
            var nIndexPath: NSIndexPath = NSIndexPath(forRow: indexPath.row + 1, inSection: indexPath.section)
            self.pickerIndexPath = nIndexPath
            
            if before{
                nIndexPath = indexPath
                self.pickerIndexPath = indexPath
            }
            
            self.tableView?.insertRowsAtIndexPaths([nIndexPath], withRowAnimation: UITableViewRowAnimation.Fade)
        }
        
        tableView?.deselectRowAtIndexPath(indexPath, animated: true)
        self.tableView?.endUpdates()
    }
    
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataValues.count
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataValues[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPickerValue = pickerDataValues[row]
        let indexPath: NSIndexPath = NSIndexPath(forRow: pickerIndexPath!.row - 1, inSection: pickerIndexPath!.section)
        let cellData: NSMutableDictionary = NSMutableDictionary(dictionary: tableDictionaryData[indexPath.row] as! NSDictionary)
        cellData.setValue(selectedPickerValue!, forKey: "selectedValue")
        tableDictionaryData.replaceObjectAtIndex(indexPath.row, withObject: cellData)
        if let cell: UITableViewCell = tableView?.cellForRowAtIndexPath(indexPath){
            cell.textLabel?.text = selectedPickerValue
        }
    }
    
    func datePickerValueChanged(sender: UIDatePicker) {
        var targetedCellIndexPath: NSIndexPath? = nil
        
        targetedCellIndexPath = NSIndexPath(forRow: self.pickerIndexPath!.row - 1, inSection: self.pickerIndexPath!.section)
        
        let cell: UITableViewCell = self.tableView?.cellForRowAtIndexPath(targetedCellIndexPath!) as UITableViewCell!
        let targetedDatePicker: UIDatePicker = sender
        
        // update our data model
        let itemData: NSMutableDictionary = NSMutableDictionary(dictionary: self.tableDictionaryData.objectAtIndex(targetedCellIndexPath!.row) as! NSDictionary)
        let dict: NSMutableDictionary = NSMutableDictionary(dictionary: itemData)
        dict.setValue(targetedDatePicker.date, forKey: "value")
        self.tableDictionaryData.replaceObjectAtIndex(targetedCellIndexPath!.row, withObject: dict)
        
        if sender.datePickerMode == .DateAndTime{
            cell.textLabel?.text = self.dateTimeFormatter.stringFromDate(targetedDatePicker.date)
        }else{
            cell.textLabel?.text = self.dateFormatter.stringFromDate(targetedDatePicker.date)
        }
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        selectedTextField = textField
        
        let point: CGPoint = self.view.convertPoint(CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height), toView: textField)
        if self.view.frame.size.height - point.y < 284{
            //let anotherPoint: CGPoint = self.view.convertPoint(CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height), toView: self.containerView)
            //print("point = \(point), anotherPoint = \(anotherPoint)")
            
            for cns in self.view.constraints{
                if cns.identifier == "bottomCnsForInputs"{
                    self.view.removeConstraint(cns)
                    break
                }
            }
            
            let bottomSpace: CGFloat = 284.0
            let bottomCns: NSLayoutConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.containerView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: bottomSpace)
            bottomCns.identifier = "bottomCnsForInputs"
            self.view.needsUpdateConstraints()
            self.view.addConstraint(bottomCns)
            UIView.animateWithDuration(0.25, animations: { 
                self.view.layoutIfNeeded()
            })
        }
        
        if textField.keyboardType == .NumberPad || textField.keyboardType == .PhonePad || textField.keyboardType == .DecimalPad{
            let keyboardDoneButtonView = UIToolbar()
            keyboardDoneButtonView.sizeToFit()
            
            // Setup the buttons to be put in the system.
            var item: UIBarButtonItem = UIBarButtonItem()
            item = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(onTextFieldDoneTap) )
            
            let flexSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
            let toolbarButtons = [flexSpace,item]
            
            //Put the buttons into the ToolBar and display the tool bar
            keyboardDoneButtonView.setItems(toolbarButtons, animated: true)
            textField.inputAccessoryView = keyboardDoneButtonView
        }
        
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        return false
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.view.needsUpdateConstraints()
        for cns in self.view.constraints{
            if cns.identifier == "bottomCnsForInputs"{
                self.view.removeConstraint(cns)
                break
            }
        }
        UIView.animateWithDuration(0.25, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func onTextFieldDoneTap(){
        selectedTextField?.resignFirstResponder()
    }
    
    // MARK: - UITextViewDelegate
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        selectedTextView = textView
        
        var point: CGPoint = self.view.convertPoint(CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height), toView: textView)
        point.y = point.y - textView.contentOffset.y
        //print(point)
        //print(self.view.frame.size.height - point.y)
        if self.view.frame.size.height - point.y < 284{
            let anotherPoint: CGPoint = self.view.convertPoint(CGPointMake(self.view.frame.size.width / 2, self.view.frame.size.height), toView: self.containerView)
            //print("point = \(point), anotherPoint = \(anotherPoint)")
            
            for cns in self.view.constraints{
                if cns.identifier == "bottomCnsForInputs"{
                    self.view.removeConstraint(cns)
                    break
                }
            }
            
            let bottomSpace: CGFloat = 284.0 - (anotherPoint.y - point.y)
            let bottomCns: NSLayoutConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.Bottom, relatedBy: NSLayoutRelation.Equal, toItem: self.containerView, attribute: NSLayoutAttribute.Bottom, multiplier: 1.0, constant: bottomSpace)
            bottomCns.identifier = "bottomCnsForInputs"
            self.view.needsUpdateConstraints()
            self.view.addConstraint(bottomCns)
            UIView.animateWithDuration(0.25, animations: {
                self.view.layoutIfNeeded()
            })
        }
        
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        
        // Setup the buttons to be put in the system.
        var item: UIBarButtonItem = UIBarButtonItem()
        item = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Plain, target: self, action: #selector(onTextViewDoneTap) )
        
        let flexSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let toolbarButtons = [flexSpace,item]
        
        //Put the buttons into the ToolBar and display the tool bar
        keyboardDoneButtonView.setItems(toolbarButtons, animated: true)
        textView.inputAccessoryView = keyboardDoneButtonView
        
        return true
    }
    
    func textViewDidEndEditing(textView: UITextView) {
        self.view.needsUpdateConstraints()
        for cns in self.view.constraints{
            if cns.identifier == "bottomCnsForInputs"{
                self.view.removeConstraint(cns)
                break
            }
        }
        UIView.animateWithDuration(0.25, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    func onTextViewDoneTap(){
        selectedTextView?.resignFirstResponder()
    }
    
    // MARK: - UIVIewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
         NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(keyboardWillShowNotification(_:)), name: UIKeyboardWillShowNotification, object: nil)
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - keyboardWillShowNotification
    func keyboardWillShowNotification(notification: NSNotification){
        if let value: NSValue = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue{
            let rawFrame: CGRect = value.CGRectValue()
            let keyboardFrame: CGRect = self.view.convertRect(rawFrame, fromView: nil)
            
            kbHeight = keyboardFrame.height
            //print("keyboardHieght: \(keyboardFrame.height)")
        }
    }
    
    // MARK: - isPhone
    func isPhone() -> Bool{
        return (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Phone ? true : false)
    }
    
    // MARK: - isPad
    func isPad() -> Bool{
        return (UIDevice.currentDevice().userInterfaceIdiom == UIUserInterfaceIdiom.Pad ? true : false)
    }
    
    func isIphone4S() -> Bool{
        return UIScreen.mainScreen().bounds.size.height <= 480 ? true : false
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return parentController.preferredStatusBarStyle()
    }
    
    // MARK: - Geometry
    func newBubble(x: CGPoint, y: CGPoint, z: CGPoint) -> CGPathRef{
        let path: CGMutablePathRef = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, x.x, x.y)
        CGPathAddLineToPoint(path, nil, y.x, y.y)
        CGPathAddLineToPoint(path, nil, z.x, z.y)
        CGPathAddLineToPoint(path, nil, x.x, x.y)
        
        
        CGPathCloseSubpath(path)
        return path
    }
    
    func addBorder(view: UIView, edges: UIRectEdge, colour: UIColor = UIColor.whiteColor(), thickness: CGFloat = 1) -> [UIView] {
        
        var borders = [UIView]()
        
        func border() -> UIView {
            let border = UIView(frame: CGRectZero)
            border.backgroundColor = colour
            border.translatesAutoresizingMaskIntoConstraints = false
            return border
        }
        
        if edges.contains(.Top) || edges.contains(.All) {
            let top = border()
            view.addSubview(top)
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[top(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["top": top]))
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[top]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["top": top]))
            borders.append(top)
        }
        
        if edges.contains(.Left) || edges.contains(.All) {
            let left = border()
            view.addSubview(left)
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[left(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["left": left]))
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[left]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["left": left]))
            borders.append(left)
        }
        
        if edges.contains(.Right) || edges.contains(.All) {
            let right = border()
            view.addSubview(right)
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:[right(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["right": right]))
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-(0)-[right]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["right": right]))
            borders.append(right)
        }
        
        if edges.contains(.Bottom) || edges.contains(.All) {
            let bottom = border()
            view.addSubview(bottom)
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:[bottom(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["bottom": bottom]))
            view.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-(0)-[bottom]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["bottom": bottom]))
            borders.append(bottom)
        }
        
        return borders
    }

}

extension UIView {
    var parentViewController: UIViewController? {
        var parentResponder: UIResponder? = self
        while parentResponder != nil {
            parentResponder = parentResponder!.nextResponder()
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}