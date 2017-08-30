//
//  TMDB.swift
//  RxAlamofireObjectMapper
//
//  Created by Arnaud Dorgans on 28/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import RxAlamofireObjectMapper
import Alamofire
import RxSwift

typealias Path = CustomStringConvertible

class TMDB {
    
    private static let scheme = "https"
    private static let host = "api.themoviedb.org"
    private static let defaultPath = "3"
    
    private static let apiKey = "e4d4519b0a27a3612fd71a6f59732405"
    
    private static func path(from paths: [Path]) -> String {
        var paths = paths
        paths.insert(defaultPath, at: 0)
        return "/" + paths.map{ $0.description }.joined(separator: "/")
    }
    
    private static func queryItems(from urlParameters: [String:CustomStringConvertible]) -> [URLQueryItem] {
        var urlParameters = urlParameters
        urlParameters["api_key"] = apiKey
        if let code = Locale.current.languageCode {
            urlParameters["language"] = code
        }
        return urlParameters.map{ URLQueryItem(name: $0.key, value: $0.value.description) }
    }

    static func request(_ method: HTTPMethod, withPath path: Path..., urlParameters: [String:CustomStringConvertible] = [:], parameters: Parameters? = nil, headers: HTTPHeaders? = nil) -> Observable<DataRequest> {
        return self.request(method, withPaths: Array(path), urlParameters: urlParameters, parameters: parameters, headers: headers)
    }
    
    static func request(_ method: HTTPMethod, withPaths paths: [Path], urlParameters: [String:CustomStringConvertible] = [:], parameters: Parameters? = nil, headers: HTTPHeaders? = nil) -> Observable<DataRequest> {
        
        let urlComponents = NSURLComponents()
        urlComponents.scheme = self.scheme
        urlComponents.host = self.host
        urlComponents.path = self.path(from: paths)
        urlComponents.queryItems = self.queryItems(from: urlParameters)
        return Observable<DataRequest>.create({ observer -> Disposable in
            let url = urlComponents.url!.absoluteString
            let request = Alamofire.request(url, method: method, parameters: parameters, headers: headers)
            observer.onNext(request)
            observer.onCompleted()
            return Disposables.create()
        })
    }
}
