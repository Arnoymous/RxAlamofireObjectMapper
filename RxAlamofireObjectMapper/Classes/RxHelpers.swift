//
//  RxHelpers.swift
//  Pods
//
//  Created by Arnaud Dorgans on 24/08/2017.
//
//

import Alamofire
import RxSwift
import ObjectMapper

extension Array where Element == [String:Any] {
    
    func mapToObjectArray<T: Mappable>(withType type: T.Type? = nil, context: MapContext?) -> [T] {
        let mapper = Mapper<T>()
        mapper.context = context
        return mapper.mapArray(JSONArray: self as [[String:Any]])
    }
}

extension Dictionary where Key == String, Value == Any {
    
    func mapToObject<T: Mappable>(withType type: T.Type? = nil, context: MapContext?) -> T? {
        let mapper = Mapper<T>()
        mapper.context = context
        return mapper.map(JSON: self)
    }
}

extension Observable where Element == [String:Any] {
    
    public func mapToObject<T: Mappable>(withType type: T.Type? = nil, context: MapContext?, mapError: Error) -> Observable<T> {
        return self.flatMap{ JSON -> Observable<T> in
            if let result = JSON.mapToObject(withType: type, context: context) {
                return .just(result)
            } else {
                return .error(mapError)
            }
        }
    }
}

extension Observable where Element == [[String:Any]] {
    
    public func mapToObjectArray<T: Mappable>(withType type: T.Type? = nil, context: MapContext?) -> Observable<[T]> {
        return self.map{ JSONArray -> [T] in
            return JSONArray.mapToObjectArray(withType: type, context: context)
        }
    }
}

extension Observable where Element:DataRequest {
    
