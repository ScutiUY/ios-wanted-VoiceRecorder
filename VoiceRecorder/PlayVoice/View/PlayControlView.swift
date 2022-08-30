//
//  PlayControlView.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/06/29.
//

import Foundation
import UIKit

protocol SoundButtonActionDelegate: AnyObject {
    func playButtonTouchUpinside(sender: UIButton)
    func backwardButtonTouchUpinside(sender: UIButton)
    func forwardTouchUpinside(sender: UIButton)
}

class PlayControlView: UIStackView {
    
    weak var delegate: SoundButtonActionDelegate?
    
    var isSelected: Bool {
        get {
            return playButton.isSelected
        }
        set {
            playButton.isSelected = newValue
        }
    }
    
    var isPlayButtonActivate: Bool {
        get {
            return playButton.isEnabled
        }
        set {
            playButton.isEnabled = newValue
        }
    }

    private var playButton: UIButton = {
        var button = UIButton()
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let largePlayImage = UIImage(systemName: "play", withConfiguration: largeConfig)
        let largePauseImage = UIImage(systemName: "pause.fill", withConfiguration: largeConfig)
        button.setImage(largePlayImage, for: .normal)
        button.setImage(largePauseImage, for: .selected)
        return button
    }()
    
    private var backwardButton: UIButton = {
        var button = UIButton()
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let largebackwardImage = UIImage(systemName: "gobackward.5", withConfiguration: largeConfig)
        button.setImage(largebackwardImage, for: .normal)
        return button
    }()
    
    private var forwardButton: UIButton = {
        var button = UIButton()
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let largeforkwardImage = UIImage(systemName: "goforward.5", withConfiguration: largeConfig)
        button.setImage(largeforkwardImage, for: .normal)
        return button
    }()
        
    override init(frame: CGRect) {
        super.init(frame: .zero)
        
        configureProperties()
        setLayoutOfPlayControlView()
        addTargetToButtons()
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureProperties() {
        self.axis = .horizontal
        self.distribution = .equalSpacing
        self.alignment = .center
    }
    
    private func setLayoutOfPlayControlView() {
        playButton.translatesAutoresizingMaskIntoConstraints = false
        backwardButton.translatesAutoresizingMaskIntoConstraints = false
        forwardButton.translatesAutoresizingMaskIntoConstraints = false
        
        self.addArrangedSubview(backwardButton)
        self.addArrangedSubview(playButton)
        self.addArrangedSubview(forwardButton)
        
        NSLayoutConstraint.activate([
            
            backwardButton.widthAnchor.constraint(equalToConstant: 50),
            backwardButton.heightAnchor.constraint(equalToConstant: 50),
            
            playButton.widthAnchor.constraint(equalToConstant: 70),
            playButton.heightAnchor.constraint(equalToConstant: 70),
            
            forwardButton.widthAnchor.constraint(equalToConstant: 50),
            forwardButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func addTargetToButtons() {
        playButton.addTarget(self, action: #selector(playButtonHandler), for: .touchUpInside)
        backwardButton.addTarget(self, action: #selector(backwardButtonHandler), for: .touchUpInside)
        forwardButton.addTarget(self, action: #selector(forwardButtonHandler), for: .touchUpInside)
    }
    
    @objc func playButtonHandler() {
        delegate?.playButtonTouchUpinside(sender: playButton)
        playButton.isSelected.toggle()
    }
    
    @objc func backwardButtonHandler() {
        delegate?.backwardButtonTouchUpinside(sender: backwardButton)
    }
    
    @objc func forwardButtonHandler() {
        delegate?.forwardTouchUpinside(sender: forwardButton)
    }
}
