//
//  ViewController.swift
//  VoiceRecorder
//
import UIKit
import AVKit
import AVFoundation

class RecordedVoiceListViewController: UIViewController {
    
    var firestorageManager = FirebaseStorageManager()
    
    var audioList: [AudioData] = []
    
    var navigationBar: UINavigationBar = {
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
        
        initalizeFirebaseAudioFiles()
        setNavgationBarProperties()
        configureRecordedVoiceListLayout()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
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
    
    func initalizeFirebaseAudioFiles() {
        firestorageManager.downloadAll { result in
            switch result {
            case .success(let data) :
                self.audioList.append(data)
                self.recordedVoiceTableView.reloadData()
                print(data.duration, data.title, "here")
            case .failure(let error) :
                print(error.localizedDescription)
            }
        }
    }
    
    @objc func createNewVoiceRecordButtonAction() {
        let recorderVC = RecordViewController()
        self.present(recorderVC, animated: true)
    }
}

extension RecordedVoiceListViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return audioList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = recordedVoiceTableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! RecordedVoiceTableViewCell
        
        cell.setTableViewCellLayout() // cell 안으로 집어 넣기
        cell.fetchAudioLabelData(data: audioList[indexPath.row])
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let voicePlayVC = VoicePlayingViewController()
        let title = audioList[indexPath.item].title
        let url = AudioFileManager().directoryPath.appendingPathComponent(audioList[indexPath.item].title)
        firestorageManager.downloadAudioUrl(from: title, to: url) { url in
            voicePlayVC.fetchRecordedDataFromMainVC(dataUrl: url!)
        }
        
        self.present(voicePlayVC, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
}
// 삭제 할때 셀에서 삭제 파일에서 삭제 스토리지에서 삭제
