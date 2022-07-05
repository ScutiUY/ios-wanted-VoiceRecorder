//
//  SampleViewController.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/02.
//
import UIKit
import AVFoundation
import AudioToolbox

class SampleViewController: UIViewController {
    
    var audioEngine : AVAudioEngine!
    var audioFile : AVAudioFile!
    var audioPlayer : AVAudioPlayerNode!
    var outref: ExtAudioFileRef?
    var audioFilePlayer: AVAudioPlayerNode!
    var mixer : AVAudioMixerNode!
    var filePath : String? = nil
    
    
    var isPlay = false
    var isRec = false
    
    lazy var playButton: UIButton = {
        var button = UIButton()
        button.setTitle("play", for: .normal)
        button.backgroundColor = .blue
        return button
    }()
    
    //Called On Play Button
    @objc func play(_ sender: Any) {
        if self.isPlay {
            self.playButton.setTitle("PLAY", for: .normal)
            self.recButton.isEnabled = true
            self.stopPlay()
        } else {
            if self.startPlay() {
                self.playButton.setTitle("STOP", for: .normal)
                self.recButton.isEnabled = false
            }
        }
    }
    
    lazy var recButton: UIButton = {
        var button = UIButton()
        button.setTitle("rec", for: .normal)
        button.backgroundColor = .blue
        return button
    }()
    
    //Called On Record Button
    @objc func rec(_ sender: Any) {
        if self.isRec {
            self.recButton.setTitle("RECORDING", for: .normal)
            self.playButton.isEnabled = true
            self.stopRecord()
        } else {
            self.recButton.setTitle("STOP", for: .normal)
            self.playButton.isEnabled = false
            self.startRecord()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .yellow
        
        // MARK: 2 - Setting Up
        
        self.audioEngine = AVAudioEngine()
        self.audioFilePlayer = AVAudioPlayerNode()
        self.mixer = AVAudioMixerNode()
        self.audioEngine.attach(audioFilePlayer)
        self.audioEngine.attach(mixer)
        
        setLayout()
        
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        recButton.addTarget(self, action: #selector(rec), for: .touchUpInside)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // MARK: 1 - Asks user for microphone permission
        
        if AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) != .authorized {
            AVCaptureDevice.requestAccess(for: AVMediaType.audio,
                                          completionHandler: { (granted: Bool) in
            })
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setLayout() {
        
        view.backgroundColor = .white
        
        playButton.translatesAutoresizingMaskIntoConstraints = false
        recButton.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(playButton)
        view.addSubview(recButton)
        
        NSLayoutConstraint.activate([
            playButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playButton.topAnchor.constraint(equalTo: view.topAnchor, constant: 70),
            playButton.widthAnchor.constraint(equalToConstant: 80),
            playButton.heightAnchor.constraint(equalToConstant: 50),
            
            recButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -70),
            recButton.widthAnchor.constraint(equalToConstant: 80),
            recButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    func startRecord() {
        
        self.filePath = nil
        
        self.isRec = true
        
        // MARK: 3 - Set up Audio Session
        try! AVAudioSession.sharedInstance().setCategory(.playAndRecord)
        try! AVAudioSession.sharedInstance().setActive(true)
        
        let format = audioEngine.inputNode.outputFormat(forBus: 0)
        
        self.audioEngine.connect(self.audioEngine.inputNode, to: self.mixer, format: format)
        self.audioEngine.connect(self.mixer, to: self.audioEngine.mainMixerNode, format: format)
        let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first! as String
        self.filePath =  dir.appending("/temp.wav")
        try! self.audioEngine.start()
    }
    
    func stopRecord() {
        self.isRec = false
        self.audioFilePlayer.stop()
        self.audioEngine.stop()
        self.mixer.removeTap(onBus: 0)
        ExtAudioFileDispose(self.outref!)
        try! AVAudioSession.sharedInstance().setActive(false)
        
        ParseAudioFile()
    }
    
    func startPlay() -> Bool {
        
        if self.filePath == nil {
            return false
        }
        
        self.isPlay = true
        
        try! AVAudioSession.sharedInstance().setCategory(.playback)
        try! AVAudioSession.sharedInstance().setActive(true)
        
        self.audioFile = try! AVAudioFile(forReading: URL(fileURLWithPath: self.filePath!))
        self.audioEngine.connect(self.audioFilePlayer, to: self.audioEngine.mainMixerNode, format: audioFile.processingFormat)
        self.audioFilePlayer.scheduleSegment(audioFile,
                                             startingFrame: AVAudioFramePosition(0),
                                             frameCount: AVAudioFrameCount(self.audioFile.length),
                                             at: nil,
                                             completionHandler: self.completion)
        try! self.audioEngine.start()
        self.audioFilePlayer.play()
        
        return true
    }
    
    //INCOMPLETE (WIP. UNUSED)
    func ParseAudioFile() {
        
        self.audioFile = try! AVAudioFile(forReading: URL(fileURLWithPath: self.filePath!))
        
        let totSamples = audioFile.length
        let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: audioFile.fileFormat.sampleRate, channels: 1, interleaved: false)!
        let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(totSamples))!
        try! audioFile.read(into: buffer)
        
        print(buffer.frameLength)
    }
    
    func stopPlay() {
        self.isPlay = false
        
        if self.audioFilePlayer != nil && self.audioFilePlayer.isPlaying {
            self.audioFilePlayer.stop()
        }
        
        self.audioEngine.stop()
        try! AVAudioSession.sharedInstance().setActive(false)
    }
    
    func completion() {

        if self.isRec {
            DispatchQueue.main.async {
                self.rec(UIButton())
            }
        } else if self.isPlay {
            DispatchQueue.main.async {
                self.play(UIButton())
            }
        }
    }
}
