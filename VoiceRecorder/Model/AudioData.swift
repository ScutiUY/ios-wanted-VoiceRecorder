//
//  AudioData.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/02.
//

import Foundation

class AudioData: Codable {
    
    var title: String
    var playTime: String
    
    init(title: String, playTime: String) {
        self.title = title
        self.playTime = playTime
    }
    
}

