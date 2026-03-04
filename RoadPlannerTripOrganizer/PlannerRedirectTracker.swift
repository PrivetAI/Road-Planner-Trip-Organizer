import Foundation

class PlannerRedirectTracker: NSObject, ObservableObject {
    @Published var plannerLinkReady: Bool = false
    @Published var showApp: Bool = false
    @Published var finalURL: URL?

    let plannerEndpoint = "https://roadplannertriporganizer.org/click.php"

    func checkRedirect() {
        guard let url = URL(string: plannerEndpoint) else {
            showApp = true
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        let task = session.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if self.plannerLinkReady { return }
                if error != nil {
                    self.showApp = true
                } else if let httpResp = response as? HTTPURLResponse,
                          let loc = httpResp.url?.absoluteString,
                          loc.contains("freeprivacypolicy.com") {
                    self.showApp = true
                } else {
                    self.finalURL = response?.url ?? url
                    self.plannerLinkReady = true
                }
            }
        }
        task.resume()

        // Timeout fallback
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in
            guard let self = self else { return }
            if !self.plannerLinkReady && !self.showApp {
                self.showApp = true
            }
        }
    }
}

extension PlannerRedirectTracker: URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        if let redirectURL = request.url?.absoluteString, redirectURL.contains("freeprivacypolicy.com") {
            DispatchQueue.main.async {
                self.showApp = true
            }
            completionHandler(nil)
        } else {
            completionHandler(request)
        }
    }
}
