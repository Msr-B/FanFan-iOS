//
//  FFPublishmentStepCell.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 15/7/4.
//  Copyright (c) 2015年 Beijing Information Science and Technology University. All rights reserved.
//

import UIKit
import EAColourfulProgressView

class FFPublishmentStepCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var stepIndexLabel: UILabel!
    @IBOutlet weak var titleImageView: UIImageView!
    @IBOutlet weak var titleImageButton: UIButton!
    @IBOutlet weak var progressView: EAColourfulProgressView!
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var separator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        let theme = SettingsManager.defaultManager.currentTheme
        stepIndexLabel.textColor = theme.subtitleTextColor
        textView.backgroundColor = theme.backgroundColorB
        textView.msr_borderColor = theme.borderColorA
        textView.textColor = theme.bodyTextColor
        separator.backgroundColor = theme.borderColorA
        titleImageButton.tintColor = theme.backgroundColorA
        titleImageButton.msr_borderColor = theme.borderColorA
        msr_scrollView?.delaysContentTouches = false
        msr_scrollView?.msr_setTouchesShouldCancel(true, inContentViewWhichIsKindOfClass: UIButton.self)
    }
    
    func update(#step: FFStepObject) {
        let theme = SettingsManager.defaultManager.currentTheme
        textView.text = step.text
        if let image = step.image {
            titleImageView.image = image
            titleImageButton.setImage(nil, forState: .Normal)
        } else {
            titleImageView.image = nil
            titleImageButton.msr_setBackgroundImageWithColor(theme.backgroundColorB)
            titleImageButton.setImage(UIImage(named: "Publishment-Camera"), forState: .Normal)
            progressView.hidden = true
        }
        updateProgress(step: step)
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    func updateProgress(#step: FFStepObject) {
        let theme = SettingsManager.defaultManager.currentTheme
        if let image = step.image {
            if step.uploadingProgresses < FFStepObject.maxProgress {
                progressView.hidden = false
                titleImageButton.msr_setBackgroundImageWithColor(UIColor.blackColor().colorWithAlphaComponent(0.5))
                progressView.updateToCurrentValue(FFStepObject.maxProgress - step.uploadingProgresses, animated: false)
            } else {
                progressView.hidden = true
                titleImageButton.setBackgroundImage(nil, forState: .Normal)
            }
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        update(step: FFStepObject())
    }
    
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        let theme = SettingsManager.defaultManager.currentTheme
        titleImageButton.enabled = !editing
        textView.editable = !editing
        textView.backgroundColor = editing ? UIColor.clearColor() : theme.backgroundColorB
    }
    
}
