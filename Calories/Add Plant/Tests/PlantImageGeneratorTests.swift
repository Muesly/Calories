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

    init() {
        let configuration: URLSessionConfiguration = .ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        let urlSession = URLSession(configuration: configuration)

        let response = GPTResponse(data: [.init(url: "https://www.example.com/plantImage")])
        MockURLProtocol.promptResponse = try! JSONEncoder().encode(response)
        MockURLProtocol.imageResponseThrows = false

        sut = PlantImageGenerator(apiKey: "some key",
                                  urlSession: urlSession)
    }

    deinit {
        sut = nil
    }

    @Test func plantImageGeneratorSucceeds() async throws {
        let response = GPTResponse(data: [.init(url: "https://www.example.com/plantImage")])
        MockURLProtocol.promptResponse = try! JSONEncoder().encode(response)
        #expect(try await sut.generate(for: "Rice") == Data())
    }

    @Test func plantImageGeneratorFailsOnDecoding() async throws {
        MockURLProtocol.promptResponse = "{\"some broken api response\":\"true\"}".data(using: .utf8)
        await #expect(performing: {
            try await sut.generate(for: "Rice")
        }, throws: { error in
            error as! PlantImageGeneratorError == PlantImageGeneratorError.failedToDecodeImageFromResponse
        })
    }

    @Test func plantImageGeneratorFailsOnNoImages() async throws {
        let response = GPTResponse(data: [])
        MockURLProtocol.promptResponse = try! JSONEncoder().encode(response)
        await #expect(performing: {
            try await sut.generate(for: "Rice")
        }, throws: { error in
            error as! PlantImageGeneratorError == PlantImageGeneratorError.noURLsReturned
        })
    }

    @Test func plantImageGeneratorFailsOnInvalidURL() async throws {
        let response = GPTResponse(data: [.init(url: "")])
        MockURLProtocol.promptResponse = try! JSONEncoder().encode(response)
        await #expect(performing: {
            try await sut.generate(for: "Rice")
        }, throws: { error in
            error as! PlantImageGeneratorError == PlantImageGeneratorError.invalidURLReturned
        })
    }

    @Test func plantImageGeneratorFailsOnFailedImageURL() async throws {
        MockURLProtocol.imageResponseThrows = true
        await #expect(performing: {
            try await sut.generate(for: "Rice")
        }, throws: { error in
            error as! PlantImageGeneratorError == PlantImageGeneratorError.failedToLoadImageAtURL
        })
    }
}

private class MockURLProtocol: URLProtocol {
    static var promptResponse: Data!
    static var imageResponseThrows: Bool = false

    private static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))? = { request in
        let urlStr = request.url?.absoluteString
        if urlStr == "https://api.openai.com/v1/images/generations" {
            return (HTTPURLResponse(), promptResponse)
        } else if urlStr == "https://www.example.com/plantImage" {
            if imageResponseThrows {
                throw NSError(domain: "", code: 404)
            } else {
                return (HTTPURLResponse(), Data())
            }
        } else {
            throw NSError(domain: "", code: 404)
        }
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            assertionFailure("Received unexpected request with no handler set")
            return
        }

        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {
        // TODO: Andd stop loading here
    }
}
