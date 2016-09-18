//
//  DisqusService.swift
//  Subspedia
//
//  Created by Matteo Riva on 05/09/16.
//  Copyright © 2016 Matteo Riva. All rights reserved.
//

import Foundation
import SafariServices

extension Notification.Name {
    static let DisqusServiceSafariAuthDidClose = Notification.Name("DisqusServiceSafariAuthDidClose")
}

public class DisqusService: NSObject, SFSafariViewControllerDelegate {
    
    public typealias disqusAuthCompletion = (Bool) -> Void
    public typealias disqusAPICompletion = ([AnyHashable : Any]?,Bool) -> Void
    
    public static let shared = DisqusService()
    
    private let authURL = "https://disqus.com/api/oauth/2.0/"
    private let baseURL = "https://disqus.com/api/3.0/"
    
    private var secretKey: String!
    private var publicKey: String!
    private var redirectURI: String!
    
    private var loggedUser: DisqusUser? {
        didSet {
            if loggedUser != nil {
                let data = NSKeyedArchiver.archivedData(withRootObject: loggedUser!)
                UserDefaults.standard.set(data, forKey: "disqusLoggedUser")
            } else {
                UserDefaults.standard.removeObject(forKey: "disqusLoggedUser")
            }
        }
    }
    
    public var loggedUserID: String? {
        get { return loggedUser?.userID }
    }
    
    public var isUserAuthenticated: Bool {
        get { return loggedUser != nil }
    }
    
    //MARK: - Init
    
    private override init() {
        if let data = UserDefaults.standard.data(forKey: "disqusLoggedUser") {
            loggedUser = NSKeyedUnarchiver.unarchiveObject(with: data) as? DisqusUser
        }
        super.init()
    }
    
    public func set(publicKey: String, secretKey: String, redirectURI: String) {
        self.publicKey = publicKey
        self.secretKey = secretKey
        self.redirectURI = redirectURI
        loggedUser?.refreshToken(publicKey: publicKey, secretKey: secretKey) {[unowned self] (success) in
            if success {
                let data = NSKeyedArchiver.archivedData(withRootObject: self.loggedUser!)
                UserDefaults.standard.set(data, forKey: "disqusLoggedUser")
            }
        }
    }
    
    //MARK: - Auth
    
