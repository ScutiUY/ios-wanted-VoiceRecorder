//
//  AudioFileManager.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/02.
//

import Foundation

class AudioFileManager {

    private let fileManager = FileManager.default

    let directoryPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent("Recorded_Voice")

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

    func createVoiceFile(fileName: String) -> URL {
        return directoryPath.appendingPathComponent(fileName)
    }

//    func createVoiceFile(withDownLoad data: AudioData) {

//    }

//    func getAudioFileDirection(fileName: String, completion: @escaping (AudioData?) -> Void) {
//        return directoryPath.appendingPathComponent(fileName)
//    }

    func getAudioFilePath(fileName: String) -> URL {
        return directoryPath.appendingPathComponent(fileName)
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
