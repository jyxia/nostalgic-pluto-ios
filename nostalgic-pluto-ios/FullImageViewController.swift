//
//  FullImageViewController.swift
//  nostalgic-pluto-ios
//
//  Created by Jinyue Xia on 7/29/15.
//  Copyright (c) 2015 Jinyue Xia. All rights reserved.
//

import UIKit

class FullImageViewController: UIViewController {

    @IBOutlet weak var fullImageView: UIImageView!
    
    var fullImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.fullImageView.image = fullImage
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}
