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
    @IBOutlet weak var zoomLevelLabel: UILabel!
    @IBOutlet weak var zoomLevelSlider: UISlider!
    
    
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
        showPicker(UIImagePickerControllerSourceType.photoLibrary)
    }
    
    func pickFromURL() {
        showActionChoiseMenu(imageURL: kImageUrlString)
    }
    
    func showPreview(_ image: UIImage? = nil, imageURL: String? = nil) {
        let zoomLevel = zoomLevelSlider.value > 0.0
            ? ORCropImageViewController.InitialZoom.custom(scale: CGFloat(zoomLevelSlider.value))
            : ORCropImageViewController.InitialZoom.min
        
        showCropController(.none, image: image, imageURL: imageURL, isPreview: true, zoomLevel: zoomLevel)
    }
    
    func cropImage(_ cursorType: ORCropImageViewController.CursorType, image: UIImage? = nil, imageURL: String? = nil) {
        let zoomLevel = zoomLevelSlider.value > 0.0
            ? ORCropImageViewController.InitialZoom.custom(scale: CGFloat(zoomLevelSlider.value))
            : ORCropImageViewController.InitialZoom.min
        
        showCropController(cursorType, image: image, imageURL: imageURL, zoomLevel: zoomLevel)
    }
    
    func showCropController(_ cursorType: ORCropImageViewController.CursorType, image: UIImage? = nil, imageURL: String? = nil, isPreview: Bool = false, zoomLevel: ORCropImageViewController.InitialZoom = .normal) {
        let vc = ORCropImageViewController.defaultViewController()
        vc.cursorType = cursorType
        vc.delegate = self
        vc.initialZoom = zoomLevel
        vc.isPreview = isPreview
        
        if let img = image {
            vc.srcImage = img
        } else if let urlStr = imageURL, let url = URL(string: urlStr) {
            vc.setupImageFromURL(url)
        }
        
        self.present(vc, animated: true, completion: nil)
    }
    
    func showPicker(_ sourceType: UIImagePickerControllerSourceType) {
        
        let photoPicker: UIImagePickerController = UIImagePickerController();
        photoPicker.sourceType = sourceType;
        photoPicker.mediaTypes = [kUTTypeImage as String];
        photoPicker.delegate = self;
        photoPicker.navigationBar.isTranslucent = false;
        
        DispatchQueue.main.async { () -> Void in
            self.present(photoPicker, animated: true, completion: nil);
        };
    }
    
    func showErrorAlert(_ title: String?, message: String?) {
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel, handler: nil)
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
        alertVC.addAction(okAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func showActionChoiseMenu(_ image: UIImage? = nil, imageURL: String? = nil) {
        let actionCropCircle = UIAlertAction(title: "Crop To Circle", style: UIAlertActionStyle.default) { (action) in
            self.cropImage(.circle, image: image, imageURL: imageURL)
        }
        
        let actionCropRoundedRect = UIAlertAction(title: "Crop To Rounded Rectangle", style: UIAlertActionStyle.default) { (action) in
            self.cropImage(.roundedRect, image: image, imageURL: imageURL)
        }
        
        let actionPreviewAndResize = UIAlertAction(title: "Preview & Resize", style: UIAlertActionStyle.default) { (action) in
            self.cropImage(.none, image: image, imageURL: imageURL)
        }
        
        let actionPreview = UIAlertAction(title: "Preview", style: UIAlertActionStyle.default) { (action) in
            self.showPreview(image, imageURL: imageURL)
        }
        
        let actionCancel = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        let actionVC = UIAlertController(title: "Choose Action", message: nil, preferredStyle: .actionSheet)
        actionVC.addAction(actionPreview)
        actionVC.addAction(actionPreviewAndResize)
        actionVC.addAction(actionCropCircle)
        actionVC.addAction(actionCropRoundedRect)
        actionVC.addAction(actionCancel)
        self.present(actionVC, animated: true, completion: nil)
    }
    
    
    //MARK: - Actions

    @IBAction func onButtonPickImageDidPress(_ sender: UIButton) {
        let photoLibraryAction = UIAlertAction(title: "Photo Library", style: UIAlertActionStyle.default) { [unowned self] (act) in
            self.pickFromPhotoLibrary()
        }
        
        let pickFromURLAction = UIAlertAction(title: "From URL", style: UIAlertActionStyle.default) { [unowned self] (act) in
            self.pickFromURL()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: nil)
        
        let alertVC = UIAlertController(title: "", message: "Select image source", preferredStyle: UIAlertControllerStyle.actionSheet)
        
        alertVC.addAction(photoLibraryAction)
        alertVC.addAction(pickFromURLAction)
        alertVC.addAction(cancelAction)
        
        self.present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func onPreferedZoomSliderValueChanged(_ sender: UISlider) {
        zoomLevelLabel.text = sender.value > 0.0 ? "x\(sender.value)" : "MIN"
    }
    
    
    //MARK: - UIImagePickerControllerDelegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        let pickedImage = (info[UIImagePickerControllerEditedImage] ?? info[UIImagePickerControllerOriginalImage]) as? UIImage
        
        picker.dismiss(animated: true, completion: { [weak self] () -> Void in
            if let strongSelf = self {
                strongSelf.showActionChoiseMenu(pickedImage)
            }
        });
    }
    
    
    //MARK: - ORCropImageViewControllerDelegate
    
    func cropVCDidFinishCrop(withImage image: UIImage?) {
        ivResult.image = image
    }
    
    func cropVCDidFailToPrepareImage(_ error: NSError?) {
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

