//
//  SoundManager.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/06/29.
//

import AVKit
import Accelerate

//TODO: - pitch enum 선언 필요

enum PitchVariable: Int {
    case middle = 0
    case row = -150
    case high = 150
}

enum PlayerType {
    case playBack
    case record
}
enum EdgeType {
    case start
    case end
}

protocol RecordingVisualizerable: AnyObject {
    func processAudioBuffer(buffer: AVAudioPCMBuffer)
}

protocol PlaybackVisualizerable: AnyObject {
    func operatingwaveProgression(progress: Float, audioLength: Float)
}

protocol SoundManagerStatusReceivable: AnyObject {
    func audioPlayerCurrentStatus(isPlaying: Bool)
    func audioFileInitializeErrorHandler(error: Error)
    func audioEngineInitializeErrorHandler(error: Error)
}

class SoundManager {
    
    weak var delegate: SoundManagerStatusReceivable?
    weak var recordVisualizerDelegate: RecordingVisualizerable!
    weak var playBackVisualizerDelegate: PlaybackVisualizerable!
    
    var isEnginePrepared = false
    private var isPlaying = false
    private var needFileSchedule = true
    
    private var fileUrl: URL!
    private var audioFile: AVAudioFile!
    
    private let recordEngine = AVAudioEngine()
    
    private let engine = AVAudioEngine()
    private lazy var inputNode = recordEngine.inputNode
    private let mixerNode = AVAudioMixerNode()
    
    private var frequency: Float = 40000
    private let eqNode = AVAudioUnitEQ(numberOfBands: 1)
    private lazy var eqFilterParameters: AVAudioUnitEQFilterParameters = eqNode.bands[0] as AVAudioUnitEQFilterParameters
    
    private let playerNode = AVAudioPlayerNode()
    private let pitchControl = AVAudioUnitTimePitch()
    
    private var audioSampleRate: Double = 0
    private var seekFrame: AVAudioFramePosition = 0
    private var currentPosition: AVAudioFramePosition = 0
    private var audioLengthSamples: AVAudioFramePosition = 0
    
    private var currentFrame: AVAudioFramePosition {
        guard
            let lastRenderTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime)
        else {
            return 0
        }
        return playerTime.sampleTime
    }
    
    // MARK: - initialize SoundManager
    func initializeSoundManager(url: URL, type: PlayerType) {
        do {
            engine.reset()
            playerNode.reset()
            fileUrl = url
            
            if type == .playBack {
                
                let file = try AVAudioFile(forReading: url)
                let fileFormat = file.processingFormat
                
                audioLengthSamples = file.length
                audioSampleRate = fileFormat.sampleRate
                audioFile = file
                configurePlayEngine(format: fileFormat)
                
            } else {
                configureRecordEngine()
            }
        } catch let error as NSError {            delegate?.audioFileInitializeErrorHandler(error: error)
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
        isEnginePrepared = true
        
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
            
            
            currentPosition = currentFrame + seekFrame
            currentPosition = max(currentPosition, 0)
            currentPosition = min(currentPosition, audioLengthSamples)
            
            if currentPosition >= audioLengthSamples {
                resetPlayer(edge: .end)
            }
            playBackVisualizerDelegate.operatingwaveProgression(progress: Float(currentPosition)/Float(audioLengthSamples), audioLength: Float(audioLengthSamples))
        }
    }
    
    private func getCurrentFrame(lastRenderTime: AVAudioTime) -> AVAudioFramePosition? {
        guard let playerTime = playerNode.playerTime(forNodeTime: lastRenderTime) else { return nil }
        return playerTime.sampleTime
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
    
    func skip(isForwards: Bool) {
        let timeToSeek: Double
        
        if isForwards {
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
        seekFrame = max(seekFrame, 0)
        seekFrame = min(seekFrame, audioLengthSamples)
        currentPosition = seekFrame
        
        let wasPlaying = playerNode.isPlaying
        playerNode.stop()
        
        if currentPosition < audioLengthSamples {
            
            currentPosition = currentFrame + seekFrame
            currentPosition = max(currentPosition, 0)
            currentPosition = min(currentPosition, audioLengthSamples)
            
            if currentPosition >= audioLengthSamples {
                playerNode.stop()
                resetPlayer(edge: .end)
                
            }
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
            delegate?.audioPlayerCurrentStatus(isPlaying: isPlaying)
            playBackVisualizerDelegate.operatingwaveProgression(progress: 0, audioLength: Float(audioLengthSamples))
        }
    }
    
    func stop() {
        playerNode.stop()
        resetPlayer(edge: .end)
    }
    
    func removeTap() {
        playerNode.removeTap(onBus: 0)
    }
    
    func changePitchValue(value: PitchVariable) {
        self.pitchControl.pitch = Float(value.rawValue * 2)
    }
    
    func changeVolume(value: Float) {
        self.playerNode.volume = value * 2
    }
    
    func changeProgressValue(value: Float) {
        self.seek(to: Double(value))
    }
}

extension SoundManager {
    
    // MARK: - Set Engine
    func configureRecordEngine() {
        let format = inputNode.outputFormat(forBus: 0)
        mixerNode.volume = 0
        
        recordEngine.attach(mixerNode)
        recordEngine.attach(eqNode)
        
        recordEngine.connect(inputNode, to: eqNode, format: format)
        recordEngine.connect(eqNode, to: mixerNode, format: format)
    }
    
    private func createAudioFile(filePath: URL) throws -> AVAudioFile {
        let format = inputNode.outputFormat(forBus: 0)
        return try AVAudioFile(forWriting: filePath, settings: format.settings)
    }
    
    func getAudioFile(filePath: URL) throws -> AVAudioFile {
        return try AVAudioFile(forReading: filePath)
    }
    
    private func setFrequency() {
        eqFilterParameters.filterType = .bandPass
        eqFilterParameters.bypass = false
        eqFilterParameters.frequency = frequency
    }
    
    func setFrequencyValue(value: Float) {
        frequency = value
    }
    
    func startRecord() {
        isEnginePrepared = true
        
        let format = inputNode.outputFormat(forBus: 0)
        
        do {
            audioFile = try createAudioFile(filePath: fileUrl)
        } catch {
            fatalError()
        }
        
        mixerNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, time in
            do {
                self.setFrequency()
                try self.audioFile.write(from: buffer)
                self.recordVisualizerDelegate.processAudioBuffer(buffer: buffer)
            } catch let error {
                self.delegate!.audioFileInitializeErrorHandler(error: error)
            }
        }
        
        do {
            try recordEngine.start()
        } catch {
            fatalError()
        }
    }
    
    func stopRecord() {
        mixerNode.removeTap(onBus: 0)
        recordEngine.stop()
        isEnginePrepared = false
    }
}
