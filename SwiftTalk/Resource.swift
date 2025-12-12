//
//  Resource.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import SwiftUI
import Observation
import TinyNetworking

@Observable
final class Resource<A> {
    let endpoint: Endpoint<A>
    
    private(set) var value: A?
    
    private var dataTask: URLSessionDataTask? {
        didSet {
            oldValue?.cancel()
        }
    }
    
    init(endpoint: Endpoint<A>) {
        self.endpoint = endpoint
        reload()
    }
    
    deinit {
        dataTask = nil
    }
    
    func reload() {
        print(endpoint.description)
        dataTask = URLSession.shared.load(endpoint) { [weak self] result in
            self?.value = try? result.get()
        }
    }
}
