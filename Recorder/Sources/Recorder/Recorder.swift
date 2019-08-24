//
//  Recorder.swift
//  Recorder
//
//  Created by Haik Ampardjian on 8/13/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import UIKit
import AVFoundation

enum RecorderError: Error {
    case cameraException
    case cannotSetSession
    case cannotAddMovieOutput
    case cannotAddVideoOutput
    case cannotAddAudioOutput
    case cannotAddPhotoOutput
    
    case failedAddInput
    
    var localizedDescription: String {
        switch self {
        case .cameraException: return "The session is already opened"
        case .cannotSetSession: return "Cannot set session preset"
        case .cannotAddMovieOutput: return "Cannot add movieOutput inside the session"
        case .cannotAddVideoOutput: return "Cannot add videoOutput inside the session"
        case .cannotAddAudioOutput: return "Cannot add audioOutput inside the session"
        case .cannotAddPhotoOutput: return "Cannot add photoOutput inside the session"
            
        case .failedAddInput: return "Failed to add input to capture session"
        }
    }
}

final class Recorder: NSObject {
    /**
     Access the configuration for the video.
     */
    public fileprivate(set) var videoConfiguration: VideoConfiguration
    
    /**
     Access the configuration for the audio.
     */
    public fileprivate(set) var audioConfiguration: AudioConfiguration
    
    /**
     Access the configuration for the photo.
     */
    public fileprivate(set) var photoConfiguration: PhotoConfiguration
    
    /**
     Will be true if the SCRecorder is currently recording
     */
    var isRecording: Bool = false
    
    /**
     Change the flash mode on the camera
     */
    var flashMode: FlashMode = .off {
        willSet {
            if let currentDevice = videoDevice {
                if currentDevice.hasFlash {
                    do {
                        try currentDevice.lockForConfiguration()
                        if newValue == .light {
                            if currentDevice.isTorchModeSupported(.on) {
                                currentDevice.torchMode = .on
                            }
                            // TODO: unceratain
                            if currentDevice.isFlashAvailable {
                                currentDevice.flashMode = .off
                            }
                        } else {
                            if currentDevice.isTorchModeSupported(.off) {
                                currentDevice.torchMode = .off
                            }
                            if currentDevice.isFlashModeSupported(newValue.captureDeviceFlashMode ?? .auto) {
                                currentDevice.flashMode = newValue.captureDeviceFlashMode ?? .auto
                            }
                        }
                        
                        currentDevice.unlockForConfiguration()
                    } catch let error {
                        assertionFailure(error.localizedDescription)
                    }
                } else {
                    assertionFailure("Device doesn't have flash")
                }
            }
            
            delegate?.recorder?(self, didChangeFlashMode: newValue, error: nil)
        }
    }
    
    /**
     Change the current used device
     */
    var device: AVCaptureDevice.Position = .back {
        willSet {
            willChangeValue(forKey: "device")
        }
        
        didSet {
            // FIXME: resetZoomOnChangeDevie
            if let _ = captureSession {
                reconfigureVideoInput(videoConfiguration.enabled, audioInput: false)
            }
            
            didChangeValue(forKey: "device")
        }
    }
    
    /**
     The session preset used for the AVCaptureSession
     */
    var captureSessionPreset: AVCaptureSession.Preset = .high {
        didSet {
            if let captureSession = captureSession {
                do {
                    try reconfigureSession()
                    self.captureSessionPreset = captureSession.sessionPreset // FIXME: potential infinite loop
                } catch let error {
                    debugPrint("Capture Session: ", error.localizedDescription)
                }
            }
        }
    }
    
    /**
     The value of this property defaults to YES, causing the capture session to automatically configure the app’s shared AVAudioSession instance for optimal recording.
     
     If you set this property’s value to NO, your app is responsible for selecting appropriate audio session settings. Recording may fail if the audio session’s settings are incompatible with the capture session.
     */
    var automaticallyConfiguresApplicationAudioSession: Bool = true
    
    /**
     The captureSession. This will be null until prepare or startRunning has
     been called. Calling unprepare will set this property to null again.
     */
    var captureSession: AVCaptureSession?
    
    /**
     Whether the recorder has been prepared.
     */
    var isPrepared: Bool {
        return captureSession != nil
    }
    
    /**
     The preview layer used for the video preview
     */
    var previewLayer: AVCaptureVideoPreviewLayer
    
