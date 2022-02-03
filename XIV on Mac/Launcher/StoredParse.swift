//
//  StoredParse.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import WebKit

public class StoredParseOperation: HTMLParseOperation {
    public override func parseWebView() {
        webView.evaluateJavaScript("document.querySelectorAll('input[name=\"_STORED_\"]')[0].value") { object, error in
            if error != nil {
                self.result = .error
                self.state = .finished
                return
            }
            guard let jsStr = object as? String else {
                self.result = .error
                self.state = .finished
                return
            }
            self.result = .result(jsStr)
            self.state = .finished
        }
    }
}
