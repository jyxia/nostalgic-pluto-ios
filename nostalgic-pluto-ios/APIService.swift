//
//  APIService.swift
//  nostalgic-pluto-ios
//
//  Created by Jinyue Xia on 1/3/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import Foundation
import UIKit

protocol APIControllerProtocol {
    func didReceiveAPIResults(response: NSDictionary) -> Void
}

class APIService {
    var delegate: APIControllerProtocol?
    static let CRASHERROR = "APICRASHED"
    
    init() {
    }
    
    func request(from: String, url: String) {
        var nsURL = NSURL(string: url)
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        let task = NSURLSession.sharedSession().dataTaskWithURL(nsURL!, completionHandler: {
            (data, response, error) in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            var error: NSError?
            if error != nil {
                println(error!)
                var erorrMessage = ["status_code" : APIService.CRASHERROR]
            } else {
                if  let jsonResult = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.MutableContainers, error: &error) as? NSDictionary {
//                    self.delegate?.didReceiveResults(from, sourceData: nil, response: jsonResult)
                } else {
                    var message = ["status_code" : APIService.CRASHERROR]
                }
            }
        })
        
        task.resume()
    }
    
    func post(url: String, httpBody: NSData?) {
        var request = NSMutableURLRequest(URL: NSURL(string: url)!)
        var session = NSURLSession.sharedSession()
        request.HTTPMethod = "POST"
//        request.HTTPBody = httpBody.dataUsingEncoding(NSUTF8StringEncoding)
        if let body = httpBody {
            request.HTTPBody = body
        }
        var err: NSError?
        request.addValue("application/json", forHTTPHeaderField: "Content-type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        var task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            var strData = NSString(data: data, encoding: NSUTF8StringEncoding)
            println("Body: \(strData)")
            var err: NSError?
            var json = NSJSONSerialization.JSONObjectWithData(data, options: .MutableLeaves, error: &err) as? NSDictionary
            
            if(err != nil) {
                println(err!.localizedDescription)
                let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                println("Error could not parse JSON: '\(jsonStr)'")
                var erorrMessage = ["status_code" : APIService.CRASHERROR]
            }
            else {
                if let parseJSON = json {
                    self.delegate?.didReceiveAPIResults(parseJSON)
                    var success = parseJSON["status_code"] as? Int
                }
                else {
                    let jsonStr = NSString(data: data, encoding: NSUTF8StringEncoding)
                    println("Error could not parse JSON: \(jsonStr)")
                    var erorrMessage = ["status_code" : APIService.CRASHERROR]
                }
            }
        })
        
        task.resume()
    }
   
    // a general function to parse passed parameters to a HTTPPostBoby String
    func paramsToHttpBody(params: Dictionary<String, Any>) -> String {
        var paramBody: String = String()
        for (key, value) in params {
            paramBody += "\(key)=\(value)&"
        }
        return paramBody.substringToIndex(paramBody.endIndex.predecessor())
    }
    
    
}