//
//  ORCropImageViewController.swift
//  InMusik Explorer
//
//  Created by Admin on 3/2/16.
//  Copyright © 2016 Stone Valley Partners. All rights reserved.
//

import UIKit
import QuartzCore


public protocol ORCropImageViewControllerDelegate {
    func titleForCropVCSubmitButton() -> String
    func titleForCropVCCancelButton() -> String
    func usingButtonsInCropVC() -> ORCropImageViewController.Button
    
    func cropVCDidFailToPrepareImage(_ error: NSError?)
    func cropVCDidFinishCrop(withImage image: UIImage?)
}

public protocol ORCropImageViewControllerDownloadDelegate {
    func downloadImage(fromURL url: URL, completion: @escaping (_ image: UIImage?, _ error: NSError?) -> Void);
}

open class ORCropImageViewController: UIViewController, UIScrollViewDelegate {

    //MARK: - Struct
    
    public struct Button : OptionSet {
        public let rawValue: Int
        
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        
        static public let Submit = Button(rawValue: 1)
        static public let Cancel = Button(rawValue: 2)
    }
    
    
    //MARK: - Enumerations
    
    public enum CursorType {
        case none
        case circle
        case roundedRect
    }
    
    public enum InitialZoom {
        case min
        case normal
        case custom(scale: CGFloat)
    }
    
    
    //MARK: - Constants
    
    let kRoundedRectCornerRadius: CGFloat = 3.0
    let kRoundedRectHeightRatio: CGFloat = 0.72
    let kFrameNormalOffset: CGFloat = 8.0
    let kButtonsPanelHeight: CGFloat = 52.0
    
    
    //MARK: - Variables
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var shadeView: UIView!
    @IBOutlet weak var btnSubmit: UIButton!
    @IBOutlet weak var btnCancel: UIButton!
    
    weak var ivImage: UIImageView!
    
    @IBOutlet weak var circleFrameView: UIView!
    
    @IBOutlet weak var lyocCursorViewWidth: NSLayoutConstraint!
    @IBOutlet weak var lyocCursorViewHeight: NSLayoutConstraint!
    @IBOutlet weak var lyocScrollViewBottomOffset: NSLayoutConstraint!
    
    var croppedImageCallback: ((_ image: UIImage?) -> Void)?;
    
    var shadeLayer: CALayer?;
    
    var shouldAddShadeLayer: Bool = true;
    
    open var initialZoom: InitialZoom = .normal
    open var isPreview: Bool = false
    
    open var srcImage: UIImage!;
    open var destImageMaxSize: CGSize?
    
    open var cursorType: CursorType = CursorType.none
    open var delegate: ORCropImageViewControllerDelegate?
    open var downloadDelegate: ORCropImageViewControllerDownloadDelegate? = ORCropImageViewControllerDefaultDownloadDelegate()
    
    
    //MARK: - Initializers
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override public init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    convenience public init(nibName: String?, bundle: Bundle?, image: UIImage) {
        self.init(nibName: nibName, bundle: bundle)
        self.srcImage = image
    }
    
    convenience public init(nibName: String?, bundle: Bundle?, imageURL url: URL) {
        self.init(nibName: nibName, bundle: bundle)
        setupImageFromURL(url)
    }
    
    convenience public init(nibName: String?, bundle: Bundle?, imageURLPath path: String) {
        guard let url = URL(string: path) else {
            self.init(nibName: nibName, bundle: bundle)
            
            ORCropImageViewController.log("Failed to initialize. Reason: Invalid URL string")
            
            onFail(withMessage: "Invalid URL string")
            
            return
        }
        
        self.init(nibName: nibName, bundle: bundle, imageURL: url)
    }
    
    
    //MARK: - Lifecycle
    
    static open func defaultViewController() -> ORCropImageViewController {
        return ORCropImageViewController(nibName: "ORCropImageViewController", bundle: Bundle(for: ORCropImageViewController.self))
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        
        self.lyocScrollViewBottomOffset.constant = (cursorType == .none) ? 0.0 : kButtonsPanelHeight
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        self.fillUI();
    }
    
