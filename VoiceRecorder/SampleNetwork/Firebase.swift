//
//  Firebase.swift
//  VoiceRecorder
//
//  Created by 백유정 on 2022/07/04.
//

import Foundation
import FirebaseStorage

class Firebase {
    
    let storage = Storage.storage()
    
    func upload(url: URL) {
        let filePath = "0705_09_18.caf"
        let data = try! Data(contentsOf: url)
        print(data, "녹음본")
        let metaData = StorageMetadata()
        metaData.contentType = "audio/x-caf"
        
        storage.reference().child(filePath).putData(data, metadata: metaData) { metaData, error in
            if let error = error {
                print(error.localizedDescription)
                return
            } else {
                print("성공")
            }
        }
    }
}
