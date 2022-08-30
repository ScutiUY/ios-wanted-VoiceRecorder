//
//  FirebaseStorageManager.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/01.
//

import Foundation
import FirebaseStorage

enum NetworkError: String {
    case uploadFailed = "오디오 파일을 서버에 업로드 할 수 없습니다."
    case deleteFailed = "오디오 파일을 서버에서 삭제 할 수 없습니다."
    case allReferenceFailed = "Firebase Storage 레퍼런스 오류"
    case MetaDataFailed = "파일 메타데이터 가져오기 실패!"
}

protocol NetworkStatusReceivable: AnyObject {
    func firebaseStorageManager(error: Error, desc: NetworkError)
}

class FirebaseStorageManager {
    
    weak var delegate: NetworkStatusReceivable!
    
    private var baseReference: StorageReference!
    
    init() {
        baseReference = Storage.storage().reference()
    }
    
    func uploadAudio(audioData: Data, audioMetaData: AudioMetaData) {
        let title = audioMetaData.title
        let duration = audioMetaData.duration
        let filePath = audioMetaData.url
        let waveforms = audioMetaData.waveforms.map{String($0)}.joined(separator: " ")
        let metaData = StorageMetadata()
        
        let customData = [
            "title": title,
            "duration": duration,
            "url": filePath,
            "waveforms": waveforms
        ]
        
        metaData.customMetadata = customData
        metaData.contentType = "audio/x-caf"
        
        baseReference.child(filePath).putData(audioData, metadata: metaData) { [unowned self] metaData, error in
            if let error = error {
                delegate.firebaseStorageManager(error: error, desc: .uploadFailed)
                return
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
        baseReference.child(urlString).delete { [unowned self] error in
            if let error = error {
                delegate.firebaseStorageManager(error: error, desc: .deleteFailed)
                return
            }
        }
    }
    
    
    func downloadAllRef(completion: @escaping ([StorageReference]) -> Void) {
        baseReference.listAll { [unowned self] result, error in
            if let error = error {
                delegate.firebaseStorageManager(error: error, desc: .allReferenceFailed)
            }
            if let result = result {
                completion(result.items)
            }
        }
    }
    
    func downloadMetaData(filePath: [StorageReference], completion: @escaping ([AudioMetaData]) -> Void) {
        
        var audioMetaDataList = [AudioMetaData]()
        
        for ref in filePath {
            baseReference.child(ref.name).getMetadata { [unowned self] metaData, error in
                if let error = error {
                    delegate.firebaseStorageManager(error: error, desc: .MetaDataFailed)
                }
                
                let data = metaData?.customMetadata
                let title = data?["title"] ?? ""
                let duration = data?["duration"] ?? "00:00"
                let url = data?["url"] ?? title + ".caf"
                let waveforms = data?["waveforms"]?.components(separatedBy: " ").map{Float($0)!} ?? []
                
                audioMetaDataList.append(AudioMetaData(title: title, duration: duration, url: url, waveforms: waveforms))
                
                if audioMetaDataList.count == filePath.count {
                    completion(audioMetaDataList)
                }
            }
        }
    }
}
