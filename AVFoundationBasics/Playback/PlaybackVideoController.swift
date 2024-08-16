import UIKit
import AVFoundation

class PlaybackVideoController: UIViewController {
    
    private var videoURL: URL?
    private var video: Video?
    
    private var startTime : UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        return label
    }()
    
    private var endTime : UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title3)
        return label
    }()
    
    private var videoTitle: UILabel = {
        let label = UILabel()
        label.font = UIFont.preferredFont(forTextStyle: .title2)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private var isMetaInvoked = false
    
    private var metaContainer: UIView = {
        let view = UIView()
        view.layer.opacity = 0.6
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        return view
    }()
    
    private var seekBar: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private var toggleIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "play")?.withRenderingMode(.alwaysTemplate).withTintColor(.white), for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.tintColor = .systemGreen
        return activityIndicator
    }()
    
    private var player: AVPlayer?
    private var playerLayer: AVPlayerLayer?
    private var playerObserver: Any?
    private var hideMetaContainerWorkItem: DispatchWorkItem?

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        playerLayer?.frame = view.bounds
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        addGesture()
        setupPlayer()
        getAssetTime()
        scheduleHideMetaContainer()
    }
    
    func getAssetTime() {
        DispatchQueue.global().asyncAfter(deadline: .now()) { [weak self] in
            guard let self, let videoURL = videoURL else {return}
            let asset = AVAsset(url: videoURL)

                    let duration = asset.duration
                    let durationTime = CMTimeGetSeconds(duration)
            
            DispatchQueue.main.async { [weak self] in
                let totalSeconds = Int(durationTime)
                    let minutes = totalSeconds / 60
                    let seconds = totalSeconds % 60
                    
                self?.endTime.text = String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }
    
    func setupPlayer() {
        guard let videoURL else { return }
        player = AVPlayer(url: videoURL)
        
        
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.frame
        playerLayer?.videoGravity = .resizeAspect
        
       
        view.layer.addSublayer(self.playerLayer!)
        view.bringSubviewToFront(metaContainer)
    }
    
    func addGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleAction))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func toggleAction() {
        playPauseTapped()
    }
    
    func setupUI() {
        view.addSubview(metaContainer)
        metaContainer.addSubview(seekBar)
        metaContainer.addSubview(playPauseButton)
        metaContainer.addSubview(toggleIcon)
        metaContainer.addSubview(videoTitle)
//        metaContainer.addSubview(startTime)
//        metaContainer.addSubview(endTime)
        
        startTime.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        endTime.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)

        NSLayoutConstraint.activate([
            metaContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            metaContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            metaContainer.topAnchor.constraint(equalTo: view.topAnchor),
            metaContainer.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            videoTitle.leadingAnchor.constraint(equalTo: metaContainer.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            videoTitle.trailingAnchor.constraint(equalTo: metaContainer.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            videoTitle.topAnchor.constraint(equalTo: metaContainer.safeAreaLayoutGuide.topAnchor, constant: 8),
            
            
//            startTime.leadingAnchor.constraint(equalTo: metaContainer.safeAreaLayoutGuide.leadingAnchor, constant: 8),
//            startTime.heightAnchor.constraint(equalToConstant: 20),
//            endTime.trailingAnchor.constraint(equalTo: metaContainer.safeAreaLayoutGuide.trailingAnchor, constant: -8),
//            startTime.heightAnchor.constraint(equalToConstant: 20),
//            startTime.bottomAnchor.constraint(equalTo: metaContainer.bottomAnchor, constant: -8),
//            endTime.bottomAnchor.constraint(equalTo: metaContainer.bottomAnchor, constant: -8),
            
            seekBar.bottomAnchor.constraint(equalTo: metaContainer.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            seekBar.leadingAnchor.constraint(equalTo: metaContainer.leadingAnchor, constant: 16),
            seekBar.trailingAnchor.constraint(equalTo: metaContainer.trailingAnchor, constant: -16),
            
            playPauseButton.centerXAnchor.constraint(equalTo: metaContainer.centerXAnchor),
            playPauseButton.centerYAnchor.constraint(equalTo: metaContainer.centerYAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 48),
            
            
            toggleIcon.centerYAnchor.constraint(equalTo: metaContainer.centerYAnchor),
            toggleIcon.centerXAnchor.constraint(equalTo: metaContainer.centerXAnchor),
            toggleIcon.widthAnchor.constraint(equalToConstant: 50)
        ])
        
        playPauseButton.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        seekBar.addTarget(self, action: #selector(seekBarValueChanged(_:)), for: .valueChanged)
    }
    
    func configurePlayer(with video: Video) {
        guard let url = URL(string: video.sources.first ?? "") else {
            print("Invalid video URL")
            return
        }
        self.videoURL = url
        self.videoTitle.text = video.title
        self.video = video
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "playbackLikelyToKeepUp" {
            activityIndicator.stopAnimating()
        }
    }
    
    @objc func playPauseTapped() {
        guard !isMetaInvoked else { return }
        
        isMetaInvoked = true
        
        // Cancel any existing hide work item
        hideMetaContainerWorkItem?.cancel()
        
        // Show metaContainer
        
        if self.player?.rate == 0 {
            self.player?.play()
            self.playPauseButton.setImage(UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate).withTintColor(.white), for: .normal)
        } else {
            self.player?.pause()
            self.playPauseButton.setImage(UIImage(named: "play")?.withRenderingMode(.alwaysTemplate).withTintColor(.white), for: .normal)
        }
        UIView.animate(withDuration: 0.3) { [weak self] in
            self?.navigationController?.navigationBar.isHidden = false
            self?.metaContainer.layer.opacity = 0.6
        } completion: { [weak self] _ in
            guard let self = self else { return }
            self.isMetaInvoked = false
            self.scheduleHideMetaContainer()
        }
    }
    
    func scheduleHideMetaContainer() {
        hideMetaContainerWorkItem = DispatchWorkItem { [weak self] in
            UIView.animate(withDuration: 0.3) { [weak self] in
                self?.metaContainer.layer.opacity = 0
                self?.navigationController?.navigationBar.isHidden = true
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2, execute: hideMetaContainerWorkItem!)
    }

    @objc func seekBarValueChanged(_ sender: UISlider) {
        guard let duration = player?.currentItem?.duration.seconds else { return }
        let value = Double(sender.value) * duration
        let seekTime = CMTime(seconds: value, preferredTimescale: 600)
        player?.seek(to: seekTime)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerLayer?.layoutIfNeeded()
        playVideo()
    }
    
    func playVideo() {
        player?.play()
        playPauseButton.setImage(UIImage(named: "pause")?.withRenderingMode(.alwaysTemplate).withTintColor(.white), for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.navigationBar.isHidden = false
        player?.pause()
        playerObserver = nil
        hideMetaContainerWorkItem?.cancel() // Cancel any pending hide tasks
    }
}
