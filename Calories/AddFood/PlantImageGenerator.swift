//
//  PlantImageGenerator.swift
//  Calories
//
//  Created by Tony Short on 31/08/2024.
//

import Foundation
import UIKit

protocol PlantImageGenerating {
    func generate(for plantName: String) async throws -> Data
}

enum PlantImageGeneratorError: Error {
    case failedToDecodeImageFromResponse
    case failedToFindContentInResponse
    case failedToDecodeImageFromGPTSuggestion
}

struct PlantImageGenerator: PlantImageGenerating {
    private func promptText(for plantName: String) -> String {
        return "Photo of \(plantName) in a white bowl"
    }

    func generate(for plantName: String) async throws -> Data {
        let apiKey = Bundle.main.infoDictionary!["GPT API Key"]!
        var request = URLRequest(url: URL(string: "https://api.openai.com/v1/images/generations")!)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        let prompt = promptText(for: plantName)
        let parameters: [String : Any] = ["model": "dall-e-3",
                                          "prompt": prompt,
                                          "n": 1,
                                          "size": "1024x1024"]
        request.httpBody = try? JSONSerialization.data(withJSONObject: parameters, options: [])

        let (data, _) = try await URLSession.shared.data(for: request)
        let response: GPTResponse
        do {
            let decoder = JSONDecoder()
            response = try decoder.decode(GPTResponse.self, from: data)
        } catch {
            throw PlantImageGeneratorError.failedToDecodeImageFromResponse
        }
        if let imageURL = response.data.first?.url {
            let (data, _) = try await URLSession.shared.data(from: URL(string: imageURL)!)
            return data
        } else {
            throw PlantImageGeneratorError.failedToFindContentInResponse
        }
    }
}

struct GPTResponse: Decodable {
    struct GPTImage: Decodable {
        let url: String
    }
    let data: [GPTImage]
}
