//
//  Resource.swift
//  SwiftTalk
//
//  Created by 程東 on 12/12/25.
//

import SwiftUI
import Combine
import Observation
import TinyNetworking

@Observable
final class Resource<A: Equatable> {
    let endpoint: Endpoint<A>
    
    private(set) var value: A?
    
    @ObservationIgnored
    let valueSubject = CurrentValueSubject<A?, Never>(nil)
    
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
            guard let self else { return }
            let value = try? result.get()
            self.valueSubject.send(value)
            self.value = value
        }
    }
}
