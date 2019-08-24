//
//  AudioConfiguration.swift
//  Hirundo
//
//  Created by Haik Ampardjian on 3/9/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import AVFoundation

public struct AudioConfigurationDefault {
    static let bitrate: UInt64 = 128000
    static let numberOfChannels: UInt32 = 2
    static let sampleRate: Float64 = 44100
    static let audioFormat: AudioFormatID = kAudioFormatMPEG4AAC
}

public final class AudioConfiguration: MediaTypeConfiguration {
    /**
     Set the sample rate of the audio
     If set to 0, the original sample rate will be used.
     If options has been changed, this property will be ignored
     */
    public var sampleRate: Float64 = 0
    
    /**
     Set the number of channels
     If set to 0, the original channels number will be used.
     If options is not nil, this property will be ignored
     */
    public var channelsCount: UInt32 = 0
    
    /**
     Must be like kAudioFormat* (example kAudioFormatMPEGLayer3)
     If options is not nil, this property will be ignored
     */
    public var format: AudioFormatID
    
    /**
     The audioMix to apply.
     
     Only used in SCAssetExportSession.
     */
    public var audioMix: AVAudioMix?
    
    public override init() {
        self.format = AudioConfigurationDefault.audioFormat
        super.init()
        self.bitrate = AudioConfigurationDefault.bitrate
    }
    
    public override func createAssetWriterOptions(usingSampleBuffer sampleBuffer: CMSampleBuffer?) -> [String : Any]? {
        guard options == nil else { return options }
        
        var nSampleRate = sampleRate
        var nChannels = channelsCount
        var nBitrate = bitrate
        
        if let preset = preset {
            switch preset {
            case .highest:
                nBitrate = 320_000
            case .medium:
                nBitrate = 128_000
            case .low:
                nBitrate = 64_000
                nChannels = 1
            }
        }
        
        if let sampleBuffer = sampleBuffer,
            let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer),
            let streamBasicDescription = CMAudioFormatDescriptionGetStreamBasicDescription(formatDescription) {
            
            if nSampleRate == 0 {
                nSampleRate = streamBasicDescription.pointee.mSampleRate
            }
            
            if nChannels == 0 {
                nChannels = streamBasicDescription.pointee.mChannelsPerFrame
            }
        }
        
        if nSampleRate == 0 {
            nSampleRate = AudioConfigurationDefault.sampleRate
        }
        
        if nChannels == 0 {
            nChannels = AudioConfigurationDefault.numberOfChannels
        }
        
        return [
            AVFormatIDKey: NSNumber(value: format),
            AVEncoderBitRateKey: NSNumber(value: nBitrate),
            AVNumberOfChannelsKey: NSNumber(value: nChannels),
            AVSampleRateKey: NSNumber(value: nSampleRate)
        ]
    }
}
