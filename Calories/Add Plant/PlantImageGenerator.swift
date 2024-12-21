//
//  PlantImageGenerator.swift
//  Calories
//
//  Created by Tony Short on 31/08/2024.
//

import Foundation
import UIKit

@MainActor
protocol PlantImageGenerating {
    func generate(for plantName: String) async throws -> Data
}

enum PlantImageGeneratorError: Error {
    case failedToDecodeImageFromResponse
    case noURLsReturned
    case invalidURLReturned
    case failedToLoadImageAtURL
}

struct PlantImageGenerator: PlantImageGenerating {
    let apiKey: String
    let urlSession: URLSession

    private func promptText(for plantName: String) -> String {
        return "Photo of \(plantName) in a white bowl"
    }

    init(apiKey: String,
         urlSession: URLSession = .shared) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    func generate(for plantName: String) async throws -> Data {
        let prompt = promptText(for: plantName)
        let request = makeRequest(prompt: prompt)
        let (data, _) = try await urlSession.data(for: request)
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
            let (data, _) = try await urlSession.data(from: url)
            return data
        } catch {
            throw PlantImageGeneratorError.failedToLoadImageAtURL
        }
    }

    private func makeRequest(prompt: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/generations")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        let parameters: [String : Any] = ["model": "dall-e-3",
                                          "prompt": prompt,
                                          "n": 1,
                                          "size": "1024x1024"]
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
