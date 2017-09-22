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

extension ObservableType where E:DataRequest {
    
    private func string(of value: Any?) -> String {
        if var value = value {
            if let data = value as? Data {
                if let JSON = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) {
                    value = JSON
                } else if let dataString = String(data: data, encoding: .utf8) {
                    return dataString
                }
            }
            if let string = (value as? CustomStringConvertible)?.description, !(value is [String:Any]) && !(value is [[String:Any]])
            {
                return string
            }
            if let jsonData = try? JSONSerialization.data(withJSONObject: value, options: .prettyPrinted),
                let jsonString = String(bytes: jsonData, encoding: .utf8) {
                return jsonString
            }
            return "\(value)"
        }
        return ""
    }
    
    private func debugRequest<T>(_ request: URLRequest?, result: Result<T>) {
        if let request = request, RxAlamofireObjectMapper.Configuration.shared.debug {
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
            if let error = RxAlamofireObjectMapper.Configuration.shared.statusCodeErrors[code] {
                return error
            }
            return nil
        } else {
            return RxAlamofireObjectMapper.Configuration.shared.networkError
        }
    }
    
    public func getResponse(withStatusCode statusCode: Int,error: Error,statusCodeError:[Int:Error] = [:]) -> Observable<HTTPURLResponse> {
        return self.getResponse(withStatusCodes: [statusCode], error: error, statusCodeError: statusCodeError)
    }
    
    public func getResponse(withStatusCodes statusCodes: [Int] = RxAlamofireObjectMapper.Configuration.shared.defaultResponseRequestStatusCodes,error: Error,statusCodeError:[Int:Error] = [:]) -> Observable<HTTPURLResponse> {
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
                          nestedKeyDelimiter: String? = nil,
                          context: MapContext? = nil,
                          mapError: Error,
                          statusCodeError:[Int:Error] = [:],
                          JSONMapHandler: ((Result<[String:Any]>, Any?, Int?, Error)->Result<[String:Any]>?)? = nil) -> Observable<T> {
        
        return self.flatMap{ self.getObject(withType: type,fromRequest: $0, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, context: context, mapError: mapError, statusCodeError: statusCodeError, JSONMapHandler: JSONMapHandler) }
    }
    
    private func getObject<T: Mappable>(withType type: T.Type?,
                           fromRequest request:DataRequest,
                           keyPath: String?,
                           nestedKeyDelimiter: String?,
                           context: MapContext?,
                           mapError: Error,
                           statusCodeError:[Int:Error],
                           JSONMapHandler: ((Result<[String:Any]>, Any?, Int?, Error)->Result<[String:Any]>?)?) -> Observable<T> {
        
        return self.getJSON(withType: [String:Any].self, fromRequest: request, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, options: .allowFragments, error: mapError, statusCodeError: statusCodeError, JSONHandler: RxAlamofireObjectMapper.JSONHandler(type: T.self, JSONMapHandler: JSONMapHandler))
            .mapToObject(withType: type, context: context, mapError: mapError)
    }
    
    public func getObjectArray<T: Mappable>(keyPath: String? = nil,
                               nestedKeyDelimiter: String? = nil,
                               context: MapContext? = nil,
                               mapError: Error,
                               statusCodeError:[Int:Error] = [:],
                               JSONMapHandler: ((Result<[[String:Any]]>, Any?, Int?, Error)->Result<[[String:Any]]>?)? = nil) -> Observable<[T]> {
        
        return self.flatMap{ self.getObjectArray(fromRequest: $0, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, context: context, mapError: mapError, statusCodeError: statusCodeError, JSONMapHandler: JSONMapHandler) }
    }
    
    private func getObjectArray<T: Mappable>(withType type: T.Type? = nil,
                                fromRequest request:DataRequest,
                                keyPath: String? = nil,
                                nestedKeyDelimiter: String?,
                                context: MapContext?,
                                mapError: Error,
                                statusCodeError:[Int:Error],
                                JSONMapHandler: ((Result<[[String:Any]]>, Any?, Int?, Error)->Result<[[String:Any]]>?)?) -> Observable<[T]> {
        return self.getJSON(withType: [[String:Any]].self, fromRequest: request, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, options: .allowFragments, error: mapError, statusCodeError: statusCodeError, JSONHandler: RxAlamofireObjectMapper.JSONHandler(type: T.self, JSONMapHandler: JSONMapHandler))
            .mapToObjectArray(withType: type, context: context)
    }
    
    public func getJSON<T>(withType type: T.Type? = nil,
                        keyPath: String? = nil,
                        nestedKeyDelimiter: String? = nil,
                        options: JSONSerialization.ReadingOptions = .allowFragments,
                        error: Error,
                        statusCodeError:[Int:Error] = [:],
                        JSONHandler: ((Result<T>, Any?, Int?, Error)->Result<T>?)? = nil) -> Observable<T> {
        
        return self.flatMap{ self.getJSON(withType: type, fromRequest: $0, keyPath: keyPath, nestedKeyDelimiter: nestedKeyDelimiter, options: options, error: error, statusCodeError: statusCodeError, JSONHandler: JSONHandler) }
    }
    
    private func getJSON<T>(withType type: T.Type?,
                         fromRequest request:DataRequest,
                         keyPath: String?,
                         nestedKeyDelimiter: String?,
                         options: JSONSerialization.ReadingOptions,
                         error: Error,
                         statusCodeError:[Int:Error],
                         JSONHandler: ((Result<T>, Any?, Int?, Error)->Result<T>?)?) -> Observable<T> {
        
        return Observable<T>.create({ observer -> Disposable in
            request.responseJSON(options: options, completionHandler: { response in
                let statusCode = response.response?.statusCode
                let serverError = self.getServerError(fromStatusCode: statusCode, errors: statusCodeError)
                var JSON = response.result.value
                if let keyPath = keyPath {
                    var keyPaths = [keyPath]
                    if let nestedKeyDelimiter = nestedKeyDelimiter {
                        keyPaths = keyPath.components(separatedBy: nestedKeyDelimiter)
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
                    let error = serverError ?? error
                    if let result = result, serverError == nil {
                        requestResult = .success(result)
                    } else {
                        requestResult = .failure(error)
                    }
                    if let customResult = JSONHandler?(requestResult, JSON, statusCode, error) {
                        return customResult
                    }
                    if let requestResult = requestResult.as(Any.self),
                        let defaultResult = RxAlamofireObjectMapper.Configuration.shared.JSONHandler.all?(requestResult, JSON, statusCode, error)?.as(T.self) {
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

extension ObservableType where E == [String:Any] {
    
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

extension ObservableType where E == [[String:Any]] {
    
    public func mapToObjectArray<T: Mappable>(withType type: T.Type? = nil, context: MapContext?) -> Observable<[T]> {
        return self.map{ JSONArray -> [T] in
            return JSONArray.mapToObjectArray(withType: type, context: context)
        }
    }
}

extension ObservableType {
    
    public func mapToResult() -> Observable<Result<E>> {
        return self.map{ .success($0) }
            .catchError{ .just(.failure($0)) }
    }
}

extension RxAlamofireObjectMapper {
    
    public static func JSONHandler<T>(type: T.Type? = nil, JSONMapHandler: ((Result<[String:Any]>, Any?, Int?, Error)->Result<[String:Any]>?)?) -> ((Result<[String:Any]>, Any?, Int?, Error)->Result<[String:Any]>?) {
        return { result, JSON, statusCode, error in
            if let customResult = JSONMapHandler?(result, JSON, statusCode, error) {
                return customResult
            }
            if let defaultConfigResult = RxAlamofireObjectMapper.Configuration.shared.JSONHandler.object?(result, T.self, JSON, statusCode, error) {
                return defaultConfigResult
            }
            return nil
        }
    }
    
    public static func JSONHandler<T>(type: T.Type? = nil, JSONMapHandler: ((Result<[[String:Any]]>, Any?, Int?, Error)->Result<[[String:Any]]>?)?) -> ((Result<[[String:Any]]>, Any?, Int?, Error)->Result<[[String:Any]]>?) {
        return { result, JSON, statusCode, error in
            if let customResult = JSONMapHandler?(result, JSON, statusCode, error) {
                return customResult
            }
            if let defaultConfigResult = RxAlamofireObjectMapper.Configuration.shared.JSONHandler.objectArray?(result, T.self, JSON, statusCode, error) {
                return defaultConfigResult
            }
            return nil
        }
    }
}

