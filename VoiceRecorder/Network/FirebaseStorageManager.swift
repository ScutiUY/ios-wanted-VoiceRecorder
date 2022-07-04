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
    
    
    init(_ url: String) {
        baseReference = Storage.storage().reference(forURL: url)
    }
    
    func downloadAll() {
        
        baseReference.listAll { (result, error) in
            
            if let error = error {
                print(error.localizedDescription)
            }
            
            if let result = result {
                for item in result.items {
                    // item.reference로 파일 다운
                    print("item storage", item.storage)
                    print("item bucket", item.bucket)
                    print("item fullPath", item.fullPath)
                    print("item desc", item.description)
                    print("item name", item.name)
                    print("item hash", item.hash)
                    print("item", item)
                }
            }
        }
        
    }
    
    func download(urlString: String, completion: @escaping (Data?) -> Void) { // 싱글톤 유무
        baseReference.downloadURL { url, error in
            
            let data = try! Data(contentsOf: url!)
            completion(data)
        }
        
    }
    
    
    func uploadAudioFile() {
        
         
        let localFile = URL(string: "path/to/image")!
        
        // Upload the file to the path "images/rivers.jpg"
        let uploadTask = baseReference.putFile(from: localFile, metadata: nil) { metadata, error in
            guard let metadata = metadata else {
                // Uh-oh, an error occurred!
                return
            }
            // Metadata contains file metadata such as size, content-type.
            let size = metadata.size
 
        }
    }
    
    func downLoadMetaData() {
        baseReference.getMetadata { metaData, error in
            print(metaData?.name)
        }
    }
}
