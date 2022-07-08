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
    
    private var audioPlotView: AudioPlotView = {
        var audioPlotView = AudioPlotView()
        audioPlotView.translatesAutoresizingMaskIntoConstraints = false
        return audioPlotView
    }()
    
    private var centerPlot: UIView = {
        var view = UIView()
        view.backgroundColor = .black
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 1
        view.layer.borderColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        return view
    }()
    
    init() {
        super.init(frame: .zero)
        self.indicatorStyle = .white
        self.backgroundColor = .gray
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.transform = CGAffineTransform(scaleX: -1, y: 1)
        setAudioPlotView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.indicatorStyle = .white
        self.backgroundColor = .gray
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
        self.addSubview(centerPlot)
        NSLayoutConstraint.activate([
            
            centerPlot.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            centerPlot.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            centerPlot.widthAnchor.constraint(equalToConstant: 1),
            centerPlot.heightAnchor.constraint(equalTo: self.heightAnchor),
            
            audioPlotView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            audioPlotView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            audioPlotView.trailingAnchor.constraint(equalTo: self.trailingAnchor),
            audioPlotView.leadingAnchor.constraint(equalTo: self.leadingAnchor),
            audioPlotView.heightAnchor.constraint(equalTo: self.heightAnchor)
            
        ])
        
    }
    
    private func rms(data: UnsafeMutablePointer<Float>, frameLength: UInt) -> Float {
        var val : Float = 0
        vDSP_measqv(data, 1, &val, frameLength)
        val *= 1000
        return val
    }
    
    func processAudioData(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else {return}
        let frames = buffer.frameLength
        
        let rmsValue = rms(data: channelData, frameLength: UInt(frames))
        audioPlotView.waveforms.append(Int(rmsValue))
        DispatchQueue.main.async { [self] in
            self.audioPlotView.setNeedsDisplay()
        }
    }
    
    func getWaveformData() -> [Int] {
        return audioPlotView.waveforms
    }
    
    func moveToCenter() {
        //audioPlotView.moveToCenter()
    }
    
}
