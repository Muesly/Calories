//
//  NetworkClient.swift
//  Calories
//
//  Created by Tony Short on 21/12/2024.
//

import Foundation

@MainActor
public protocol NetworkClientType {
    func data(fromRequest request: URLRequest) async throws -> Data
}

public struct NetworkClient: NetworkClientType {
    let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func data(fromRequest request: URLRequest) async throws -> Data {
        let (data, _) = try await urlSession.data(for: request)
        return data
    }
}
