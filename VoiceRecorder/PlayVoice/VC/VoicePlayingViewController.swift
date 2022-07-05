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
    
    var soundManager: SoundManager!
    
    // title Label
    private lazy var recordedVoiceTitle: UILabel = {
        var label = UILabel()
        label.font = UIFont.systemFont(ofSize: 20)
        label.textAlignment = .center
        label.text = "Test Text"
        return label
    }()
    
    // middle view stackView
    private lazy var middleAnchorView: UIView = {
        var stackView = UIView()
        return stackView
    }()
    
    // currentPlayView
    private lazy var currentPlayingView: UIView = {
        var view = UIView()
        view.backgroundColor = .brown
        return view
    }()
    
    // segment and volume View
    private lazy var pitchSegmentController: UISegmentedControl = {
        var segment = UISegmentedControl(items: ["일반 목소리", "아기 목소리", "할아버지 목소리"])
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    private lazy var volumeSlider: UISlider = {
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
        soundManager.stopPlayer()
    }
    
    private func configureLayoutOfVoicePlayVC() {
        
        view.backgroundColor = .white
        
        recordedVoiceTitle.translatesAutoresizingMaskIntoConstraints = false
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
    
    // Model 만들어서 들어와야 함. 06/29 레이아웃만 확인중 ~ 업데이트 예정
    func fetchRecordedDataFromMainVC(dataUrl: URL) {
        
        setSoundManager() // soundManager 초기화
        
        let sampleData = ["Sample Title", 300] as [Any]
        
        if let recordedTitle = sampleData[0] as? String {
            recordedVoiceTitle.text = recordedTitle
        } else {
            recordedVoiceTitle.text = "Title"
        }
        
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
            soundManager.changePitchValue(value: 100)
        } else {
            soundManager.changePitchValue(value: -100)
        }
        
    }
}

// MARK: - Sound Control Button Delegate

extension VoicePlayingViewController: SoundButtonActionDelegate {
    
    func playButtonTouchUpinside(sender: UIButton) {
        if sender.isSelected {
            soundManager.pause()
        } else {
            soundManager.play()
        }
    }
    
    func backwardButtonTouchUpinside(sender: UIButton) {
        print("backwardButton Clicked")
        
        soundManager.seek(to: true)
    }
    
    func forwardTouchUpinside(sender: UIButton) {
        soundManager.seek(to: false)
    }
}


// MARK: - SoundeManager Delegate

extension VoicePlayingViewController: ReceiveSoundManagerStatus {
    func observeAudioPlayerDidFinishPlaying(_ player: AVAudioPlayerNode) {
        
        DispatchQueue.main.async {
            self.playControlView.playButton.isSelected = false // 멘토님께 질문 - 접근 방식이
            
            // 임시 초기화 다시 함수와 data형식에 맞춰서 프로퍼티 만들어야함 06.30 이후 업데이트 예정
            let filePath = Bundle.main.path(forResource: "sound", ofType: ".mp3")
            let fileUrl = URL(fileURLWithPath: filePath!)
            //self.soundManager.stopPlayer()
            //self.soundManager.initializedEngine(url: fileUrl)
        }
        
    }
}


