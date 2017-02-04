//
//  TheTakeCategory.swift
//

import Foundation
import NextGenDataManager

class TheTakeCategory: ProductCategory {
    
    struct Keys {
        static let CategoryID = "categoryId"
        static let CategoryName = "categoryName"
        static let ChildCategories = "childCategories"
    }
    
    var id: Int
    var name: String
    var childCategories: [ProductCategory]?
    
    init(info: NSDictionary) {
        id = (info[Keys.CategoryID] as! NSNumber).intValue
        name = info[Keys.CategoryName] as! String
        
        if let childCategories = info[Keys.ChildCategories] as? [NSDictionary] {
            self.childCategories = childCategories.map({ return TheTakeCategory(info: $0) })
        }
    }
    
}