    override open func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews();
        setupUI()
        fillUI()
    }
    
    
    //MARK: - Setup
    
    open func setupImageFromURL(_ url: URL) {
        guard let dlDelegate = downloadDelegate else {
            onFail(withMessage: "Download delegate is not set!")
            return
        }
        
        dlDelegate.downloadImage(fromURL: url) { [weak self] (image, error) in
            if let srcImage = image {
                self?.srcImage = srcImage
                self?.setupUI()
                self?.fillUI()
            } else {
                self?.delegate?.cropVCDidFailToPrepareImage(error)
            }
        }
    }
    
    func setupUI() {
        prepareCursorView();
        prepareShadeLayer();
        prepareScrollView();
        prepareBottomBarButtons()
    }
    
    func prepareBottomBarButtons() {
        let usingButtons = delegate?.usingButtonsInCropVC() ?? [.Submit, .Cancel]
        
        if usingButtons.contains(.Submit) && srcImage != nil && !isPreview {
            let title = delegate?.titleForCropVCSubmitButton() ?? NSLocalizedString("Save", comment: "")
            btnSubmit.setTitle(title, for: UIControlState())
            btnSubmit.isHidden = false
        } else {
            btnSubmit.isHidden = true
        }
        
        if usingButtons.contains(.Cancel) {
            let title = delegate?.titleForCropVCCancelButton() ?? NSLocalizedString("Cancel", comment: "")
            btnCancel.setTitle(title, for: UIControlState())
            btnCancel.isHidden = false
        } else {
            btnCancel.isHidden = true
        }
    }
    
    func prepareShadeLayer() {
        self.shadeLayer?.removeFromSuperlayer();
        
        self.circleFrameView.isHidden = (cursorType == CursorType.none)
        self.shadeView.isHidden = self.circleFrameView.isHidden
        
        switch cursorType {
        case .roundedRect:
            var frameWidth: CGFloat = 0.0
            var frameHeight: CGFloat = 0.0
            
            if self.view.frame.size.width < self.view.frame.size.height {
                frameWidth = self.view.frame.size.width - kFrameNormalOffset * 2
                frameHeight = frameWidth * kRoundedRectHeightRatio
            } else {
                frameHeight = self.view.frame.size.height - (kFrameNormalOffset + kButtonsPanelHeight)
                frameWidth = frameHeight / kRoundedRectHeightRatio
            }
            
            self.shadeLayer = roundedRectShadeLayer()
            self.shadeLayer!.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: frameWidth, height: frameHeight));
        case .circle:
            self.shadeLayer = circleShadeLayer();
            self.shadeLayer!.frame = self.shadeView.bounds;
        default: break
        }
        
        if self.shadeLayer != nil {
            self.shadeView.layer.addSublayer(self.shadeLayer!);
        }
    }
    
    func prepareScrollView() {
        
        if cursorType != .none {
            let bottomInset: CGFloat = self.view.frame.size.height - self.circleFrameView.frame.maxY - kButtonsPanelHeight;
            let rightInset: CGFloat = self.view.frame.size.width - self.circleFrameView.frame.maxX;
            
            self.scrollView.contentInset = UIEdgeInsets(top: self.circleFrameView.frame.origin.y, left: self.circleFrameView.frame.origin.x, bottom: bottomInset, right: rightInset);
        } else {
            self.scrollView.contentInset = UIEdgeInsets.zero
        }
    }
    
    func prepareCursorView() {
        
        switch cursorType {
        case .roundedRect:
            
            var frameWidth: CGFloat = 0.0
            var frameHeight: CGFloat = 0.0
            
            if self.view.frame.size.width < self.view.frame.size.height {
                frameWidth = self.view.frame.size.width - kFrameNormalOffset * 2.0
                frameHeight = frameWidth * kRoundedRectHeightRatio
            } else {
                frameHeight = self.view.frame.size.height - (kFrameNormalOffset + kButtonsPanelHeight)
                frameWidth = frameHeight / kRoundedRectHeightRatio
            }
           
            self.circleFrameView.layer.cornerRadius = kRoundedRectCornerRadius
            self.circleFrameView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: frameWidth, height: frameHeight))
            
            self.lyocCursorViewWidth.constant = frameWidth
            self.lyocCursorViewHeight.constant = frameHeight
        default:
            var minSideSize = min(self.view.frame.size.width, self.view.frame.size.height - kButtonsPanelHeight)
            minSideSize -= 16.0
            
            self.circleFrameView.layer.cornerRadius = minSideSize * 0.5;
            self.circleFrameView.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: minSideSize, height: minSideSize))
            self.lyocCursorViewWidth.constant = minSideSize
            self.lyocCursorViewHeight.constant = minSideSize
        }
        
        self.circleFrameView.center = CGPoint(x: self.view.frame.size.width * 0.5, y: (self.view.frame.size.height - kButtonsPanelHeight) * 0.5)
        self.circleFrameView.layer.borderColor = UIColor.white.cgColor;
        self.circleFrameView.layer.borderWidth = 2.0;
    }
    
    func fillUI() {
        if self.srcImage == nil {
            return
        }
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false;
        
        var imageScale: CGFloat = 1.0
        var minimalScale: CGFloat = 1.0
        
        if (cursorType != .none) {
            let scaleX = circleFrameView.frame.size.width / srcImage.size.width
            let scaleY = circleFrameView.frame.size.height / srcImage.size.height
            
            let maxSideScale: CGFloat = max(scaleX, scaleY)
            imageScale = maxSideScale
            minimalScale = imageScale
        } else {
            imageScale = self.view.frame.size.height / srcImage.size.height
            minimalScale = self.view.frame.size.width / srcImage.size.width
        }
        
        let scrollContentSize: CGSize = CGSize(width: srcImage.size.width, height: srcImage.size.height);
        
        self.scrollView.minimumZoomScale = minimalScale;
        self.scrollView.zoomScale = 1.0;
        self.scrollView.contentSize = scrollContentSize;
        
        if self.ivImage != nil {
            self.ivImage.removeFromSuperview()
        }
        
        let ivImage: UIImageView = UIImageView(image: srcImage);
        ivImage.frame = CGRect(origin: CGPoint.zero, size: scrollContentSize);
        ivImage.center = CGPoint(x: scrollView.contentSize.width * 0.5, y: scrollView.contentSize.height * 0.5);
        
        self.scrollView.addSubview(ivImage);
        self.ivImage = ivImage;
        
        switch initialZoom {
        case .min:
            self.scrollView.zoomScale = minimalScale;
        case .normal:
            self.scrollView.zoomScale = imageScale;
        case .custom(scale: let scale):
            self.scrollView.zoomScale = scale >= minimalScale ? scale : minimalScale
        }
        
    }
    
    //MARK: - Internal operations
    
    func circleShadeLayer() -> CALayer {
        
        let maskFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height);
        let circleFrame: CGRect = CGRect(x: self.circleFrameView.frame.origin.x, y: self.circleFrameView.frame.origin.y,
            width: self.circleFrameView.frame.size.width, height: self.circleFrameView.frame.size.height);
        
        let radius: CGFloat = circleFrame.size.width * 0.5;
        let path: UIBezierPath = UIBezierPath(rect: maskFrame);
        let circlePath: UIBezierPath = UIBezierPath(roundedRect:circleFrame, cornerRadius:radius);
        
        path.append(circlePath);
        
        path.usesEvenOddFillRule = true;
        
        let fillLayer: CAShapeLayer = CAShapeLayer();
        fillLayer.path = path.cgPath;
        fillLayer.fillRule = kCAFillRuleEvenOdd;
        fillLayer.fillColor = UIColor(white: 0.0, alpha: 0.75).cgColor;
        fillLayer.opacity = 1.0;

        return fillLayer;
    }
    
    func roundedRectShadeLayer() -> CALayer {
        
        let frameHeight: CGFloat = self.circleFrameView.frame.size.width * kRoundedRectHeightRatio
        
        let maskFrame: CGRect = CGRect(x: 0.0, y: 0.0, width: self.view.frame.size.width, height: self.view.frame.size.height);
        let rectFrame: CGRect = CGRect(x: self.circleFrameView.frame.origin.x, y: self.circleFrameView.frame.origin.y,
                                         width: self.circleFrameView.frame.size.width, height: frameHeight);
        
        let path: UIBezierPath = UIBezierPath(rect: maskFrame);
        let circlePath: UIBezierPath = UIBezierPath(roundedRect:rectFrame, cornerRadius:kRoundedRectCornerRadius);
        
        path.append(circlePath);
        
        path.usesEvenOddFillRule = true;
        
        let fillLayer: CAShapeLayer = CAShapeLayer();
        fillLayer.path = path.cgPath;
        fillLayer.fillRule = kCAFillRuleEvenOdd;
        fillLayer.fillColor = UIColor(white: 0.0, alpha: 0.75).cgColor;
        fillLayer.opacity = 1.0;
        
        return fillLayer;
    }
    
    func croppedImage() -> UIImage? {
        
        guard self.ivImage.image != nil else {
            return nil;
        }
        
        let cropRect: CGRect = CGRect(x: (scrollView.contentOffset.x + scrollView.contentInset.left) / scrollView.zoomScale,
                                      y: (scrollView.contentOffset.y + scrollView.contentInset.top) / scrollView.zoomScale,
                                      width: circleFrameView.frame.size.width / scrollView.zoomScale,
                                      height: circleFrameView.frame.size.height / scrollView.zoomScale);
        
        UIGraphicsBeginImageContext(self.srcImage.size);
        
        UIGraphicsGetCurrentContext()!.translateBy(x: 0.5 * self.srcImage.size.width, y: 0.5 * self.srcImage.size.height);
        self.srcImage.draw(in: CGRect(origin: CGPoint(x: -self.srcImage.size.width * 0.5, y: -self.srcImage.size.height * 0.5), size: self.srcImage.size));
        
        let normalImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        
        let cgImage: CGImage = .none != cursorType ? normalImage.cgImage!.cropping(to: cropRect)! : normalImage.cgImage!;
        let croppedImage: UIImage = UIImage(cgImage: cgImage);
        var requiredScale: CGFloat = 1.0
        
        if let maxSize = self.destImageMaxSize {
            if croppedImage.size.width > croppedImage.size.height {
                requiredScale = maxSize.width / croppedImage.size.width
            } else {
                requiredScale = maxSize.height / croppedImage.size.height
            }
        }
        
        var scaledImageRect = CGRect(origin: CGPoint.zero, size: croppedImage.size)
        
        if requiredScale < 1.0 {
            let scaledImageWidth = croppedImage.size.width * requiredScale
            let scaledImageHeight = croppedImage.size.height * requiredScale
            scaledImageRect = CGRect(origin: CGPoint.zero, size: CGSize(width: scaledImageWidth, height: scaledImageHeight))
        }
        
        UIGraphicsBeginImageContext(scaledImageRect.size);
        croppedImage.draw(in: scaledImageRect);
        
        let resultImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!;
        UIGraphicsEndImageContext();
        
        let resultImageSize = resultImage.size
        print(resultImageSize)
        
        return croppedImage;
    }
    
    
    //MARK: - Actions
    
    @IBAction func onChooseButtonTouchUp(_ sender: AnyObject) {
        
        if croppedImageCallback != nil {
            croppedImageCallback!(croppedImage());
        }
        
        delegate?.cropVCDidFinishCrop(withImage: croppedImage())
        
        self.dismiss(animated: true, completion: nil);
    }
    
    @IBAction func onCancelButtonTouchUp(_ sender: AnyObject) {
    
        self.dismiss(animated: true, completion: nil);
    }
    
    
    //MARK: - UIScrollViewDelegate
    
    open func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return ivImage;
    }
    
    open func scrollViewDidZoom(_ scrollView: UIScrollView) {
        self.ivImage.transform = CGAffineTransform(scaleX: scrollView.zoomScale, y: scrollView.zoomScale);
        self.ivImage.center = CGPoint(x: scrollView.contentSize.width * 0.5, y: scrollView.contentSize.height * 0.5);
        
        if cursorType == .none {
            let verticalInset = (self.view.frame.size.height - self.ivImage.frame.size.height) * 0.5
            
            if verticalInset >= 0.0 {
                scrollView.contentInset = UIEdgeInsets(top: verticalInset, left: 0.0, bottom: verticalInset, right: 0.0)
            }
        }
    }
    
    
    //MARK: - Helpers
    
    static func log(_ msg: String) {
        print("[Crop Image VC]: \(msg)")
    }
    
    func onFail(withMessage msg: String) {
        let userInfo: [AnyHashable: Any] = [kCFErrorLocalizedDescriptionKey as AnyHashable : msg]
        let error = NSError(domain: "url_error", code: -1, userInfo: userInfo)
        delegate?.cropVCDidFailToPrepareImage(error)
    }
}
