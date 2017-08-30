//
//  MovieController.swift
//  RxAlamofireObjectMapper
//
//  Created by Arnoymous on 08/24/2017.
//  Copyright (c) 2017 Arnoymous. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import PureLayout

class MovieController: UIViewController {
    
    let tableView = UITableView()
    let searchBar = UISearchBar()
    
    let vm = MovieViewModel()
    let disposeBag = DisposeBag()
    
    let cellIdentifier = "cell"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Movies"
        
        self.view.addSubview(searchBar)
        searchBar.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .bottom)
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        self.view.addSubview(tableView)
        tableView.autoPinEdgesToSuperviewEdges(with: .zero, excludingEdge: .top)
        tableView.autoPinEdge(.top, to: .bottom, of: searchBar)
        
        setupRx()
    }
    
    func setupRx() {
        
        searchBar.rx.text
            .bind(to: vm.in_search)
            .disposed(by: disposeBag)
        
        vm.items
            .bind(to: self.tableView.rx.items(cellIdentifier: cellIdentifier)) { index, movie, cell in
                cell.textLabel?.text = movie.title
                cell.selectionStyle = .none
            }.disposed(by: disposeBag)
        
        vm.loadShots
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [unowned self] result in
                switch result {
                case .failure(let error):
                    let alert = UIAlertController(error: error) { [unowned self] in
                        self.vm.reload()
                    }
                    self.present(alert, animated: true, completion: nil)
                default:
                    break
                }
            }).disposed(by: disposeBag)
    }
}
