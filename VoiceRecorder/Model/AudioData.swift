//
//  AudioData.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/02.
//

import Foundation

class AudioData: Codable {
    
    var title: String
    var duration: String
    
    init(title: String, duration: String) {
        self.title = title
        self.duration = duration
    }
    
}

