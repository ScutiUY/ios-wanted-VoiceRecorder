//
//  RecordViewController.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/04.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController {
    
    var soundManager = SoundManager()
    var audioFileManager = AudioFileManager()
    var firebase = Firebase()
    var engine = AVAudioEngine()
    
    var isStartRecording: Bool = false
    var recordButton: UIButton = {
        var button = UIButton()
        button.setImage(UIImage(systemName: "circle.fill"), for: .normal)
        button.tintColor = .systemRed
        return button
    }()

    var playButton: UIButton = {
        var button = UIButton()
        button.setImage(UIImage(systemName: "play"), for: .normal)
        button.backgroundColor = .blue
        return button
    }()
    
    private lazy var recordURL: URL = {
        var documentsURL: URL = {
            let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
            return paths.first!
        }()

        let fileName = UUID().uuidString + ".caf"
        let url = documentsURL.appendingPathComponent(fileName)
        return url
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setLayout()
        setAudio()
        recordButton.addTarget(self, action: #selector(control), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
    }
    
    func setLayout() {
        recordButton.translatesAutoresizingMaskIntoConstraints = false
        playButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(recordButton)
        view.addSubview(playButton)
        
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -30),
            recordButton.widthAnchor.constraint(equalToConstant: 80),
            recordButton.heightAnchor.constraint(equalToConstant: 80),
            
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            playButton.widthAnchor.constraint(equalToConstant: 60),
            playButton.heightAnchor.constraint(equalToConstant: 60)
        ])
    }
    
    func recordButtonToggle() {
        DispatchQueue.main.async {
            let image = self.isStartRecording ? UIImage(systemName: "square.circle") : UIImage(systemName: "circle.fill")
            self.recordButton.setImage(image, for: .normal)
        }
    }

    func setAudio() {
        requestMicrophoneAccess { [weak self] allowed in
            if allowed {
                // 녹음 권한 허용
                let format = self?.engine.inputNode.outputFormat(forBus: 0)
                self?.soundManager.configureRecordEngine(format: format!)
            } else {
                // 녹음 권한 거부
                fatalError()
            }
        }
    }
    
    /// 녹음 시작 & 정지 컨트롤
    @objc private func control() {
        isStartRecording = !isStartRecording
        recordButtonToggle()
        
        let url = audioFileManager.createVoiceFile(fileName: "fileNAME")
        if isStartRecording { // 녹음 시작일 때
            soundManager.startRecord(filePath: url)
        } else { // 녹음 끝일 때
            soundManager.stopRecord()
            firebase.upload(url: url)
        }
    }
    
    @objc private func play() {
        soundManager.play()
    }
}

extension RecordViewController {
    
    /// 마이크 접근 권한 요청
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
