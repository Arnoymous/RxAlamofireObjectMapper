//
//  Failure.swift
//  RxAlamofireObjectMapper
//
//  Created by Arnaud Dorgans on 28/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit

enum Failure: Error {

    //movie
    case movieGet
}

extension Failure: LocalizedError {
    
    var errorDescription: String? {
        switch self {
        case .movieGet:
            return "Unable to retrieve movies"
        }
    }
    
    static func withMessage(_ message: String) -> Error {
        return NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: message])
    }
}
