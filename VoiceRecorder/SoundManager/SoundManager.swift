//
//  SoundManager.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/06/29.
//

import Foundation
import AVFoundation
import AVKit

enum TpyeOfPlayer {
    case playBack
    case record
}

protocol ReceiveSoundManagerStatus {
    func observeAudioPlayerDidFinishPlaying(_ playerNode: AVAudioPlayerNode)
}

class SoundManager: NSObject {
    
    var delegate: ReceiveSoundManagerStatus?
    
    private let engine = AVAudioEngine()
    
    private let mixerNode = AVAudioMixerNode()
    
    private let playerNode = AVAudioPlayerNode()
    private let pitchControl = AVAudioUnitTimePitch()
    
    private var audioSampleRate: Double = 0
    private var audioLengthSeconds: Double = 0

    private var seekFrame: AVAudioFramePosition = 0
    private var currentPosition: AVAudioFramePosition = 0
    private var audioLengthSamples: AVAudioFramePosition = 0
    
    var audioFile: AVAudioFile!
    
    override init() {
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    // MARK: - initialize SoundManager
    func initializeSoundManager(url: URL, type: TpyeOfPlayer) {
        
        do {
            let file = try AVAudioFile(forReading: url)
            let fileFormat = file.processingFormat

            audioLengthSamples = file.length
            audioSampleRate = fileFormat.sampleRate
            audioLengthSeconds = Double(audioLengthSamples) / audioSampleRate
            
            audioFile = file
                
            if type == .playBack {
                configurePlayEngine(format: fileFormat)
            } else {
                configureRecordEngine(format: fileFormat)
            }
            
            
        } catch let error as NSError {
            print("엔진 초기화 실패")
            print("코드 : \(error.code), 메세지 : \(error.localizedDescription)")
        }
        
    }
    
    func configureRecordEngine(format: AVAudioFormat) {
        engine.reset()
        engine.attach(mixerNode)
        engine.connect(engine.inputNode, to: mixerNode, format: format)
        engine.prepare()
        
        do {
            try engine.start()
            configurePlayerNode()
        } catch {
            print("엔진 초기화 실패")
            // 실패시 메소드 추가 예정
        }
        
    }
    
    func configurePlayEngine(format: AVAudioFormat) {
        engine.reset()
        engine.attach(playerNode)
        engine.attach(pitchControl)
        
        engine.connect(playerNode, to: pitchControl, format: format)
        engine.connect(pitchControl, to: engine.mainMixerNode, format: format)
        
        engine.prepare()
    }
    
    func configurePlayerNode() {
        playerNode.scheduleFile(audioFile, at: nil) { [self] in
            self.delegate?.observeAudioPlayerDidFinishPlaying(playerNode)
        }
    }
    
    private func createAudioFile(filePath: URL) throws -> AVAudioFile {
        let format = engine.inputNode.outputFormat(forBus: 0)
        return try AVAudioFile(forWriting: filePath, settings: format.settings)
    }
    
    func startRecord(filePath: URL) {
        engine.reset()
        
        let format = engine.inputNode.outputFormat(forBus: 0)
        configureRecordEngine(format: format)
        
        do {
            audioFile = try createAudioFile(filePath: filePath)
        } catch {
            fatalError()
        }
        
        mixerNode.removeTap(onBus: 0)
        mixerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, time in
            do {
                try self.audioFile.write(from: buffer)
                
            } catch {
                fatalError()
            }
        }
      
        do {
            try engine.start()
        } catch {
            fatalError()
        }
    }
    
    func stopRecord() {
        engine.stop()
        engine.isRunning
    }
    
    func play() {
        try! engine.start()
        playerNode.play()
        
    }
    
    func pause() {
        playerNode.pause()
    }
    
    func stopPlayer() {
        playerNode.stop()
    }
    
    func getCurrentPosition()  {
        
    }
    
    func seek(to: Bool) {
        
        
    }
    
    
    func changePitchValue(value: Float) {
        self.pitchControl.pitch = value
    }
    
    func changeVolume(value: Float) {
        self.playerNode.volume = value
    }
    
}

