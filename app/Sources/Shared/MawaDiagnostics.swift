import Foundation

enum MawaDiagnostics {
    private static let endpoint = URL(string: "http://72.60.30.66:9120/event?token=xB-jpgodgrmuoJejTMf3oPX4cw-S7rCO")!

    static func send(event: String, source: String, details: [String: String] = [:]) {
        var payload: [String: Any] = [
            "event": event,
            "source": source,
            "client_ts": ISO8601DateFormatter().string(from: Date()),
            "bundle_id": Bundle.main.bundleIdentifier ?? "unknown",
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown"
        ]
        if !details.isEmpty {
            payload["details"] = details
        }

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            return
        }

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 4

        URLSession.shared.dataTask(with: request).resume()
    }
}
