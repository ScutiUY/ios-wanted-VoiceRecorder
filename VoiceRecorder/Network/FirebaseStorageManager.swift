//
//  FirebaseStorageManager.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/01.
//

import Foundation
import FirebaseStorage
import UIKit

class FirebaseStorageManager {
    
    private var baseReference: StorageReference!
    private let dateUtil = DateUtil()
    private let soundManager = SoundManager()
    
    init() {
        baseReference = Storage.storage().reference()
    }
    
    func uploadAudio(url: URL) {
        let title = dateUtil.formatDate()
        let filePath = "\(title).caf"
        let data = try! Data(contentsOf: url)
        
        let metaData = StorageMetadata()
        let customData = [
            "title": title,
            "duration": String(Int(soundManager.totalPlayTime()))
        ]
        metaData.customMetadata = customData
        metaData.contentType = "audio/x-caf"
        
        baseReference.child(filePath).putData(data, metadata: metaData) { metaData, error in
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                print("성공")
            }
        }
    }
    
    func downloadAudio(from urlString: String, to localUrl: URL, completion: @escaping (URL?) -> Void) {
        baseReference.child(urlString).write(toFile: localUrl) { url, error in
            completion(url)
        }
    }
    
    func downloadAll(completion: @escaping (Result<AudioData, Error>) -> Void) {
        baseReference.listAll { result, error in
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let result = result {
                for item in result.items {
                    // item.reference로 파일 다운
                    self.downloadMetaData(filePath: item.name) { result in
                        switch result {
                        case .success(let audioData) :
                            completion(.success(audioData))
                        case .failure(let error) :
                            completion(.failure(error))
                        }
                    }
                }
            }
        }
    }
    
    func downloadMetaData(filePath: String, completion: @escaping (Result<AudioData, Error>) -> Void) {
        let ref = baseReference.child(filePath)
        var audioData = AudioData(title: "", duration: "")
        var title: String = ""
        var duration: String = ""
        
        ref.getMetadata { metaData, error in
            if let error = error {
                completion(.failure(error))
            }
            
            let data = metaData?.customMetadata
            title = data?["title"] ?? "no title"
            duration =  data?["duration"] ?? "00:00"
            
            audioData = AudioData(title: title, duration: duration)
            completion(.success(audioData))
        }
    }
    
}
