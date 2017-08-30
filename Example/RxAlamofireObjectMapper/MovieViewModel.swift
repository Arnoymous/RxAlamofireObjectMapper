//
//  MovieViewModel.swift
//  RxAlamofireObjectMapper
//
//  Created by Arnaud Dorgans on 28/08/2017.
//  Copyright © 2017 CocoaPods. All rights reserved.
//

import UIKit
import Alamofire
import RxSwift
import RxDataSources

class MovieViewModel {
    
    let in_reload = PublishSubject<Void>()
    let in_search = BehaviorSubject<String?>(value: nil)
    
    private var currentSearch: Observable<String?> {
        return in_search
    }
    
    private var updateSearch: Observable<String?> {
        return in_search.throttle(0.5, scheduler: MainScheduler.instance)
    }
    
    private let itemsObserver = BehaviorSubject<[Movie]>(value: [])
    var items: Observable<[Movie]> {
        return itemsObserver.asObservable()
    }
    
    var loadShots: Observable<Result<[Movie]>> {
        return Observable.merge(in_reload.withLatestFrom(currentSearch), updateSearch)
            .flatMapLatest{ Movie.get(withQuery: $0).mapToResult() }
            .do(onNext: { [unowned self] result in
                self.itemsObserver.onNext(result.value ?? [])
            })
    }
    
    func reload() {
        in_reload.onNext()
    }
}
