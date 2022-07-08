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
    private let audioFileManager = AudioFileManager()
    
    init() {
        baseReference = Storage.storage().reference()
    }
    
    func uploadAudio(audioData: Data, audioMetaData: AudioMetaData) {
        let title = audioMetaData.title
        let duration = audioMetaData.duration
        let filePath = audioMetaData.url
        
        let metaData = StorageMetadata()
        let customData = [
            "title": title,
            "duration": duration,
            "url": filePath
        ]
        metaData.customMetadata = customData
        metaData.contentType = "audio/x-caf"
        
        baseReference.child(filePath).putData(audioData, metadata: metaData) { metaData, error in
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                print("upload success")
            }
        }
    }
    
    func downloadAudio(_ urlString: String, to localUrl: URL, completion: @escaping (URL?) -> Void) {
        DispatchQueue.global().async {
            self.baseReference.child(urlString).write(toFile: localUrl) { url, error in
                completion(url)
            }
        }
    }
    
    func deleteAudio(urlString: String) {
        baseReference.child(urlString).delete { error in
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                print("delete success")
            }
        }
    }
    
    func downloadAllRef(completion: @escaping (Result<[StorageReference], Error>) -> Void) {
        baseReference.listAll { result, error in
            if let error = error {
                completion(.failure(error))
            }
            if let result = result {
                print(result.items.count)
                completion(.success(result.items))
            }
        }
    }
    
    func downloadMetaData(filePath: [StorageReference], completion: @escaping (Result<[AudioMetaData], Error>) -> Void) {
        
        var audioMetaDataList = [AudioMetaData]()
        
        for ref in filePath {
            baseReference.child(ref.name).getMetadata { metaData, error in
                if let error = error {
                    completion(.failure(error))
                }
                
                let data = metaData?.customMetadata
                let title = data?["title"] ?? ""
                let duration = data?["duration"] ?? "00:00"
                let url = data?["url"] ?? ""
                
                audioMetaDataList.append(AudioMetaData(title: title, duration: duration, url: url))
                
                if audioMetaDataList.count == filePath.count {
                    completion(.success(audioMetaDataList))
                }
            }
        }
    }
}
