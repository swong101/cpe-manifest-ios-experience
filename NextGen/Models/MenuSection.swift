//
//  MenuSection.swift
//

import Foundation

class MenuSection {

    var title: String
    var value: String?
    var items: [MenuItem]?
    var isExpanded = false

    var numItems: Int {
        return (items?.count ?? 0)
    }

    var numRows: Int {
        return (isExpanded ? (numItems + 1) : 1)
    }

    var isExpandable: Bool {
        return (numItems > 0)
    }

    init(title: String, value: String? = nil, items: [MenuItem]? = nil) {
        self.title = title
        self.value = value
        self.items = items
    }

    func toggle() {
        isExpanded = !isExpanded
    }

    func item(atIndex index: Int) -> MenuItem? {
        if let items = items, items.count > index {
            return items[index]
        }

        return nil
    }

}
