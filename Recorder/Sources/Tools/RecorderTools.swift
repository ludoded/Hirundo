//
//  RecorderTools.swift
//  Recorder
//
//  Created by Haik Ampardjian on 8/13/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import AVFoundation

public class RecorderTools: NSObject {
    /**
     Returns the best session preset that is compatible with all available video
     devices (front and back camera). It will ensure that buffer output from
     both camera has the same resolution.
     */
    public static var bestCaptureSessionPresetCompatibleWithAllDevices: AVCaptureSession.Preset {
        let backDevices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera, .builtInDualCamera, .builtInTrueDepthCamera],
                                                                mediaType: .video,
                                                                position: .back).devices
        let frontDevices = AVCaptureDevice.DiscoverySession.init(deviceTypes: [.builtInWideAngleCamera],
                                                                 mediaType: .video,
                                                                 position: .front).devices
        let videoDevices = backDevices + frontDevices
        
        var highestCompatibleDimension = CMVideoDimensions(width: 0, height: 0)
        var lowestSet = false
        
        for device in videoDevices {
            var highestDeviceDimension = CMVideoDimensions(width: 0, height: 0)
            
            for format in device.formats {
                let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                
                if dimension.width * dimension.height > highestDeviceDimension.width * highestDeviceDimension.height {
                    highestDeviceDimension = dimension
                }
            }
            
            if !lowestSet
                || highestCompatibleDimension.width * highestCompatibleDimension.height > highestDeviceDimension.width * highestDeviceDimension.height {
                lowestSet = true
                highestCompatibleDimension = highestDeviceDimension
            }
        }
        
        return RecorderTools.captureSessionPreset(forDimension: highestCompatibleDimension)
    }
    
    /**
     Returns the best captureSessionPreset for a device that is equal or under the max specified size
     */
    public static func bestCaptureSessionPreset(forDevice device: AVCaptureDevice?, withMaxSize maxSize: CGSize) -> AVCaptureSession.Preset {
        var highestDeviceDimension = CMVideoDimensions(width: 0, height: 0)
        
        for format in device?.formats ?? [] {
            let dimension = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
            
            if dimension.width <= Int32(maxSize.width)
                && dimension.height <= Int32(maxSize.height)
                && dimension.width * dimension.height > highestDeviceDimension.width * highestDeviceDimension.height {
                highestDeviceDimension = dimension
            }
        }
        
        return RecorderTools.captureSessionPreset(forDimension: highestDeviceDimension)
    }
    
    /**
     Returns the best captureSessionPreset for a device position that is equal or under the max specified size
     */
    public static func bestCaptureSessionPreset(forDevicePosition devicePosition: AVCaptureDevice.Position, withMaxSize maxSize: CGSize) -> AVCaptureSession.Preset {
        return RecorderTools.bestCaptureSessionPreset(forDevice: RecorderTools.videoDeviceForPosition(position: devicePosition),
                                                      withMaxSize: maxSize)
    }
    
    public static func formatInRange(format: AVCaptureDevice.Format, frameRate: CMTimeScale) -> Bool {
        let dimension = CMVideoDimensions(width: 0, height: 0)
        return formatInRange(format: format, frameRate: frameRate, dimensions: dimension)
    }
    
    public static func formatInRange(format: AVCaptureDevice.Format, frameRate: CMTimeScale, dimensions videoDimensions: CMVideoDimensions) -> Bool {
        let size = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
        
        if size.width >= videoDimensions.width && size.height >= videoDimensions.height {
            for range in format.videoSupportedFrameRateRanges
                where range.minFrameDuration.timescale >= frameRate && range.maxFrameDuration.timescale <= frameRate {
                    return true
            }
        }
        
        return false
    }
    
    public static func maxFrameRate(forFormat format: AVCaptureDevice.Format, minFrameRate: CMTimeScale) -> CMTimeScale {
        var lowerTimeScale: CMTimeScale = 0
        
        for range in format.videoSupportedFrameRateRanges
            where range.minFrameDuration.timescale >= minFrameRate && (lowerTimeScale == 0 || range.minFrameDuration.timescale < lowerTimeScale) {
                lowerTimeScale = range.minFrameDuration.timescale
        }
        
        return lowerTimeScale
    }
    
    public static func videoDeviceForPosition(position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let deviceTypes: [AVCaptureDevice.DeviceType]
        
        switch position {
        case .front:
            deviceTypes = [.builtInWideAngleCamera]
        default:
            deviceTypes = [.builtInDualCamera, .builtInTrueDepthCamera]
        }
        
        let videoDevices = AVCaptureDevice.DiscoverySession.init(deviceTypes: deviceTypes, mediaType: .video, position: position).devices
        
        return videoDevices.first
    }
    
    public static var assetWriterMetadata: [AVMetadataItem] {
        let creationDate = AVMutableMetadataItem()
        creationDate.keySpace = AVMetadataKeySpace.common
        creationDate.key = AVMetadataKey.commonKeyCreationDate as NSCopying & NSObjectProtocol
        creationDate.value = NSString(string: Date().toISO8601())
        
        let software = AVMutableMetadataItem()
        software.keySpace = AVMetadataKeySpace.common
        software.key = AVMetadataKey.commonKeySoftware as NSCopying & NSObjectProtocol
        software.value = NSString(string: "Hirundo")
        
        return [creationDate, software]
    }
    
    // MARK: Private
    private static func captureSessionPreset(forDimension videoDimension: CMVideoDimensions) -> AVCaptureSession.Preset {
        if videoDimension.width >= 3840 && videoDimension.height >= 2160 {
            return AVCaptureSession.Preset.hd4K3840x2160
        }
        if videoDimension.width >= 1920 && videoDimension.height >= 1080 {
            return AVCaptureSession.Preset.hd1920x1080
        }
        if videoDimension.width >= 1280 && videoDimension.height >= 720 {
            return AVCaptureSession.Preset.hd1280x720
        }
        if videoDimension.width >= 960 && videoDimension.height >= 540 {
            return AVCaptureSession.Preset.iFrame960x540
        }
        if videoDimension.width >= 640 && videoDimension.height >= 480 {
            return AVCaptureSession.Preset.vga640x480
        }
        if videoDimension.width >= 352 && videoDimension.height >= 288 {
            return AVCaptureSession.Preset.cif352x288
        }
        
        return AVCaptureSession.Preset.low
    }
}

extension Date {
    func toISO8601() -> String {
        return Date.getFormatter().string(from: self)
    }
    
    static func fromISO8601(iso8601: String) -> Date? {
        return Date.getFormatter().date(from: iso8601)
    }
    
    private static func getFormatter() -> DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        
        return formatter
    }
}
