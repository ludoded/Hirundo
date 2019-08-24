//
//  MediaTypeConfiguration.swift
//  Hirundo
//
//  Created by Haik Ampardjian on 3/9/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import AVFoundation

public enum SCPresetQuality: String {
    case highest, medium, low
}

public class MediaTypeConfiguration: NSObject {
    /**
     Whether this media type is enabled or not.
     */
    @objc public var enabled: Bool {
        willSet {
            guard newValue != enabled else { return }
            willChangeValue(forKey: #keyPath(enabled))
        }
        
        didSet {
            guard enabled != oldValue else { return }
            didChangeValue(forKey: #keyPath(enabled))
        }
    }
    
    /**
     Whether this input type should be ignored. Unlike the "enabled" property,
     this does not remove the input or outputs. It just asks the recorder to not
     write the buffers even though it is enabled. This is only needed if you want
     to quickly enable/disable this media type without reconfiguring all the input/outputs
     which can be is a quite slow operation to do.
     */
    public var shouldIgnore: Bool = false
    
    /**
     Set the bitrate of the audio
     If options is not nil, this property will be ignored
     */
    public var bitrate: UInt64 = 0
    
    /**
     If set, every other properties but "enabled" will be ignored
     and this options dictionary will be used instead.
     */
    public var options: [String : Any]?
    
    /**
     Defines a preset to use. If set, most properties will be
     ignored to use values that reflect this preset.
     */
    public var preset: SCPresetQuality?
    
    public override init() {
        self.enabled = true
        super.init()
    }
    
    public func createAssetWriterOptions(usingSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String : Any]? {
        return nil
    }

}
