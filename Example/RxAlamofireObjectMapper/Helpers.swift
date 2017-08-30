//
//  Helpers.swift
//  RxAlamofireObjectMapper
//
//  Created by Arnaud Dorgans on 30/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

extension UIAlertController {
    
    convenience init(error: Error, actions: [UIAlertAction], preferredStyle: UIAlertControllerStyle = .alert) {
        self.init(title: "Error", message: error.localizedDescription, preferredStyle: preferredStyle)
        actions.forEach{ self.addAction($0) }
    }
    
    convenience init(error: Error, preferredStyle: UIAlertControllerStyle = .alert, retryBlock: (()->Void)? = nil) {
        var actions = [UIAlertAction]()
        actions.append(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        actions.append(UIAlertAction(title: "Retry", style: .default, handler: { _ in retryBlock?()}))
        self.init(error: error, actions: actions, preferredStyle: preferredStyle)
    }
}
