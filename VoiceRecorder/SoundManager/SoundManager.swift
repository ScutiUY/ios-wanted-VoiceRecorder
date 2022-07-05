//
//  SoundManager.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/06/29.
//

import Foundation
import AVFoundation
import AVKit

protocol ReceiveSoundManagerStatus {
    func observeAudioPlayerDidFinishPlaying(_ playerNode: AVAudioPlayerNode)
}

class SoundManager: NSObject {
    
    var delegate: ReceiveSoundManagerStatus?
    
    private let engine = AVAudioEngine()
    private lazy var inputNode = engine.inputNode
    private let mixerNode = AVAudioMixerNode()
    
    private let playerNode = AVAudioPlayerNode()
    private let pitchControl = AVAudioUnitTimePitch()
    
    var songLengthSamples: AVAudioFramePosition!
    
    var sampleRateSong: Float = 0
    var lengthSongSeconds: Float = 0
    var startInSongSeconds: Float = 0
    
    var audioFile: AVAudioFile!
    
    override init() {
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        try? AVAudioSession.sharedInstance().setActive(true)
    }
    
    func initializedEngine(url: URL) {
        
        do {
            let file = try AVAudioFile(forReading: url)
            let fileFormat = file.processingFormat
            let audioFrameCount = UInt32(file.length)
            
            
            let buffer = AVAudioPCMBuffer(pcmFormat: fileFormat, frameCapacity: audioFrameCount)
            //
            audioFile = file
            songLengthSamples = audioFile.length
            sampleRateSong = Float(fileFormat.sampleRate)
            lengthSongSeconds = Float(songLengthSamples) / sampleRateSong
            
            //
            
            
            configurePlayEngine(format: fileFormat)
            
            playerNode.scheduleFile(file, at: nil) { [self] in
                self.delegate?.observeAudioPlayerDidFinishPlaying(playerNode)
            }
            
        } catch let error as NSError {
            print("엔진 초기화 실패")
            print("코드 : \(error.code), 메세지 : \(error.localizedDescription)")
        }
        
    }
    
    func configureRecordEngine(format: AVAudioFormat) {
        engine.attach(mixerNode)
        
        engine.connect(inputNode, to: mixerNode, format: format)
    }
    
    func configurePlayEngine(format: AVAudioFormat) {
        
        engine.attach(playerNode)
        engine.attach(pitchControl)
        
        engine.connect(playerNode, to: pitchControl, format: format)
        engine.connect(pitchControl, to: engine.mainMixerNode, format: format)
        //engine.connect(engine.mainMixerNode, to: engine.outputNode, format: format)
        
        // mainMixerNode로 가면 바로 끝내고 prepare로 돌아가는듯함
        // ouptNode로 연결하면 무한루프 됨
        // 아마 mainMixerNode쪽에 종료 메소드가 포함 되어 있는듯
        
        engine.prepare()
    }
    
    func configurePlayerNode() {
        
    }
    
    private func createAudioFile(filePath: URL) throws -> AVAudioFile {
        let format = inputNode.outputFormat(forBus: 0)
        return try AVAudioFile(forWriting: filePath, settings: format.settings)
    }
    
    func startRecord(filePath: URL) {
        engine.reset()
        
        let format = inputNode.outputFormat(forBus: 0)
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
    
    func getCurrentPosition() -> Float {
        if(self.playerNode.isPlaying){
            if let nodeTime = self.playerNode.lastRenderTime, let playerTime = playerNode.playerTime(forNodeTime: nodeTime) {
                let elapsedSeconds = startInSongSeconds + (Float(playerTime.sampleTime) / Float(sampleRateSong))
                print("Elapsed seconds: \(elapsedSeconds)")
                return elapsedSeconds
            }
        }
        return 0
    }
    
    func seek(to: Bool) {
        
        playerNode.stop()
        
        let startSample = Float(4.0)//floor(time * sampleRateSong)
        let lengthSamples = Float(songLengthSamples) - startSample
        
        playerNode.scheduleSegment(audioFile, startingFrame: AVAudioFramePosition(4), frameCount: AVAudioFrameCount(lengthSamples), at: nil, completionHandler: {self.playerNode.pause()})
        playerNode.play(at: AVAudioTime(hostTime: 5))
        
    }
    
    
    func changePitchValue(value: Float) {
        self.pitchControl.pitch = value
    }
    
    func changeVolume(value: Float) {
        self.playerNode.volume = value
    }
    
}

