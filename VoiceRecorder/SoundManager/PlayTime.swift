//
//  PlayTime.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/09.
//

import Foundation
import AVKit

class PlayTime {
    
    func totalPlayTime(audioFile: AVAudioFile) -> Double {
        let length = audioFile.length
        let sampleRate = audioFile.processingFormat.sampleRate
        let audioPlayTime = Double(length) / sampleRate
        
        return audioPlayTime
    }
    
    func convertTimeToString(_ seconds: TimeInterval) -> String {
        if seconds.isNaN {
            return "00:00"
        }
        
        let min = Int(seconds / 60)
        let sec = Int(seconds.truncatingRemainder(dividingBy: 60))
        let strTime = String(format: "%02d:%02d", min, sec)
        
        return strTime
    }
}
