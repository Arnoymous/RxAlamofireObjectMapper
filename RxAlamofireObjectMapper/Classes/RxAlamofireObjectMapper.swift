//
//  RxAlamofireObjectMapper.swift
//  Pods
//
//  Created by Arnaud Dorgans on 24/08/2017.
//
//

import UIKit
import Alamofire

public class RxAlamofireObjectMapper {
    
    public class Configuration {
        
        public var debug: Bool = false
        
        public var networkError: Error?
        
        public var defaultStatusCodeErrors = [Int:Error]()
        public var defaultResponseStatusCodes = [Int]()
        
        public var JSONHandler: (
            all:((Result<Any>, Any?, Int?)->Result<Any>?)?,
            object:((Result<[String:Any]>, Any?, Int?)->Result<[String:Any]>?)?,
            objectArray:((Result<[[String:Any]]>, Any?, Int?)->Result<[[String:Any]]>?)?
            ) = (nil, nil, nil)
        
        internal init() { }
    }
    
    public static let config = Configuration()

    private init() { }
}
