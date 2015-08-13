//
//  PublishmentViewController.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 15/3/18.
//  Copyright (c) 2015年 Beijing Information Science and Technology University. All rights reserved.
//

import AFNetworking
import AssetsLibrary
import EAColourfulProgressView
import SVProgressHUD
import UIKit
import ZFTokenField

@objc protocol PublishmentViewControllerPresentable {
    var topics: Set<Topic> { get set }
    var title: String? { get set }
    var body: String? { get set }
    var attachmentKey: String? { get set }
    func post(#success: (() -> Void)?, failure: ((NSError) -> Void)?)
    func uploadImageWithJPEGData(jpegData: NSData, success: ((Int) -> Void)?, failure: ((NSError) -> Void)?) -> AFHTTPRequestOperation
}

extension Question: PublishmentViewControllerPresentable {}
extension Answer: PublishmentViewControllerPresentable {
    var topics: Set<Topic> {
        set {
            question?.topics = newValue
        }
        get {
            return question?.topics ?? Set()
        }
    }
}
extension Article: PublishmentViewControllerPresentable {}

@objc protocol PublishmentViewControllerDelegate: class {
    optional func publishmentViewControllerDidSuccessfullyPublishDataObject(publishmentViewController: PublishmentViewController)
}

class FFStepObject: Equatable {
    var image: UIImage? = nil
    var attachID: Int? = nil
    var text: String = ""
    var operation: AFHTTPRequestOperation? = nil
    var uploadingProgresses: Int = 0
    var uploaded: Bool = false {
        didSet {
            if uploaded {
                uploadingProgresses = FFStepObject.maxProgress
            }
        }
    }
    static let maxProgress = 1000
}

func ==(lhs: FFStepObject, rhs: FFStepObject) -> Bool {
    return lhs === rhs
}

class PublishmentViewController: UIViewController, ZFTokenFieldDataSource, ZFTokenFieldDelegate, UITableViewDelegate, UITableViewDataSource, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet weak var headerLabel: UILabel!
    @IBOutlet weak var publishButton: UIButton!
    @IBOutlet weak var dismissButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var tagsField: ZFTokenField?
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var titleField: UITextView?
    @IBOutlet weak var bodyField: UITextView!
    @IBOutlet weak var titleLabel: UILabel?
    @IBOutlet weak var tagsLabel: UILabel?
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var imagesLabel: UILabel!
    @IBOutlet weak var separatorA: UIView!
    @IBOutlet weak var separatorB: UIView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var reorderButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    typealias SelfType = PublishmentViewController
    
    var delegate: PublishmentViewControllerDelegate?
    
    var dataObject: PublishmentViewControllerPresentable! {
        didSet {
            if dataObject.attachmentKey == nil {
                dataObject.attachmentKey = "\(NSDate(timeIntervalSinceNow: 0).timeIntervalSince1970)".msr_MD5EncryptedString
            }
        }
    }
    
    static let cellReuseIdentifier = "FFPublishmentStepCell"
    static let imageViewTag = 23333
    static let progressViewTag = 23334
    static let buttonTag = 23335
    static let overlayViewTag = 23336
    static let maxImageSideLength: CGFloat = 1920
    static let imageCompressionQuality: CGFloat = 0.7
    
    var converting = false
    var tags = [String]()
    
    var steps = [FFStepObject()] // initialized with 1 step
    var currentStep: FFStepObject? = nil
    
    var currentTextView: UITextView?
    
