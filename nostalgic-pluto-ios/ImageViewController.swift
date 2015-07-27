//
//  ImageViewController.swift
//  nostalgic-pluto-ios
//
//  Created by Jinyue Xia on 7/19/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import UIKit
import CoreLocation

class ImageViewController: UIViewController, CLUploaderDelegate, APIControllerProtocol {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    @IBOutlet weak var metaLabel: UILabel!

    var cloudinary:CLCloudinary = CLCloudinary()
    
    var image: UIImage!
    var userLat: CLLocationDegrees?
    var userLon: CLLocationDegrees?
    var time : NSDate?

    var imageInfo: ImageInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = image
        self.prepareImageInfo("htjjsg2wymkkt3vqg15u", time: "2015-07-27T04:42:40Z")

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func didPressSend(sender: AnyObject) {
        uploadToCloudinary()
    }

    //----------------------------------------------------------------------------------------------
    // cloudinary upload
    //----------------------------------------------------------------------------------------------
    func uploadToCloudinary() {
        let forUpload = UIImageJPEGRepresentation(image, 0.8) as NSData

        let uploader = CLUploader(cloudinary, delegate: self)
        uploader.upload(forUpload, options: nil, withCompletion:onCloudinaryCompletion, andProgress:onCloudinaryProgress)
    }
    
    func onCloudinaryCompletion(successResult:[NSObject : AnyObject]!, errorResult:String!, code:Int, idContext:AnyObject!) {
        println(successResult)
        let publicId = successResult["public_id"] as! String
        let time = successResult["created_at"] as! String
        println("now cloudinary uploaded, public id is: \(publicId), ready for uploading media")
        self.uploadProgressView.setProgress(0, animated: false)
        self.metaLabel.text = successResult["url"] as? String
//        self.prepareImageInfo(publicId, time: time)
    }
    
    func onCloudinaryProgress(bytesWritten:Int, totalBytesWritten:Int, totalBytesExpectedToWrite:Int, idContext:AnyObject!) {
        var progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite) as Float
        self.uploadProgressView.setProgress(progress, animated: false)
        println("uploading to cloudinary... wait! \(progress * 100)%")
    }
    
    //----------------------------------------------------------------------------------------------
    // prepare to send to API
    //----------------------------------------------------------------------------------------------
    private func prepareImageInfo(publicId: String, time: String) {
        var loc: [Double]?
        if self.userLat != nil &&  self.userLon != nil {
            loc = [Double(self.userLat!), Double(self.userLon!)]
        }
        self.imageInfo = ImageInfo(name: publicId, loc: loc, time: time)
        let requestBody = self.JSONStringify(self.imageInfo!.toJSON(), prettyPrinted: false)
        println(requestBody)
        var apiService = APIService()
        let apiURL = APIAdapter.api.newImageAPI()
        apiService.post(apiURL, httpBody: requestBody)
    }

    private func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> String {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    return string as String
                }
            }
        }
        return ""
    }
    
    
    //----------------------------------------------------------------------------------------------
    // Struct for ImageInfo
    //----------------------------------------------------------------------------------------------
    struct ImageInfo {
        var name: String
        var loc: [Double]?
        var time : String
        
        func toJSON() -> [String : AnyObject] {
            var location:[Double]
            if let loc = self.loc {
                location = loc
            } else  {
                location = [0.0, 0.0]
            }
            
            return [
                "name": self.name,
                "time": self.time,
                "loc": [
                    "type" : "Point",
                    "coordinates": location
                ]
            ]
        }
    }
    
    func didReceiveAPIResults(response: NSDictionary) {
        println(response)
    }
}
