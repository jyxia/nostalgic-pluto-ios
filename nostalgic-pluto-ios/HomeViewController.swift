//
//  ViewController.swift
//  nostalgic-pluto-ios
//
//  Created by Jinyue Xia on 7/18/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import UIKit
import MobileCoreServices
import AVFoundation
import CoreLocation

class HomeViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var capturePreview: UIView!
    var newImage: UIImage?
    let captureSession = AVCaptureSession()
    var previewLayer : AVCaptureVideoPreviewLayer?
    var captureDevice : AVCaptureDevice?
    var stillImageOutput: AVCaptureStillImageOutput?
    
    let locationManager = CLLocationManager()
    
    // data for this page
    var userLat: CLLocationDegrees?
    var userLon: CLLocationDegrees?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initLocationManager()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        capturePreview.bounds = CGRectInset(capturePreview.frame, 0, 0)
        previewLayer!.frame = capturePreview.bounds
        self.navigationController?.setToolbarHidden(false, animated: false)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        let devices = AVCaptureDevice.devices()
        
        // Loop through all the capture devices on this phone
        for device in devices {
            // Make sure this particular device supports video
            if (device.hasMediaType(AVMediaTypeVideo)) {
                // Finally check the position and confirm we've got the back camera
                if(device.position == AVCaptureDevicePosition.Back) {
                    captureDevice = device as? AVCaptureDevice
                    if captureDevice != nil {
                        println("Capture device found")
                        beginSession()
                    }
                }
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    private func setDeviceReady() {
        let devices = AVCaptureDevice.devices()
        self.setDeviceReady()
    }
    
    private func beginSession() {
        self.configureDevice()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        var backCamera = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        
        var error: NSError?
        var input = AVCaptureDeviceInput(device: backCamera, error: &error)
        
        if error == nil && captureSession.canAddInput(input) {
            captureSession.addInput(input)
            
            stillImageOutput = AVCaptureStillImageOutput()
            stillImageOutput!.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
            if captureSession.canAddOutput(stillImageOutput) {
                captureSession.addOutput(stillImageOutput)
                previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
                previewLayer!.videoGravity = AVLayerVideoGravityResizeAspectFill
                previewLayer!.connection?.videoOrientation = AVCaptureVideoOrientation.Portrait
                capturePreview.layer.masksToBounds = false
                capturePreview.layer.addSublayer(previewLayer)
                captureSession.startRunning()
            }
        }

    }
    
    private func configureDevice() {
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.focusMode = AVCaptureFocusMode.AutoFocus
            device.unlockForConfiguration()
        }
    }
    
    private func focusTo(value : Float) {
        if let device = captureDevice {
            if(device.lockForConfiguration(nil)) {
                device.setFocusModeLockedWithLensPosition(value, completionHandler: { (time) -> Void in

                })
                device.unlockForConfiguration()
            }
        }
    }
    
    @IBAction func didPressTakePhoto(sender: UIBarButtonItem) {
        if let videoConnection = stillImageOutput!.connectionWithMediaType(AVMediaTypeVideo) {
            videoConnection.videoOrientation = AVCaptureVideoOrientation.Portrait
            stillImageOutput?.captureStillImageAsynchronouslyFromConnection(videoConnection, completionHandler: {(sampleBuffer, error) in
                if (sampleBuffer != nil) {
                    var imageData = AVCaptureStillImageOutput.jpegStillImageNSDataRepresentation(sampleBuffer)
                    var dataProvider = CGDataProviderCreateWithCFData(imageData)
                    var cgImageRef = CGImageCreateWithJPEGDataProvider(dataProvider, nil, true, kCGRenderingIntentDefault)
                    
                    var image = UIImage(CGImage: cgImageRef, scale: 1.0, orientation: UIImageOrientation.Right)
                    self.newImage = image
                    self.performSegueWithIdentifier("ShowImageInfo", sender: self)
                }
            })
        }
    }

    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if let device = captureDevice {
            device.lockForConfiguration(nil)
            device.focusMode = AVCaptureFocusMode.Locked
            device.unlockForConfiguration()
        }
        var anyTouch = touches.first as! UITouch
        let touchPer = touchPercent( anyTouch as UITouch )
        focusTo(Float(touchPer.x))
    }
    
    override func touchesMoved(touches: Set<NSObject>, withEvent event: UIEvent) {
        var anyTouch = touches.first as! UITouch
        let touchPer = touchPercent( anyTouch as UITouch )
        focusTo(Float(touchPer.x))
    }
    
    func touchPercent(touch : UITouch) -> CGPoint {
        // Get the dimensions of the screen in points
        // let screenSize = UIScreen.mainScreen().bounds.size
        let screenSize = capturePreview.bounds.size
        // Create an empty CGPoint object set to 0, 0
        var touchPer = CGPointZero
        
        // Set the x and y values to be the value of the tapped position, divided by the width/height of the screen
        touchPer.x = touch.locationInView(self.capturePreview).x / screenSize.width
        touchPer.y = touch.locationInView(self.capturePreview).y / screenSize.height
        
        // Return the populated CGPoint
        return touchPer
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ShowImageInfo" {
            let destinationVC = segue.destinationViewController as! ImageViewController
            destinationVC.image = newImage
            destinationVC.userLat = self.userLat
            destinationVC.userLon = self.userLon
            self.hidesBottomBarWhenPushed = true
        }
    }
    
    //----------------------------------------------------------------------------------------------------------------------
    // LocationManager
    //----------------------------------------------------------------------------------------------------------------------
    func initLocationManager() {
        self.locationManager.delegate = self
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.startUpdatingLocation()
    }
    
    // implement location didUpdataLocation
    func locationManager(manager: CLLocationManager!, didUpdateLocations locations: [AnyObject]!) {
        println("location is  \(locations)")
        var userLocation: CLLocation = locations[0] as! CLLocation
        self.userLat = userLocation.coordinate.latitude
        self.userLon = userLocation.coordinate.longitude
        self.locationManager.stopUpdatingLocation()
    }
    
    // implement location didFailWithError
    func locationManager(manager: CLLocationManager!, didFailWithError error: NSError!) {
        var message = "Our app requires to acess your location"
        self.noLocationAlert(message, controller: self)
    }

    private func noLocationAlert(message: String, controller: UIViewController) {
        var alert = UIAlertController(title: "Alert", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        var okAction = UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().openURL(NSURL(string:UIApplicationOpenSettingsURLString)!)
            return
        })
        alert.addAction(okAction)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil))
        controller.presentViewController(alert, animated: true, completion: nil)
    }


}