    private func string(of value: Any?) -> String {
        if let value = value {
            if let string = (value as? CustomStringConvertible)?.description, !(value is [String:Any]) && !(value is [[String:Any]]) {
                return string
            } else if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted),
                let jsonString = String(bytes: jsonData, encoding: .utf8) {
                return jsonString
            } else if let data = value as? Data,
                let dataString = String(data: data, encoding: .utf8) {
                return dataString
            } else {
                return "\(value)"
            }
        }
        return ""
    }
    
    private func debugRequest<T>(_ request: URLRequest?, result: Result<T>) {
        if let request = request, RxAlamofireObjectMapper.config.debug {
            print("\n******** Request ********")
            print("method:\(request.httpMethod ?? "")")
            print("url:\(request.url?.absoluteString ?? "")")
            print("headers:\(string(of: request.allHTTPHeaderFields))")
            print("parameters:\(self.string(of: request.httpBody))")
            print("******** Result ********")
            switch result {
            case .success(let value):
                print("result: \(self.string(of: value))")
            case .failure(let error):
                print("error:\(error.localizedDescription)")
            }
            print("*************************\n")
        }
    }
    
    private func getServerError(fromStatusCode code: Int?, errors: [Int:Error]) -> Error? {
        if let code = code {
            if let error = errors[code] {
                return error
            }
            if let error = RxAlamofireObjectMapper.config.statusCodeErrors[code] {
                return error
            }
            return nil
        } else {
            return RxAlamofireObjectMapper.config.networkError
        }
    }
    
    public func getResponse(withStatusCode statusCode: Int,error: Error,statusCodeError:[Int:Error] = [:]) -> Observable<HTTPURLResponse> {
        return self.getResponse(withStatusCodes: [statusCode], error: error, statusCodeError: statusCodeError)
    }
    
    public func getResponse(withStatusCodes statusCodes: [Int] = [],error: Error,statusCodeError:[Int:Error] = [:]) -> Observable<HTTPURLResponse> {
        return self.flatMap{ self.getResponse(fromRequest: $0,withStatusCodes: statusCodes, error: error, statusCodeError: statusCodeError) }
    }
    
    private func getResponse(fromRequest request:DataRequest,withStatusCodes statusCodes: [Int],error: Error,statusCodeError:[Int:Error]) -> Observable<HTTPURLResponse> {
        return Observable<HTTPURLResponse>.create({ (observer:AnyObserver<HTTPURLResponse>) -> Disposable in
            let request = request.response(completionHandler: { (response:DefaultDataResponse) in
                let serverError = self.getServerError(fromStatusCode: response.response?.statusCode, errors: statusCodeError)
                var result: Result<HTTPURLResponse>
                if let response = response.response, (statusCodes.contains(response.statusCode) || statusCodes.isEmpty) && serverError == nil {
                    result = .success(response)
                } else {
                    result = .failure(serverError ?? error)
                }
                self.debugRequest(response.request, result: result)
                observer.on(result.event)
                observer.onCompleted()
            })
            return Disposables.create {
                request.cancel()
            }
        })
    }
    
    public func getObject<T: Mappable>(withType type: T.Type? = nil,
                   keyPath: String? = nil,
                   keyPathDelimiter: String? = nil,
                   context: MapContext? = nil,
                   mapError: Error,
                   statusCodeError:[Int:Error] = [:],
                   JSONMapHandler: ((Result<[String:Any]>, Any?, Int?)->Result<[String:Any]>?)? = nil) -> Observable<T> {
        
        return self.flatMap{ self.getObject(withType: type,fromRequest: $0, keyPath: keyPath, keyPathDelimiter: keyPathDelimiter, context: context, mapError: mapError, statusCodeError: statusCodeError, JSONMapHandler: JSONMapHandler) }
    }
    
    private func getObject<T: Mappable>(withType type: T.Type?,
                           fromRequest request:DataRequest,
                           keyPath: String?,
                           keyPathDelimiter: String?,
                           context: MapContext?,
                           mapError: Error,
                           statusCodeError:[Int:Error],
                           JSONMapHandler: ((Result<[String:Any]>, Any?, Int?)->Result<[String:Any]>?)?) -> Observable<T> {
        
        return self.getJSON(withType: [String:Any].self, keyPath: keyPath, keyPathDelimiter: keyPathDelimiter, error: mapError, statusCodeError: statusCodeError) { result, JSON, statusCode in
            if let customResult = JSONMapHandler?(result, JSON, statusCode) {
                return customResult
            }
            if let defaultConfigResult = RxAlamofireObjectMapper.config.JSONHandler.object?(result, JSON, statusCode) {
                return defaultConfigResult
            }
            return nil
        }.mapToObject(withType: type, context: context, mapError: mapError)
    }
    
    public func getObjectArray<T: Mappable>(keyPath: String? = nil,
                               keyPathDelimiter: String? = nil,
                               context: MapContext? = nil,
                               mapError: Error,
                               statusCodeError:[Int:Error] = [:],
                               JSONMapHandler: ((Result<[[String:Any]]>, Any?, Int?)->Result<[[String:Any]]>?)? = nil) -> Observable<[T]> {
        
        return self.flatMap{ self.getObjectArray(fromRequest: $0, keyPath: keyPath, keyPathDelimiter: keyPathDelimiter, context: context, mapError: mapError, statusCodeError: statusCodeError, JSONMapHandler: JSONMapHandler) }
    }
    
    private func getObjectArray<T: Mappable>(withType type: T.Type? = nil,
                          fromRequest request:DataRequest,
                          keyPath: String? = nil,
                          keyPathDelimiter: String?,
                          context: MapContext?,
                          mapError: Error,
                          statusCodeError:[Int:Error],
                          JSONMapHandler: ((Result<[[String:Any]]>, Any?, Int?)->Result<[[String:Any]]>?)?) -> Observable<[T]> {
        
        return self.getJSON(withType: [[String:Any]].self, keyPath: keyPath, keyPathDelimiter: keyPathDelimiter, error: mapError, statusCodeError: statusCodeError) { result, JSON, statusCode in
            if let customResult = JSONMapHandler?(result, JSON, statusCode) {
                return customResult
            }
            if let defaultConfigResult = RxAlamofireObjectMapper.config.JSONHandler.objectArray?(result, JSON, statusCode) {
                return defaultConfigResult
            }
            return nil
        }.mapToObjectArray(withType: type, context: context)
    }
    
    public func getJSON<T>(withType type: T.Type? = nil,
                 keyPath: String? = nil,
                 keyPathDelimiter: String? = nil,
                 options: JSONSerialization.ReadingOptions = .allowFragments,
                 error: Error,
                 statusCodeError:[Int:Error] = [:],
                 JSONHandler: ((Result<T>, Any?, Int?)->Result<T>?)? = nil) -> Observable<T> {
        
        return self.flatMap{ self.getJSON(withType: type, fromRequest: $0, keyPath: keyPath, keyPathDelimiter: keyPathDelimiter, options: options, error: error, statusCodeError: statusCodeError, JSONHandler: JSONHandler) }
    }
    
    private func getJSON<T>(withType type: T.Type?,
                         fromRequest request:DataRequest,
                         keyPath: String?,
                         keyPathDelimiter: String?,
                         options: JSONSerialization.ReadingOptions,
                         error: Error,
                         statusCodeError:[Int:Error],
                         JSONHandler: ((Result<T>, Any?, Int?)->Result<T>?)?) -> Observable<T> {
        
        return Observable<T>.create({ observer -> Disposable in
            request.responseJSON(options: options, completionHandler: { response in
                let statusCode = response.response?.statusCode
                let serverError = self.getServerError(fromStatusCode: statusCode, errors: statusCodeError)
                var JSON = response.result.value
                if let keyPath = keyPath {
                    var keyPaths = [keyPath]
                    if let keyPathDelimiter = keyPathDelimiter {
                        keyPaths = keyPath.components(separatedBy: keyPathDelimiter)
                    }
                    JSON = keyPaths.reduce(JSON, { (JSON, keyPath) -> Any? in
                        var JSON = JSON
                        if let JSON = (JSON as? [String:Any])?[keyPath] {
                            return JSON
                        }
                        return nil
                    })
                }
                let result = JSON as? T
                func getResult() -> Result<T> {
                    var requestResult: Result<T>
                    if let result = result, serverError == nil {
                        requestResult = .success(result)
                    } else {
                        requestResult = .failure(serverError ?? error)
                    }
                    if let customResult = JSONHandler?(requestResult, JSON, statusCode) {
                        return customResult
                    }
                    if let requestResult = requestResult.as(Any.self),
                        let defaultResult = RxAlamofireObjectMapper.config.JSONHandler.json?(requestResult, JSON, statusCode)?.as(T.self) {
                        return defaultResult
                    }
                    return requestResult
                }
                let requestResult = getResult()
                self.debugRequest(response.request, result: requestResult)
                observer.on(requestResult.event)
                observer.onCompleted()
            })
            return Disposables.create {
                request.cancel()
            }
        })
    }
}

extension Result {
    
    internal func `as`<T>(_ type: T.Type) -> Result<T>? {
        switch self {
        case .success(let object):
            if let object = object as? T {
                return .success(object)
            }
            return nil
        case .failure(let error):
            return .failure(error)
        }
    }
    
    internal var event: RxSwift.Event<Value> {
        switch self {
        case .success(let object):
            return .next(object)
        case .failure(let error):
            return .error(error)
        }
    }
}

