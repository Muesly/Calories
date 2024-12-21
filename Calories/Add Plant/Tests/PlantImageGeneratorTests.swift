//
//  PlantImageGeneratorTests.swift
//  CaloriesTests
//
//  Created by Tony Short on 01/09/2024.
//

import Foundation
import Testing

@testable import Calories

@MainActor
final class PlantImageGeneratorTests {
    var sut: PlantImageGenerator!
    var mockNetworkClient: MockNetworkClient!

    init() {
        mockNetworkClient = MockNetworkClient()
        sut = PlantImageGenerator(apiKey: "some key", networkClient: mockNetworkClient)
    }

    deinit {
        mockNetworkClient = nil
        sut = nil
    }

    @Test func promptText() {
        #expect(sut.promptText(for: "Rice") == "Photo of Rice in a white bowl")
    }

    @Test func plantImageGeneratorSucceeds() async throws {
        let response = GPTResponse(data: [GPTResponse.GPTImage(url: "https://www.example.com/plantImage")])
        mockNetworkClient.promptResponse = try JSONEncoder().encode(response)
        #expect(try await sut.generate(for: "Rice") == Data())
    }

    @Test func plantImageGeneratorFailsOnDecoding() async throws {
        mockNetworkClient.promptResponse = "{\"some broken api response\":\"true\"}".data(using: .utf8)
        await #expect(performing: {
            try await sut.generate(for: "Rice")
        }, throws: { error in
            error as! PlantImageGeneratorError == PlantImageGeneratorError.failedToDecodeImageFromResponse
        })
    }

    @Test func plantImageGeneratorFailsOnNoImages() async throws {
        let response = GPTResponse(data: [])
        mockNetworkClient.promptResponse = try! JSONEncoder().encode(response)
        await #expect(performing: {
            try await sut.generate(for: "Rice")
        }, throws: { error in
            error as! PlantImageGeneratorError == PlantImageGeneratorError.noURLsReturned
        })
    }

    @Test func plantImageGeneratorFailsOnInvalidURL() async throws {
        let response = GPTResponse(data: [.init(url: "")])
        mockNetworkClient.promptResponse = try! JSONEncoder().encode(response)
        await #expect(performing: {
            try await sut.generate(for: "Rice")
        }, throws: { error in
            error as! PlantImageGeneratorError == PlantImageGeneratorError.invalidURLReturned
        })
    }

    @Test func plantImageGeneratorFailsOnFailedImageURL() async throws {
        let response = GPTResponse(data: [GPTResponse.GPTImage(url: "https://www.example.com/plantImage")])
        mockNetworkClient.promptResponse = try JSONEncoder().encode(response)
        mockNetworkClient.imageResponseThrows = true
        await #expect(performing: {
            try await sut.generate(for: "Rice")
        }, throws: { error in
            error as! PlantImageGeneratorError == PlantImageGeneratorError.failedToLoadImageAtURL
        })
    }
}

class MockNetworkClient: NetworkClientType {
    var promptResponse: Data!
    var imageResponse: Data!
    var imageResponseThrows: Bool = false

    func data(fromRequest request: URLRequest) async throws -> Data {
        let urlStr = request.url?.absoluteString
        if urlStr == "https://api.openai.com/v1/images/generations" {
            return promptResponse
        } else if urlStr == "https://www.example.com/plantImage" {
            if imageResponseThrows {
                throw NSError(domain: "", code: 404)
            } else {
                return Data()
            }
        } else {
            throw NSError(domain: "", code: 404)
        }
    }
}
