//
//  VideoConfiguration.swift
//  Hirundo
//
//  Created by Haik Ampardjian on 3/9/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import AVFoundation
import UIKit

public struct VideoConfigurationDefault {
    static let codec = AVVideoCodecType.hevc
    static let scalingMode = AVVideoScalingModeResizeAspectFill
    static let bitrate: UInt64 = 2_000_000
}

public enum WatermarkAnchorLocation {
    case topLeft, topRight, bottomLeft, bottomRight
}

@objc public protocol VideoOverlay where Self: NSObject {
    /**
     Called to determine whether setFrame:, updateWithVideoTime: and layoutIfNeeded should be called on the main thread.
     You should avoid returning YES as much as possible from this method, since it will potentially
     greatly reduce the encoding speed. Some views like UITextView requires to layout on the main thread.
     */
    @objc optional func requiresUpdateOnMainThread(atVideoTime time: TimeInterval, videoSize: CGSize) -> Bool
    
    /**
     Update the underlying view with the given time.
     This method will be called on the main thread if requiresVideoTimeUpdateOnMainThread returns true,
     otherwise it will be called in an arbitrary queue managed by the SCAssetExportSession.
     */
    @objc optional func update(withVideoTime time: TimeInterval)
}

public final class VideoConfiguration: MediaTypeConfiguration {
    /**
     Change the size of the video
     If options has been changed, this property will be ignored
     If this value is CGSizeZero, the input video size received
     from the camera will be used
     Default is CGSizeZero
     */
    public var size: CGSize = .zero
    
    /**
     Change the affine transform for the video
     If options has been changed, this property will be ignored
     */
    public var affineTransform: CGAffineTransform = .identity
    
    /**
     Set the codec used for the video
     Default is AVVideoCodecH264
     */
    public var codec: AVVideoCodecType
    
    /**
     Set the video scaling mode
     */
    public var scalingMode: String
    
    /**
     The maximum framerate that this SCRecordSession should handle
     If the camera appends too much frames, they will be dropped.
     If this property's value is 0, it will use the current video
     framerate from the camera.
     */
    public var maxFrameRate: CMTimeScale = 0
    
    /**
     The time scale of the video
     A value more than 1 will make the buffers last longer, it creates
     a slow motion effect. A value less than 1 will make the buffers be
     shorter, it creates a timelapse effect.
     
     Only used in SCRecorder.
     */
    public var timeScale: CGFloat = 1
    
    /**
     If true and videoSize is CGSizeZero, the videoSize
     used will equal to the minimum width or height found,
     thus making the video square.
     */
    public var sizeAsSquare: Bool = false
    
    /**
     If true, each frame will be encoded as a keyframe
     This is needed if you want to merge the recordSegments using
     the passthrough preset. This will seriously impact the video
     size. You can set this to NO and change the recordSegmentsMergePreset if you want
     a better quality/size ratio, but the merge will be slower.
     Default is NO
     */
    public var shouldKeepOnlyKeyFrames: Bool = false
    
    /**
     If not nil, each appended frame will be processed by this SCFilter.
     While it seems convenient, this removes the possibility to change the
     filter after the segment has been added.
     Setting a new filter will cause the SCRecordSession to stop the
     current record segment if the previous filter was NIL and the
     new filter is NOT NIL or vice versa. If you want to have a smooth
     transition between filters in the same record segment, make sure to set
     an empty SCFilterGroup instead of setting this property to nil.
     */
//    public var filter: SCFilter?
    
    /**
     If YES, the affineTransform will be ignored and the output affineTransform
     will be the same as the input asset.
     
     Only used in SCAssetExportSession.
     */
    public var keepInputAffineTransform: Bool = true
    
    /**
     The video composition to use.
     
     Only used in SCAssetExportSession.
     */
    public var composition: AVVideoComposition?
    
