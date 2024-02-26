//
//  APIClientTests.swift
//
//
//  Created by Ulaş Sancak on 1.10.2023.
//

import XCTest
@testable import WPSwift
import Combine

@available(macOS 14.0, *)
final class APIClientTests: XCTestCase {
    private struct Mocked: Decodable {
        let title: String
    }

    private struct EncodableFailure: Encodable {
        let value: Double = .infinity
    }

    private let configuration = URLSessionConfiguration.default
    private var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        WPSwift.initialize(route: "https://www.example.com/wp-json", namespace: "wp/v2")
        URLProtocol.registerClass(MockedURLProtocol.self)
        configuration.protocolClasses = [MockedURLProtocol.self]
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        URLProtocol.unregisterClass(MockedURLProtocol.self)
        configuration.protocolClasses = nil
    }

    func testURL() throws {
        WPSwift.initialize(route: "https://www.example.com/wp-json", namespace: "wp/v2")
        let url = try String.initialize(with: "")
        XCTAssertEqual(url, "https://www.example.com/wp-json/wp/v2/")
    }

    func testURLWithFailure() throws {
        WPSwift.initialize(route: "http://\u{FFFD}\u{FFFE}", namespace: "wp/v2")
        do {
            _ = try String.initialize(with: "")
            XCTAssert(false, "URL initialize should have been failed.")
        } catch NetworkError.urlMalformed {
            XCTAssertEqual(NetworkError.urlMalformed.errorDescription, "URL is malformed.", "Network error message does not match.")
        } catch {
            XCTAssert(false, error.localizedDescription)
        }
    }

    func testAsync() async throws {
        let exampleString = "{\"title\":\"Title\"}"
        let exampleData = exampleString.data(using: .utf8)
        MockedURLProtocol.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "https://www.example.com/wp-json/wp/v2")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (response, exampleData)
        }

        let networkManager = try WPClient<EmptyModel, Mocked>(.init(sessionConfiguration: configuration, endpoint: WPEndpoint.Posts.posts.path, parameters: nil))
        let response = try await networkManager.fetch()
        XCTAssertEqual(response.title, "Title", "Response data does not match the example data.")
    }

    func testCombine() throws {
        let exampleString = "{\"title\":\"Title\"}"
        let exampleData = exampleString.data(using: .utf8)
        MockedURLProtocol.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "https://www.example.com/wp-json/wp/v2")!, statusCode: 200, httpVersion: nil, headerFields: nil)
            return (response, exampleData)
        }

        let networkManager = try WPClient<EmptyModel, Mocked>(.init(sessionConfiguration: configuration, endpoint: WPEndpoint.Posts.posts.path, parameters: nil))

        let publisher = networkManager.fetchPublisher()

        let expectation = self.expectation(description: "api")

        publisher
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    XCTAssert(false, error.localizedDescription)
                    expectation.fulfill()
                case .finished:
                    expectation.fulfill()
                    break
                }
            } receiveValue: { response in
                XCTAssertEqual(response.title, "Title", "Response data does not match the example data.")
            }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testAsyncWithFailure() async throws {
        let exampleString = "{\"message\":\"Title\"}"
        let exampleData = exampleString.data(using: .utf8)
        MockedURLProtocol.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "https://www.example.com/wp-json/wp/v2")!, statusCode: 403, httpVersion: nil, headerFields: nil)
            return (response, exampleData)
        }

        let networkManager = try WPClient<EmptyModel, Mocked>(.init(sessionConfiguration: configuration, endpoint: WPEndpoint.Posts.posts.path, parameters: nil))
        do {
            _ = try await networkManager.fetch()
            XCTAssert(false, "API returned with success. It should have return with failure!")
        } catch NetworkError.api {
            XCTAssertEqual(NetworkError.api.errorDescription, "API returned an unexpected response.", "Network error message does not match.")
        } catch {
            XCTAssertTrue(false, error.localizedDescription)
        }
    }

    func testCombineWithFailure() throws {
        let exampleString = "{\"title\":\"Title\"}"
        let exampleData = exampleString.data(using: .utf8)
        MockedURLProtocol.observer = { request -> (URLResponse?, Data?) in
            let response = HTTPURLResponse(url: URL(string: "https://www.example.com/wp-json/wp/v2")!, statusCode: 403, httpVersion: nil, headerFields: nil)
            return (response, exampleData)
        }

        let networkManager = try WPClient<EmptyModel, Mocked>(.init(sessionConfiguration: configuration, endpoint: WPEndpoint.Posts.posts.path, parameters: nil))

        let publisher = networkManager.fetchPublisher()

        let expectation = self.expectation(description: "api")

        publisher
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    guard let error = error as? NetworkError,
                          error == .api else {
                        XCTAssert(false, error.localizedDescription)
                        return
                    }
                    XCTAssertEqual(NetworkError.api.errorDescription, "API returned an unexpected response.", "Network error message does not match.")
                    expectation.fulfill()
                case .finished:
                    XCTAssert(false, "API returned with success. It should have return with failure!")
                    expectation.fulfill()
                    break
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

    func testCombineWithEncodingFailure() throws {
        WPSwift.initialize(route: "http://www.example.com/wp-json", namespace: "wp/v2")
        let networkManager = try WPClient<EncodableFailure, Mocked>(.init(sessionConfiguration: configuration, endpoint: WPEndpoint.Posts.posts.path, method: .post, requestModel: EmptyModel()))

        let publisher = networkManager.fetchPublisher()

        let expectation = self.expectation(description: "api")

        publisher
            .receive(on: RunLoop.main)
            .sink { completion in
                switch completion {
                case .failure(let error):
                    guard let error = error as? EncodingError,
                          case .invalidValue = error else {
                        XCTAssert(false, error.localizedDescription)
                        return
                    }
                    expectation.fulfill()
                case .finished:
                    XCTAssert(false, "API returned with success. It should have return with failure!")
                    expectation.fulfill()
                    break
                }
            } receiveValue: { _ in }
            .store(in: &cancellables)

        waitForExpectations(timeout: 1)
    }

//    func testHeaders() throws {
//        let request = APIRequest<EmptyModel, Post>(endpoint: WPEndpoint.Posts.posts.path, method: .get, headers: ["Custom-Header": "Custom-Value"])
//        XCTAssertEqual(request.headers["Content-Type"], "application/json", "Headers don't match.")
//        XCTAssertEqual(request.headers["Custom-Header"], "Custom-Value", "Headers don't match.")
//    }

    func testErrorDescriptions() {
        let urlMalformed: NetworkError = .urlMalformed
        XCTAssertEqual(urlMalformed.errorDescription, "URL is malformed.", "Network Error Description does not matcn.")
        let api: NetworkError = .api
        XCTAssertEqual(api.errorDescription, "API returned an unexpected response.", "Network Error Description does not matcn.")
        let unknown: NetworkError = .unknown
        XCTAssertEqual(unknown.errorDescription, "Unknown error.", "Network Error Description does not matcn.")
    }
}
