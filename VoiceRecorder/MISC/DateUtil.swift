//
//  DateUtil.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/04.
//

import Foundation

class DateUtil {
    
    func formatDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy. MM. dd HH:mm:ss"
        formatter.locale = Locale(identifier: "ko_KR")

        return formatter.string(from: Date())
    }
    
}
