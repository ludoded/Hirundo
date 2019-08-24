//
//  PhotoConfiguration.swift
//  Hirundo
//
//  Created by Haik Ampardjian on 3/9/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import AVFoundation

public class PhotoConfiguration: NSObject {
    /**
     Whether the photo output is enabled or not.
     Changing this value after the session has been opened
     on the SCRecorder has no effect.
     */
    public var enabled: Bool
    
    /**
     If set, every other properties but "enabled" will be ignored
     and this options dictionary will be used instead.
     */
    @objc public var options: AVCapturePhotoSettings? {
        willSet {
            willChangeValue(forKey: #keyPath(options))
        }
        
        didSet {
            didChangeValue(forKey: #keyPath(options))
        }
    }
    
    /**
     Returns the output settings for the
     */
    public var createOutputSettings: AVCapturePhotoSettings? {
        guard options != nil
            else {
                let settings = AVCapturePhotoSettings()
                let _ = settings.availablePreviewPhotoPixelFormatTypes.first!
                let previewFormat: [String : Any] = [:]
                settings.previewPhotoFormat = previewFormat
                return settings
        }
        
        return options
    }
    
    override init() {
        self.enabled = true
        super.init()
    }
}