    /**
     Convenient way to set a view inside the preview layer
     */
    var previewView: UIView? {
        willSet {
            previewLayer.removeFromSuperlayer()
        }
        
        didSet {
            if previewView != nil {
                previewView?.layer.insertSublayer(previewLayer, at: 0)
                previewViewFrameChanged()
            }
        }
    }
    
    /**
     Set the delegate used to receive messages for the SCRecorder
     */
    var delegate: RecorderDelegate?
    
    /**
     The record session to which the recorder will flow the camera/microphone buffers
     */
    var session: RecordSession?
    
    /**
     The video orientation. This is automatically set if autoSetVideoOrientation is enabled
     */
    var videoOrientation: AVCaptureVideoOrientation
    
    /**
     The video stabilization mode to use.
     Default is AVCaptureVideoStabilizationModeStandard
     */
    var videoStabilizationMode: AVCaptureVideoStabilizationMode
    
    /**
     If true, the videoOrientation property will be set automatically
     depending on the current device orientation
     Default is False
     */
    var autoSetVideoOrientation: Bool = false
    
    /**
     If enabled, the recorder will initialize the session and create the record segments
     when asking to record. Otherwise it will do it as soon as possible.
     Default is YES
     */
    var initializeSessionLazily: Bool = true
    
    /**
     The dispatch queue that the SCRecorder uses for sending messages to the attached
     SCRecordSession.
     */
    var sessionQueue = DispatchQueue(label: "com.haikampardjian.Recorder2.session")
    
    
    
    
    
    
    
    
    
    // MARK: - Methods
    override init() {
        previewLayer = AVCaptureVideoPreviewLayer()
        previewLayer.videoGravity = .resizeAspectFill
        
        videoOrientation = .portrait
        videoStabilizationMode = .standard
        
        videoConfiguration = VideoConfiguration()
        audioConfiguration = AudioConfiguration()
        photoConfiguration = PhotoConfiguration()
        
        super.init()
    }
    
    /**
     Create the AVCaptureSession
     Calling this method will set the captureSesion and configure it properly.
     If an error occured during the creation of the captureSession, this methods will return NO.
     */
    func prepare() throws {
        if captureSession != nil {
            throw RecorderError.cameraException
        }
        
        let session = AVCaptureSession()
        session.automaticallyConfiguresApplicationAudioSession = automaticallyConfiguresApplicationAudioSession
        
        beginSessionConfigurationCount = 0
        captureSession = session
        
        beginConfiguration()
        
        try reconfigureSession()
        // FIXME: impl later
        
        previewLayer.session = session
        
        reconfigureVideoInput(true, audioInput: true)
        
        commitConfiguration()
    }
    
    /**
     Signal to the recorder that the previewView frame has changed.
     This will make the previewLayer to matches the size of the previewView.
     */
    func previewViewFrameChanged() {
        previewLayer.setAffineTransform(.identity)
        previewLayer.frame = previewView!.bounds
    }
    
    /**
     Start the flow of inputs in the AVCaptureSession.
     prepare will be called if it wasn't prepared before.
     Calling this method will block until it's done.
     If it returns NO, an error will be set in the "error" property.
     */
    func startRunning() throws {
        defer {
            if !(captureSession?.isRunning ?? false) {
                captureSession?.startRunning()
            }
        }
        
        if !isPrepared {
            try prepare()
        }
    }
    
    /**
     End the flow of inputs in the AVCaptureSession
     This wont destroy the AVCaptureSession.
     */
    func stopRunning() {
        captureSession?.stopRunning()
    }

    /**
     Switch between the camera devices
     */
    func switchCaptureDevices() {
        if device == .back {
            device = .front
        } else {
            device = .back
        }
    }
    
    /**
     Allow the recorder to append the sample buffers inside the current setted session
     */
    func record() {
        
    }
    
    /**
     Disallow the recorder to append the sample buffers inside the current setted session.
     If a record segment has started, this will be either canceled or completed depending on
     if it is empty or not.
     */
    func pause() {
        
    }
    
    /**
     Disallow the recorder to append the sample buffers inside the current setted session.
     If a record segment has started, this will be either canceled or completed depending on
     if it is empty or not.
     @param completionHandler called on the main queue when the recorder is ready to record again.
     */
    func pause(completionHandler: (() -> Void)?) {
        
    }

