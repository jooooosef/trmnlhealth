import Foundation

protocol WebhookClient {
    /// POSTs a JSON body to the webhook URL. Throws on transport errors
    /// and non-2xx responses.
    func post(_ body: Data, to url: URL) async throws
}

struct WebhookResponseError: LocalizedError {
    let statusCode: Int

    var errorDescription: String? {
        "Server responded with status \(statusCode)"
    }
}

final class URLSessionWebhookClient: WebhookClient {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func post(_ body: Data, to url: URL) async throws {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 15

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw WebhookResponseError(statusCode: http.statusCode)
        }
    }
}