    func cells(i: Int) -> FFPublishmentStepCell? {
        return tableView.cellForRowAtIndexPath(NSIndexPath(forRow: i, inSection: 0)) as? FFPublishmentStepCell
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let theme = SettingsManager.defaultManager.currentTheme
        view.backgroundColor = theme.backgroundColorA
        view.clipsToBounds = true
        for v in [UIView?](arrayLiteral: titleField, tagsField, bodyField) {
            v?.msr_borderColor = theme.borderColorA
            v?.backgroundColor = theme.backgroundColorB
        }
        headerLabel.textColor = theme.titleTextColor
        for v in [titleLabel, tagsLabel, descriptionLabel, imagesLabel] {
            v?.textColor = theme.subtitleTextColor
        }
        titleField?.textColor = theme.titleTextColor
        tagsField?.textField.textColor = theme.subtitleTextColor
        tagsField?.textField.font = UIFont.systemFontOfSize(14)
        bodyField.textColor = theme.bodyTextColor
        separatorA.backgroundColor = theme.borderColorA
        separatorB.backgroundColor = theme.borderColorA
        publishButton.addTarget(self, action: "publish", forControlEvents: .TouchUpInside)
        dismissButton.addTarget(self, action: "dismiss", forControlEvents: .TouchUpInside)
        reorderButton.backgroundColor = theme.backgroundColorB
        reorderButton.setTitleColor(theme.subtitleTextColor, forState: .Normal)
        addButton.backgroundColor = theme.backgroundColorB
        addButton.setTitleColor(theme.subtitleTextColor, forState: .Normal)
        publishButton.backgroundColor = theme.backgroundColorB
        publishButton.setTitleColor(theme.subtitleTextColor, forState: .Normal)
        for v in [reorderButton, addButton, publishButton, dismissButton] {
            v.msr_setBackgroundImageWithColor(theme.highlightColor, forState: .Highlighted)
            v.msr_borderColor = theme.borderColorA
        }
//        for v in [UITextInputTraits?](arrayLiteral: titleField, tagsField?.textField, bodyField) {
//            'v?.keyboardAppearance = theme.keyboardAppearance'
//            // 'Optional Protocol Setter Requirements' is not supported in Swift 1.2.
//            // See The Swift Programming Language book - Optional Protocol Requirements
//        }
        tagsField?.textField.keyboardAppearance = theme.keyboardAppearance
        for v in [UITextView?](arrayLiteral: titleField, bodyField) {
            v?.keyboardAppearance = theme.keyboardAppearance
        }
        scrollView.delaysContentTouches = false
        scrollView.scrollIndicatorInsets.top = 20
        scrollView.msr_setTouchesShouldCancel(true, inContentViewWhichIsKindOfClass: UIButton.self)
        let tap = UITapGestureRecognizer(target: self, action: "didTouchBlankArea")
        scrollView.addGestureRecognizer(tap)
        tableView.estimatedRowHeight = 200
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.registerNib(UINib(nibName: "FFPublishmentStepCell", bundle: NSBundle.mainBundle()), forCellReuseIdentifier: SelfType.cellReuseIdentifier)
        tableView.delaysContentTouches = false
        tableView.msr_wrapperView?.delaysContentTouches = false
        tableView.msr_setTouchesShouldCancel(true, inContentViewWhichIsKindOfClass: UIButton.self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
        tagsField?.reloadData()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        tableView.editing = false
    }
    
    // MARK: - ZFTokenFieldDataSource
    
    func lineHeightForTokenField(tokenField: ZFTokenField!) -> CGFloat {
        return 24
    }
    
    func numberOfTokensInTokenField(tokenField: ZFTokenField!) -> Int {
        return tags.count
    }
    
    func tokenField(tokenField: ZFTokenField!, viewForTokenAtIndex index: Int) -> UIView! {
        let tag = tags[index]
        let theme = SettingsManager.defaultManager.currentTheme
        let label = UILabel()
        label.text = tag
        label.textColor = theme.subtitleTextColor
        label.font = UIFont.systemFontOfSize(14)
        label.sizeToFit()
        label.frame.size.height = lineHeightForTokenField(tagsField)
        label.frame.size.width += 20
        label.textAlignment = .Center
        label.layer.masksToBounds = true
        label.layer.cornerRadius = 3
        label.backgroundColor = theme.backgroundColorA
        return label
    }
    
    // MARK: - ZFTokenFieldDelegate
    
    func tokenMarginForTokenField(tokenField: ZFTokenField!) -> CGFloat {
        return 5
    }
    
    func tokenField(tokenField: ZFTokenField!, didRemoveTokenAtIndex index: Int) {
        tags.removeAtIndex(index)
    }
    
    func tokenField(tokenField: ZFTokenField!, didReturnWithText text: String!) {
        tags.append(text)
        tokenField?.reloadData()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField === tagsField?.textField {
            if textField.text ?? "" == "" {
                return false
            }
            for tag in tags {
                if tag == textField.text {
                    return false
                }
            }
            return true
        }
        return true
    }
    
    func tokenFieldDidReloadData(tokenField: ZFTokenField!) {
        let theme = SettingsManager.defaultManager.currentTheme
        tagsField?.textField.attributedPlaceholder = NSAttributedString(string: tags.count > 0 ? "..." : "输入并以换行键添加，可添加多个", attributes: [NSForegroundColorAttributeName: theme.footnoteTextColor])
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return steps.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let step = steps[indexPath.row]
        let cell = tableView.dequeueReusableCellWithIdentifier(SelfType.cellReuseIdentifier, forIndexPath: indexPath) as! FFPublishmentStepCell
        cell.stepIndexLabel.text = "\(indexPath.row + 1)"
        cell.textView.delegate = self
        cell.titleImageButton.addTarget(self, action: "didPressUploadButton:", forControlEvents: .TouchUpInside)
        cell.update(step: step)
        return cell
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, editingStyleForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCellEditingStyle {
        return tableView.editing ? .None : .Delete
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        // Required to show the edit buttons. Don't remove and keep empty please.
    }
    
    func tableView(tableView: UITableView, moveRowAtIndexPath sourceIndexPath: NSIndexPath, toIndexPath destinationIndexPath: NSIndexPath) {
        var a = sourceIndexPath.row
        var b = destinationIndexPath.row
        cells(a)?.stepIndexLabel.text = "\(b + 1)"
        if a < b {
            for i in a + 1...b {
                cells(i)?.stepIndexLabel.text = "\(i)"
            }
        } else if a > b {
            for i in b...a - 1 {
                cells(i)?.stepIndexLabel.text = "\(i + 2)"
            }
        }
        let step = steps[a]
        steps.removeAtIndex(a)
        steps.insert(step, atIndex: b)
    }
    
    func tableView(tableView: UITableView, didEndEditingRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let deleteAction = UITableViewRowAction(style: .Default, title: "删除") {
            [weak self] action, indexPath in
            if let self_ = self {
                let rows = self_.tableView.numberOfRowsInSection(0)
                self_.tableView.beginUpdates()
                self_.steps[indexPath.row].operation?.cancel()
                self_.steps.removeAtIndex(indexPath.row)
                if indexPath.row < rows - 1 {
                    for i in indexPath.row + 1..<rows {
                        self_.cells(i)?.stepIndexLabel.text = "\(i)"
                    }
                }
                self_.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
                self_.tableView.endUpdates()
            }
            return
        }
        return [deleteAction]
    }
    
    func tableView(tableView: UITableView, shouldIndentWhileEditingRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
    // MARK: - UITextViewDelegate
    
    func textViewShouldBeginEditing(textView: UITextView) -> Bool {
        currentTextView = textView
        return true
    }
    
    func textViewDidBeginEditing(textView: UITextView) {
        scrollCursorToVisibleInTextView(textView)
    }
    
    func textViewDidChange(textView: UITextView) {
        if let indexPath = tableView.indexPathForRowAtPoint(textView.convertPoint(CGPointZero, toView: tableView)) {
            steps[indexPath.row].text = textView.text
        }
        tableView.beginUpdates()
        tableView.endUpdates()
        scrollCursorToVisibleInTextView(textView)
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [NSObject : AnyObject]) {
        SVProgressHUD.showWithMaskType(.Gradient)
        picker.dismissViewControllerAnimated(true, completion: nil)
        converting = true
        if let step = currentStep {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
                [weak self] in
                if let self_ = self {
                    var images = map([info[UIImagePickerControllerOriginalImage] as! UIImage]) {
                        (image: UIImage) -> UIImage in
                        let scale = min(1, min(SelfType.maxImageSideLength / image.size.width, SelfType.maxImageSideLength / image.size.height))
                        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                        return image.msr_imageOfSize(size)
                    }
                    var uploadingProgress = [0]
                    var uploaded = [false]
                    var attachIDs: [Int?] = [nil]
                    let jpegs = map(images) {
                        return UIImageJPEGRepresentation($0, SelfType.imageCompressionQuality)
                    }
                    dispatch_async(dispatch_get_main_queue()) {
                        [weak self] in
                        step.image = images.first!
                        step.uploadingProgresses = uploadingProgress.first!
                        step.attachID = attachIDs.first!
                        if let index = find(self_.steps, step) {
                            self_.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
                        }
                        for i in 0..<images.count {
                            let image = images[i]
                            let jpeg = jpegs[i]
                            let operation = self_.dataObject.uploadImageWithJPEGData(jpeg,
                                success: {
                                    attachID in
                                    step.attachID = attachID
                                    return
                                },
                                failure: {
                                    error in
                                    var message = error.userInfo?[NSLocalizedDescriptionKey] as? String
                                    if message == nil && error.code != NSURLErrorCancelled {
                                        message = "未知错误。"
                                    }
                                    if message != nil {
                                        let ac = UIAlertController(title: "上传失败", message: message!, preferredStyle: .Alert) // Needs localization
                                        ac.addAction(UIAlertAction(title: "好", style: .Default, handler: nil))
                                        self_.presentViewController(ac, animated: true, completion: nil)
                                    }
                                    step.image = nil
                                    if let index = find(self_.steps, step) {
                                        self_.tableView.reloadRowsAtIndexPaths([NSIndexPath(forRow: index, inSection: 0)], withRowAnimation: .None)
                                    }
                                    return
                            })
                            operation.setUploadProgressBlock() {
                                bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                                step.uploadingProgresses = Int(totalBytesWritten * Int64(FFStepObject.maxProgress) / totalBytesExpectedToWrite)
                                if let index = find(self_.steps, step) {
                                    self_.cells(index)?.updateProgress(step: step)
                                }
                                return
                            }
                            step.operation = operation
                        }
                        self_.converting = false
                        SVProgressHUD.dismiss()
                    }
                }
            }
        }
    }
    
    @IBAction func didPressUploadButton(sender: UIButton) {
        if let indexPath = tableView.indexPathForRowAtPoint(sender.convertPoint(CGPointZero, toView: tableView)) {
            currentStep = steps[indexPath.row]
            currentStep?.operation?.cancel()
            showImagePickerController()
        }
    }
    
    @IBAction func toggleReorderTableViewCells() {
        let editing = !tableView.editing
        reorderButton.setTitle(editing ? "完成调整" : "调整顺序", forState: .Normal)
        tableView.editing = editing
        tableView.reloadData()
    }
    
    @IBAction func addStep() {
        tableView.beginUpdates()
        steps.append(FFStepObject())
        tableView.insertRowsAtIndexPaths([NSIndexPath(forRow: tableView.numberOfRowsInSection(0), inSection: 0)], withRowAnimation: .Automatic)
        tableView.endUpdates()
    }
    
    func showImagePickerController() {
        let ac = UIAlertController(title: "您想从哪里获取图片？", message: nil, preferredStyle: .ActionSheet)
        let ipc = UIImagePickerController()
        ipc.delegate = self
        ac.addAction(UIAlertAction(title: "相机", style: .Default) {
            [weak self] _ in
            ipc.sourceType = .Camera
            self?.showDetailViewController(ipc, sender: self)
            return
        })
        ac.addAction(UIAlertAction(title: "相簿", style: .Default) {
            [weak self] _ in
            ipc.sourceType = .PhotoLibrary
            self?.showDetailViewController(ipc, sender: self)
            return
        })
        ac.addAction(UIAlertAction(title: "清除", style: .Destructive) {
            [weak self] _ in
            if let self_ = self {
                if let step = self_.currentStep {
                    step.image = nil
                    step.operation = nil
                    step.attachID = nil
                    step.uploaded = false
                    step.uploadingProgresses = 0
                    if let index = find(self_.steps, step) {
                        self_.cells(index)?.update(step: step)
                    }
                }
            }
            return
        })
        ac.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        showDetailViewController(ac, sender: self)
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return SettingsManager.defaultManager.currentTheme.statusBarStyle
    }
    
    func didTouchBlankArea() {
        view.endEditing(true)
    }
    
    func dismiss() {
        if converting {
            return
        }
        let ac = UIAlertController(title: "再次确认", message: "您确定要丢弃已输入的信息吗？这些信息将不会保存。", preferredStyle: .ActionSheet)
        ac.addAction(UIAlertAction(title: "丢弃信息", style: .Destructive)
            /* handler: */ {
                [weak self] action in
                if let self_ = self {
                    self_.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
            })
        ac.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    func publish() {
        if converting {
            return
        }
        for step in steps {
            if step.operation?.executing ?? false {
                let ac = UIAlertController(title: "请稍等", message: "图片还未上传完成。", preferredStyle: .Alert)
                ac.addAction(UIAlertAction(title: "好", style: .Default, handler: nil))
                presentViewController(ac, animated: true, completion: nil)
                return
            }
        }
        if tagsField?.textField.text ?? "" != "" {
            tokenField(tagsField, didReturnWithText: tagsField!.textField.text)
        }
        let ac = UIAlertController(title: "再次确认", message: "您确定要发布吗？", preferredStyle: .ActionSheet)
        ac.addAction(UIAlertAction(title: "是的", style: .Default)
            /* handler: */ {
                [weak self] action in
                if let self_ = self {
                    SVProgressHUD.showWithMaskType(.Gradient)
                    dispatch_async(dispatch_get_main_queue()) {
                        if let text = self_.titleField?.text {
                            self_.dataObject.title = text
                        }
                        if self_.tagsField != nil {
                            var topics = Set<Topic>()
                            for tag in self_.tags {
                                let topic = Topic.temporaryObject()
                                topic.title = tag
                                topics.insert(topic)
                            }
                            self_.dataObject.topics = topics
                        }
                        var body = self_.bodyField.text ?? ""
                        for (i, step) in enumerate(self_.steps) {
                            body += "\n\n\(i + 1)."
                            if let attachID = step.attachID {
                                body += "[attach]\(attachID)[/attach]"
                            }
                            let texts = step.text.componentsSeparatedByString("\n")
                            for text in texts {
                                body += "\n  " + text
                            }
                        }
                        self_.dataObject.body = body
                        self_.dataObject.post(
                            success: {
                                question in
                                SVProgressHUD.dismiss()
                                SVProgressHUD.showSuccessWithStatus("已发布", maskType: .Gradient)
                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(NSEC_PER_SEC / 2)), dispatch_get_main_queue()) {
                                    SVProgressHUD.dismiss()
                                    self_.delegate?.publishmentViewControllerDidSuccessfullyPublishDataObject?(self_)
                                    self_.dismissViewControllerAnimated(true, completion: nil)
                                }
                            },
                            failure: {
                                error in
                                SVProgressHUD.dismiss()
                                let ac = UIAlertController(title: "发布失败", message: error.userInfo?[NSLocalizedDescriptionKey] as? String ?? "未知错误。", preferredStyle: .Alert)
                                ac.addAction(UIAlertAction(title: "好", style: .Default, handler: nil))
                                self_.presentViewController(ac, animated: true, completion: nil)
                        })
                    }
                }
            })
        ac.addAction(UIAlertAction(title: "取消", style: .Cancel, handler: nil))
        presentViewController(ac, animated: true, completion: nil)
    }
    
    // MARK: - Keyboard Notification Observer
    
    func keyboardWillChangeFrame(notification: NSNotification) {
        let info = MSRAnimationInfo(keyboardNotification: notification)
        info.animate() {
            [weak self] in
            if let self_ = self {
                let bottom = UIScreen.mainScreen().bounds.height - info.frameEnd.minY
                self_.bottomConstraint.constant = bottom
                self_.view.layoutIfNeeded()
                if let textView = self_.currentTextView {
                    self_.scrollCursorToVisibleInTextView(textView)
                }
            }
            return
        }
    }
    
    func scrollCursorToVisibleInTextView(textView: UITextView) {
        if let position = textView.selectedTextRange?.start {
            var cursorRect = textView.caretRectForPosition(position)
            cursorRect = scrollView.convertRect(cursorRect, fromView: textView)
            cursorRect = cursorRect.rectByInsetting(dx: -20, dy: -20)
            scrollView.scrollRectToVisible(cursorRect, animated: true)
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
}
