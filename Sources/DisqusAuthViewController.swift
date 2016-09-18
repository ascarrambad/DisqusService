//
//  DisqusAuthViewController.swift
//  DisqusService
//
//  Copyright (c) 2016 Matteo Riva <matteoriva@me.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit
import WebKit

internal class DisqusAuthViewController: UIViewController, WKNavigationDelegate {
    
    private let webView = WKWebView()
    
    var callback: ((String) -> Void)!
    var url: URL!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(webView)
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        let height = NSLayoutConstraint(item: webView, attribute: .height, relatedBy: .equal, toItem: view, attribute: .height, multiplier: 1, constant: 0)
        let width = NSLayoutConstraint(item: webView, attribute: .width, relatedBy: .equal, toItem: view, attribute: .width, multiplier: 1, constant: 0)
        view.addConstraints([height, width])
        
        let endButton = UIBarButtonItem(barButtonSystemItem: .done,
                                        target: self,
                                        action: #selector(dismissAction))
        endButton.tintColor = UIColor.black
        
        navigationController?.navigationBar.tintColor = UIColor.black
        navigationItem.leftBarButtonItem = endButton
        navigationItem.title = "Disqus Login"
        
        webView.load(URLRequest(url: url!))
    }

    func dismissAction() {
        dismiss(animated: true, completion: nil)
    }
    
    //MARK: - WkNavigationDelegate
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.request.url?.scheme == "disqus-redirect" {
            decisionHandler(.cancel)
            callback(navigationAction.request.url!.query!.replacingOccurrences(of: "code=", with: ""))
            self.dismiss(animated: true, completion: nil)
        } else {
            decisionHandler(.allow)
        }
    }

}
