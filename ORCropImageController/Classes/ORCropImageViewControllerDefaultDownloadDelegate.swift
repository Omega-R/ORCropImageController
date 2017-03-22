//
//  ORCropImageViewControllerDefaultDownloadDelegate.swift
//  ORCropImageExample
//
//  Created by Nikita Egoshin on 03.05.16.
//  Copyright © 2016 Omega-R. All rights reserved.
//

import UIKit

class ORCropImageViewControllerDefaultDownloadDelegate: NSObject, ORCropImageViewControllerDownloadDelegate {

    public func downloadImage(fromURL url: URL, completion: @escaping (UIImage?, NSError?) -> Void) {
        DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.background).async {
            guard let data = try? Data(contentsOf: url) else {
                completion(nil, nil)
                return
            }
            
            guard let image = UIImage(data: data) else {
                completion(nil, nil)
                return
            }
            
            DispatchQueue.main.async(execute: {
                completion(image, nil)
            })
        }
    }
}
