//
//  Movie.swift
//  RxAlamofireObjectMapper
//
//  Created by Arnaud Dorgans on 28/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import ObjectMapper
import RxSwift

class Movie: Mappable {
    
    var id: Int = 0
    var title: String = ""
    
    required init?(map: Map) {
        guard let _ = map.JSON["id"] else {
            return nil
        }
    }

    func mapping(map: Map) {
        id <- map["id"]
        title <- map["title"]
    }
    
    static func get() -> Observable<[Movie]> {
        return TMDB.request(.get, withPath: "discover","movie")
            .getObjectArray(keyPath: "results", mapError: Failure.movieGet)
    }

    static func get(withQuery query: String?) -> Observable<[Movie]> {
        if let query = query, !query.isEmpty {
            return TMDB.request(.get, withPath: "search","movie", urlParameters: ["query": query])
                .getObjectArray(keyPath: "results", mapError: Failure.movieGet)
        }
        return self.get()
    }
}
