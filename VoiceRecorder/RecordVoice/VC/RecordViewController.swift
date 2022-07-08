//
//  RecordViewController.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/04.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController {
    
    private var soundManager = SoundManager()
    private var audioFileManager = AudioFileManager()
    private var firebaseStorageManager = FirebaseStorageManager()
    
    private let date = DateUtil().currentDate
    private lazy var urlString = "\(self.date).caf"
    
    private var isStartRecording: Bool = false
    
    private var recordButton: UIButton = {
        var button = UIButton()
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let largeRecordImage = UIImage(systemName: "circle.fill", withConfiguration: largeConfig)
        button.setImage(largeRecordImage, for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    private var visualizer: AudioVisualizeView = {
        var visualizer = AudioVisualizeView()
        visualizer.translatesAutoresizingMaskIntoConstraints = false
        return visualizer
    }()
    
    private lazy var playControlView: PlayControlView = {
        var view = PlayControlView()
        view.delegate = self
        view.playButton(isActivate: false)
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setLayout()
        setAudio()
        soundManager.visualDelegate = self
        soundManager.delegate = self
        recordButton.addTarget(self, action: #selector(control), for: .touchUpInside)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        NotificationCenter.default.post(name: .dismissVC, object: nil)
    }
    
    private func setLayout() {
        view.backgroundColor = .white
        
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        playControlView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(recordButton)
        view.addSubview(playControlView)
        view.addSubview(visualizer)
        
        NSLayoutConstraint.activate([
            
            visualizer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            visualizer.centerYAnchor.constraint(equalTo: view.centerYAnchor).constraintWithMultiplier(0.5),
            visualizer.heightAnchor.constraint(equalToConstant: 200),
            visualizer.widthAnchor.constraint(equalTo: view.widthAnchor),
            
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80),
            
            playControlView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playControlView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playControlView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            playControlView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    private func setAudio() {
        requestMicrophoneAccess { [self] allowed in
            if allowed {
                let localUrl = audioFileManager.getAudioFilePath(fileName: urlString)
                soundManager.initializeSoundManager(url: localUrl, type: .record)
            } else {
                // 녹음 권한 거부
                fatalError()
            }
        }
    }
    
    private func recordButtonToggle() {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let largeRecordImage = UIImage(systemName: "circle.fill", withConfiguration: largeConfig)
        let largePauseImage = UIImage(systemName: "square.circle", withConfiguration: largeConfig)
        
        let image = self.isStartRecording ? largePauseImage : largeRecordImage
        self.recordButton.setImage(image, for: .normal)
    }
    
    private func passData(localUrl : URL) {
        let data = try! Data(contentsOf: localUrl)
        let totalTime = soundManager.totalPlayTime(date: date)
        let duration = soundManager.convertTimeToString(totalTime)
        let audioMetaData = AudioMetaData(title: date, duration: duration, url: urlString)
        
        firebaseStorageManager.uploadAudio(audioData: data, audioMetaData: audioMetaData)
    }
    
    // 녹음 시작 & 정지 컨트롤
    @objc private func control() {
        isStartRecording = !isStartRecording
        playControlView.playButton(isActivate: !isStartRecording)
        recordButtonToggle()
        
        if isStartRecording { // 녹음 시작일 때
            soundManager.startRecord()
        } else { // 녹음 끝일 때
            soundManager.stopRecord()
            visualizer.moveToCenter()
            playControlView.playButton(isActivate: true)
            let localUrl = audioFileManager.getAudioFilePath(fileName: urlString)
            passData(localUrl: localUrl)
            soundManager.initializeSoundManager(url: localUrl, type: .playBack)
        }
    }
}

extension RecordViewController {
    
    // 마이크 접근 권한 요청
    private func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        do {
            let recordingSession: AVAudioSession = AVAudioSession.sharedInstance()
            switch recordingSession.recordPermission {
            case .undetermined: // 아직 녹음 권한 요청이 되지 않음, 사용자에게 권한 요청
                recordingSession.requestRecordPermission({ allowed in // bool 값
                    completion(allowed)
                })
            case .denied: // 사용자가 녹음 권한 거부, 사용자가 직접 설정 화면에서 권한 허용을 하게끔 유도
                print("[Failure] Record Permission is Denied.")
                completion(false)
            case .granted: // 사용자가 녹음 권한 허용
                print("[Success] Record Permission is Granted.")
                completion(true)
            @unknown default:
                fatalError("[ERROR] Record Permission is Unknown Default.")
            }
        }
    }
}

extension RecordViewController: SoundButtonActionDelegate {
    
    func playButtonTouchUpinside(sender: UIButton) {
        guard soundManager.isEnginePrepared else { return }
        self.soundManager.playNpause()
    }
    
    func backwardButtonTouchUpinside(sender: UIButton) {
        print("backwardButton Clicked")
        soundManager.skip(isForwards: false)
    }
    
    func forwardTouchUpinside(sender: UIButton) {
        print("forwardButton Clicked")
        soundManager.skip(isForwards: true)
    }
}

extension RecordViewController: Visualizerable {
    
    func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        visualizer.processAudioData(buffer: buffer)
    }
}

extension RecordViewController: SoundManagerStatusReceivable {
    func audioPlayerCurrentStatus(isPlaying: Bool) {
        soundManager.removeTap()
        self.playControlView.isSelected = false
    }
    
    func audioFileInitializeErrorHandler(error: Error) {
        let alert = UIAlertController(title: "파일 초기화 실패!", message: "오류코드: \(error.localizedDescription)", preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
    
    func audioEngineInitializeErrorHandler(error: Error) {
        let alert = UIAlertController(title: "엔진 초기화 실패!", message: "오류코드: \(error.localizedDescription)", preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
    
}
