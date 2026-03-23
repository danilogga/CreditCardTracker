import Foundation

actor APIClient {
    static let shared = APIClient()

    private let baseURL = Secrets.apiBaseURL
    private let token = Secrets.apiToken

    func fetchDashboard(month: String, page: Int = 1, pageSize: Int = 15, categoryId: String? = nil) async throws -> DashboardResponse {
        var components = URLComponents(string: baseURL)
        var queryItems = [
            URLQueryItem(name: "month", value: month),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "pageSize", value: String(pageSize))
        ]
        if let categoryId {
            queryItems.append(URLQueryItem(name: "categoryId", value: categoryId))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw APIError.networkError(underlying: error)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse(statusCode: -1)
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw APIError.invalidResponse(statusCode: httpResponse.statusCode)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(DashboardResponse.self, from: data)
        } catch {
            throw APIError.decodingFailed(underlying: error)
        }
    }
}
