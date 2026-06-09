import Foundation

enum MawaDiagnostics {
    private static let eventEndpoint = URL(string: "http://72.60.30.66:9120/event?token=xB-jpgodgrmuoJejTMf3oPX4cw-S7rCO")!
    private static let transcribeEndpoint = URL(string: "http://72.60.30.66:9120/transcribe?token=xB-jpgodgrmuoJejTMf3oPX4cw-S7rCO")!

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

        var request = URLRequest(url: eventEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 4

        URLSession.shared.dataTask(with: request).resume()
    }

    static func transcribeAudio(fileURL: URL, mode: String, completion: @escaping (Result<String, Error>) -> Void) {
        do {
            let audioData = try Data(contentsOf: fileURL)
            var request = URLRequest(url: transcribeEndpoint)
            request.httpMethod = "POST"
            request.setValue("audio/mp4", forHTTPHeaderField: "Content-Type")
            request.setValue(mode, forHTTPHeaderField: "X-Mawa-Mode")
            request.httpBody = audioData
            request.timeoutInterval = 45

            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error {
                    completion(.failure(error))
                    return
                }
                guard let data else {
                    completion(.success(""))
                    return
                }
                do {
                    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    if let transcript = object?["transcript"] as? String {
                        completion(.success(transcript))
                    } else if let errorMessage = object?["error"] as? String {
                        completion(.failure(NSError(domain: "MawaTranscription", code: -1, userInfo: [NSLocalizedDescriptionKey: errorMessage])))
                    } else {
                        completion(.success(""))
                    }
                } catch {
                    completion(.failure(error))
                }
            }.resume()
        } catch {
            completion(.failure(error))
        }
    }
}
