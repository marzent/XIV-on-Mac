//
//  HTMLParser.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Foundation
import WebKit

// Fetches the STORED out of a login page html
public enum HTMLParseResult: Equatable {
    case result(String)
    case error
    
    public static func ==(lhs: HTMLParseResult, rhs: HTMLParseResult) -> Bool {
        switch (lhs, rhs) {
        case (.error, .error):
            return true
        case (let .result(r1), let .result(r2)):
            return r1 == r2
        default:
            return false
        }
    }
}

public class HTMLParseOperation: AsyncOperation, WKNavigationDelegate {
    let html: String
    
    init(html: String) {
        self.html = html
        super.init()
    }
    
    var webView: WKWebView!
    var result: HTMLParseResult?
    
    override open func main() {
        if self.isCancelled {
            state = .finished
            return
        } else {
            state = .executing
        }
        
        DispatchQueue.main.async {
            self.webView = WKWebView()
            self.webView.navigationDelegate = self
            self.webView.loadHTMLString(self.html, baseURL: URL(string: "http://localhost"))
        }
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        parseWebView()
    }
    
    open func parseWebView() {
        // Implement in subclasses
    }
}