    /**
     The watermark to use. If the composition is not set, this watermark
     image will be applied on the exported video.
     
     Only used in SCAssetExportSession.
     */
    public var watermarkImage: UIImage?
    
    /**
     The watermark image location and size in the input video frame coordinates.
     
     Only used in SCAssetExportSession.
     */
    public var watermarkFrame: CGRect = .zero
    
    /**
     Specify a buffer size to use. By default the SCAssetExportSession tries
     to figure out which size to use by looking at the composition and the natural
     size of the inputAsset. If the filter you set return back an image with a different
     size, you should put the output size here.
     
     Only used in SCAssetExportSession.
     Default is CGSizeZero
     */
    public var bufferSize: CGSize = .zero
    
    /**
     Set a specific key to the video profile
     */
    public var profileLevel: String?
    
    /**
     The overlay view that will be drawn on top of the video.
     
     Only used in SCAssetExportSession.
     */
    public var overlay: VideoOverlay?
    
    /**
     The watermark anchor location.
     
     Default is top left
     
     Only used in SCAssetExportSession.
     */
    public var watermarkAnchorLocation: WatermarkAnchorLocation?
    
    
    public func createAssetWriterOptions(withVideoSize videoSize: CGSize) -> [String : Any] {
        guard options == nil else {
            return options!
        }
        
        var outputSize = size
        var nBitrate = bitrate
        
        if let preset = preset {
            switch preset {
            case .low:
                nBitrate = 500_000
                outputSize = VideoConfiguration.makeVideoSize(size: videoSize, requestedWidth: 640)
            case .medium:
                nBitrate = 1_000_000
                outputSize = VideoConfiguration.makeVideoSize(size: videoSize, requestedWidth: 1280)
            case .highest:
                nBitrate = 6_000_000
                outputSize = VideoConfiguration.makeVideoSize(size: videoSize, requestedWidth: 1920)
            }
        }
        
        if __CGSizeEqualToSize(outputSize, .zero) {
            outputSize = videoSize
        }
        
        if sizeAsSquare {
            if videoSize.width > videoSize.height {
                outputSize.width = videoSize.height
            } else {
                outputSize.height = videoSize.width
            }
        }
        
        var compressionSettings: [String : Any] = [
            AVVideoAverageBitRateKey: NSNumber(value: nBitrate)
        ]
        
        if shouldKeepOnlyKeyFrames {
            compressionSettings[AVVideoMaxKeyFrameIntervalKey] = NSNumber(value: 1)
        }
        
        if let level = profileLevel {
            compressionSettings[AVVideoProfileLevelKey] = level
        }
        
        compressionSettings[AVVideoAllowFrameReorderingKey] = NSNumber(value: false)
        compressionSettings[AVVideoExpectedSourceFrameRateKey] = NSNumber(value: 30)
        
        return [
            AVVideoCodecKey: codec,
            AVVideoScalingModeKey: scalingMode,
            AVVideoWidthKey: NSNumber(value: Double(outputSize.width)),
            AVVideoHeightKey: NSNumber(value: Double(outputSize.height)),
            AVVideoCompressionPropertiesKey: compressionSettings
        ]
    }
    
    public override init() {
        self.codec = VideoConfigurationDefault.codec
        self.scalingMode = VideoConfigurationDefault.scalingMode
        super.init()
        self.bitrate = VideoConfigurationDefault.bitrate
    }
    
    public override func createAssetWriterOptions(usingSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String : Any]? {
        guard let sampleBuffer = sampleBuffer,
            let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
            else { return nil }
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        return createAssetWriterOptions(withVideoSize: CGSize(width: width, height: height))
    }
    
    // MARK: - Private
    private static func makeVideoSize(size: CGSize, requestedWidth: CGFloat) -> CGSize {
        let ratio = size.width / requestedWidth
        
        if ratio <= 1 {
            return size
        }
        
        return CGSize(width: size.width / ratio,
                      height: size.height / ratio)
    }
    
    
}
