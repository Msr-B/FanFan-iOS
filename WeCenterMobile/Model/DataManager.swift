//
//  DataManager.swift
//  WeCenterMobile
//
//  Created by Darren Liu on 14/10/7.
//  Copyright (c) 2014年 ifLab. All rights reserved.
//

import Foundation
import CoreData

class DataManager: NSObject {
    required init?(name: String?) {
        super.init()
        managedObjectModel = NSManagedObjectModel(contentsOfURL: NSBundle.mainBundle().URLForResource("WeCenterMobile", withExtension: "momd")!)
        if managedObjectModel == nil {
            return nil
        }
        if name != nil {
            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
            let directory = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last as! NSURL
            let url = directory.URLByAppendingPathComponent(name! + ".sqlite")
            var error: NSError? = nil
            if persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
                let dict = NSMutableDictionary()
                dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data."
                dict[NSLocalizedFailureReasonErrorKey] = "There was an error creating or loading the application's saved data."
                dict[NSUnderlyingErrorKey] = error
                error = NSError(
                    domain: NetworkManager.defaultManager!.website,
                    code: NetworkManager.defaultManager!.internalErrorCode.integerValue,
                    userInfo: dict as [NSObject: AnyObject])
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                return nil
            }
            managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
            managedObjectContext!.persistentStoreCoordinator = persistentStoreCoordinator
        }
    }
    static var defaultManager = DataManager(name: "WeCenterMobile") // for creating cached objects
    static var temporaryManager = DataManager(name: nil) // for creating temporary objects
    func create(entityName: String) -> NSManagedObject {
        let entity = managedObjectModel.entitiesByName[entityName] as! NSEntityDescription
        return NSManagedObject(entity: entity, insertIntoManagedObjectContext: managedObjectContext)
    }
    func fetch(entityName: String, ID: NSNumber, error: NSErrorPointer) -> NSManagedObject? {
        let request = managedObjectModel.fetchRequestFromTemplateWithName(entityName + "_By_ID",
            substitutionVariables: [
                "ID": ID
            ])!
        let results = managedObjectContext?.executeFetchRequest(request, error: error)
        if results != nil && results!.count != 0 {
            return results![0] as? NSManagedObject
        } else {
            if error != nil && error.memory == nil {
                error.memory = NSError() // Needs specification
            }
            return nil
        }
    }
    func fetchAll(entityName: String, error: NSErrorPointer) -> [NSManagedObject] {
        let request = managedObjectModel.fetchRequestTemplateForName(entityName)!
        let results = managedObjectContext?.executeFetchRequest(request, error: error)
        if results != nil {
            return results as! [NSManagedObject]
        } else {
            if error != nil && error.memory == nil {
                error.memory = NSError() // Needs specification
            }
            return []
        }
    }
    func autoGenerate(entityName: String, ID: NSNumber) -> NSManagedObject {
        var object = fetch(entityName, ID: ID, error: nil)
        if object == nil {
            object = create(entityName)
            object!.setValue(ID, forKey: "id")
        }
        return object!
    }
    func removeAllObjectsWithEntityName(entityName: String) {
        managedObjectContext?.msr_deleteAllObjectsWithEntityName(entityName)
    }
    func saveChanges(error: NSErrorPointer) {
        if managedObjectContext?.hasChanges ?? false {
            managedObjectContext?.save(error)
        }
    }
    private var managedObjectModel: NSManagedObjectModel!
    private var managedObjectContext: NSManagedObjectContext?
}
