//
//  Action.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/10/7.
//  Copyright (c) 2014年 ifLab. All rights reserved.
//

import Foundation
import CoreData

class Action: NSManagedObject {

    @NSManaged var date: NSDate
    @NSManaged var id: NSNumber
    @NSManaged var user: User
    
    class func get(#ID: NSNumber, error: NSErrorPointer) -> Action? {
        return dataManager.fetch("Action", ID: ID, error: error) as? Action
    }
    
}
