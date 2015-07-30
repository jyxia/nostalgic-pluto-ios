//
//  ImagePreviewTableViewController.swift
//  nostalgic-pluto-ios
//
//  Created by Jinyue Xia on 7/29/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import UIKit
import CoreLocation

class ImagePreviewTableViewController: UITableViewController, CLUploaderDelegate, APIControllerProtocol {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var uploadProgressView: UIProgressView!
    @IBOutlet weak var descTextView: UITextView!
    
    var cloudinary:CLCloudinary = CLCloudinary()
    
    var image: UIImage!
    var userLat: CLLocationDegrees?
    var userLon: CLLocationDegrees?
    
    var imageInfo: ImageInfo?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTextview()
        self.imageView.image = image
        self.tableView.rowHeight = UITableViewAutomaticDimension
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setToolbarHidden(true, animated: false)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.descTextView.resignFirstResponder()
        if (indexPath.section == 0 && indexPath.row == 0) {
            self.performSegueWithIdentifier("FullImageViewSeg", sender: self)
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "FullImageViewSeg" {
            let destinationViewer = segue.destinationViewController as! FullImageViewController
            destinationViewer.fullImage = self.image
        }
    }
    
    @IBAction func didPressSend(sender: AnyObject) {
        if self.navigationItem.rightBarButtonItem!.enabled {
            uploadToCloudinary()
            self.navigationItem.title = "Sending..."
            self.navigationItem.rightBarButtonItem?.enabled = false
        }
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
        // println(successResult)
        let publicId = successResult["public_id"] as! String
        let time = successResult["created_at"] as! String
        println("now cloudinary uploaded, public id is: \(publicId), ready for uploading media")
        self.uploadProgressView.setProgress(0, animated: false)
        let url = successResult["url"] as? String
        self.prepareImageInfo(publicId, time: time)
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
            loc = [Double(self.userLon!), Double(self.userLat!)]
        }
        var imgDescription = ""
        if var imageDescription = self.descTextView.text {
            imgDescription = imageDescription
        }
        self.imageInfo = ImageInfo(name: publicId, loc: loc, time: time, imgDescription: imgDescription)
        let requestBody = self.JSONStringify(self.imageInfo!.toJSON(), prettyPrinted: false)
        var apiService = APIService()
        apiService.delegate = self
        let apiURL = APIAdapter.api.newImageAPI()
        apiService.post(apiURL, httpBody: requestBody)
    }
    
    
    //----------------------------------------------------------------------------------------------
    // Struct for ImageInfo
    //----------------------------------------------------------------------------------------------
    struct ImageInfo {
        var name: String
        var loc: [Double]?
        var time : String
        var imgDescription: String
        
        func toJSON() -> [String : AnyObject] {
            var location:[Double]
            if let loc = self.loc {
                location = loc
            } else  {
                location = [0.0, 0.0]
            }
            
            let locArray: [String: AnyObject] = [
                "type" : "Point",
                "coordinates": location
            ]
            
            return [
                "name": self.name,
                "time": self.time,
                "loc": locArray,
                "description": self.imgDescription
            ]
        }
    }
    
    // implement APIControllerProtocal
    func didReceiveAPIResults(response: NSDictionary) {
        let data = self.JSONStringify(self.imageInfo!.toJSON(), prettyPrinted: false)
        if let string = NSString(data: data!, encoding: NSUTF8StringEncoding) {
        }
        println(response)
        self.navigationItem.title = "Preview"
        self.navigationItem.rightBarButtonItem?.title = "Done"
        self.navigationItem.rightBarButtonItem?.style = UIBarButtonItemStyle.Plain
    }
    
    private func JSONStringify(value: AnyObject, prettyPrinted: Bool = false) -> NSData? {
        var options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : nil
        if NSJSONSerialization.isValidJSONObject(value) {
            if let data = NSJSONSerialization.dataWithJSONObject(value, options: options, error: nil) {
                if let string = NSString(data: data, encoding: NSUTF8StringEncoding) {
                    // return string as String
                    // println("post body is: \(string as String)")
                }
                return data
            }
        }
        return nil
    }
    
    private func setupTextview() {
        descTextView.layer.cornerRadius = 5
        descTextView.layer.borderColor = UIColor.lightGrayColor().CGColor
        descTextView.layer.borderWidth = 1
    }


}
