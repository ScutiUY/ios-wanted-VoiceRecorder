//
//  FireStorageService.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/02.
//

import Foundation
import FirebaseStorage

protocol NetworkMethodProtocol {
    
    var method: StorageTaskManagement { get }
}

enum FireStorageService {
    static let baseUrl = "gs://voicerecorder-d6222.appspot.com/"
    static let secondUrl = "gs://voicerecorder2-a2d03.appspot.com/"
}

extension FireStorageService {
    enum NetworkMethodType: NetworkMethodProtocol {
        
        case download(StorageTaskManagement)
        case upload(StorageTaskManagement)
    
        var method: StorageTaskManagement {
            switch self {
            case .download(let storage):
                return storage as! StorageDownloadTask
            case .upload(let storage):
                return storage as! StorageUploadTask
            }
        }
    }
}
