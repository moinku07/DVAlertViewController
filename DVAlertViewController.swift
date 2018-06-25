//
//  DVAlertViewController.swift
//  Discussions
//
//  Created by Moin Uddin on 4/15/15.
//  Copyright (c) 2015 Moin Uddin. All rights reserved.
//

import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

fileprivate func <= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l <= r
  default:
    return !(rhs < lhs)
  }
}

fileprivate func >= <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l >= r
  default:
    return !(lhs < rhs)
  }
}


enum DVAlertViewControllerStyle: Int{
    case popup = 0, actionSheet, datePicker, picker
}

enum DVAlertViewControllerCellType: Int {
    case date = 0, dateTime, picker
}

class DVAlertViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    fileprivate var popoverVC: UIViewController!
    var parentController: UIViewController!
    fileprivate var popoverView: UIView?
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
                cancelButton.setTitle(cancelTitle, for: UIControlState())
            }
        }
    }
    var doneTitle: String = "Okay"{
        didSet{
            if createButton != nil{
                createButton.setTitle(doneTitle, for: UIControlState())
            }
        }
    }
    fileprivate var actionSheetBottomConstraint: NSLayoutConstraint!
    fileprivate let actionSheetHeight: CGFloat = 250
    
    fileprivate var containerView: UIView!
    var containerViewHeight: CGFloat = 250{
        didSet{
            if containerView != nil{
                self.view.needsUpdateConstraints()
                containerViewHeightCns.constant = containerViewHeight
                UIView.animate(withDuration: 0.25, animations: {() -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    fileprivate var containerViewHeightCns: NSLayoutConstraint!
    fileprivate var contentView: UIView!
    var contentViewPadding: CGFloat = 8.0{
        didSet{
            if containerView != nil && contentView != nil{
                for cns in containerView.constraints{
                    if (cns.firstItem as? NSObject == containerView || cns.secondItem as? NSObject == contentView) || (cns.firstItem as? NSObject == contentView || cns.secondItem as? NSObject == containerView){
                        if cns.firstAttribute == .top && cns.secondAttribute == .top{
                            cns.constant = contentViewPadding
                        }else if cns.firstAttribute == .bottom && cns.secondAttribute == .bottom{
                            cns.constant = contentViewPadding
                        }else if cns.firstAttribute == .leading && cns.secondAttribute == .leading{
                            cns.constant = contentViewPadding
                        }else if cns.firstAttribute == .trailing && cns.secondAttribute == .trailing{
                            cns.constant = contentViewPadding
                        }
                    }
                }
            }
        }
        willSet{
            if containerView != nil{
                containerViewHeight = containerViewHeight - (2 * (self.contentViewPadding - newValue))
                /*for cns in self.view.constraints{
                    if (cns.firstAttribute == .height || cns.secondAttribute == .height) && (cns.firstItem as? NSObject == containerView || cns.secondItem as? NSObject == containerView){
                        cns.constant = cns.constant - (2 * (self.contentViewPadding - newValue))
                        break
                    }
                }*/
            }
        }
    }
    fileprivate var contentSize: CGSize? = nil
    var titleLabel: UILabel!
    var messageLabel: UILabel?
    var cancelButton: UIButton!
    var createButton: UIButton!
    fileprivate var buttonsContainer: UIView!
    var toolbar: UIView!
    fileprivate var _bgLayer: CAShapeLayer!
    fileprivate var tableView: UITableView?
    var tableRowHeight: CGFloat = 44.0
    var tableData: [String] = [String]()
    var tableCellFont: UIFont = UIFont.systemFont(ofSize: 14)
    var tableCellSelectedFont: UIFont = UIFont.boldSystemFont(ofSize: 14.0)
    var tableCellAccessoryView: UIView?
    var tableCellSelectedAccessoryView: UIView?
    fileprivate var selectedIndexPath: IndexPath?
    fileprivate var prevSelectedIndexPath: IndexPath?
    var shouldReturnSelectionOnDismiss: Bool = true
    var shouldDismissOnEmptyAreaTap: Bool = true
    var selectionColor: UIColor? = nil
    var selectedIndex: Int?{
        didSet{
            selectedIndexPath = IndexPath(row: selectedIndex!, section: 0)
        }
    }
    var textAllingment: NSTextAlignment = .left
    
    // For table with dictionary data, picker and datepicker
    fileprivate var pickerIndexPath: IndexPath?
    fileprivate var pickerCellRowHeight: CGFloat = 150//216
    
    fileprivate var pickerDataValues: [String] = [String]()
    var selectedPickerValue: String?
    var selectedPickerIndex: Int?
    var selectedDate: Date = Date()
    fileprivate var datePickerMode: UIDatePickerMode = UIDatePickerMode.date
    fileprivate var minimumDate: Date?
    fileprivate var maximumDate: Date?
    fileprivate var minuteInterval: Int?
    var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy/MM/dd"
        return dateFormatter
    }()
    var dateTimeFormatter: DateFormatter = {
        let dateTimeFormatter = DateFormatter()
        dateTimeFormatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
        return dateTimeFormatter
    }()
    var tableDictionaryData: [[String: Any]] = [[String: Any]]()
    // Example array structure
    /*[
        [
            "title": "Select Date Picker",
            "type": DVAlertViewControllerCellType.Date.rawValue,
            "value": Date()
        ],
        [
            "title": "Select DateTime Picker",
            "type": DVAlertViewControllerCellType.DateTime.rawValue,
            "value": Date()
        ],
        [
            "title": "Select Picker",
            "type": DVAlertViewControllerCellType.Picker.rawValue,
            "options": ["Add", "Sub"],
            "selectedValue": "Sub"
        ]
    ]*/
    
    // End of table with dictionary
    
    fileprivate var inputFields: [AnyObject]?
    var inputFieldHeight: CGFloat = 30.0
    fileprivate var selectedTextView: UITextView?
    fileprivate var selectedTextField: UITextField?
    fileprivate var kbHeight: CGFloat = 0
    
    var hiddenControl: Bool = false{
        didSet{
            if self.hiddenControl{
                buttonsContainer.isHidden = true
                if contentViewBottomCns != nil{
                    containerView.needsUpdateConstraints()
                    containerView.addConstraint(contentViewBottomCns!)
                    self.containerView.layoutIfNeeded()
                }
            }else{
                buttonsContainer.isHidden = false
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
                toolbar.isHidden = true
                if contentViewTopCns != nil{
                    containerView.needsUpdateConstraints()
                    containerView.addConstraint(contentViewTopCns!)
                    self.containerView.layoutIfNeeded()
                }
            }else{
                toolbar.isHidden = false
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
    
    fileprivate var contentViewTopCns: NSLayoutConstraint?
    fileprivate var contentViewBottomCns: NSLayoutConstraint?
    
    fileprivate var fromView: UIView?
    fileprivate var fromViewPoint: CGPoint?
    
    fileprivate var shouldShowInCenterY: Bool = true
    fileprivate var shouldShowInTop: Bool = false
    fileprivate var shouldShowInBottom: Bool = false
    fileprivate var shouldShowInLeft: Bool = false
    fileprivate var shouldShowInRigth: Bool = false
    fileprivate var fromViewHeight: CGFloat = 0
    fileprivate var fromViewWidth: CGFloat = 0
    
    var cancelBlock : (() -> Void)?
    var doneBlock : ((_ index: Int?) -> Void)?
    
    var statusBarStyle: UIStatusBarStyle?{
        didSet{
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var preferredStatusBarStyle : UIStatusBarStyle {
        if statusBarStyle != nil{
            return statusBarStyle!
        }
        return parentController.preferredStatusBarStyle
    }
    
    var statusBarHidden: Bool = false{
        didSet{
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    override var prefersStatusBarHidden: Bool{
        return statusBarHidden
    }
    
    convenience init(parentController: UIViewController, popoverView: UIView, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil){
        self.init()
        
        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        self.parentController = parentController
        self.popoverVC = nil
        self.popoverView = popoverView
        self.style = style
        self.contentSize = contentSize != nil ? contentSize : self.isPad() ? CGSize(width: 400, height: 300) : CGSize(width: 280, height: 220)
        
        self.view.isUserInteractionEnabled = true
        self.view.isMultipleTouchEnabled = true
        
        self.createPopupContents()
    }
    
    convenience init(parentController: UIViewController, popoverVC: UIViewController?, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil){
        self.init()
        
        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        self.parentController = parentController
        self.popoverVC = popoverVC
        self.style = style
        self.contentSize = contentSize != nil ? contentSize : self.isPad() ? CGSize(width: 400, height: 300) : CGSize(width: 280, height: 220)
        
        self.view.isUserInteractionEnabled = true
        self.view.isMultipleTouchEnabled = true
        
        self.createPopupContents()
    }
    
    convenience init(inputFields: [AnyObject], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil) {
        
        self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize)
        
        self.inputFields = inputFields
    }
    
    convenience init(parentController: UIViewController, popoverVC: UIViewController?, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView){
        self.init()
        
        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        self.parentController = parentController
        self.popoverVC = popoverVC
        self.style = style
        self.contentSize = contentSize != nil ? contentSize : self.isPad() ? CGSize(width: 400, height: 300) : CGSize(width: 280, height: 220)
        self.fromView = fromView
        
        self.view.isUserInteractionEnabled = true
        self.view.isMultipleTouchEnabled = true
        
        self.createPopupContents()
    }
    
    convenience init(parentController: UIViewController, popoverVC: UIViewController?, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromPoint: CGPoint){
        self.init()
        
        self.modalPresentationStyle = UIModalPresentationStyle.overCurrentContext
        self.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        
        self.parentController = parentController
        self.popoverVC = popoverVC
        self.style = style
        self.contentSize = contentSize != nil ? contentSize : self.isPad() ? CGSize(width: 400, height: 300) : CGSize(width: 280, height: 220)
        self.fromViewPoint = fromPoint
        //DVPrint(fromViewPoint)
        self.view.isUserInteractionEnabled = true
        self.view.isMultipleTouchEnabled = true
        
        self.createPopupContents()
    }
    
    convenience init(title: String, message: String, parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil){
        
        let messageLabel = UILabel()
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 15.0)
        messageLabel.textColor = UIColor.black
        messageLabel.text = message
        
        let messageLabelHeight: CGFloat = messageLabel.sizeThatFits(CGSize(width: (280 - 16), height: CGFloat(MAXFLOAT))).height
        
        let newContentSize: CGSize = contentSize != nil ?  contentSize! : CGSize(width: 280, height: 100 + messageLabelHeight)
        
        self.init(parentController: parentController, popoverView: messageLabel, style: style, contentSize: newContentSize)
     
        self.title = title
        self.messageLabel = messageLabel
        
        for cns in containerView.constraints{
            if (cns.firstItem as? NSObject == toolbar && cns.secondItem as? NSObject == contentView) || (cns.firstItem as? NSObject == contentView && cns.secondItem as? NSObject == toolbar){
                cns.constant = 0
                break
            }
        }
    }
    
    convenience init(title: String, parentController: UIViewController, popoverVC: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView){
        
        self.init(parentController: parentController, popoverVC: popoverVC, style: style, contentSize: contentSize, fromView: fromView)
        
        self.title = title
    }
    
    convenience init(data: [String], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView? = nil) {
        if fromView != nil{
            self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromView: fromView!)
        }else{
            self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize)
        }
        
        self.tableData = data
    }
    
    convenience init(data: [[String: Any]], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromView: UIView? = nil) {
        if fromView != nil{
            self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromView: fromView!)
        }else{
            self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize)
        }
        
        self.tableDictionaryData = data
    }
    
    convenience init(data: [String], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromPoint: CGPoint) {
        
        self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromPoint: fromPoint)
        
        self.tableData = data
    }
    
    convenience init(data: [[String: Any]], parentController: UIViewController, style: DVAlertViewControllerStyle, contentSize: CGSize? = nil, fromPoint: CGPoint? = nil) {
        if fromPoint != nil{
            self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize, fromPoint: fromPoint!)
        }else{
            self.init(parentController: parentController, popoverVC: nil, style: style, contentSize: contentSize)
        }
        
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
    // datepicker
    convenience init(title: String, selectedDate: Date?, minimumDate: Date?, maximumDate: Date?, minuteInterval: Int? = nil, datePickerMode: UIDatePickerMode?, parentController: UIViewController){
        self.init(parentController: parentController, popoverVC: nil, style: DVAlertViewControllerStyle.datePicker, contentSize: nil)
        
        self.title = title
        if selectedDate != nil{
            self.selectedDate = selectedDate!
        }
        if datePickerMode != nil{
            self.datePickerMode = datePickerMode!
        }
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        self.minuteInterval = minuteInterval
    }
    // picker
    convenience init(title: String, pickerData: [String], selectedIndex: Int?, parentController: UIViewController){
        self.init(parentController: parentController, popoverVC: nil, style: DVAlertViewControllerStyle.picker, contentSize: nil)
        
        self.title = title
        self.pickerDataValues = pickerData
        self.selectedPickerIndex = selectedIndex
        if selectedIndex == nil{
            self.selectedPickerIndex = 0
        }
        if selectedIndex == nil{
            selectedPickerValue = pickerData[self.selectedPickerIndex!]
        }
    }
    
    func createPopupContents(){
        self.view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        
        var height: CGFloat = self.contentSize != nil ? self.contentSize!.height + (contentViewPadding * 2) : actionSheetHeight + (contentViewPadding * 2)
        
        if (fromViewPoint != nil || fromView != nil) && height >= parentController.view.bounds.size.height - 110{
           height = parentController.view.bounds.size.height - 150
        }
        
        var width: CGFloat = self.contentSize != nil ? self.contentSize!.width : 280
        
        if width >= parentController.view.bounds.size.width{
            width = parentController.view.bounds.size.width - 20
        }
        if self.style == DVAlertViewControllerStyle.actionSheet || self.style == DVAlertViewControllerStyle.datePicker || self.style == DVAlertViewControllerStyle.picker{
            height = self.contentSize != nil ? self.contentSize!.height + (contentViewPadding * 2) : actionSheetHeight + (contentViewPadding * 2)
            width = UIScreen.main.bounds.width
        }
        
        containerViewHeight = height
        contentSize = CGSize(width: width, height: height)
        //DVPrint("fromViewPoint before = \(fromViewPoint)")
        if let pvc: UIViewController = fromView?.parentViewController{
            fromViewPoint = pvc.view.convert(CGPoint(x: 0, y: 0), from: fromView)
        }
        //DVPrint("fromViewPoint after = \(fromViewPoint)")
        
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
        
        if UIApplication.shared.userInterfaceLayoutDirection == UIUserInterfaceLayoutDirection.rightToLeft || Locale.preferredLanguages[0].hasPrefix("ar"){
            shouldShowInCenterY = true
        }
        
        if shouldShowInCenterY{
            shouldShowInRigth = false
            shouldShowInLeft = false
        }
        
        //DVPrint("fromViewPoint after = \(fromViewPoint)")
        //DVPrint("shouldShowInCenterY = \(shouldShowInCenterY)")
        //DVPrint("shouldShowInBottom = \(shouldShowInBottom)")
        //DVPrint("shouldShowInTop = \(shouldShowInTop)")
        //DVPrint("shouldShowInLeft = \(shouldShowInLeft)")
        //DVPrint("shouldShowInRigth = \(shouldShowInRigth)")
        
        // create container view
        containerView = UIView()
        containerView.backgroundColor = UIColor.white
        if self.style == DVAlertViewControllerStyle.popup{
            containerView.layer.cornerRadius = 4
        }
        containerView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(containerView)
        
        // containerView constraints
        containerViewHeightCns = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: height)
        self.view.addConstraint(containerViewHeightCns)
        let centerX: NSLayoutConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0)
        self.view.addConstraint(centerX)
        
        if self.style == DVAlertViewControllerStyle.popup{
            self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: width))
            if shouldShowInCenterY{
                let centerYCns: NSLayoutConstraint = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0)
                centerYCns.priority = UILayoutPriority(rawValue: 750)
                self.view.addConstraint(centerYCns)
            }else if shouldShowInBottom{
                //DVPrint("bottom")
                self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: (fromViewPoint!.y + fromViewHeight + 10)))
                
            }else if shouldShowInTop{
                //DVPrint("top")
                self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: (fromViewPoint!.y - (height + 5))))
            }
            
            if shouldShowInRigth{
                self.view.removeConstraint(centerX)
                self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: (parentController.view.bounds.size.width - (width + 10))))
            }else if shouldShowInLeft{
                self.view.removeConstraint(centerX)
                //DVPrint("shouldShowInLeft = \(shouldShowInLeft)")
                
                var constant: CGFloat = fromViewPoint!.x - 10
                if fromView != nil && fromViewPoint!.x < 15{
                    constant = fromViewPoint!.x + (fromView!.frame.size.width / 2) - 10
                }
                
                //DVPrint("constant = \(constant)")
                self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: constant))
            }
        }else if self.style == DVAlertViewControllerStyle.actionSheet || self.style == DVAlertViewControllerStyle.datePicker || self.style == DVAlertViewControllerStyle.picker{
            self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
            self.view.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: self.view, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0))
            
            actionSheetBottomConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: -height)
            self.view.addConstraint(actionSheetBottomConstraint)
        }
        
        // toolbar
        toolbar = UIView()
        //toolbar.backgroundColor = UIColor.purpleColor()
        toolbar.clipsToBounds = true
        toolbar.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(toolbar)
        
        // toolbar constraints
        containerView.addConstraint(NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: toolbar, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0))
        containerView.addConstraint(NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 44))
        
        // titleLabel
        titleLabel = UILabel()
        //titleLabel.backgroundColor = UIColor.grayColor()
        titleLabel.text = self.title
        titleLabel.textAlignment = NSTextAlignment.center
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        toolbar.addSubview(titleLabel)
        
        // titleLable constraints
        toolbar.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.equal, toItem: toolbar, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0))
        toolbar.addConstraint(NSLayoutConstraint(item: titleLabel, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: toolbar, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
        
        // bottom buttons container
        buttonsContainer = UIView()
        let borderView: UIView = UIView()
        
        if self.style == DVAlertViewControllerStyle.popup{
            //buttonsContainer.backgroundColor = UIColor.grayColor()
            buttonsContainer.translatesAutoresizingMaskIntoConstraints = false
            
            containerView.addSubview(buttonsContainer)
            
            containerView.addConstraint(NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 41))
            containerView.addConstraint(NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
            containerView.addConstraint(NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0))
            containerView.addConstraint(NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            
            borderView.backgroundColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1)
            borderView.translatesAutoresizingMaskIntoConstraints = false
            
            buttonsContainer.addSubview(borderView)
            
            buttonsContainer.addConstraint(NSLayoutConstraint(item: borderView, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 1))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: borderView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: borderView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: borderView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 0))
        }
        
        cancelButton = UIButton()
        //cancelButton.backgroundColor = UIColor.redColor()
        cancelButton.setTitle(cancelTitle, for: UIControlState())
        cancelButton.setTitleColor(UIColor(hex: "616161"), for: UIControlState())
        cancelButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        if self.style == DVAlertViewControllerStyle.popup{
            cancelButton.setBackgroundImage(UIColor.imageWithColor(UIColor(hex: "dfdfe2"), size: nil), for: UIControlState.highlighted)
            buttonsContainer.addSubview(cancelButton)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(260 * Int64(NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)){
                let bottomLeftBorder: UIBezierPath = UIBezierPath(roundedRect: self.cancelButton.bounds, byRoundingCorners: UIRectCorner.bottomLeft, cornerRadii: CGSize(width: 4,height: 4))
                let cancelButtonMask: CAShapeLayer = CAShapeLayer()
                cancelButtonMask.frame = self.cancelButton.bounds
                cancelButtonMask.path = bottomLeftBorder.cgPath
                self.cancelButton.layer.mask = cancelButtonMask
            }
        }else if self.style == DVAlertViewControllerStyle.actionSheet || self.style == DVAlertViewControllerStyle.datePicker || self.style == DVAlertViewControllerStyle.picker{
            cancelButton.setTitleColor(UIColor(hex: "8a8a8a"), for: UIControlState.highlighted)
            cancelButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.left
            toolbar.addSubview(cancelButton)
        }
        cancelButton.addTarget(self, action: #selector(DVAlertViewController.cancelTap(_:)), for: .touchUpInside)
        
        createButton = UIButton()
        //createButton.backgroundColor = UIColor.redColor()
        createButton.setTitle(doneTitle, for: UIControlState())
        createButton.setTitleColor(UIColor(hex: "34bdf5"), for: UIControlState())
        createButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        createButton.translatesAutoresizingMaskIntoConstraints = false
        if self.style == DVAlertViewControllerStyle.popup{
            createButton.setBackgroundImage(UIColor.imageWithColor(UIColor(hex: "dfdfe2"), size: nil), for: UIControlState.highlighted)
            buttonsContainer.addSubview(createButton)
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(260 * Int64(NSEC_PER_MSEC)) / Double(NSEC_PER_SEC)){
                let bottomRightBorder: UIBezierPath = UIBezierPath(roundedRect: self.createButton.bounds, byRoundingCorners: UIRectCorner.bottomRight, cornerRadii: CGSize(width: 4,height: 4))
                let createButtonMask: CAShapeLayer = CAShapeLayer()
                createButtonMask.frame = self.createButton.bounds
                createButtonMask.path = bottomRightBorder.cgPath
                self.createButton.layer.mask = createButtonMask
            }
        }else if self.style == DVAlertViewControllerStyle.actionSheet || self.style == DVAlertViewControllerStyle.datePicker || self.style == DVAlertViewControllerStyle.picker{
            createButton.setTitleColor(UIColor(hex: "6bc8ee"), for: UIControlState.highlighted)
            createButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.right
            toolbar.addSubview(createButton)
        }
        createButton.addTarget(self, action: #selector(DVAlertViewController.createTap(_:)), for: .touchUpInside)
        
        if self.style == DVAlertViewControllerStyle.popup{
            let buttonSeperatorBorder: UIView = UIView()
            buttonSeperatorBorder.backgroundColor = UIColor(red: 200/255, green: 199/255, blue: 204/255, alpha: 1)
            buttonSeperatorBorder.translatesAutoresizingMaskIntoConstraints = false
            buttonsContainer.addSubview(buttonSeperatorBorder)
            
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 40))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.width, multiplier: 0.5, constant: -0.5))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: borderView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 40))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.width, multiplier: 0.5, constant: -0.5))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: borderView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: buttonsContainer, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            
            buttonsContainer.addConstraint(NSLayoutConstraint(item: buttonSeperatorBorder, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 1))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: buttonSeperatorBorder, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: borderView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: buttonSeperatorBorder, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: buttonsContainer, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 0))
            buttonsContainer.addConstraint(NSLayoutConstraint(item: buttonSeperatorBorder, attribute: NSLayoutAttribute.centerX, relatedBy: NSLayoutRelation.greaterThanOrEqual, toItem: buttonsContainer, attribute: NSLayoutAttribute.centerX, multiplier: 1.0, constant: 0))
        }else if self.style == DVAlertViewControllerStyle.actionSheet || self.style == DVAlertViewControllerStyle.datePicker || self.style == DVAlertViewControllerStyle.picker{
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 30))
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 70))
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: toolbar, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
            
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: toolbar, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: 8))
            toolbar.addConstraint(NSLayoutConstraint(item: cancelButton, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: titleLabel, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: -8))
            
            toolbar.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: 30))
            toolbar.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.width, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.width, multiplier: 1.0, constant: 70))
            toolbar.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: toolbar, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
            
            toolbar.addConstraint(NSLayoutConstraint(item: createButton, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: titleLabel, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 8))
            toolbar.addConstraint(NSLayoutConstraint(item: toolbar, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: createButton, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: 8))
        }
        
        contentView = UIView()
        contentView.backgroundColor = UIColor.clear
        //contentView.backgroundColor = UIColor.greenColor()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(contentView)
        
        containerView.addConstraint(NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.leading, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.leading, multiplier: 1.0, constant: contentViewPadding))
        containerView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.trailing, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.trailing, multiplier: 1.0, constant: contentViewPadding))
        let cns1 = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: toolbar, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 8)
        cns1.priority = UILayoutPriority(rawValue: 750)
        containerView.addConstraint(cns1)
        
        let cns2 = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: contentViewPadding)
        cns2.priority = UILayoutPriority(rawValue: 750)
        containerView.addConstraint(cns2)
        
        contentViewTopCns = NSLayoutConstraint(item: contentView, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: containerView, attribute: NSLayoutAttribute.top, multiplier: 1.0, constant: 8)
        contentViewTopCns?.priority = UILayoutPriority(rawValue: 1000)
        
        if self.style == DVAlertViewControllerStyle.popup{
            let cns3 = NSLayoutConstraint(item: buttonsContainer, attribute: NSLayoutAttribute.top, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: contentViewPadding)
            cns3.priority = UILayoutPriority(rawValue: 750)
            containerView.addConstraint(cns3)
            
            let cns4 = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: contentViewPadding)
            cns4.priority = UILayoutPriority(rawValue: 750)
            containerView.addConstraint(cns4)
            
            contentViewBottomCns = NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: 8)
            contentViewBottomCns?.priority = UILayoutPriority(rawValue: 1000)
        }else if self.style == DVAlertViewControllerStyle.actionSheet{
            containerView.addConstraint(NSLayoutConstraint(item: containerView, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: contentView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: contentViewPadding))
        }
        
        if fromViewPoint != nil{
            hiddenControl = true
            hiddenToolbar = true
            /*buttonsContainer.removeFromSuperview()
            toolbar.removeFromSuperview()*/
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch: UITouch = touches.first{
            if shouldDismissOnEmptyAreaTap{
                let location = touch.location(in: self.view)
                let fingerRect: CGRect = CGRect(x: location.x-5, y: location.y-5, width: 10, height: 10)
                if !fingerRect.intersects(containerView.frame){
                    if (tableData.count > 0 || tableDictionaryData.count > 0) && shouldReturnSelectionOnDismiss{
                        self.createButton.sendActions(for: UIControlEvents.touchUpInside)
                    }else if shouldDismissOnEmptyAreaTap{
                        self.cancelButton.sendActions(for: UIControlEvents.touchUpInside)
                    }
                }
            }
        }
    }
    
    @objc func cancelTap(_ sender: AnyObject){
        if self.cancelBlock != nil{
            self.cancelBlock?()
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc func createTap(_ sender: AnyObject){
        if self.doneBlock != nil{
            if tableData.count > 0 && selectedIndexPath != nil{
                self.doneBlock?((selectedIndexPath as IndexPath?)?.row)
            }else{
                self.doneBlock?(nil)
            }
            self.hide()
        }else{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func show(){
        if popoverVC != nil{
            popoverVC.view.frame = contentView.bounds
            contentView.addSubview(popoverVC.view)
            
            self.addChildViewController(popoverVC)
            popoverVC.didMove(toParentViewController: self)
        }else if popoverView != nil{
            popoverView!.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(popoverView!)
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[popoverView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["popoverView": popoverView!]))
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[popoverView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["popoverView": popoverView!]))
        }else if tableData.count > 0 || tableDictionaryData.count > 0{
            tableView = UITableView(frame: self.contentView.bounds)
            //tableView.backgroundColor = UIColor.redColor()
            tableView?.delegate = self
            tableView?.dataSource = self
            tableView?.separatorStyle = .none
            self.updateTableScrollEnabled()
            tableView?.translatesAutoresizingMaskIntoConstraints = false
            self.contentView.addSubview(tableView!)
            
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[table]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["table": tableView!]))
            self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[table]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["table": tableView!]))
        }else if inputFields != nil{
            var contentViewHeight: CGFloat = CGFloat(inputFields!.count) * inputFieldHeight
            var topView: UIView? = nil
            for (index, field) in inputFields!.enumerated(){
                if field.isKind(of: UITextField.self) || field.isKind(of: UITextView.self){
                    var textField: UIView!
                    
                    if let textfield: UITextField = field as? UITextField{
                        textfield.delegate = self
                        textfield.tag = index
                        textfield.returnKeyType = index < inputFields!.count - 1 ? UIReturnKeyType.next : UIReturnKeyType.done
                        textField = textfield
                    }else if let textView: UITextView = field as? UITextView{
                        textView.delegate = self
                        textField = textView
                    }
                    
                    textField.translatesAutoresizingMaskIntoConstraints = false
                    contentView.addSubview(textField)
                    
                    self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[textField]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["textField": textField]))
                    
                    if inputFields?.count == 1{
                        self.contentView.addConstraint(NSLayoutConstraint(item: textField, attribute: NSLayoutAttribute.height, relatedBy: NSLayoutRelation.equal, toItem: nil, attribute: NSLayoutAttribute.height, multiplier: 1.0, constant: inputFieldHeight))
                        self.contentView.addConstraint(NSLayoutConstraint(item: textField, attribute: NSLayoutAttribute.centerY, relatedBy: NSLayoutRelation.equal, toItem: self.contentView, attribute: NSLayoutAttribute.centerY, multiplier: 1.0, constant: 0))
                    }else{
                        if topView == nil{
                            if index < inputFields!.count - 1{
                                self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[textField(height)]", options: NSLayoutFormatOptions(), metrics: ["height": inputFieldHeight], views: ["textField": textField]))
                            }else{
                                self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[textField(height)]-(>=0)-|", options: NSLayoutFormatOptions(), metrics: ["height": inputFieldHeight], views: ["textField": textField]))
                            }
                        }else{
                            if index < inputFields!.count - 1{
                                self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[topView]-0-[textField(height)]", options: NSLayoutFormatOptions(), metrics: ["height": inputFieldHeight], views: ["textField": textField, "topView": topView!]))
                            }else{
                                self.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:[topView]-0-[textField(height)]-(>=0)-|", options: NSLayoutFormatOptions(), metrics: ["height": inputFieldHeight], views: ["textField": textField, "topView": topView!]))
                            }
                        }
                    }
                    
                    topView = textField
                }
            }
            
            
            
            if !hiddenControl && !hiddenToolbar{
                contentViewHeight = contentViewHeight + 81.0 + (contentViewPadding * 2)
            }else if !hiddenControl || !hiddenToolbar{
                contentViewHeight = contentViewHeight + 41.0 + (contentViewPadding * 2)
            }else if hiddenControl && hiddenToolbar{
                contentViewHeight = contentViewHeight + (contentViewPadding * 2)
            }
            
            if contentViewHeight > contentSize?.height{
                self.view.needsUpdateConstraints()
                containerViewHeightCns.constant = contentViewHeight
                self.view.layoutIfNeeded()
            }
        }else if self.style == .datePicker{
            let datepicker: UIDatePicker = UIDatePicker()
            //datepicker.setValue(UIFont.systemFontOfSize(14), forKey: "font")
            //datepicker.setValue(UIColor.redColor(), forKey: "textColor")
            datepicker.datePickerMode = UIDatePickerMode.date
            datepicker.datePickerMode = self.datePickerMode
            datepicker.minimumDate = self.minimumDate
            datepicker.maximumDate = self.maximumDate
            if minuteInterval != nil{
                datepicker.minuteInterval = minuteInterval!
            }
            datepicker.date = Date()
            datepicker.date = self.selectedDate
            
            datepicker.addTarget(self, action: #selector(actionDatePickerValueChange(_:)), for: UIControlEvents.valueChanged)
            
            contentView.addSubview(datepicker)
            datepicker.translatesAutoresizingMaskIntoConstraints = false
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[datepicker]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["datepicker": datepicker]))
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[datepicker]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["datepicker": datepicker]))
        }else if self.style == .picker{
            let pickerView: UIPickerView = UIPickerView()
            pickerView.delegate = self
            pickerView.dataSource = self
            if selectedPickerIndex != nil{
                pickerView.selectRow(selectedPickerIndex!, inComponent: 0, animated: false)
            }
            
            
            pickerView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(pickerView)
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pickerView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["pickerView": pickerView]))
            contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pickerView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["pickerView": pickerView]))
        }
        
        if self.style == DVAlertViewControllerStyle.popup{
            var shouldAnimate: Bool = true
            if !self.shouldShowInCenterY{
                containerView.alpha = 0
                shouldAnimate = false
            }
            parentController.present(self, animated: shouldAnimate){ () -> Void in
                if !self.shouldShowInCenterY{
                    if self._bgLayer != nil{
                        self._bgLayer.removeFromSuperlayer()
                    }else{
                        self._bgLayer = CAShapeLayer()
                    }
                    var centerX: CGFloat = self.fromViewPoint!.x
                    centerX = self.fromViewPoint!.x - self.view.convert(CGPoint(x: 0, y: 0), from: self.containerView).x
                    //DVPrint("centerX = \(centerX)")
                    if self.fromView != nil{
                        if self.contentSize?.width <= centerX + self.fromViewWidth/2 + 10{
                            centerX = centerX + self.contentSize!.width/2 - 5
                        }else{
                            centerX = centerX + self.fromViewWidth/2
                        }
                    }
                    //DVPrint("centerX1 = \(centerX)")
                    var path: CGPath = self.newBubble(CGPoint(x: centerX - 5, y: 0), y: CGPoint(x: centerX + 5, y: 0), z: CGPoint(x: centerX, y: -10))
                    if self.shouldShowInTop{
                        path = self.newBubble(CGPoint(x: centerX - 5, y: self.containerView.frame.size.height), y: CGPoint(x: centerX + 5, y: self.containerView.frame.size.height), z: CGPoint(x: centerX, y: self.containerView.frame.size.height + 10))
                    }
                    //DVPrint("shouldShowInLeft = \(self.shouldShowInLeft)")
                    //DVPrint("shouldShowInRigth = \(self.shouldShowInRigth)")
                    self._bgLayer.path = path
                    
                    self._bgLayer.fillColor = UIColor.white.cgColor
                    
                    
                    
                    self.containerView.layer.insertSublayer(self._bgLayer, at: 0)
                }
                UIView.animate(withDuration: 0.25, animations: { 
                    self.containerView.alpha = 1
                })
            }
        }else if self.style == DVAlertViewControllerStyle.actionSheet || self.style == DVAlertViewControllerStyle.datePicker || self.style == DVAlertViewControllerStyle.picker{
            parentController.present(self, animated: false) { () -> Void in
                self.view.needsUpdateConstraints()
                self.actionSheetBottomConstraint.constant = 0
                UIView.animate(withDuration: 0.2, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }
        }
    }
    
    func hide(_ animation: Bool? = false){
        if self.style == .actionSheet || self.style == .datePicker{
            self.view.needsUpdateConstraints()
            self.actionSheetBottomConstraint.constant = -(self.contentSize != nil ? self.contentSize!.height + (contentViewPadding * 2) : actionSheetHeight + (contentViewPadding * 2))
            UIView.animate(withDuration: 0.2, animations: {
                self.view.layoutIfNeeded()
                }, completion: { (finished: Bool) in
                    self.dismiss(animated: false, completion: nil)
            })
        }else{
            UIView.animate(withDuration: 0.2, animations: { () -> Void in
                self.view.alpha = 0
                }, completion: { (success: Bool) -> Void in
                    self.dismiss(animated: animation!, completion: nil)
            })
        }
    }
    
    
    func updateTableScrollEnabled(){
        if !hiddenControl && !hiddenToolbar{
            //DVPrint("here !! = \(contentSize!.height - CGFloat(96.0)), \(CGFloat(CGFloat(tableData.count) * tableRowHeight))")
            if contentSize!.height - CGFloat(96.0) >= CGFloat(CGFloat(tableData.count) * tableRowHeight){
                tableView?.isScrollEnabled = false
            }else{
                tableView?.isScrollEnabled = true
            }
        }else if !hiddenControl || !hiddenToolbar{
            //DVPrint("here ! = \(contentSize!.height - CGFloat(48.0)), \(CGFloat(CGFloat(tableData.count) * tableRowHeight))")
            if contentSize!.height - CGFloat(48.0) >= CGFloat(CGFloat(tableData.count) * tableRowHeight){
                tableView?.isScrollEnabled = false
            }else{
                tableView?.isScrollEnabled = true
            }
        }else if hiddenControl && hiddenToolbar{
            //DVPrint("here && = \(contentSize!.height - CGFloat(16.0)), \(CGFloat(CGFloat(tableData.count) * tableRowHeight))")
            if contentSize!.height - (contentViewPadding * 2) >= CGFloat(CGFloat(tableData.count) * tableRowHeight){
                tableView?.isScrollEnabled = false
            }else{
                tableView?.isScrollEnabled = true
            }
        }
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    @objc func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableDictionaryData.count > 0{
            if self.pickerIndexPath != nil{
                // we have a date picker, so allow for it in the number of rows in this section
                return tableDictionaryData.count + 1
            }
            return tableDictionaryData.count
        }
        return tableData.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if pickerIndexPath == indexPath{
            return self.pickerCellRowHeight
        }
        return tableRowHeight
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell: UITableViewCell?
        
        if tableDictionaryData.count > 0{
            var cellData: [String: Any]!
            
            if (indexPath as NSIndexPath).row < tableDictionaryData.count{
                cellData = tableDictionaryData[indexPath.row]
            }
            
            if pickerIndexPath?.section == indexPath.section && indexPath.row >= pickerIndexPath?.row{
                cellData = tableDictionaryData[indexPath.row - 1]
            }
            
            let cellType: Int? = cellData["type"] as? Int
            
            if pickerIndexPath != nil{
                if cellType == DVAlertViewControllerCellType.date.rawValue || cellType == DVAlertViewControllerCellType.dateTime.rawValue{
                    var datePickerCell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "datePicker")
                    if datePickerCell == nil{
                        datePickerCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "datePicker")
                        let datepicker: UIDatePicker = UIDatePicker()
                        //datepicker.setValue(UIFont.systemFontOfSize(14), forKey: "font")
                        //datepicker.setValue(UIColor.redColor(), forKey: "textColor")
                        datepicker.datePickerMode = UIDatePickerMode.date
                        if cellType == DVAlertViewControllerCellType.dateTime.rawValue{
                            datepicker.datePickerMode = UIDatePickerMode.dateAndTime
                        }
                        
                        datepicker.date = Date()
                        if let date: Date = cellData["value"] as? Date{
                            datepicker.date = date
                        }
                        datepicker.addTarget(self, action: #selector(datePickerValueChanged(_:)), for: UIControlEvents.valueChanged)
                        
                        datepicker.translatesAutoresizingMaskIntoConstraints = false
                        datePickerCell?.contentView.addSubview(datepicker)
                        datePickerCell!.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[datepicker]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["datepicker": datepicker]))
                        datePickerCell!.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[datepicker]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["datepicker": datepicker]))
                    }
                    
                    cell = datePickerCell
                }else if cellType == DVAlertViewControllerCellType.picker.rawValue{
                    var uiPickerCell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "uiPicker")
                    if uiPickerCell == nil{
                        uiPickerCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "uiPicker")
                        let pickerView: UIPickerView = UIPickerView()
                        
                        if let options: [String] = cellData["options"] as? [String]{
                            pickerDataValues = options
                            pickerView.delegate = self
                            pickerView.dataSource = self
                            
                            if let selectedValue: String = cellData["selectedValue"] as? String{
                                selectedPickerValue = selectedValue
                                pickerView.selectRow(pickerDataValues.index(of: selectedValue)!, inComponent: 0, animated: false)
                            }
                            
                        }
                        
                        
                        pickerView.translatesAutoresizingMaskIntoConstraints = false
                        uiPickerCell?.contentView.addSubview(pickerView)
                        uiPickerCell!.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[pickerView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["pickerView": pickerView]))
                        uiPickerCell!.contentView.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[pickerView]-0-|", options: NSLayoutFormatOptions(), metrics: nil, views: ["pickerView": pickerView]))
                    }
                    
                    cell = uiPickerCell
                }
            }else{
                if cellType == DVAlertViewControllerCellType.date.rawValue || cellType == DVAlertViewControllerCellType.dateTime.rawValue || cellType == DVAlertViewControllerCellType.picker.rawValue{
                    var pickerCell: UITableViewCell? = tableView.dequeueReusableCell(withIdentifier: "pickerCell")
                    
                    if pickerCell == nil{
                        pickerCell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "pickerCell")
                    }
                    
                    pickerCell?.textLabel?.text = cellData["title"] as? String
                    
                    if cellType == DVAlertViewControllerCellType.date.rawValue{
                        if let date: Date = cellData["value"] as? Date{
                            pickerCell?.textLabel?.text = self.dateFormatter.string(from: date)
                        }
                    }else if cellType == DVAlertViewControllerCellType.dateTime.rawValue{
                        if let date: Date = cellData["value"] as? Date{
                            pickerCell?.textLabel?.text = self.dateTimeFormatter.string(from: date)
                        }
                    }else if cellType == DVAlertViewControllerCellType.picker.rawValue{
                        if let selectedValue: String = cellData["selectedValue"] as? String{
                            pickerCell?.textLabel?.text = selectedValue
                        }
                    }
                    
                    cell = pickerCell
                }
            }
        }else{
            cell = tableView.dequeueReusableCell(withIdentifier: "cell")
            
            if cell == nil{
                cell = UITableViewCell(style: UITableViewCellStyle.default, reuseIdentifier: "cell")
            }
            cell?.textLabel?.text = tableData[(indexPath as NSIndexPath).row]
            cell?.textLabel?.font = tableCellFont
            cell?.textLabel?.textAlignment = textAllingment
            cell?.backgroundColor = .white
            
            cell?.selectionStyle = .none
            /*cell?.layoutMargins = UIEdgeInsetsZero
            cell?.preservesSuperviewLayoutMargins = false
            cell?.separatorInset = UIEdgeInsetsZero*/
        }
        
        if selectedIndexPath == indexPath && cell?.reuseIdentifier != "pickerCell"{
            if selectionColor != nil{
                cell?.textLabel?.font = tableCellSelectedFont
                cell?.backgroundColor = selectionColor
            }else{
                if tableCellSelectedAccessoryView != nil{
                    cell?.accessoryView = tableCellSelectedAccessoryView!
                }else{
                    cell?.accessoryType = .checkmark
                }
            }
        }else{
            if tableCellAccessoryView != nil{
                cell?.accessoryView = tableCellAccessoryView!
            }else{
                cell?.accessoryType = .none
            }
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        prevSelectedIndexPath = selectedIndexPath
        selectedIndexPath = indexPath
        
        let cell: UITableViewCell = tableView.cellForRow(at: indexPath) as UITableViewCell!
        
        if shouldReturnSelectionOnDismiss && cell.reuseIdentifier != "datepicker" && cell.reuseIdentifier != "pickerCell" && cell.reuseIdentifier != "uiPicker"{
            //DVPrint("here \(indexPath.row)")
            createButton.sendActions(for: UIControlEvents.touchUpInside)
            return
        }else{
            if prevSelectedIndexPath != nil{
                if let prevcell: UITableViewCell = tableView.cellForRow(at: prevSelectedIndexPath!) as UITableViewCell!{
                    if tableCellAccessoryView != nil{
                        cell.accessoryView = tableCellAccessoryView!
                    }else{
                        cell.accessoryType = .none
                    }
                    prevcell.backgroundColor = .white
                    prevcell.textLabel?.font = tableCellFont
                }
            }
            if cell.reuseIdentifier != "pickerCell"{
                if selectionColor != nil{
                    cell.textLabel?.font = tableCellSelectedFont
                    cell.backgroundColor = selectionColor
                }else{
                    if tableCellSelectedAccessoryView != nil{
                        cell.accessoryView = tableCellSelectedAccessoryView!
                    }else{
                        cell.accessoryType = .checkmark
                    }
                }
            }
        }
        
        
        if cell.reuseIdentifier == "pickerCell"{
            displayPicker(indexPath)
        }else{
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func displayPicker(_ indexPath: IndexPath){
        var shouldShowPicker: Bool = true
        //check if previously displayed picker is above selected indexPath
        var before: Bool = false
        // check for previusly displayed picker
        if self.pickerIndexPath != nil{
            before = (self.pickerIndexPath! as IndexPath).row < (indexPath as NSIndexPath).row
            //println("before picker delete")
            
            self.tableView?.beginUpdates()
            
            let nIndexPath: IndexPath = IndexPath(row: (self.pickerIndexPath! as NSIndexPath).row, section: (self.pickerIndexPath! as NSIndexPath).section)
            // if previously selected row match with current row
            if (self.pickerIndexPath! as IndexPath).row - 1 == (indexPath as NSIndexPath).row{
                shouldShowPicker = false
                //println("before same picker delete")
                self.pickerIndexPath = nil
                self.tableView?.deleteRows(at: [nIndexPath], with: UITableViewRowAnimation.fade)
            }else{
                //DVPrint("before different picker delete")
                self.pickerIndexPath = nil
                self.tableView?.deleteRows(at: [nIndexPath], with: UITableViewRowAnimation.fade)
            }
            self.tableView?.endUpdates()
            
            // println("after picker delete")
        }
        
        //println("before picker add")
        self.tableView?.beginUpdates()
        if shouldShowPicker{
            var nIndexPath: IndexPath = IndexPath(row: (indexPath as NSIndexPath).row + 1, section: (indexPath as NSIndexPath).section)
            self.pickerIndexPath = nIndexPath
            
            if before{
                nIndexPath = indexPath
                self.pickerIndexPath = indexPath
            }
            
            self.tableView?.insertRows(at: [nIndexPath], with: UITableViewRowAnimation.fade)
        }
        
        tableView?.deselectRow(at: indexPath, animated: true)
        self.tableView?.endUpdates()
    }
    
    
    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerDataValues.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerDataValues[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        selectedPickerValue = pickerDataValues[row]
        selectedPickerIndex = row
        
        if tableDictionaryData.count > 0{
            let indexPath: IndexPath = IndexPath(row: pickerIndexPath!.row - 1, section: pickerIndexPath!.section)
            var cellData: [String: Any] = tableDictionaryData[indexPath.row]
            cellData["selectedValue"] = selectedPickerValue!
            tableDictionaryData[indexPath.row] = cellData
            
            if let cell: UITableViewCell = tableView?.cellForRow(at: indexPath){
                cell.textLabel?.text = selectedPickerValue
            }
        }
    }
    
    @objc func datePickerValueChanged(_ sender: UIDatePicker) {
        var targetedCellIndexPath: IndexPath? = nil
        
        targetedCellIndexPath = IndexPath(row: (self.pickerIndexPath! as NSIndexPath).row - 1, section: (self.pickerIndexPath! as NSIndexPath).section)
        
        let cell: UITableViewCell = self.tableView?.cellForRow(at: targetedCellIndexPath!) as UITableViewCell!
        let targetedDatePicker: UIDatePicker = sender
        
        // update our data model
        var itemData: [String: Any] = self.tableDictionaryData[targetedCellIndexPath!.row]
        itemData["value"] = targetedDatePicker.date
        
        self.tableDictionaryData[targetedCellIndexPath!.row] = itemData
        
        if sender.datePickerMode == .dateAndTime{
            cell.textLabel?.text = self.dateTimeFormatter.string(from: targetedDatePicker.date)
        }else{
            cell.textLabel?.text = self.dateFormatter.string(from: targetedDatePicker.date)
        }
    }
    
    @objc func actionDatePickerValueChange(_ sender: UIDatePicker){
        self.selectedDate = sender.date
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        selectedTextField = textField
        
        if textField.keyboardType == .numberPad || textField.keyboardType == .phonePad || textField.keyboardType == .decimalPad{
            let keyboardDoneButtonView = UIToolbar()
            keyboardDoneButtonView.sizeToFit()
            
            // Setup the buttons to be put in the system.
            var item: UIBarButtonItem = UIBarButtonItem()
            item = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(onTextFieldDoneTap) )
            
            let flexSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
            let toolbarButtons = [flexSpace,item]
            
            //Put the buttons into the ToolBar and display the tool bar
            keyboardDoneButtonView.setItems(toolbarButtons, animated: true)
            textField.inputAccessoryView = keyboardDoneButtonView
        }
        
        return true
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.returnKeyType == .next{
            if let nextTextField: UITextField = textField.superview?.viewWithTag(textField.tag + 1) as? UITextField{
                nextTextField.becomeFirstResponder()
            }
        }else{
            textField.resignFirstResponder()
        }
        
        return false
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        if style == .actionSheet{
            actionSheetBottomConstraint.constant = 0
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func onTextFieldDoneTap(){
        selectedTextField?.resignFirstResponder()
    }
    
    // MARK: - UITextViewDelegate
    func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        selectedTextView = textView
        
        let keyboardDoneButtonView = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        
        // Setup the buttons to be put in the system.
        var item: UIBarButtonItem = UIBarButtonItem()
        item = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.plain, target: self, action: #selector(onTextViewDoneTap) )
        
        let flexSpace: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.flexibleSpace, target: nil, action: nil)
        let toolbarButtons = [flexSpace,item]
        
        //Put the buttons into the ToolBar and display the tool bar
        keyboardDoneButtonView.setItems(toolbarButtons, animated: true)
        textView.inputAccessoryView = keyboardDoneButtonView
        
        return true
    }
    
    @objc func onTextViewDoneTap(){
        selectedTextView?.resignFirstResponder()
    }
    
    // MARK: - UIVIewController Methods

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShowNotification(_:)), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHideNotification(_:)), name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: - keyboardWillShowNotification
    @objc func keyboardWillShowNotification(_ notification: Notification){
        if let value: NSValue = (notification as NSNotification).userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue{
            let rawFrame: CGRect = value.cgRectValue
            let keyboardFrame: CGRect = self.view.convert(rawFrame, from: nil)
            
            kbHeight = keyboardFrame.height
            //DVPrint("keyboardHieght: \(keyboardFrame.height)")
            
            if style == .actionSheet{
                self.view.needsUpdateConstraints()
                actionSheetBottomConstraint.constant = kbHeight
                UIView.animate(withDuration: 0.25, animations: { () -> Void in
                    self.view.layoutIfNeeded()
                })
            }else if style == .popup{
                let position: CGPoint = self.view.convert(CGPoint.zero, to: self.containerView)
                if self.view.frame.size.height - (abs(position.y) + self.containerView.frame.size.height) < kbHeight{
                    var shouldAddBottomCns: Bool = true
                    for cns in self.view.constraints{
                        if cns.identifier == "bottomCnsForInputs"{
                            shouldAddBottomCns = false
                        }
                    }
                    
                    if shouldAddBottomCns{
                        let bottomSpace: CGFloat = kbHeight
                        let bottomCns: NSLayoutConstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.bottom, relatedBy: NSLayoutRelation.equal, toItem: self.containerView, attribute: NSLayoutAttribute.bottom, multiplier: 1.0, constant: bottomSpace)
                        bottomCns.identifier = "bottomCnsForInputs"
                        self.view.needsUpdateConstraints()
                        self.view.addConstraint(bottomCns)
                        UIView.animate(withDuration: 0.25, animations: {
                            self.view.layoutIfNeeded()
                        })
                    }
                }
            }
        }
    }
    
    // MARK: - keyboardWillHideNotification
    @objc func keyboardWillHideNotification(_ notification: Notification){
        kbHeight = 0
        
        if style == .actionSheet{
            self.view.needsUpdateConstraints()
            actionSheetBottomConstraint.constant = kbHeight
            UIView.animate(withDuration: 0.25, animations: { () -> Void in
                self.view.layoutIfNeeded()
            })
        }else if style == .popup{
            self.view.needsUpdateConstraints()
            for cns in self.view.constraints{
                if cns.identifier == "bottomCnsForInputs"{
                    self.view.removeConstraint(cns)
                    break
                }
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: - isPhone
    func isPhone() -> Bool{
        return (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.phone ? true : false)
    }
    
    // MARK: - isPad
    func isPad() -> Bool{
        return (UIDevice.current.userInterfaceIdiom == UIUserInterfaceIdiom.pad ? true : false)
    }
    
    func isIphone4S() -> Bool{
        return UIScreen.main.bounds.size.height <= 480 ? true : false
    }
    
    // MARK: - Geometry
    func newBubble(_ x: CGPoint, y: CGPoint, z: CGPoint) -> CGPath{
        let path: CGMutablePath = CGMutablePath()
        path.move(to: x)
        path.addLine(to: y)
        path.addLine(to: z)
        path.addLine(to: x)
        /*CGPathMoveToPoint(path, nil, x.x, x.y)
        CGPathAddLineToPoint(path, nil, y.x, y.y)
        CGPathAddLineToPoint(path, nil, z.x, z.y)
        CGPathAddLineToPoint(path, nil, x.x, x.y)
        */
        
        path.closeSubpath()
        return path
    }
    
    func addBorder(_ view: UIView, edges: UIRectEdge, colour: UIColor = UIColor.white, thickness: CGFloat = 1) -> [UIView] {
        
        var borders = [UIView]()
        
        func border() -> UIView {
            let border = UIView(frame: CGRect.zero)
            border.backgroundColor = colour
            border.translatesAutoresizingMaskIntoConstraints = false
            return border
        }
        
        if edges.contains(.top) || edges.contains(.all) {
            let top = border()
            view.addSubview(top)
            view.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[top(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["top": top]))
            view.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[top]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["top": top]))
            borders.append(top)
        }
        
        if edges.contains(.left) || edges.contains(.all) {
            let left = border()
            view.addSubview(left)
            view.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[left(==thickness)]",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["left": left]))
            view.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[left]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["left": left]))
            borders.append(left)
        }
        
        if edges.contains(.right) || edges.contains(.all) {
            let right = border()
            view.addSubview(right)
            view.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:[right(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["right": right]))
            view.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:|-(0)-[right]-(0)-|",
                    options: [],
                    metrics: nil,
                    views: ["right": right]))
            borders.append(right)
        }
        
        if edges.contains(.bottom) || edges.contains(.all) {
            let bottom = border()
            view.addSubview(bottom)
            view.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "V:[bottom(==thickness)]-(0)-|",
                    options: [],
                    metrics: ["thickness": thickness],
                    views: ["bottom": bottom]))
            view.addConstraints(
                NSLayoutConstraint.constraints(withVisualFormat: "H:|-(0)-[bottom]-(0)-|",
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
            parentResponder = parentResponder!.next
            if let viewController = parentResponder as? UIViewController {
                return viewController
            }
        }
        return nil
    }
}
