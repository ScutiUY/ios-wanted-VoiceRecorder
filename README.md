# 🎙️ Voice Recorder

## 👨‍👩‍👦‍👦 팀원 소개

| <center>**UY**</center>   | <center>**에리얼**</center> |
| -------------------------------------------------------- | --------------------------------------------------------- |
| [<img src="https://github.com/ScutiUY.png" width="200">](https://github.com/ScutiUY) |  [<img src="https://github.com/BAEKYUJEONG.png" width="200">](https://github.com/BAEKYUJEONG)| 

<br>

## 🖥 프로젝트 소개
### **녹음 메모를 기록하고, 확인하는 APP** 

- 첫 화면에서 녹음된 Voice List 확인
- 플러스 버튼을 이용해 녹음 기능 진입
- 녹음 진행 시 Frequency 조절하며 녹음 가능
- 녹음 후 재생 확인
- 5초 전후 재생 기능
- 재생 시 PitchControl 기능
- 재생 파형 확인
- FirebaseStorage Clound

<br>

## ⏱️ 개발 기간 및 사용 기술

- 개발 기간: 2022.07.27 ~ 2022.08.09 (2주)
- 사용 기술:  `UIKit`, `FirebaseStorage`, `AVAudioEngine`, `AVAudioUnitEQ`, `AVFAudio`, `Accelerate`,  `MVC`

<br>

## 🖼 디자인 패턴
### MVVM? MVC?

- MVC를 선택한 이유

1. 규모가 크지 않은 프로젝트에서 보여줄 뷰의 수가 많지 않음 ✅

2. 기능의 직관적인 분리

3. Model과 View가 다른 곳에 종속되지 않음 → 확장의 편리성

<br>

## 📌 핵심 기술

- AudioEngine을 이용한 녹음과 재생

- 소리 파형 내부에서의 스크롤

- 오디오와 Visualizer 연동

- Network 처리

<br>

## ⭐ 새로 배운 것

**AVAudioEngine을 사용한 Audio Data 처리**

**AVAudioUnitEQ를 이용한 Frequency 처리**

**Firebase Cloud Storage를 이용한 녹음 파일 저장소**

**Cloud와 Local의 Data upload & download & delete 분기 처리**

**재사용 가능한 Custom View 구현 및 사용**

<br>

## 📖 DataFlow
![VoiceRecoder](https://user-images.githubusercontent.com/36326157/186368491-9e0947c9-3e1c-4ecc-9a09-1b587b20a60c.png)



<br>

## ⚠️ 이슈

- Visualizer 구현시 scrollView 내부에서 Layer를 그릴시 scrollView contentSize를 늘려도 정방향으로 늘어남으로 인해 원하는 방향으로 스크롤 불가
    
    → CGAffineTransform() 메서드를 사용하여 뷰를 반전 시켜줌
    

```swift
// 스크롤을 담당하는 AudioVisualizeView 초기화 부분
init(playType: PlayType) {
        super.init(frame: .zero)
        // ...
        switch playType {
        case .playback:
            self.transform = CGAffineTransform(scaleX: 1, y: -1)
        case .record:
            self.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        // ...
    }

// 직접 레이어를 그리는 AudioPlotView
init(playType: PlayType) {
        // ...
        switch playType {
        case .playback:
            self.transform = CGAffineTransform(scaleX: 1, y: -1)
        case .record:
            self.transform = CGAffineTransform(scaleX: -1, y: 1)
        }
        // ...
    }

```

<br>

- 기존 방식: 서버에서 downloadAllRef()를 통해 모든 데이터에 대한 주소를 가져와 개별 데이터 통신 성공시마다 반환
    
    → 성공한 모든 데이터를 배열로 반환 하여 한번에 뷰에서 처리
    

```swift

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
```

<br>

- Visualizer를 포함한 VC에서 present 될 시 layer를 그리는 뷰 지정이 제대로 되지 않는 이슈
    
    → DispatchQueue를 통해서 view가 올라올때 0.01초를 기다렸다가 그려줌으로써 해결
    

```swift
DispatchQueue.global().asyncAfter(deadline: DispatchTime.now() + 1) { [self] in
		DispatchQueue.main.async { [self] in
		    visualizer.setWaveformData(waveDataArray: audioData.waveforms)
        visualEffectView.removeFromSuperview()
        loadingIndicator.stopAnimating()
    }
}
loadingIndicator.startAnimating()
```
<br>

## 💼 리팩토링

- 메인 VC를 접근하여 VoiceList 표시 시, 전체 파일의 metaData를 download하여 보여주는 방식
    
    → 첫 진입시만 다운 받고, 이후 녹음되는 파일은 delegate Pattern으로 metaData만 넘겨 VoiceList에 추가하여 보여주는 방식 
    

```swift
protocol PassMetaDataDelegate {
    func sendMetaData(audioMetaData: AudioMetaData)
}

class RecordViewController: UIViewController {
    
    var delegate: PassMetaDataDelegate!
        // ...
        

        private func passData(localUrl : URL) {
        let data = try! Data(contentsOf: localUrl)
        let totalTime = soundManager.totalPlayTime(date: date)
        let duration = soundManager.convertTimeToString(totalTime)
        let audioMetaData = AudioMetaData(title: date, duration: duration, url: urlString)
        
        firebaseStorageManager.uploadAudio(audioData: data, audioMetaData: audioMetaData)
        delegate.sendMetaData(audioMetaData: audioMetaData)
    }

        // ...
}
```

```swift
extension RecordedVoiceListViewController: PassMetaDataDelegate {
    
    func sendMetaData(audioMetaData: AudioMetaData) {
        audioMetaDataList.append(audioMetaData)
        sortAudioFiles()
        recordedVoiceTableView.reloadData()
    }
}
```

<br>

- 녹음이 끝나고 uploadAudio에 넘겨주는 파라미터를 단일값으로 각각 보내고 로직 수행
    1. 그러다보니 각각의 class에서 받은 많은 역할을 수행
    2. SOLID 원칙 중 단일 책임 원칙(SRP)에 위배
    
     → AudioMetaData Model을 만들어 값을 담아서 보냄
    

```swift
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
```

<br>

## 📱 UI

| 녹음 & 리스트 업데이트 | 재생 | 5초 전후 |
| ------ | ------ | ------ |
| ![Simulator Screen Recording - iPhone 11 Pro - 2022-07-09 at 23 54 00](https://user-images.githubusercontent.com/36326157/178111050-d7648abb-ef63-4ab3-949f-a671efd0e5c7.gif) | ![Simulator Screen Recording - iPhone 11 Pro - 2022-07-09 at 23 55 00](https://user-images.githubusercontent.com/36326157/178111047-21e9b0c4-70be-4c44-9ea8-cc8bf0fd7bdb.gif) |![Simulator Screen Recording - iPhone 11 Pro - 2022-07-09 at 23 52 48](https://user-images.githubusercontent.com/36326157/178111076-ac749808-eb35-4f34-9e95-6574fd86ba6e.gif) |
