//
//  AnswerComment.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/11/26.
//  Copyright (c) 2014年 Beijing Information Science and Technology University. All rights reserved.
//

import Foundation
import CoreData

class AnswerComment: NSManagedObject {

    @NSManaged var atID: NSNumber?
    @NSManaged var body: String?
    @NSManaged var date: NSDate?
    @NSManaged var id: NSNumber
    @NSManaged var answer: Answer?
    @NSManaged var atUser: User?
    @NSManaged var user: User?
    
    class func post(#answerID: NSNumber, body: String, atUserName: String?, success: (() -> Void)?, failure: ((NSError) -> Void)?) {
        NetworkManager.defaultManager!.request("Post Answer Comment",
            GETParameters: ["answer_id": answerID],
            POSTParameters: ["message": body],
            success: {
                data in
                success?()
                return
            },
            failure: failure)
    }

}
