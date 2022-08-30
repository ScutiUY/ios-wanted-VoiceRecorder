//
//  AudioPlotView.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/07.
//

import UIKit

protocol VisualizerStatusReceivable: AnyObject {
    func visualizer(auidoPlotView: UIView)
}

enum PlayType {
    case playback
    case record
}

class AudioPlotView: UIView {

    weak var delegate: VisualizerStatusReceivable!
    private var caLayer: CAShapeLayer!
    
    var active = false {
        didSet {
            if self.active {
                self.color = UIColor.red.cgColor
            }
            else {
                self.color = UIColor.gray.cgColor
            }
        }
    }
    
    private var color = UIColor.gray.cgColor
    var waveforms = [Float]()
    var count = 0
    
    init(playType: PlayType) {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.clear
        caLayer = CAShapeLayer()
        caLayer.strokeColor = UIColor.red.cgColor
        caLayer.lineWidth = 1
        caLayer.cornerRadius = 0.5
        self.layer.addSublayer(caLayer)
        switch playType {
        case .playback:
            self.transform = CGAffineTransform(scaleX: 1, y: -1)
        case .record:
            self.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        
    }
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        self.backgroundColor = UIColor.clear
        caLayer = CAShapeLayer()
        caLayer.strokeColor = UIColor.red.cgColor
        caLayer.lineWidth = 1
        caLayer.cornerRadius = 0.5
        self.layer.addSublayer(caLayer)
        self.transform = CGAffineTransform(scaleX: -1, y: 1)
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        self.backgroundColor = UIColor.clear
        caLayer = CAShapeLayer()
        caLayer.strokeColor = UIColor.red.cgColor
        caLayer.lineWidth = 1
        caLayer.cornerRadius = 0.5
        self.layer.addSublayer(caLayer)
        self.transform = CGAffineTransform(scaleX: -1, y: 1)
    }
 
    public func shiftWaveform() {
        guard let sublayers = self.layer.sublayers else { return }
        for layer in sublayers {
            let transform  = CATransform3DTranslate(layer.transform, -5, 0, 0)
            layer.transform = transform
        }
    }
    
    func shiftForward() {
        guard let sublayers = self.layer.sublayers else { return }
        for layer in sublayers {
            let transform  = CATransform3DTranslate(layer.transform, -1, 0, 0)
            layer.transform = transform
        }
    }
    
    func importWaveformData(waveData: [Float]) {
        waveforms = waveData
        drawPlaybackWaveForm()
    }
    
    func exportWaveformData() -> [Float] {
        return waveforms
    }
    
    override func draw(_ rect: CGRect) {
        drawRecordingWaveForm()
    }
    
    func drawRecordingWaveForm() {
        shiftWaveform()
        count += 1
    
        let path: UIBezierPath!
        
        if let ppath = caLayer.path {
            path = UIBezierPath(cgPath: ppath)
        } else {
            path = UIBezierPath()
        }
    
        guard var wave = waveforms.last else { return }
        
        if (wave) <= 2 {
            wave = 2
        }
        
        let startX = Float(self.bounds.width) / 2 + 5 * Float(count)
        let startY = self.bounds.origin.y + self.bounds.height/2
        
        path.move(to: CGPoint(x: CGFloat(startX), y: startY + CGFloat(wave)))
        path.addLine(to: CGPoint(x: CGFloat(startX), y: startY - CGFloat(wave)))
      
        caLayer.path = path.cgPath
    }
    
    func drawPlaybackWaveForm() {
        for i in waveforms {
            count+=1
            let path: UIBezierPath!
            
            if let ppath = caLayer.path {
                path = UIBezierPath(cgPath: ppath)
            } else {
                path = UIBezierPath()
            }
            
            var wave = i
            if (wave) <= 2 {
                wave = 2
            }
            let startX = Float(self.bounds.width) / 2 + 5 * Float(-count) + 15
            let startY = self.bounds.origin.y + self.bounds.height/2
            
            path.move(to: CGPoint(x: CGFloat(startX), y: startY + CGFloat(wave)))
            path.addLine(to: CGPoint(x: CGFloat(startX), y: startY - CGFloat(wave)))
          
            caLayer.path = path.cgPath
            self.setNeedsLayout()
        }
    }
}
