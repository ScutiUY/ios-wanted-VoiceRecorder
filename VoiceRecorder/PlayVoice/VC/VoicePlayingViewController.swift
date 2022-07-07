//
//  VoicePlayingViewController.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/06/29.
//

import UIKit
import AVFoundation
import AVKit

class VoicePlayingViewController: UIViewController {
    
    private var soundManager: SoundManager!
    
    private var recordedVoiceTitle: UILabel = {
        var label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        label.text = "Test Text"
        return label
    }()
    
    private var middleAnchorView: UIView = {
        var stackView = UIView()
        return stackView
    }()
    
    private var currentPlayingView: UIView = {
        var view = UIView()
        view.backgroundColor = .brown
        return view
    }()
    
    private var pitchSegmentController: UISegmentedControl = {
        var segment = UISegmentedControl(items: ["일반 목소리", "아기 목소리", "할아버지 목소리"])
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    private var volumeSlider: UISlider = {
        var slider = UISlider()
        slider.setValue(0.5, animated: true)
        slider.minimumValueImage = UIImage(systemName: "speaker")
        slider.maximumValueImage = UIImage(systemName: "speaker.wave.3")
        return slider
    }()
    
    // Play, for/bacward button
    private lazy var playControlView: PlayControlView = {
        var view = PlayControlView()
        view.delegate = self
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayoutOfVoicePlayVC()
        addViewsActionsToVC()
    }
    override func viewWillDisappear(_ animated: Bool) {
        soundManager.stop()
        soundManager.removeTap()
        playControlView.isSelected = false
    }
    
    private func configureLayoutOfVoicePlayVC() {
        
        view.backgroundColor = .white
        
        middleAnchorView.translatesAutoresizingMaskIntoConstraints = false
        currentPlayingView.translatesAutoresizingMaskIntoConstraints = false
        pitchSegmentController.translatesAutoresizingMaskIntoConstraints = false
        volumeSlider.translatesAutoresizingMaskIntoConstraints = false
        playControlView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(recordedVoiceTitle)
        view.addSubview(middleAnchorView)
        middleAnchorView.addSubview(currentPlayingView)
        view.addSubview(pitchSegmentController)
        view.addSubview(volumeSlider)
        view.addSubview(playControlView)
        
        NSLayoutConstraint.activate([
            
            recordedVoiceTitle.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            recordedVoiceTitle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordedVoiceTitle.widthAnchor.constraint(equalTo: view.widthAnchor),
            recordedVoiceTitle.heightAnchor.constraint(equalToConstant: 30),
            
            middleAnchorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            middleAnchorView.widthAnchor.constraint(equalTo: view.widthAnchor),
            middleAnchorView.topAnchor.constraint(equalTo: recordedVoiceTitle.bottomAnchor),
            middleAnchorView.bottomAnchor.constraint(equalTo: playControlView.topAnchor),
            
            currentPlayingView.centerYAnchor.constraint(equalTo: middleAnchorView.centerYAnchor).constraintWithMultiplier(0.5),
            currentPlayingView.centerXAnchor.constraint(equalTo: middleAnchorView.centerXAnchor),
            currentPlayingView.heightAnchor.constraint(equalToConstant: 100),
            currentPlayingView.widthAnchor.constraint(equalTo:  middleAnchorView.widthAnchor, multiplier: 0.9),
            
            volumeSlider.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            volumeSlider.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            volumeSlider.heightAnchor.constraint(equalToConstant: 30),
            volumeSlider.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            
            playControlView.bottomAnchor.constraint(equalTo: volumeSlider.topAnchor, constant: -10),
            playControlView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playControlView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            playControlView.heightAnchor.constraint(equalToConstant: 100),
            
            pitchSegmentController.bottomAnchor.constraint(equalTo: playControlView.topAnchor,constant: -20),
            pitchSegmentController.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pitchSegmentController.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
        
        ])
        
    }
    
    func fetchRecordedDataFromMainVC(dataUrl: URL) {
        setSoundManager()
        recordedVoiceTitle.text = "\(dataUrl.lastPathComponent.split(separator: ".")[0])"
        soundManager.initializeSoundManager(url: dataUrl, type: .playBack)
    }
    
    func setSoundManager() {
        soundManager = SoundManager()
        soundManager.delegate = self
    }
    
    func addViewsActionsToVC() {
        volumeSlider.addTarget(self, action: #selector(changeVolumeValue), for: .valueChanged)
        pitchSegmentController.addTarget(self, action: #selector(changePitchValue), for: .valueChanged)
    }
    
    
    @objc func changeVolumeValue() {
        
        soundManager.changeVolume(value: volumeSlider.value)
    }
    
    @objc func changePitchValue() {
        if pitchSegmentController.selectedSegmentIndex == 0 {
            soundManager.changePitchValue(value: 0)
        } else if pitchSegmentController.selectedSegmentIndex == 1 {
            soundManager.changePitchValue(value: 150)
        } else {
            soundManager.changePitchValue(value: -150)
        }
        
    }
}

// MARK: - Sound Control Button Delegate

extension VoicePlayingViewController: SoundButtonActionDelegate {
    
    func playButtonTouchUpinside(sender: UIButton) {
        soundManager.playNpause()
    }
    
    func backwardButtonTouchUpinside(sender: UIButton) {
        soundManager.skip(forwards: false)
    }
    
    func forwardTouchUpinside(sender: UIButton) {
        soundManager.skip(forwards: true)
    }
}


// MARK: - SoundeManager Delegate

extension VoicePlayingViewController: ReceiveSoundManagerStatus {
    func audioPlayerCurrentStatus(isPlaying: Bool) {
        soundManager.removeTap()
        DispatchQueue.main.async {
            self.playControlView.isSelected = isPlaying
            
        }
        
    }
    
    func audioFileInitializeErrorHandler(error: Error) {
        let alert = UIAlertController(title: "파일 초기화 실패!", message: "오류코드: \(error.localizedDescription)", preferredStyle: .alert)
        self.present(alert, animated: true)
    }
    
    
    func audioEngineInitializeErrorHandler(error: Error) {
        let alert = UIAlertController(title: "엔진 초기화 실패!", message: "오류코드: \(error.localizedDescription)", preferredStyle: .alert)
        self.present(alert, animated: true)
    }
    
}


