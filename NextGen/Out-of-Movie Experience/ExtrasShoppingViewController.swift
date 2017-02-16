//
//  ExtrasShoppingViewController.swift
//

import UIKit
import NextGenDataManager
import MBProgressHUD

class ExtrasShoppingViewController: MenuedViewController {
    
    private var extrasShoppingItemsViewController: ExtrasShoppingItemsViewController? {
        for viewController in self.childViewControllers {
            if let viewController = viewController as? ExtrasShoppingItemsViewController {
                return viewController
            }
            
            if let navigationController = viewController as? UINavigationController, let viewController = navigationController.topViewController as? ExtrasShoppingItemsViewController {
                return viewController
            }
        }
        
        return nil
    }
    
    private var hud: MBProgressHUD?
    private var didAutoSelectCategory = false
    private var productCategoriesSessionDataTask: URLSessionDataTask?
    private var productListSessionDataTask: URLSessionDataTask?
    
    deinit {
        if let currentTask = productCategoriesSessionDataTask {
            currentTask.cancel()
            productCategoriesSessionDataTask = nil
        }
        
        if let currentTask = productListSessionDataTask {
            currentTask.cancel()
            productListSessionDataTask = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        menuSections.append(MenuSection(info: [MenuSection.Keys.Title: String.localize("label.all")]))
        
        if let productCategories = experience.productCategories {
            for category in productCategories {
                let info = NSMutableDictionary()
                info[MenuSection.Keys.Title] = category.name
                info[MenuSection.Keys.Value] = String(category.id)
                
                if let children = (category.childCategories ?? nil) {
                    if children.count > 1 {
                        var rows = [[MenuItem.Keys.Title: String.localize("label.all"), MenuItem.Keys.Value: String(category.id)]]
                        for child in children {
                            rows.append([MenuItem.Keys.Title: child.name, MenuItem.Keys.Value: String(child.id)])
                        }
                        
                        info[MenuSection.Keys.Rows] = rows
                    }
                }
                
                menuSections.append(MenuSection(info: info))
            }
        } else {
            menuTableView?.removeFromSuperview()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !didAutoSelectCategory {
            if let menuTableView = menuTableView {
                let selectedPath = IndexPath(row: 0, section: 0)
                menuTableView.selectRow(at: selectedPath, animated: false, scrollPosition: UITableViewScrollPosition.top)
                self.tableView(menuTableView, didSelectRowAt: selectedPath)
                if let menuSection = menuSections.first {
                    if menuSection.expandable {
                        let selectedPath = IndexPath(row: 1, section: 0)
                        menuTableView.selectRow(at: selectedPath, animated: false, scrollPosition: UITableViewScrollPosition.top)
                        self.tableView(menuTableView, didSelectRowAt: selectedPath)
                    }
                }
            } else {
                selectProducts()
            }
            
            didAutoSelectCategory = true
        }
    }
    
    private func selectProducts(categoryID: String? = nil) {
        if let productAPIUtil = NGDMConfiguration.productAPIUtil {
            productListSessionDataTask?.cancel()
            DispatchQueue.main.async {
                self.hud = MBProgressHUD.showAdded(to: self.view, animated: true)
                
                DispatchQueue.global(qos: .userInteractive).async {
                    self.productListSessionDataTask = productAPIUtil.getCategoryProducts(categoryID, completion: { [weak self] (products) in
                        self?.productListSessionDataTask = nil
                        
                        DispatchQueue.main.async {
                            self?.extrasShoppingItemsViewController?.products = products
                            self?.hud?.hide(true)
                        }
                    })
                }
            }
        }  else if let childExperiences = experience.childExperiences {
            var products = [ProductItem]()
            for childExperience in childExperiences {
                if let product = childExperience.product {
                    if let categoryID = categoryID {
                        if let category = product.category, category.id == categoryID {
                            products.append(product)
                        }
                    } else {
                        products.append(product)
                    }
                }
            }
            
            extrasShoppingItemsViewController?.products = products
        }
    }
    
    // MARK: UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        super.tableView(tableView, didSelectRowAt: indexPath)
        
        var categoryID: String?
        if let menuSection = (tableView.cellForRow(at: indexPath) as? MenuSectionCell)?.menuSection, !menuSection.expandable {
            categoryID = menuSection.value
        } else {
            categoryID = (tableView.cellForRow(at: indexPath) as? MenuItemCell)?.menuItem?.value
        }
        
        selectProducts(categoryID: categoryID)
    }

}
