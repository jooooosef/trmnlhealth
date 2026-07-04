import Foundation
import Testing
@testable import HealthForTRMNL

/// Intercepts real URLSession traffic in-process so the ACTUAL outgoing
/// HTTP request of URLSessionWebhookClient can be asserted, no network.
nonisolated final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) static var lastRequest: URLRequest?
    nonisolated(unsafe) static var lastBody: Data?
    nonisolated(unsafe) static var responseStatus = 200

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.lastRequest = request
        Self.lastBody = Self.bodyData(of: request)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: Self.responseStatus,
            httpVersion: nil,
            headerFields: nil
        )!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data())
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    /// URLSession hands the body to protocols as a stream, not httpBody.
    private static func bodyData(of request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var data = Data()
        let bufferSize = 4096
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer { buffer.deallocate() }
        while stream.hasBytesAvailable {
            let read = stream.read(buffer, maxLength: bufferSize)
            guard read > 0 else { break }
            data.append(buffer, count: read)
        }
        return data
    }
}

@Suite(.serialized)
struct URLSessionWebhookClientTests {
    private func makeClient() -> URLSessionWebhookClient {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [StubURLProtocol.self]
        return URLSessionWebhookClient(session: URLSession(configuration: config))
    }

    @Test
    func postSendsJSONBodyToGivenAddress() async throws {
        StubURLProtocol.responseStatus = 200
        let body = Data(#"{"merge_variables":{"schema_version":1}}"#.utf8)
        // 192.0.2.x is an RFC 5737 documentation address: guaranteed
        // unroutable. StubURLProtocol intercepts the request before any
        // DNS or socket work, so no traffic leaves the process either way.
        let url = URL(string: "http://192.0.2.50:4567/api/custom_plugins/my-uuid")!

        try await makeClient().post(body, to: url)

        #expect(StubURLProtocol.lastRequest?.httpMethod == "POST")
        #expect(StubURLProtocol.lastRequest?.url == url)
        #expect(StubURLProtocol.lastRequest?.value(forHTTPHeaderField: "Content-Type") == "application/json")
        #expect(StubURLProtocol.lastBody == body)
    }

    @Test
    func postThrowsOnServerError() async {
        StubURLProtocol.responseStatus = 429

        await #expect(throws: WebhookResponseError.self) {
            try await makeClient().post(Data("{}".utf8), to: URL(string: "http://localhost:4567/api/custom_plugins/x")!)
        }
    }
}
