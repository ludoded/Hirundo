//
//  RecorderViewController.swift
//  Recorder
//
//  Created by Haik Ampardjian on 8/13/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import UIKit
import AVFoundation

final class RecorderViewController: UIViewController {
    @IBOutlet fileprivate weak var recordView: UIView!
    @IBOutlet fileprivate weak var stopButton: UIButton!
    @IBOutlet fileprivate weak var retakeButton: UIButton!
    @IBOutlet fileprivate weak var previewView: UIView!
    @IBOutlet fileprivate weak var loadingView: UIView!
    @IBOutlet fileprivate weak var timeRecordedLabel: UILabel!
    @IBOutlet fileprivate weak var downBar: UIView!
    @IBOutlet fileprivate weak var switchCameraModeButton: UIButton!
    @IBOutlet fileprivate weak var reverseCamera: UIButton!
    @IBOutlet fileprivate weak var flashModeButton: UIButton!
    @IBOutlet fileprivate weak var capturePhotoButton: UIButton!
    @IBOutlet fileprivate weak var ghostModeButton: UIButton!
    @IBOutlet fileprivate weak var toolsContainerView: UIView!
    @IBOutlet fileprivate weak var openToolsButton: UIButton!
    @IBOutlet fileprivate weak var toolsAreaConstraint: NSLayoutConstraint!
    
