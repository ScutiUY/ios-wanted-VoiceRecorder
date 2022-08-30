//
//  FrequencyControlView.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/09.
//

import Foundation
import UIKit

protocol SliderEvnetDelegate {
    func sliderEventValueChanged(sender: UISlider)
}

class FrequencyControlView: UIStackView {
    
    var delegate: SliderEvnetDelegate?
    
    private var sliderFrequency: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 20000
        slider.maximumValue = 26000
        slider.value = 23000
        return slider
    }()
    
    private var sliderLabel: UILabel = {
        let label = UILabel()
        label.text = "CutOff Frequency"
        label.numberOfLines = 1
        return label
    }()
    
    init() {
        super.init(frame: .zero)
        
        configureProperties()
        setLayoutOfFrequencyControlView()
        addTargetToSlider()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureProperties() {
        self.axis = .vertical
        self.distribution = .equalSpacing
        self.alignment = .center
    }
    
    private func setLayoutOfFrequencyControlView() {
        sliderFrequency.translatesAutoresizingMaskIntoConstraints = false
        sliderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        self.addArrangedSubview(sliderFrequency)
        self.addArrangedSubview(sliderLabel)
        
        NSLayoutConstraint.activate([
            sliderFrequency.widthAnchor.constraint(equalTo: self.widthAnchor),
            sliderFrequency.heightAnchor.constraint(equalToConstant: 30),
            
            sliderLabel.widthAnchor.constraint(equalToConstant: 150),
            sliderLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func addTargetToSlider() {
        sliderFrequency.addTarget(self, action: #selector(onChangeValueSlider), for: UIControl.Event.valueChanged)
    }
    
    @objc func onChangeValueSlider() {
        delegate?.sliderEventValueChanged(sender: sliderFrequency)
    }
}
