//
//  FullScreenImageViewController.swift
//  nextStudents
//
//  Copyright © 2020 Tim Kohlstadt, Benedict Zendel. All rights reserved.
//


import UIKit

class FullScreenImageViewController: UIViewController , UIScrollViewDelegate {
    
    // MARK: - Variables
    
    var imageUrl: String?
    var imageToShow: UIImage?
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var imageView: UIImageView!
    
    // MARK: - UIViewController events
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let image = imageToShow {
            imageView.image = image
        }
    }
    
}
