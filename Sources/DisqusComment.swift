//
//  DisqusComment.swift
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

extension Notification.Name {
    static let DisqusServiceDidPostNewComment = Notification.Name("DisqusServiceDidPostNewComment")
}

public class DisqusComment: NSObject {
    
    public let profileImageURL: URL
    public let authorID: String?
    public let author: String?
    public let message: String
    public let postID: String
    public let isDeleted: Bool
    public let elapsedTime: String?
    public let points: Int
    
    public let parentID: String?
    public var replies = [DisqusComment]()
    
    required public init?(disqusData: [AnyHashable : Any]) {
        
        guard let author = disqusData["author"] as? [AnyHashable : Any],
            let avatar = author["avatar"] as? [AnyHashable : Any],
            let avatarURL = avatar["permalink"] as? String,
            let comment = disqusData["raw_message"] as? String,
            let tmpDate = disqusData["createdAt"] as? String,
            let isDeleted = disqusData["isDeleted"] as? Bool,
            let id = disqusData["id"] as? String,
            let points = disqusData["points"] as? Int
            else { return nil }
        
        self.profileImageURL = URL(string: avatarURL)!
        self.author = author["name"] as? String
        self.authorID = author["id"] as? String
        self.message =  comment
        self.isDeleted = isDeleted
        self.postID = id
        self.points = points
        
        if let parentID = disqusData["parent"] as? Int {
            self.parentID = "\(parentID)"
        } else {
            self.parentID = nil
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy'-'MM'-'dd'T'HH':'mm':'ss Z"
        
        if let creationDate = formatter.date(from: "\(tmpDate) +0000") {
            let today = Date()
            let distanceBetweenDates = today.timeIntervalSince(creationDate)
            
            if (distanceBetweenDates/31536000 >= 1) {
                elapsedTime = "\(Int(distanceBetweenDates/31536000)) y"
            } else if (distanceBetweenDates/2592000 >= 1) {
                elapsedTime = "\(Int(distanceBetweenDates/2592000)) mes"
            } else if (distanceBetweenDates/604800 >= 1) {
                elapsedTime = "\(Int(distanceBetweenDates/604800)) set"
            } else if (distanceBetweenDates/86400 >= 1) {
                elapsedTime = "\(Int(distanceBetweenDates/86400)) gg"
            } else if (distanceBetweenDates/3600 >= 1) {
                elapsedTime = "\(Int(distanceBetweenDates/3600)) h"
            } else if (distanceBetweenDates/60 >= 1) {
                elapsedTime = "\(Int(distanceBetweenDates/60)) min"
            } else if (distanceBetweenDates >= 30) {
                elapsedTime = "\(Int(distanceBetweenDates)) sec"
            } else {
                elapsedTime = "Ora"
            }
        } else {
            elapsedTime = "n/d"
        }
        
        super.init()
    }
    
    public func attachReplies(_ replies: [[AnyHashable : Any]]) {
        
        let real = replies.filter { $0["parent"] as! Int == Int(self.postID)! }
        let remaining = replies.filter { $0["parent"] as! Int != Int(self.postID)! }
        
        if real.count == 0 { return }
        
        for comment in real {
            if let dComment = DisqusComment(disqusData: comment) {
                self.replies.append(dComment)
                if remaining.count != 0 {
                    dComment.attachReplies(remaining)
                }
            }
        }
    }
   
}
