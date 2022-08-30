
import UIKit
import AVKit

class VoicePlayingViewController: UIViewController {
    
    private var soundManager: SoundManager!
    var audioData = AudioMetaData(title: "", duration: "", url: "", waveforms: [])
    
    private var loadingIndicator: UIActivityIndicatorView = {
        var indicator = UIActivityIndicatorView()
        indicator.style = .large
        return indicator
    }()
    
    private var blurEffect: UIBlurEffect = {
        var blurEffect = UIBlurEffect(style: .dark)
        return blurEffect
    }()
    
    private var visualEffectView: UIVisualEffectView = {
        var visualEffectView = UIVisualEffectView()
        return visualEffectView
    }()
    
    private var centerLine: UIView = {
        var view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.borderWidth = 1
        view.layer.borderColor = CGColor.init(red: 255, green: 255, blue: 255, alpha: 1)
            return view
    }()
    
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
    
    private lazy var visualizer: AudioVisualizeView = {
        var visualizer = AudioVisualizeView(playType: .playback)
        visualizer.translatesAutoresizingMaskIntoConstraints = false
        visualizer.isTouchable = true
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
    
    private lazy var playControlView: PlayControlView = {
        var view = PlayControlView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.delegate = self
        return view
    }()
    
    init(title: String) {
        super.init(nibName: nil, bundle: nil)
        
        recordedVoiceTitle.text = title
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureLayoutOfVoicePlayVC()
        addViewsActionsToVC()
        
        DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) { [self] in
            DispatchQueue.main.async { [self] in
                visualizer.setWaveformData(waveDataArray: audioData.waveforms)
                visualEffectView.removeFromSuperview()
                loadingIndicator.stopAnimating()
            }
        }
        loadingIndicator.startAnimating()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard soundManager != nil else { return }
        soundManager.stop()
        soundManager.removeTap()
        playControlView.isSelected = false
    }
    
    private func configureLayoutOfVoicePlayVC() {
        visualEffectView.effect = blurEffect
        visualEffectView.frame = view.frame
        loadingIndicator.center = view.center
        
        view.backgroundColor = .white
        
        view.addSubview(recordedVoiceTitle)
        view.addSubview(middleAnchorView)
        
        middleAnchorView.addSubview(visualizer)
        middleAnchorView.addSubview(centerLine)
        middleAnchorView.addSubview(progressBar)
        
        view.addSubview(pitchSegmentController)
        view.addSubview(volumeSlider)
        view.addSubview(playControlView)
        
        view.addSubview(visualEffectView)
        view.addSubview(loadingIndicator)
        
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
            
            centerLine.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            centerLine.centerYAnchor.constraint(equalTo: visualizer.centerYAnchor),
            centerLine.heightAnchor.constraint(equalTo: visualizer.heightAnchor, constant: 20),
            centerLine.widthAnchor.constraint(equalToConstant: 1),
            
            progressBar.centerYAnchor.constraint(equalTo: middleAnchorView.centerYAnchor).constraintWithMultiplier(1),
            progressBar.centerXAnchor.constraint(equalTo: middleAnchorView.centerXAnchor),
            progressBar.widthAnchor.constraint(equalTo:  middleAnchorView.widthAnchor, multiplier: 0.9),
            progressBar.heightAnchor.constraint(equalToConstant: 10),
            
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
    
    func fetchRecordedDataFromMainVC(audioData: AudioMetaData, fileUrl: URL) {
        setSoundManager()
        self.audioData = audioData
        soundManager.initializeSoundManager(url: fileUrl, type: .playBack)
    }
    
    private func setSoundManager() {
        soundManager = SoundManager()
        soundManager.delegate = self
        soundManager.playBackVisualizerDelegate = self
    }
    
    private func addViewsActionsToVC() {
        volumeSlider.addTarget(self, action: #selector(changeVolumeValue), for: .valueChanged)
        pitchSegmentController.addTarget(self, action: #selector(changePitchValue), for: .valueChanged)
    }
    
    @objc func changeVolumeValue() {
        soundManager.changeVolume(value: volumeSlider.value)
    }
    
    @objc func changePitchValue() {
        if pitchSegmentController.selectedSegmentIndex == 0 {
            soundManager.changePitchValue(value: .middle)
        } else if pitchSegmentController.selectedSegmentIndex == 1 {
            soundManager.changePitchValue(value: .high)
        } else {
            soundManager.changePitchValue(value: .row)
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
}

extension VoicePlayingViewController: PlaybackVisualizerable {
    
    func operatingwaveProgression(progress: Float, audioLength: Float) {
        DispatchQueue.main.async { [self] in
            if progress < 0 {
                progressBar.progress = 0
            } else {
                progressBar.progress = progress
            }
            
            visualizer.operateVisualizerMove(value: progress, audioLenth: audioLength, centerViewMargin: visualizer.frame.maxX)
        }
    }
}
