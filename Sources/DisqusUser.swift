//
//	DisqusUser.swift
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

import Foundation

class DisqusUser: NSObject, NSCoding {
    
    private(set) var accessToken: String
    private var refreshToken: String
    let userID: String
    let username: String
    var isTokenValid = true
    
    init?(json: [AnyHashable : Any]) {
        guard let accessToken = json["access_token"] as? String,
            let refreshToken = json["refresh_token"] as? String,
            let userID = json["user_id"] as? Int,
            let username = json["username"] as? String
            else { return nil }
        
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.userID = "\(userID)"
        self.username = username
    }
    
    required init?(coder aDecoder: NSCoder) {
        accessToken = aDecoder.decodeObject(forKey: "access_token") as! String
        refreshToken = aDecoder.decodeObject(forKey: "refresh_token") as! String
        userID = aDecoder.decodeObject(forKey: "user_id") as! String
        username = aDecoder.decodeObject(forKey: "username") as! String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(accessToken, forKey: "access_token")
        aCoder.encode(refreshToken, forKey: "refresh_token")
        aCoder.encode(userID, forKey: "user_id")
        aCoder.encode(username, forKey: "username")
    }
    
    func refreshToken(publicKey: String, secretKey: String, completionHandler: @escaping (Bool) -> Void) {
        
        let url = URL(string: "https://disqus.com/api/oauth/2.0/access_token/")!
        
        let params = ["grant_type" : "refresh_token",
                      "client_id" : publicKey,
                      "client_secret" : secretKey,
                      "refresh_token" : refreshToken]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        var paramString = ""
        for (key,value) in params {
            paramString += "\(key)=\(value)&"
        }
        
        request.httpBody = paramString.data(using: String.Encoding.utf8)!
        
        URLSession.shared.dataTask(with: request, completionHandler: {[unowned self] (data, _, error) in
            if error == nil {
                if let json = (try? JSONSerialization.jsonObject(with: data!, options: [])) as? [AnyHashable : Any] {
                    
                    guard let accessToken = json["access_token"] as? String,
                        let refreshToken = json["refresh_token"] as? String
                        else {
                            DisqusService.shared.logout()
                            return
                    }
                    
                    self.accessToken = accessToken
                    self.refreshToken = refreshToken
                }
            }
            completionHandler(error == nil)
            self.isTokenValid = error == nil
            }).resume()
        
    }
}
