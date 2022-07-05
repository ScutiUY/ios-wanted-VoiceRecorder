//
//  RecordedVoiceTableViewCell.swift
//  VoiceRecorder
//
//  Created by 신의연 on 2022/07/02.
//

import UIKit

class RecordedVoiceTableViewCell: UITableViewCell {

    private lazy var labelStackView: UIStackView = {
        var stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing
        stackView.alignment = .center
        return stackView
    }()
    
    private lazy var audioTitle: UILabel = {
        var label = UILabel()
        label.text = "Sample Title"
        return label
    }()
    
    private lazy var audioPlaytime: UILabel = {
        var label = UILabel()
        label.text = "Sample Playtime"
        return label
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setTableViewCellLayout()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func setTableViewCellLayout() {
        
        labelStackView.translatesAutoresizingMaskIntoConstraints = false
        audioTitle.translatesAutoresizingMaskIntoConstraints = false
        audioPlaytime.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(labelStackView)
        labelStackView.addArrangedSubview(audioTitle)
        labelStackView.addArrangedSubview(audioPlaytime)
        
        NSLayoutConstraint.activate([
            
            labelStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor),
            labelStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor),
            labelStackView.widthAnchor.constraint(equalTo: self.widthAnchor, multiplier: 0.9),
            labelStackView.heightAnchor.constraint(equalTo: self.heightAnchor),
            
        ])
        
    }
    
    func fetchAudioLabelData(data: AudioData) {
        audioTitle.text = data.title
        audioPlaytime.text = data.playTime
    }
}
