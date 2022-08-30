//
//  AudioData.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/02.
//

class AudioMetaData {
    var title: String
    var duration: String
    var url: String
    var waveforms: [Float]
    
    init(title: String, duration: String, url: String, waveforms: [Float]) {
        self.title = title
        self.duration = duration
        self.url = url
        self.waveforms = waveforms
    }
}

