//
//  RecorderDelegate.swift
//  Recorder
//
//  Created by Haik Ampardjian on 8/13/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import Foundation
import AVFoundation

@objc public enum FlashMode: Int {
    case off
    case on
    case auto
    case light
    
    var captureDeviceFlashMode: AVCaptureDevice.FlashMode? {
        switch self {
        case .off: return .off
        case .on: return .on
        case .auto: return .auto
        case .light: return nil
        }
    }
}

@objc protocol RecorderDelegate where Self: NSObject {
    /**
     Called when the recorder has reconfigured the videoInput
     */
    @objc optional func recorderDidReconfigureVideoInput(_ recorder: Recorder, error: Error?)
    
    /**
     Called when the recorder has reconfigured the audioInput
     */
    @objc optional func recorderDidReconfigureAudioInput(_ recorder: Recorder, error: Error?)
    
    /**
     Called when the flashMode has changed
     */
    @objc optional func recorder(_ recorder: Recorder, didChangeFlashMode flashMode: FlashMode, error: Error?)
    
    /**
     Called when the capture session outputs a video sample buffer.
     This will be called in the SCRecorder internal queue, make sure
     you don't block the thread for too long.
     */
    @objc optional func recorder(_ recorder: Recorder, didOutputVideoSampleBuffer videoSampleBuffer: CMSampleBuffer)
    
    /**
     Called when the capture session outputs an audio sample buffer.
     This will be called in the SCRecorder internal queue, make sure
     you don't block the thread for too long.
     */
    @objc optional func recorder(_ recorder: Recorder, didOutputAudioSampleBuffer audioSampleBuffer: CMSampleBuffer)
    
    /**
     Called when the recorder has lost the focus. Returning true will make the recorder
     automatically refocus at the center.
     */
    @objc optional func recorderShouldAutomaticallyRefocus(_ recorder: Recorder) -> Bool
    
    /**
     Called before the recorder will start focusing
     */
    @objc optional func recorderWillStartFocus(_ recorder: Recorder)
    
    /**
     Called when the recorder has started focusing
     */
    @objc optional func recorderDidStartFocus(_ recorder: Recorder)
    
    /**
     Called when the recorder has finished focusing
     */
    @objc optional func recorderDidEndFocus(_ recorder: Recorder)
    
    /**
     Called before the recorder will start adjusting exposure
     */
    @objc optional func recorderWillStartAdjustingExposure(_ recorder: Recorder)
    
    /**
     Called when the recorder has started adjusting exposure
     */
    @objc optional func recorderDidStartAdjustingExposure(_ recorder: Recorder)
    
    /**
     Called when the recorder has finished adjusting exposure
     */
    @objc optional func recorderDidEndAdjustingExposure(_ recorder: Recorder)
    
    /**
     Called when the recorder has initialized the audio in a session
     */
    @objc optional func recorder(_ recorder: Recorder, didInitializeAudioInSession session: RecordSession, error: Error?)
    
    /**
     Called when the recorder has initialized the video in a session
     */
    @objc optional func recorder(_ recorder: Recorder, didInitializeVideoInSession session: RecordSession, error: Error?)
    
    /**
     Called when the recorder has started a segment in a session
     */
    @objc optional func recorder(_ recorder: Recorder, didBeginSegmentInSession session: RecordSession, error: Error?)
    
    /**
     Called when the recorder has completed a segment in a session
     */
//    @objc optional func recorder(_ recorder: Recorder, didCompleteSegment segment: RecordSessionSegment, inSession session: RecordSession, error: Error?)
    
    /**
     Called when the recorder has appended a video buffer in a session
     */
    @objc optional func recorder(_ recorder: Recorder, didAppendVideoSampleBufferInSession session: RecordSession)
    
    /**
     Called when the recorder has appended an audio buffer in a session
     */
    @objc optional func recorder(_ recorder: Recorder, didAppendAudioSampleBufferInSession session: RecordSession)
    
    /**
     Called when the recorder has skipped an audio buffer in a session
     */
    @objc optional func recorder(_ recorder: Recorder, didSkipAudioSampleBufferInSession session: RecordSession)
    
    /**
     Called when the recorder has skipped a video buffer in a session
     */
    @objc optional func recorder(_ recorder: Recorder, didSkipVideoSampleBufferInSession session: RecordSession)
    
    /**
     Called when a session has reached the maxRecordDuration
     */
    @objc optional func recorder(_ recorder: Recorder, didCompleteSession session: RecordSession)
    
    /**
     Gives an opportunity to the delegate to create an info dictionary for a record segment.
     */
    @objc optional func createSegmentInfoForRecorder(_ recorder: Recorder) -> [String : Any]?
}

