//
//  ArticleComment.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/11/26.
//  Copyright (c) 2014年 Beijing Information Science and Technology University. All rights reserved.
//

import CoreData
import Foundation

class ArticleComment: Comment {
    
    @NSManaged var article: Article?
    @NSManaged var agreementCount: NSNumber?
    
    var evaluation: Evaluation?
    
    override func post(#success: (() -> Void)?, failure: ((NSError) -> Void)?) {
        super.post(success: success, failure: failure)
        var parameters: [NSObject: AnyObject] = [
            "article_id": article!.id,
            "message": body!]
        if atUser != nil {
            parameters["at_uid"] = atUser!.id
        }
        NetworkManager.defaultManager!.POST("Post Article Comment",
            parameters: parameters,
            success: {
                [weak self] data in
                success?()
                return
            },
            failure: failure)
    }

}