    /**
     Capture a photo from the camera
     @param completionHandler called on the main queue with the image taken or an error in case of a problem
     */
    func capturePhoto(completionHandler: (_ error: Error?, _ image: UIImage?) -> Void) {
        
    }
    
    // MARK: - Private
    /**
     This is used to keep track of how many beginConfiguration processes are at current
     */
    private var beginSessionConfigurationCount: Int = 0
    
    /**
     All type of outputs
     */
    private var videoOutput: AVCaptureVideoDataOutput?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var audioOutput: AVCaptureAudioDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    
    private var audioDevice: AVCaptureDevice? {
        return audioConfiguration.enabled ? AVCaptureDevice.default(for: .audio) : nil
    }
    
    private var videoDevice: AVCaptureDevice? {
        return videoConfiguration.enabled ? RecorderTools.videoDeviceForPosition(position: device) : nil
    }
    
    private var actualVideoOrientation: AVCaptureVideoOrientation {
        if autoSetVideoOrientation {
            switch UIDevice.current.orientation {
            case .landscapeLeft:
                return .landscapeLeft
            case .landscapeRight:
                return .landscapeRight
            case .portrait:
                return .portrait
            case .portraitUpsideDown:
                return .portraitUpsideDown
            default:
                break
            }
        }
        
        return videoOrientation
    }
    
    /**
     beginConfiguration increments counter
     and call beginConfiguration for captureSession
     */
    private func beginConfiguration() {
        beginSessionConfigurationCount += 1
        if beginSessionConfigurationCount == 1 {
            captureSession?.beginConfiguration()
        }
    }
    
    /**
     commitConfiguration decrements counter
     and call commitConfiguration for captureSession
     */
    private func commitConfiguration() {
        beginSessionConfigurationCount -= 1
        if beginSessionConfigurationCount == 0 {
            captureSession?.commitConfiguration()
        }
    }
    
    private func reconfigureSession() throws {
        if let session = captureSession {
            beginConfiguration()
            
            if session.sessionPreset != captureSessionPreset {
                if session.canSetSessionPreset(captureSessionPreset) {
                    session.sessionPreset = captureSessionPreset
                } else {
                    throw RecorderError.cannotSetSession
                }
            }

            // FIXME: impl later
//            if fastRecordMethodEnabled {
//
//            } else {
            if movieOutput != nil && session.outputs.contains(movieOutput!) {
                session.removeOutput(movieOutput!)
            }
            
            // FIXME: impl later videoOutputAdded
            if videoConfiguration.enabled {
                if videoOutput == nil {
                    videoOutput = AVCaptureVideoDataOutput()
                    videoOutput?.alwaysDiscardsLateVideoFrames = false
                    videoOutput?.setSampleBufferDelegate(self, queue: sessionQueue)
                }
                
                if !session.outputs.contains(videoOutput!) {
                    if session.canAddOutput(videoOutput!) {
                        session.addOutput(videoOutput!)
                    } else {
                        throw RecorderError.cannotAddVideoOutput
                    }
                }
            }
            
            // FIXME: impl later audioConfiguration
            if audioConfiguration.enabled {
                if audioOutput == nil {
                    audioOutput = AVCaptureAudioDataOutput()
                    audioOutput?.setSampleBufferDelegate(self, queue: sessionQueue)
                }
                
                if !session.outputs.contains(audioOutput!) {
                    if session.canAddOutput(audioOutput!) {
                        session.addOutput(audioOutput!)
                    } else {
                        throw RecorderError.cannotAddPhotoOutput
                    }
                }
            }
//            }
            
            if photoConfiguration.enabled {
                if photoOutput == nil {
                    photoOutput = AVCapturePhotoOutput()
//                    photoOutput?.setPreparedPhotoSettingsArray([photoConfiguration.createOutputSettings!], completionHandler: nil)
                }
                
                if !session.outputs.contains(photoOutput!) {
                    if session.canAddOutput(photoOutput!) {
                        session.addOutput(photoOutput!)
                    } else {
                        throw RecorderError.cannotAddPhotoOutput
                    }
                }
            }
            
            commitConfiguration()
        }
    }
    
