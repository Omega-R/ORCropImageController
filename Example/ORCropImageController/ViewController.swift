//
//  ViewController.swift
//  ORCropImageExample
//
//  Created by Nikita Egoshin on 03.05.16.
//  Copyright © 2016 Omega-R. All rights reserved.
//

import UIKit
import MobileCoreServices
import ORCropImageController

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, ORCropImageViewControllerDelegate {

    //MARK: - Constants
    
    let kImageUrlString = "http://sg.uploads.ru/t/ToB8l.jpg"
    
    
    //MARK: - Variables
    
    @IBOutlet weak var ivResult: UIImageView!
    
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        ivResult.layer.cornerRadius = ivResult.frame.size.width * 0.5
        ivResult.clipsToBounds = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    //MARK: - Internal operations
    
    func pickFromPhotoLibrary() {
        showPicker(UIImagePickerControllerSourceType.PhotoLibrary)
    }
    
    func pickFromURL() {
        guard let imageURL = NSURL(string: kImageUrlString) else {
            showErrorAlert("Loading error", message: "Failed to load image.\nReason: Invalid URL")
            return
        }
        
        let vc = ORCropImageViewController.defaultViewController()
        vc.delegate = self
        vc.setupImageFromURL(imageURL)
        self.presentViewController(vc, animated: true, completion: nil)
    }
    
    func showPicker(sourceType: UIImagePickerControllerSourceType) {
        
        let photoPicker: UIImagePickerController = UIImagePickerController();
        photoPicker.sourceType = sourceType;
        photoPicker.mediaTypes = [kUTTypeImage as String];
        photoPicker.delegate = self;
        photoPicker.navigationBar.translucent = false;
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            self.presentViewController(photoPicker, animated: true, completion: nil);
        };
    }
    
    func showErrorAlert(title: String?, message: String?) {
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.Cancel, handler: nil)
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alertVC.addAction(okAction)
        
        self.presentViewController(alertVC, animated: true, completion: nil)
    }
    
    
    //MARK: - Actions

    @IBAction func onButtonPickImageDidPress(sender: UIButton) {
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.Default) { [unowned self] (act) in
            self.pickFromPhotoLibrary()
        }
        
        let pickFromURLAction = UIAlertAction(title: "From URL", style: UIAlertActionStyle.Default) { [unowned self] (act) in
            self.pickFromURL()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: nil)
        
        let alertVC = UIAlertController(title: "", message: "Select image source", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        alertVC.addAction(photoLibraryAction)
        alertVC.addAction(pickFromURLAction)
        alertVC.addAction(cancelAction)
        
        self.presentViewController(alertVC, animated: true, completion: nil)
    }
    
    
    //MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let pickedImage = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage
        
        picker.dismissViewControllerAnimated(true, completion: { [weak self] () -> Void in
            if let strongSelf = self {
                let vc = ORCropImageViewController.defaultViewController()
                vc.delegate = self
                vc.cursorType = .Circle
                vc.srcImage = pickedImage
                strongSelf.presentViewController(vc, animated: true, completion: nil)
            }
        });
    }
    
    
    //MARK: - ORCropImageViewControllerDelegate
    
    func cropVCDidFinishCrop(withImage image: UIImage?) {
        ivResult.image = image
    }
    
    func cropVCDidFailToPrepareImage(error: NSError?) {
        if let err = error {
            showErrorAlert(nil, message: err.localizedDescription)
        }
    }
    
    func titleForCropVCSubmitButton() -> String {
        return "Choose"
    }
    
    func titleForCropVCCancelButton() -> String {
        return "Cancel"
    }
    
    func usingButtonsInCropVC() -> ORCropImageViewController.Button {
        return [.Cancel, .Submit]
    }
    
}

