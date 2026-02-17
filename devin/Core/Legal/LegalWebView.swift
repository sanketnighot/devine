import SwiftUI
import WebKit

struct LegalWebView: View {
    let document: LegalDocument

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            WebView(urlString: document.urlString)
                .background(DevineTheme.Colors.bgPrimary)
                .navigationTitle(document.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
        }
        .tint(DevineTheme.Colors.ctaPrimary)
    }
}

private struct WebView: UIViewRepresentable {
    let urlString: String

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView(frame: .zero)
        webView.allowsBackForwardNavigationGestures = true
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        guard let url = URL(string: urlString) else {
            return
        }
        if webView.url != url {
            webView.load(URLRequest(url: url))
        }
    }
}
