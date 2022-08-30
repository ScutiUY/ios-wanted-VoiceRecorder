//
//  RecordViewController.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/04.
//

import UIKit
import AVFoundation

protocol PassMetaDataDelegate {
    func sendMetaData(audioMetaData: AudioMetaData)
}

class RecordViewController: UIViewController {
    
    var delegate: PassMetaDataDelegate!
    
    private let soundManager = SoundManager()
    private let audioFileManager = AudioFileManager()
    private let firebaseStorageManager = FirebaseStorageManager()
    private let playTime = PlayTime()
    
    private let date = DateUtil().currentDate
    private lazy var urlString = "\(self.date).caf"
    
    private var isStartRecording: Bool = false
    
    private var visualizer: AudioVisualizeView = {
        var visualizer = AudioVisualizeView(playType: .record)
        visualizer.translatesAutoresizingMaskIntoConstraints = false
        return visualizer
    }()
    
    private var centerLine: UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 1
        view.layer.borderColor = CGColor.init(red: 255, green: 255, blue: 255, alpha: 1)
            return view
    }()
    
    private lazy var playControlView: PlayControlView = {
        var view = PlayControlView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isPlayButtonActivate = false
        view.delegate = self
        return view
    }()
    
    private var frequencyControlView: FrequencyControlView = {
        var view = FrequencyControlView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var recordButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let largeRecordImage = UIImage(systemName: "circle.fill", withConfiguration: largeConfig)
        button.setImage(largeRecordImage, for: .normal)
        button.tintColor = .systemRed
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLayout()
        setAudio()
        soundManager.recordVisualizerDelegate = self
        soundManager.playBackVisualizerDelegate = self
        soundManager.delegate = self
        frequencyControlView.delegate = self
        
        recordButton.addTarget(self, action: #selector(controlRecord), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        requestMicrophoneAccess { [self] allowed in
            if !allowed {
                requestMicrophoneAccessDeniedHandler()
            }
        }
    }
    
    private func setLayout() {
        view.backgroundColor = .white
        
        view.addSubview(visualizer)
        view.addSubview(centerLine)
        view.addSubview(playControlView)
        view.addSubview(frequencyControlView)
        view.addSubview(recordButton)
        
        NSLayoutConstraint.activate([
            
            visualizer.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            visualizer.centerYAnchor.constraint(equalTo: view.centerYAnchor).constraintWithMultiplier(0.5),
            visualizer.widthAnchor.constraint(equalTo: view.widthAnchor),
            visualizer.heightAnchor.constraint(equalToConstant: 200),
            
            centerLine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerLine.centerYAnchor.constraint(equalTo: visualizer.centerYAnchor),
            centerLine.heightAnchor.constraint(equalTo: visualizer.heightAnchor, constant: 20),
            centerLine.widthAnchor.constraint(equalToConstant: 1),
            
            playControlView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playControlView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playControlView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            playControlView.heightAnchor.constraint(equalToConstant: 100),
            
            frequencyControlView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            frequencyControlView.topAnchor.constraint(equalTo: playControlView.bottomAnchor, constant: 40),
            frequencyControlView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            frequencyControlView.heightAnchor.constraint(equalToConstant: 80),
            
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -50),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80)
        ])
    }
    
    private func setAudio() {
        requestMicrophoneAccess { [self] allowed in
            guard allowed == true else {
                DispatchQueue.main.async {
                    self.dismiss(animated: true)
                }
                return
            }
            
            let localUrl = audioFileManager.getAudioFilePath(fileName: urlString)
            soundManager.initializeSoundManager(url: localUrl, type: .record)
        }
    }
    
    private func requestMicrophoneAccessDeniedHandler() {
        let alert = UIAlertController(title: "녹음 권한 거부", message: "녹음 권한을 설정해주세요.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default) { _ in
            DispatchQueue.main.async {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL,
                                              options: [:],
                                              completionHandler: nil)
                }
            }
        }
        let cancleAction = UIAlertAction(title: "취소", style: .cancel)
        alert.addAction(okAction)
        alert.addAction(cancleAction)
        self.present(alert, animated: true)
    }
    
    private func recordButtonToggle() {
        let largeConfig = UIImage.SymbolConfiguration(pointSize: 50, weight: .regular, scale: .large)
        let largeRecordImage = UIImage(systemName: "circle.fill", withConfiguration: largeConfig)
        let largePauseImage = UIImage(systemName: "square.circle", withConfiguration: largeConfig)
        
        let image = self.isStartRecording ? largePauseImage : largeRecordImage
        self.recordButton.setImage(image, for: .normal)
    }
    
    private func passData(localUrl : URL) {
        do {
            let data = try Data(contentsOf: localUrl)
            let audioFile = try soundManager.getAudioFile(filePath: localUrl)
            let totalTime = playTime.totalPlayTime(audioFile: audioFile)
            let duration = playTime.convertTimeToString(totalTime)
            let wavefrom = visualizer.getWaveformData()
            let audioMetaData = AudioMetaData(title: date, duration: duration, url: urlString, waveforms: wavefrom)
            
            firebaseStorageManager.uploadAudio(audioData: data, audioMetaData: audioMetaData)
            delegate.sendMetaData(audioMetaData: audioMetaData)
        
        } catch let error {
            audioDataConvertingErrorHandler(error: error)
        }
    }
    
    // 녹음 시작 & 정지 컨트롤
    @objc private func controlRecord() {
        isStartRecording.toggle()
        playControlView.isPlayButtonActivate = !isStartRecording
        visualizer.isTouchable = !isStartRecording
        recordButtonToggle()
        
        if isStartRecording {
            soundManager.startRecord()
        } else {
            soundManager.stopRecord()
            playControlView.isPlayButtonActivate = true
            visualizer.isTouchable = !isStartRecording
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

extension RecordViewController: RecordingVisualizerable {
    
    func processAudioBuffer(buffer: AVAudioPCMBuffer) {
        visualizer.processAudioData(buffer: buffer)
    }
}

extension RecordViewController: SoundButtonActionDelegate {
    
    func playButtonTouchUpinside(sender: UIButton) {
        guard soundManager.isEnginePrepared else { return }
        visualizer.moveToStartingPoint()
        soundManager.playNpause()
    }
    
    func backwardButtonTouchUpinside(sender: UIButton) {
        soundManager.skip(isForwards: false)
    }
    
    func forwardTouchUpinside(sender: UIButton) {
        soundManager.skip(isForwards: true)
    }
}

extension RecordViewController: PlaybackVisualizerable {
    
    func operatingwaveProgression(progress: Float, audioLength: Float) {
        DispatchQueue.main.async { [self] in
            visualizer.operateVisualizerMove(value: progress, audioLenth: audioLength, centerViewMargin: visualizer.frame.maxX)
        }
    }
}
    
extension RecordViewController : SliderEvnetDelegate {
    
    func sliderEventValueChanged(sender: UISlider) {
        soundManager.setFrequencyValue(value: sender.value)
    }
}

extension RecordViewController: SoundManagerStatusReceivable {
    
    func audioPlayerCurrentStatus(isPlaying: Bool) {
        soundManager.removeTap()
        DispatchQueue.main.async {
            self.playControlView.isSelected = isPlaying
            self.visualizer.moveToStartingPoint()
        }
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
    
    func audioDataConvertingErrorHandler(error: Error) {
        let alert = UIAlertController(title: "오디오 데이터 변환 실패", message: "오류코드: \(error.localizedDescription)", preferredStyle: .alert)
        let action = UIAlertAction(title: "확인", style: .default)
        alert.addAction(action)
        self.present(alert, animated: true)
    }
}
