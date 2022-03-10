//
//  SidParse.swift
//  XIV on Mac
//
//  Created by Marc-Aurel Zent on 02.02.22.
//

import Cocoa
import WebKit
import JavaScriptCore

// Make the "user" function visible to JS
@objc protocol SidParseJSExport: JSExport {
    func user(_ string: String)
}

@objc public class SidParseOperation: HTMLParseOperation, SidParseJSExport {
    var loginStr: String?
    
    public override func parseWebView() {
        webView.evaluateJavaScript("document.getElementsByName(\"mainForm\")[0].childNodes[1].textContent") { object, error in
            if error != nil {
                self.errorOut()
                return
            }
            guard let jsText = object as? String else {
                self.errorOut()
                return
            }

            let js = JSContext()!
            js.exceptionHandler = { context, value in
                print(value!.debugDescription)
            }
            // window = new Object;
            let window = JSValue(newObjectIn: js)!
            // window.external = this Swift SidParseOperation instance
            window.setObject(self, forKeyedSubscript: "external" as NSString)
            // global.window = window
            js.setObject(window, forKeyedSubscript: "window" as NSString)

            // This should hopefully cause the user function to get called
            js.evaluateScript(jsText)

            guard let str = self.loginStr else {
                self.errorOut()
                return
            }
            self.result = .result(str)
            self.state = .finished
        }
    }
    
    func errorOut() {
        result = .error
        state = .finished
        return
    }
    
    // Since this instance is assigned to the "external" property on "window"
    // in the JS, calling window.external.user() should execute this function.
    @objc func user(_ string: String) {
        loginStr = string
    }
}
