//
//  SoundManager.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/06/29.
//


import AVKit
import Accelerate

enum PlayerType {
    case playBack
    case record
}
enum EdgeType {
    case start
    case end
}

//TODO: - 리팩 때 프로토콜 이름 수정 SoundManagerStatusReceivable
protocol ReceiveSoundManagerStatus {
    func audioPlayerCurrentStatus(isPlaying: Bool)
    func audioFileInitializeErrorHandler(error: Error)
    func audioEngineInitializeErrorHandler(error: Error)
}

class SoundManager {
    
    var delegate: ReceiveSoundManagerStatus?
    
    private var isPlaying = false
    private var needFileSchedule = true
    
    private let engine = AVAudioEngine()
    private let mixerNode = AVAudioMixerNode()
    private let playerNode = AVAudioPlayerNode()
    private let pitchControl = AVAudioUnitTimePitch()
    
    
    private let frequencies: [Int] = [32, 63, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    
    private var audioSampleRate: Double = 0
    private var audioPlayDuration: Double = 0
    private var seekFrame: AVAudioFramePosition = 0
    private var currentPosition: AVAudioFramePosition = 0
    private var audioLengthSamples: AVAudioFramePosition = 0
    private var lastPlayerTime: Double = 0
    
    private var currentFrame: AVAudioFramePosition {
        guard
            let lastRenderTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime)
        else {
            return 0
        }
        
        return playerTime.sampleTime
    }
    
    private var audioFile: AVAudioFile!
    
    //TODO: - AppDelegate에서 선언
    init() {
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - initialize SoundManager
    func initializeSoundManager(url: URL, type: PlayerType) {
        
        do {
            let file = try AVAudioFile(forReading: url)
            let fileFormat = file.processingFormat
            
            audioLengthSamples = file.length
            audioSampleRate = fileFormat.sampleRate
            audioPlayDuration = Double(audioLengthSamples) / audioSampleRate
            print("audio Length \(audioLengthSamples) audioSampleRate \(audioSampleRate) \(audioPlayDuration)")
            audioFile = file
            
            if type == .playBack {
                configurePlayEngine(format: fileFormat)
            } else {
                configureRecordEngine(format: fileFormat)
            }
            
            
        } catch let error as NSError {
            delegate?.audioFileInitializeErrorHandler(error: error)
        }
        
    }
    // MARK: - Set Engine
    
    private func configurePlayEngine(format: AVAudioFormat) {
        
        engine.reset()
        engine.attach(playerNode)
        engine.attach(pitchControl)
        
        engine.connect(playerNode, to: pitchControl, format: engine.mainMixerNode.outputFormat(forBus: 0))
        engine.connect(pitchControl, to: engine.mainMixerNode, format: engine.mainMixerNode.outputFormat(forBus: 0))
        
        engine.prepare()
        
        do {
            try engine.start()
        } catch let e as NSError {
            delegate?.audioEngineInitializeErrorHandler(error: e)
        }
    }
    
    // MARK: - configure PlayerNode
    private func schedulePlayerNode() {
        
        guard let file = audioFile, needFileSchedule else {
            return
        }
        needFileSchedule = false
        seekFrame = 0
        
        
        playerNode.scheduleFile(file, at: nil) { [self] in
            self.needFileSchedule = true
        }
        
        playerNode.installTap(onBus: 0, bufferSize: 1024, format: playerNode.outputFormat(forBus: 0)) { [unowned self] buffer, time in
            
            guard var currentPosition = getCurrentFrame(lastRenderTime: time) else { return }
            currentPosition = specifyFrameStandard(frame: currentFrame + seekFrame, length: audioLengthSamples)
            
            if currentPosition >= audioLengthSamples {
                resetPlayer(edge: .end)
                delegate?.audioPlayerCurrentStatus(isPlaying: isPlaying)
            }
            
        }
    }
    
    private func getCurrentFrame(lastRenderTime: AVAudioTime) -> AVAudioFramePosition? {
        guard let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime) else { return nil }
        return playerTime.sampleTime
    }
    
    private func specifyFrameStandard(frame: AVAudioFramePosition, length: AVAudioFramePosition) -> AVAudioFramePosition {
        
        var convertedFrame = frame
        
        convertedFrame = max(frame, 0)
        convertedFrame = min(frame, length)
        
        return convertedFrame
    }
    
    func playNpause() {
        
        if isPlaying {
            playerNode.pause()
        } else {
            if needFileSchedule {
                schedulePlayerNode()
            }
            playerNode.play()
        }
        
        isPlaying.toggle()
    }
    
    func skip(forwards: Bool) {
        let timeToSeek: Double
        
        if forwards {
            timeToSeek = 5
        } else {
            timeToSeek = -5
        }
        
        seek(to: timeToSeek)
    }
    
    private func seek(to time: Double) {
        guard let audioFile = audioFile else { return }
        
        let offset = AVAudioFramePosition(time * audioSampleRate)
        seekFrame = currentPosition + offset
        currentPosition = specifyFrameStandard(frame: seekFrame, length: audioLengthSamples)
        
        let wasPlaying = playerNode.isPlaying
        
        playerNode.stop()
        
        if currentPosition < 0 {
            resetPlayer(edge: .start)
            playerNode.scheduleFile(audioFile, at: nil)
            if wasPlaying {
                playerNode.play()
            }
            
        } else if currentPosition < audioLengthSamples {
            
            needFileSchedule = false
            
            let frameCount = AVAudioFrameCount(audioLengthSamples - seekFrame)
            
            playerNode.scheduleSegment(
                audioFile,
                startingFrame: seekFrame,
                frameCount: frameCount,
                at: nil
            ) {
                self.needFileSchedule = true
            }
            if wasPlaying {
                playerNode.play()
            }
            
        } else {
            resetPlayer(edge: .end)
            delegate?.audioPlayerCurrentStatus(isPlaying: isPlaying)
        }
    }
    
    private func resetPlayer(edge: EdgeType) {
        seekFrame = 0
        currentPosition = 0
        
        switch edge {
        case .start:
            needFileSchedule = false
            isPlaying = true
        case .end:
            needFileSchedule = true
            isPlaying = false
        }
    }
    
    func stop() {
        playerNode.stop()
        resetPlayer(edge: .end)
    }
    
    
    func removeTap() {
        playerNode.removeTap(onBus: 0)
    }
    func changePitchValue(value: Float) {
        self.pitchControl.pitch = value*2
    }
    
    func changeVolume(value: Float) {
        self.playerNode.volume = value*2
    }
    
}
