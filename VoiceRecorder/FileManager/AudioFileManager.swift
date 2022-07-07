//
//  AudioFileManager.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/02.
//

import Foundation

class AudioFileManager {
    
    private let fileManager = FileManager.default
    
    let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Recorded_Voice") // 메인 폴더
    
    init() {
        initalizeFileFolder()
    }
    
    private func initalizeFileFolder() {
        
        guard !fileManager.fileExists(atPath: directoryPath.path) else { return }
        createDic()
    }
    
    private func createDic() {
        do {
            try fileManager.createDirectory(at: directoryPath, withIntermediateDirectories: false)
        } catch let erorr {
            print(erorr.localizedDescription)
        }
    }
    
    func createVoiceFile(withDownLoad data: AudioData) {
        
    }
    
    func getAudioData(fileName: String, completion: @escaping (AudioData?) -> Void) {
        let data = AudioData(title: fileName, duration: "")
        completion(data)
    }
    
    func getAudioFilePath(fileName: String) -> URL {
        return directoryPath.appendingPathComponent(fileName) // fileName으로 파일경로 설정 ex) document/Recorded_Voice/2022_06_12_16:00:00
    }
    
    func readDirectory() {
        let path = directoryPath.path
        
        do {
            let items = try fileManager.contentsOfDirectory(atPath: path)
            
            for item in items {
                print(item)
            }
        } catch let e {
            print(e.localizedDescription)
        }
            
    }
    
}
