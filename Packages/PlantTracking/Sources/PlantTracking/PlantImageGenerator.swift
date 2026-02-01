//
//  PlantImageGenerator.swift
//  Calories
//
//  Created by Tony Short on 31/08/2024.
//

import Foundation
import UIKit
import CaloriesFoundation

enum PlantImageGeneratorError: Error {
    case failedToDecodeImageFromResponse
    case noURLsReturned
    case invalidURLReturned
    case failedToLoadImageAtURL
}

struct PlantImageGenerator: PlantImageGenerating {
    let apiKey: String
    let networkClient: NetworkClientType

    func promptText(for plantName: String) -> String {
        return "Photo of \(plantName) in a white bowl"
    }

    init(
        apiKey: String,
        networkClient: NetworkClientType = NetworkClient()
    ) {
        self.apiKey = apiKey
        self.networkClient = networkClient
    }

    func generate(for plantName: String) async throws -> Data {
        let prompt = promptText(for: plantName)
        let request = makeRequest(prompt: prompt)
        let data = try await networkClient.data(fromRequest: request)

        let response: GPTResponse
        do {
            let decoder = JSONDecoder()
            response = try decoder.decode(GPTResponse.self, from: data)
        } catch {
            throw PlantImageGeneratorError.failedToDecodeImageFromResponse
        }

        guard let imageURL = response.data.first?.url else {
            throw PlantImageGeneratorError.noURLsReturned
        }
        guard let url = URL(string: imageURL) else {
            throw PlantImageGeneratorError.invalidURLReturned
        }
        do {
            return try await networkClient.data(fromRequest: URLRequest(url: url))
        } catch {
            throw PlantImageGeneratorError.failedToLoadImageAtURL
        }
    }

    private func makeRequest(prompt: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/generations")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)",
        ]
        let parameters: [String: Any] = [
            "model": "dall-e-3",
            "prompt": prompt,
            "n": 1,
            "size": "1024x1024",
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])
        return request
    }
}

struct GPTResponse: Codable {
    struct GPTImage: Codable {
        let url: String
    }
    let data: [GPTImage]
}

class StubbedPlantGenerator: PlantImageGenerating {
    var returnedData = Data()

    func generate(for plantName: String) async throws -> Data {
        return returnedData
    }
}
