//
//  AudioPlotView.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/07.
//

import UIKit

class AudioPlotView: UIView {
    
    private var caLayer: CAShapeLayer!
    // MARK: - Vars
    
    /// Bar width
    var barWidth: CGFloat = 4.0
    
    /// Indicate that waveform should draw active/inactive state
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
    
    /// Color for bars
    private var color = UIColor.gray.cgColor
    
    /// Given waveforms
    var waveforms = [Int]()
    private var count = 0
    
    // MARK: - Init
    
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
        caLayer = CAShapeLayer()
        caLayer.strokeColor = UIColor.red.cgColor
        caLayer.lineWidth = 1
        caLayer.cornerRadius = 0.5
        self.layer.addSublayer(caLayer)
        self.transform = CGAffineTransform(scaleX: -1, y: 1)
    }
        
    public func shiftWaveform(value: CGFloat) {
        guard let sublayers = self.layer.sublayers else { return }
        for layer in sublayers {
            layer.transform = CATransform3DTranslate(layer.transform, 0, 0, 0)
            let transform  = CATransform3DTranslate(layer.transform, value, 0, 0)
            layer.transform = transform
        }
    }
    
    public func shiftWaveform() {
        guard let sublayers = self.layer.sublayers else { return }
        for layer in sublayers {
            let transform  = CATransform3DTranslate(layer.transform, -5, 0, 0)
            layer.transform = transform
        }
        
    }
    
    func shiftBackward(value: CGFloat) {
        guard let sublayers = self.layer.sublayers else { return }
        for layer in sublayers {
            layer.transform = CATransform3DTranslate(layer.transform, 0, 0, 0)
            let transform  = CATransform3DTranslate(layer.transform, value, 0, 0)
            layer.transform = transform
        }
        
    }
    
    func move() {
        caLayer.scroll(CGPoint(x: 100, y: 300))
    }
    
    override func draw(_ rect: CGRect) {
        shiftWaveform()
        count += 1
    
        let path: UIBezierPath!
        
        if let ppath = caLayer.path {
            path = UIBezierPath(cgPath: ppath)
        } else {
            path = UIBezierPath()
        }
    
        guard var wave = waveforms.last else { return }
        
        if (Int(wave) <= 2) {
            wave = 2
        }
        
        let startX = Int(self.bounds.width/2) + 5*count
        let startY = Int(self.bounds.origin.y) + Int(self.bounds.height)/2
        
        path.move(to: CGPoint(x: startX, y: startY + wave))
        path.addLine(to: CGPoint(x: startX, y: startY - wave))
      
        caLayer.path = path.cgPath
    }
    
}
