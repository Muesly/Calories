//
//  NetworkClient.swift
//  Calories
//
//  Created by Tony Short on 21/12/2024.
//

import Foundation

@MainActor
protocol NetworkClientType {
    func data(fromRequest request: URLRequest) async throws -> Data
}

struct NetworkClient: NetworkClientType {
    let urlSession: URLSession

    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    func data(fromRequest request: URLRequest) async throws -> Data {
        let (data, _) = try await urlSession.data(for: request)
        return data
    }
}
