//
//  ViewController.swift
//  WebViewTest
//
//  Created by Henry Javier Serrano Echeverria on 22/12/20.
//

import UIKit
import WebKit
import Combine

final class ViewController: UIViewController, WKUIDelegate, WKNavigationDelegate {

    private var webView: WKWebView!
    private var cancellables = Set<AnyCancellable>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        let myRequest = URLRequest(url: URL(string: "https://www.google.com")!)
        let myRequest = URLRequest(url: URL(string: "http://127.0.0.1:8000")!)
        
        webView.load(myRequest)
    }
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = WKWebsiteDataStore.nonPersistent()
        webConfiguration.setURLSchemeHandler(self, forURLScheme: "scb")
//        webConfiguration.setURLSchemeHandler(self, forURLScheme: "https")
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        let source = "function captureLog(msg) { window.webkit.messageHandlers.logHandler.postMessage(msg); } window.console.log = captureLog;"
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: false)
        webView.configuration.userContentController.addUserScript(script)
        webView.configuration.userContentController.add(self, name: "logHandler")
        
        view = webView
    }

    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        print("decidePolicyFor navigationAction: \(navigationAction.request.url!)")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse, decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void) {
        print("decidePolicyFor navigationResponse: \(navigationResponse)")
        decisionHandler(.allow)
    }
    
    func webView(_ webView: WKWebView, didCommit navigation: WKNavigation!) {
        print("didCommit: \(String(describing: navigation))")
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        print("didFinish: \(String(describing: navigation))")
    }
    
    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        print("didStartProvisionalNavigation: \(String(describing: navigation))")
    }
    
    func webView(_ webView: WKWebView, didReceive challenge: URLAuthenticationChallenge, completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("didReceive challenge: \(challenge)")
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            let credential = URLCredential(trust: challenge.protectionSpace.serverTrust!)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }

}

enum HenryError: Error {
    case noNetwork
}

extension ViewController: WKURLSchemeHandler {
    func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        print("start urlSchemeTask: \(urlSchemeTask.request)")
        
        let urlString = urlSchemeTask.request.url!.absoluteString.replacingOccurrences(of: "scb://", with: "https://")
//        let urlString = urlSchemeTask.request.url!.absoluteString
        let request = URLRequest(url: URL(string: urlString)!, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 5)
        
        URLSession.shared.dataTaskPublisher(for: request).sink(receiveCompletion: { completion in
            switch completion {
            case .failure:
                urlSchemeTask.didFailWithError(HenryError.noNetwork)
            case .finished:
                print("Request finished")
            }
        }, receiveValue: { data, response in
            urlSchemeTask.didReceive(response)
            urlSchemeTask.didReceive(data)
            urlSchemeTask.didFinish()
            
            print("Request was successful")
        }).store(in: &cancellables)
    }
    
    func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        print("stop urlSchemeTask: \(urlSchemeTask.request)")
    }
}

extension ViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        print("LOG: \(message.body)")
    }
}