    public func authenticate(viewController: UIViewController, completionHandler: @escaping disqusAuthCompletion) {
        
        var urlString = "authorize/"
        urlString += "?client_id=\(publicKey!)"
        urlString += "&scope=read,write"
        urlString += "&response_type=code"
        urlString += "&redirect_uri=\(redirectURI!)"
        
        let url = URL(string: authURL + urlString)!
        
        if #available(iOS 9.0, *) {
            let safariVC = SFSafariViewController(url: url)
            safariVC.delegate = self
            viewController.present(safariVC, animated: true, completion: nil)
            NotificationCenter.default.addObserver(forName: .DisqusServiceSafariAuthDidClose,
                                                   object: nil, queue: .main ) {[unowned self] (notif) in
                                                    safariVC.dismiss(animated: true, completion: nil)
                                                    let tmpCode = (notif.object as! URL).query!.replacingOccurrences(of: "code=", with: "")
                                                    let url2 = URL(string: self.authURL + "access_token/")!
                                                    let params = ["grant_type" : "authorization_code",
                                                                  "client_id" : self.publicKey!,
                                                                  "client_secret" : self.secretKey!,
                                                                  "redirect_uri" : self.redirectURI!.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!,
                                                                  "code" : tmpCode]
                                                    
                                                    self.performPOSTConnection(url: url2, parameters: params) { [unowned self] (data, error) in
                                                        if let json = data as? [AnyHashable : Any] {
                                                            self.loggedUser = DisqusUser(json: json)
                                                        }
                                                        completionHandler(error == nil)
                                                    }
            }
        } else {
            let nav = DisqusAuthViewController()
            nav.url = url
            nav.callback = { (tmpCode) in
                let url2 = URL(string: self.authURL + "access_token/")!
                let params = ["grant_type" : "authorization_code",
                              "client_id" : self.publicKey!,
                              "client_secret" : self.secretKey!,
                              "redirect_uri" : self.redirectURI!.addingPercentEncoding(withAllowedCharacters: .alphanumerics)!,
                              "code" : tmpCode]
                
                self.performPOSTConnection(url: url2, parameters: params) { [unowned self] (data, error) in
                    if let json = data as? [AnyHashable : Any] {
                        self.loggedUser = DisqusUser(json: json)
                    }
                    completionHandler(error == nil)
                }
            }
            let navVC = UINavigationController(rootViewController: nav)
            viewController.present(navVC, animated: true, completion: nil)
        }
    }
    
    public func logout() {
        loggedUser = nil
    }
    
    //MARK: - Api call
    
    public func performGETRequest(api: String, authRequired: Bool = false, params: [AnyHashable : Any], completionHandler: @escaping disqusAPICompletion) {
        performRequest(api: api, authRequired: authRequired, params: params, method: "GET", completionHandler: completionHandler)
    }
    
    public func performPOSTRequest(api: String, authRequired: Bool = false, params: [AnyHashable : Any], completionHandler: @escaping disqusAPICompletion) {
        performRequest(api: api, authRequired: authRequired, params: params, method: "POST", completionHandler: completionHandler)
    }
    
    private func performRequest(api: String, authRequired: Bool, params: [AnyHashable : Any], method: String, completionHandler: @escaping disqusAPICompletion) {
        let url = URL(string: baseURL + api + ".json")!
        
        var params = params
        params["api_key"] = publicKey!
        params["api_secret"] = secretKey!
        
        if let token = loggedUser?.accessToken {
            if authRequired {
                params["access_token"] = token
            }
        }
        
        let block: conCompletion = { (data, error) in
            let errorCond = error == nil && ((data as? [AnyHashable : Any])?["code"] as? Int) == 0
            completionHandler(data as? [AnyHashable : Any], errorCond)
        }
        
        if method == "GET" {
            performGETConnection(url: url, parameters: params, completionHandler: block)
        } else if method == "POST" {
            performPOSTConnection(url: url, parameters: params, completionHandler: block)
        }
        
    }
    
    //MARK: - General
    
    private typealias conCompletion = (Any?, Error?) -> Void
    
    private func performGETConnection(url: URL, parameters: [AnyHashable : Any]?, completionHandler: @escaping conCompletion) {
        
        var paramString = "?"
        if let parameters = parameters {
            
            for (key,value) in parameters {
                paramString += "\(key)=\(value)&"
            }
            paramString.characters.removeLast()
        }
        let url = URL(string: url.absoluteString + paramString)!
        
        performConnection(url: url, method: "GET", parameters: nil, completionHandler: completionHandler)
    }
    
    private func performPOSTConnection(url: URL, parameters: [AnyHashable : Any]?, completionHandler: @escaping conCompletion) {
        performConnection(url: url, method: "POST", parameters: parameters, completionHandler: completionHandler)
    }
    
    private func performConnection(url: URL, method: String, parameters: [AnyHashable : Any]?, completionHandler: @escaping conCompletion) {
        
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if method == "POST" {
            request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
            
            if let parameters = parameters {
                
                var paramString = ""
                for (key,value) in parameters {
                    paramString += "\(key)=\(value)&"
                }
                paramString.characters.removeLast()
                
                request.httpBody = paramString.data(using: String.Encoding.utf8)!
            }
        }
        
        URLSession.shared.dataTask(with: request, completionHandler: { (data, _, error) in
            
            var json: Any? = nil
            if data != nil {
                json = try? JSONSerialization.jsonObject(with: data!, options: [])
            }
            
            completionHandler(json, error)
        }).resume()
    }
    
    //MARK: - SFSafariViewControllerDelegate
    
    @available(iOS 9.0, *)
    public func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        
    }

}
