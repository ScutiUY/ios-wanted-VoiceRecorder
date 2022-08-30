//
//  AudioPlotView.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/08.
//

import UIKit
import AVFAudio
import Accelerate

class AudioVisualizeView: UIScrollView {
    
    private var count = 0
    private var playType: PlayType = .record

    var isTouchable: Bool {
        get {
            return self.isScrollEnabled
        } set {
            self.isScrollEnabled = newValue
        }
    }
    
    private var audioPlotView: AudioPlotView = {
        var audioPlotView = AudioPlotView()
        audioPlotView.translatesAutoresizingMaskIntoConstraints = false
        return audioPlotView
    }()
    
    init(playType: PlayType) {
        super.init(frame: .zero)
        self.indicatorStyle = .white
        self.backgroundColor = .black
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.playType = playType
        
        switch playType {
        case .playback:
            self.transform = CGAffineTransform(scaleX: 1, y: -1)
        case .record:
            self.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        
        setAudioPlotView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.indicatorStyle = .white
        self.backgroundColor = .black
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.transform = CGAffineTransform(scaleX: -1, y: 1)
        setAudioPlotView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        setAudioPlotView()
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setAudioPlotView() {
        self.addSubview(audioPlotView)
        
        NSLayoutConstraint.activate([
            
            audioPlotView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            audioPlotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            audioPlotView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            audioPlotView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            audioPlotView.heightAnchor.constraint(equalTo: self.heightAnchor)
        ])
    }
    
    func processAudioData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let channelDataValue = channelData.pointee
        let frames = buffer.frameLength
        
        let rmsValue = rms(data: channelDataValue, frameLength: UInt(frames))
        audioPlotView.waveforms.append(rmsValue)
        
        DispatchQueue.main.async { [self] in
            udpateVisualizerContentSize()
            self.audioPlotView.setNeedsDisplay()
        }
    }
    
    func getWaveformData() -> [Float] {
        return audioPlotView.exportWaveformData()
    }
    
    func setWaveformData(waveDataArray: [Float]) {
        DispatchQueue.main.async {
            self.contentSize.width += 5 * CGFloat(waveDataArray.count)
        }
        audioPlotView.importWaveformData(waveData: waveDataArray)
    }
    
    func moveToStartingPoint() {
        switch playType {
        case .playback:
            self.setContentOffset(.zero, animated: true)
        case .record:
            let bottomOffset = CGPoint(x: self.contentSize.width - self.bounds.size.width, y: 0)
            self.setContentOffset(bottomOffset, animated: false)
        }
    }
    
    func operateVisualizerMove(value: Float, audioLenth: Float, centerViewMargin: CGFloat) {
        DispatchQueue.main.async { [self] in
            let percent = self.contentSize.width - centerViewMargin
            let currentPersent = CGFloat(value) * percent
            switch self.playType {
            case .playback:
                self.setContentOffset(CGPoint(x: currentPersent, y: 0), animated: true)
            case .record:
                self.setContentOffset(CGPoint(x: Int(self.bounds.minX) - 20, y: 0), animated: true)
            }
        }
    }
    
    private func rms(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
        var val : Float = 0
        vDSP_measqv(data, 1, &val, frameLength)
        val *= 1000
        return val
    }
    
    private func udpateVisualizerContentSize() {
        self.contentSize.width += 5
    }
}
