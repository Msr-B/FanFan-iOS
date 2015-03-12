//
//  FeaturedQuestionAnswer.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 15/3/12.
//  Copyright (c) 2015年 Beijing Information Science and Technology University. All rights reserved.
//

import Foundation
import CoreData

class FeaturedQuestionAnswer: FeaturedObject {

    @NSManaged var question: Question
    @NSManaged var answers: NSSet

}
