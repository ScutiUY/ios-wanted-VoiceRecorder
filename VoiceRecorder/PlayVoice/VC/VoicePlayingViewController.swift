
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
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()
    
    private var visualizer: AudioVisualizeView = {
        var visualizer = AudioVisualizeView()
        return visualizer
    }()
    
    private var progressBar: UIProgressView = {
        var view = UIProgressView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private var pitchSegmentController: UISegmentedControl = {
        var segment = UISegmentedControl(items: ["일반 목소리", "아기 목소리", "할아버지 목소리"])
        segment.translatesAutoresizingMaskIntoConstraints = false
        segment.selectedSegmentIndex = 0
        return segment
    }()
    
    private var volumeSlider: UISlider = {
        var slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.setValue(0.5, animated: true)
        slider.minimumValueImage = UIImage(systemName: "speaker")
        slider.maximumValueImage = UIImage(systemName: "speaker.wave.3")
        return slider
    }()
    
    // Play, for/bacward button
    private lazy var playControlView: PlayControlView = {
        var view = PlayControlView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
//    
//    init() {
//        super.init(frame: CGRectZero, style: UITableViewStyle.Plain)
//        initialize()
//    }
//    required init(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        initialize()
//    }
//    
//    init(frame: CGRect) {
//        super.init(frame: frame, style: UITableViewStyle.Plain)
//        initialize()
//    }
//    
//    override init(frame: CGRect, style: UITableViewStyle) {
//        super.init(frame: frame, style: style)
//        initialize()
//    }
//    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureLayoutOfVoicePlayVC()
        addViewsActionsToVC()
    }
    override func viewWillDisappear(_ animated: Bool) {
        guard soundManager != nil || soundManager.isEnginePrepared else { return }
        soundManager.stop()
        soundManager.removeTap()
        playControlView.isSelected = false
    }
    
    private func configureLayoutOfVoicePlayVC() {
        
        view.backgroundColor = .white
        
        visualizer.translatesAutoresizingMaskIntoConstraints = false
        //view.addSubview(audioPlotView)
        
        view.addSubview(recordedVoiceTitle)
        view.addSubview(middleAnchorView)
        middleAnchorView.addSubview(visualizer)
        middleAnchorView.addSubview(progressBar)
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
            
            visualizer.centerYAnchor.constraint(equalTo: middleAnchorView.centerYAnchor).constraintWithMultiplier(0.5),
            visualizer.centerXAnchor.constraint(equalTo: middleAnchorView.centerXAnchor),
            visualizer.heightAnchor.constraint(equalToConstant: 100),
            visualizer.widthAnchor.constraint(equalTo:  middleAnchorView.widthAnchor, multiplier: 0.9),
            
            progressBar.centerYAnchor.constraint(equalTo: middleAnchorView.centerYAnchor).constraintWithMultiplier(1),
            progressBar.centerXAnchor.constraint(equalTo: middleAnchorView.centerXAnchor),
            progressBar.widthAnchor.constraint(equalTo:  middleAnchorView.widthAnchor, multiplier: 0.9),
            progressBar.heightAnchor.constraint(equalToConstant: 50),
            
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
    
    func setTitle(title: String) {
        recordedVoiceTitle.text = title
    }
    
    func fetchRecordedDataFromMainVC(dataUrl: URL) {
        setSoundManager()
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
        soundManager.skip(isForwards: false)
    }
    
    func forwardTouchUpinside(sender: UIButton) {
        soundManager.skip(isForwards: true)
    }
}


// MARK: - SoundeManager Delegate
extension VoicePlayingViewController: SoundManagerStatusReceivable {
    func audioPlayerCurrentStatus(isPlaying: Bool) {
        soundManager.removeTap()
        DispatchQueue.main.async {
            self.playControlView.isSelected = isPlaying
            
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
    
}

