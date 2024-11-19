//
//  Extensions.swift
//  Powerful Reports
//
//  Created by Aaron Strickland on 19/11/2024.
//


import UIKit

extension UINavigationController {
    open override func viewWillLayoutSubviews() {
        navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
    }
}
