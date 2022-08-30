//
//  ViewController.swift
//  VoiceRecorder
//
import UIKit
import AVKit

class RecordedVoiceListViewController: UIViewController {
    
    private let firebaseStorageManager = FirebaseStorageManager()
    private let fileManager = AudioFileManager()
    private var audioMetaDataList: [AudioMetaData] = []
    
    lazy var navigationBar: UINavigationBar = {
        var navigationBar = UINavigationBar()
        return navigationBar
    }()
    
    lazy var recordedVoiceTableView: UITableView = {
        var tableView = UITableView()
        tableView.register(RecordedVoiceTableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        fileManager.delegate = self
        firebaseStorageManager.delegate = self
        
        initializeFirebaseAudioFiles()
        setNavgationBarProperties()
        configureRecordedVoiceListLayout()
    }
    
    private func initializeFirebaseAudioFiles() {
        firebaseStorageManager.downloadAllRef { [self] result in
            firebaseStorageManager.downloadMetaData(filePath: result) { [self] metaDataList in
                audioMetaDataList = metaDataList
                sortAudioFiles()
                recordedVoiceTableView.reloadData()
            }
        }
    }
    
    private func setNavgationBarProperties() {
        let navItem = UINavigationItem(title: "Voice Recorder")
        let doneItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(createNewVoiceRecordButtonAction))
        
        navItem.rightBarButtonItem = doneItem
        
        navigationBar.setItems([navItem], animated: false)
    }
    
    private func configureRecordedVoiceListLayout() {
        view.backgroundColor = .white
        
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        recordedVoiceTableView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(navigationBar)
        view.addSubview(recordedVoiceTableView)
        
        NSLayoutConstraint.activate([
            
            navigationBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            navigationBar.widthAnchor.constraint(equalTo: view.widthAnchor),
            navigationBar.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            navigationBar.heightAnchor.constraint(equalToConstant: 44),
            
            recordedVoiceTableView.topAnchor.constraint(equalTo: navigationBar.bottomAnchor),
            recordedVoiceTableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            recordedVoiceTableView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordedVoiceTableView.widthAnchor.constraint(equalTo: view.widthAnchor)
        ])
    }
    
    private func sortAudioFiles() {
        audioMetaDataList.sort { $0.title > $1.title }
    }
    
    @objc func createNewVoiceRecordButtonAction() {
        let recordVC = RecordViewController()
        recordVC.delegate = self
        self.present(recordVC, animated: true)
    }
}

extension RecordedVoiceListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioMetaDataList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recordedVoiceTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RecordedVoiceTableViewCell
        cell.fetchAudioLabelData(data: audioMetaDataList[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let voicePlayVC = VoicePlayingViewController(title: audioMetaDataList[indexPath.item].title)
        let audioMetaData = audioMetaDataList[indexPath.item]
        let path = audioMetaDataList[indexPath.item].url
        let filePath = fileManager.getAudioFilePath(fileName: path)
        
        if fileManager.isFileExist(atPath: path) {
            voicePlayVC.fetchRecordedDataFromMainVC(audioData: audioMetaData, fileUrl: filePath)
        } else {
            firebaseStorageManager.downloadAudio(path, to: filePath) { url in
                voicePlayVC.fetchRecordedDataFromMainVC(audioData: audioMetaData, fileUrl: filePath)
            }
        }
        self.present(voicePlayVC, animated: true)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        firebaseStorageManager.deleteAudio(urlString: audioMetaDataList[indexPath.row].url)
        fileManager.deleteLocalAudioFile(fileName: audioMetaDataList[indexPath.row].url)
        audioMetaDataList.remove(at: indexPath.row)
        recordedVoiceTableView.reloadData()
    }
}

extension RecordedVoiceListViewController: FileStatusReceivable, NetworkStatusReceivable {
    
    func firebaseStorageManager(error: Error, desc: NetworkError) {
        let alert = UIAlertController(title: desc.rawValue, message: error.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
    
    func fileManager(_ fileManager: FileManager, error: FileError, desc: Error?) {
        let alert = UIAlertController(title: error.rawValue, message: desc?.localizedDescription, preferredStyle: .alert)
        let okAction = UIAlertAction(title: "확인", style: .default)
        alert.addAction(okAction)
        present(alert, animated: true)
    }
}

extension RecordedVoiceListViewController: PassMetaDataDelegate {
    
    func sendMetaData(audioMetaData: AudioMetaData) {
        audioMetaDataList.append(audioMetaData)
        sortAudioFiles()
        recordedVoiceTableView.reloadData()
    }
}