    @IBAction fileprivate func switchCameraMode(_ sender: Any) {
        if recorder.captureSessionPreset == .photo {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.capturePhotoButton.alpha = 0.0
                self.recordView.alpha = 1.0
                self.retakeButton.alpha = 1.0
                self.stopButton.alpha = 1.0
            }) { (finished) in
                self.recorder.captureSessionPreset = .high
                self.switchCameraModeButton.setTitle("Switch Photo", for: .normal)
                self.flashModeButton.setTitle("Flash: Off", for: .normal)
                self.recorder.flashMode = .off
            }
        } else {
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self.capturePhotoButton.alpha = 1.0
                self.recordView.alpha = 0.0
                self.retakeButton.alpha = 0.0
                self.stopButton.alpha = 0.0
            }) { (finished) in
                self.recorder.captureSessionPreset = .photo
                self.switchCameraModeButton.setTitle("Switch Video", for: .normal)
                self.flashModeButton.setTitle("Flash: Auto", for: .normal)
                self.recorder.flashMode = .auto
            }
        }
    }
    
    @IBAction fileprivate func switchFlash(_ sender: Any) {
        var flashModeString: String = ""
        if recorder.captureSessionPreset == .photo {
            switch recorder.flashMode {
            case .auto:
                flashModeString = "Flash: Off"
                recorder.flashMode = .off
                break
            case .off:
                flashModeString = "Flash: On"
                recorder.flashMode = .on
                break
            case .on:
                flashModeString = "Flash: Light"
                recorder.flashMode = .light
                break
            case .light:
                flashModeString = "Flash: Auto"
                recorder.flashMode = .auto
                break
            }
        } else {
            switch recorder.flashMode {
            case .off:
                flashModeString = "Flash: On"
                recorder.flashMode = .light
                break
            case .light:
                flashModeString = "Flash: Off"
                recorder.flashMode = .off
                break
            default: break
            }
        }
        
        flashModeButton.setTitle(flashModeString, for: .normal)
    }
    
    @IBAction fileprivate func capturePhoto(_ sender: Any) {
        recorder.capturePhoto { [weak self] (error, image) in
            if image != nil {
                self?.showPhoto(image!)
            } else {
                self?.showAlertView(withTitle: "Failed to capture photo", message: error!.localizedDescription)
            }
        }
    }
    
    @IBAction fileprivate func switchGhostMode(_ sender: Any) {
        ghostModeButton.isSelected = !ghostModeButton.isSelected
        ghostImageView.isHidden = !ghostModeButton.isSelected
        
        // FIXME: impl later
    }
    
    @IBAction fileprivate func toolsButtonTapped(_ sender: Any) {
        UIView.animate(withDuration: 0.15) {
            self.toolsAreaConstraint.constant = self.toolsAreaConstraint.constant > 0 ? -200 : 200
            self.view.layoutIfNeeded()
        }
    }
    
    @IBAction fileprivate func closeCameraTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    private var recorder: Recorder!
    private var recordSession: RecordSession!
    
    private var photo: UIImage!
    private var ghostImageView: UIImageView!
    
    // TODO: focusView: RecorderToolsView - this is for focus and exposure
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    deinit {
        recorder.previewView = nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        capturePhotoButton.alpha = 0.0
        
        recorder = Recorder()
        recorder.captureSessionPreset = RecorderTools.bestCaptureSessionPresetCompatibleWithAllDevices
        recorder.delegate = self
        recorder.autoSetVideoOrientation = false
        
        recorder.previewView = previewView
        
        retakeButton.addTarget(self, action: #selector(handleRetakeButtonTapped), for: .touchUpInside)
        stopButton.addTarget(self, action: #selector(handleStopButtonTapped), for: .touchUpInside)
        reverseCamera.addTarget(self, action: #selector(handleReverseCameraTapped), for: .touchUpInside)
        
        recordView.addGestureRecognizer(UIGestureRecognizer(target: self, action: #selector(handleTouchDetected)))
        loadingView.isHidden = true
        
        // FIXME: later add focusView setup
        
        
        
        recorder.initializeSessionLazily = false
        
        do {
            try recorder.prepare()
        } catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        prepareSession()
        
        navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        recorder.previewViewFrameChanged()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        do {
            try recorder.startRunning()
        } catch let error {
            debugPrint("Start running error: ", error.localizedDescription)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        recorder.stopRunning()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        navigationController?.isNavigationBarHidden = false
    }
    
    // Mark: - Handle
    private func prepareSession() {
        if recorder.session == nil {
            let session = RecordSession()
            session.fileType = AVFileType.mov
            
            recorder.session = session
        }
        
        updateTimeRecordedLabel()
        //        updateGhostImage() // FIXME: impl later
    }
    
    private func updateTimeRecordedLabel() {
        let currentTime = recorder.session?.duration ?? .zero
        timeRecordedLabel.text = String(format: "%.2f sec", CMTimeGetSeconds(currentTime))
    }
    
    private func showAlertView(withTitle title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        navigationController?.present(alert, animated: true, completion: nil)
    }
    
    private func showVideo() {
        // FIXME: impl later
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // FIXME: impl later
    }
    
    private func showPhoto(_ photo: UIImage) {
        self.photo = photo
        // FIXME: impl later
//        performSegue(withIdentifier: <#T##String#>, sender: <#T##Any?#>)
    }
    
    @objc private func handleReverseCameraTapped() {
        recorder.switchCaptureDevices()
    }
    
    @objc private func handleStopButtonTapped() {
        recorder.pause { [unowned self] in
            self.saveAndShowSession(self.recorder.session)
        }
    }
    
    private func saveAndShowSession(_ session: RecordSession?) {
//        RecordSessionManager()
        
        recordSession = session
        showVideo()
    }
    
    @objc private func handleRetakeButtonTapped() {
        let recordSession = recorder.session
        
        if recordSession != nil {
            recorder.session = nil
            
            // If the recordSession was saved, we don't want to completely destroy it
            // FIXME:
        }
    }
    
    @objc private func handleTouchDetected(touchDetector: UIGestureRecognizer) {
        if touchDetector.state == .began {
            ghostImageView.isHidden = true
            recorder.record()
        } else {
            recorder.pause()
        }
    }
}

extension RecorderViewController: RecorderDelegate {
    func recorder(_ recorder: Recorder, didSkipVideoSampleBufferInSession session: RecordSession) {
        debugPrint("Skipped video buffer")
    }
    
    func recorderDidReconfigureAudioInput(_ recorder: Recorder, error: Error?) {
        debugPrint("Reconfigured audio input: ", error?.localizedDescription ?? "")
    }
    
    func recorderDidReconfigureVideoInput(_ recorder: Recorder, error: Error?) {
        debugPrint("Reconfigured video input: ", error?.localizedDescription ?? "")
    }
}

extension RecorderViewController: UIImagePickerControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let url = info[.mediaURL] {
            // FIXME: impl later
//            let segment = RecordSessionSegment(
        }
    }
}