    private func reconfigureVideoInput(_ shouldConfigureVideo: Bool, audioInput shouldConfigureAudio: Bool) {
        if let captureSession = captureSession {
            var videoError: Error? = nil
            var audioError: Error? = nil
            
            defer {
                if shouldConfigureAudio {
                    delegate?.recorderDidReconfigureAudioInput?(self, error: audioError)
                }
                
                if shouldConfigureVideo {
                    delegate?.recorderDidReconfigureVideoInput?(self, error: videoError)
                }
            }
            
            beginConfiguration()
            
            
            if shouldConfigureVideo {
                do {
                    try configureDevice(videoDevice, mediaType: .video)
                    // FIXME: impl later
                    sessionQueue.sync {
                        self.updateVideoOrientation()
                    }
                } catch let error {
                    videoError = error
                }
            }
            
            if shouldConfigureAudio {
                do {
                    try configureDevice(audioDevice, mediaType: .audio)
                } catch let error {
                    audioError = error
                }
            }
            
            commitConfiguration()
            
        }
    }
    
    private func updateVideoOrientation() {
        // FIXME: impl later
        
        let videoOrientation = actualVideoOrientation
        let videoConnection = videoOutput?.connection(with: .video)
        
        if videoConnection?.isVideoOrientationSupported ?? false {
            videoConnection?.videoOrientation = videoOrientation
        }
        
        if previewLayer.connection?.isVideoOrientationSupported ?? false {
            previewLayer.connection?.videoOrientation = videoOrientation
        }
        
        let photoConnection = photoOutput?.connection(with: .video)
        if photoConnection?.isVideoOrientationSupported ?? false {
            photoConnection?.videoOrientation = videoOrientation
        }
        
        let movieOutputConnection = movieOutput?.connection(with: .video)
        if movieOutputConnection?.isVideoOrientationSupported ?? false {
            movieOutputConnection?.videoOrientation = videoOrientation
        }
    }
    
    private func configureDevice(_ newDevice: AVCaptureDevice?, mediaType: AVMediaType) throws {
        let currentInput = currentDeviceInput(forMediaType: mediaType)
        
        if currentInput?.device != newDevice {
            if mediaType == .video {
                do {
                    try newDevice!.lockForConfiguration()
                    if newDevice!.isSmoothAutoFocusSupported {
                        newDevice!.isSmoothAutoFocusEnabled = true
                    }
                    newDevice!.isSubjectAreaChangeMonitoringEnabled = true
                    
                    if newDevice!.isLowLightBoostSupported {
                        newDevice!.automaticallyEnablesLowLightBoostWhenAvailable = true
                    }
                    
                    newDevice!.unlockForConfiguration()
                } catch let err {
                    debugPrint("Failed To configure device: ", err.localizedDescription)
                }
                /// FIXME: impl later videoInputAdded
            } else {
                /// FIXME: impl later audioInputAdded
            }
            
            var newInput: AVCaptureDeviceInput? = nil
            
            if let newDevice = newDevice {
                newInput = try AVCaptureDeviceInput(device: newDevice)
            }
            
            if let currentInput = currentInput {
                captureSession?.removeInput(currentInput)
                if currentInput.device.hasMediaType(.video) {
                    // FIXME: imple later removeVideoObservers
                }
            }
            
            if let newInput = newInput, let captureSession = captureSession {
                if captureSession.canAddInput(newInput) {
                    captureSession.addInput(newInput)
                    
                    if newInput.device.hasMediaType(.video) {
                        // FIXME: videoInputAdded
                    } else {
                        // FIXME: impl later
                    }
                } else {
                    throw RecorderError.failedAddInput
                }
            }
        }
    }
    
    // Return device input for particular media type
    private func currentDeviceInput(forMediaType mediaType: AVMediaType) -> AVCaptureDeviceInput? {
        for deviceInput in captureSession?.inputs ?? []
            where (deviceInput as? AVCaptureDeviceInput)?.device.hasMediaType(mediaType) ?? false {
            return deviceInput as? AVCaptureDeviceInput
        }
        
        return nil
    }
}

extension Recorder: AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == videoOutput {
            // FIXME: impl later
            
            guard !videoConfiguration.shouldIgnore else { return }
            
            // FIXME: impl later
        } else if output == audioOutput {
            // FIXME: impl later
            
            guard !audioConfiguration.shouldIgnore else { return }
        }
        
        if !initializeSessionLazily || isRecording {
            if let recordSession = session {
                if output == videoOutput {
                    // FIXME: impl later
                } else if output == audioOutput {
                    // FIXME: impl later
                }
            }
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didDrop sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
