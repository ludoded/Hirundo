//
//  RecorderSession.swift
//  Recorder
//
//  Created by Haik Ampardjian on 8/13/19.
//  Copyright © 2019 Haik Ampardjian. All rights reserved.
//

import AVFoundation

final class RecordSession: NSObject {
    /**
     The output file type used for the AVAssetWriter.
     If null, AVFileTypeMPEG4 will be used for a video file, AVFileTypeAppleM4A for an audio file
     */
    var fileType: AVFileType?
    
    /**
     The duration of the whole recordSession including the current recording segment
     and the previously added record segments.
     */
    var duration: CMTime {
        return .zero
        //return CMTimeAdd(<#T##lhs: CMTime##CMTime#>, <#T##rhs: CMTime##CMTime#>)
    }
}
