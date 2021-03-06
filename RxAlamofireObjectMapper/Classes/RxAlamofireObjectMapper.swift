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
        
        public var statusCodeErrors = [Int:Error]()
        public var defaultResponseRequestStatusCodes = [Int]()
        
        public var JSONHandler: (
            all:((Result<Any>, Any?, Int?, Error)->Result<Any>?)?,
            object:((Result<[String:Any]>, Any.Type, Any?, Int?, Error)->Result<[String:Any]>?)?,
            objectArray:((Result<[[String:Any]]>, Any.Type, Any?, Int?, Error)->Result<[[String:Any]]>?)?
            ) = (nil, nil, nil)
        
        public static let shared = Configuration()
        
        internal init() { }
    }
    
    private init() { }
}
