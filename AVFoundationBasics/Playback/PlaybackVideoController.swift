import UIKit
import AVFoundation

class PlaybackVideoController: UIViewController {
    
    private var seekBar: UISlider = {
        let slider = UISlider()
        slider.translatesAutoresizingMaskIntoConstraints = false
        return slider
    }()
    
    private var toggleIcon : UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private var playPauseButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Play", for: .normal)
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

    override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            playerLayer?.frame = view.bounds
        }
  
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupUI()
        addGesture()
        
        
    }
    
    func addGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(toggleAction))
        view.addGestureRecognizer(tapGesture)
    }
    
    @objc func toggleAction() {
        playPauseTapped()
        showPlayPauseIcon()
    }
    
    private func showPlayPauseIcon() {
        
        if player?.rate == 0 {
            toggleIcon.image = UIImage(named: "play")
        }
        else {
            toggleIcon.image = UIImage(named: "pause")
        }
        
        toggleIcon.isHidden = false
        toggleIcon.layoutIfNeeded()
        UIView.animate(withDuration: TimeInterval(integerLiteral: 3000)) {
            self.toggleIcon.isHidden = true
        }

    }
    func setupUI() {
        // Setup player view
        view.addSubview(seekBar)
        view.addSubview(playPauseButton)
        view.addSubview(activityIndicator)
        view.addSubview(toggleIcon)

        
        NSLayoutConstraint.activate([
            // Player view constraints
        
            // Seek bar constraints
            seekBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -18),
            seekBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            seekBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            
            // Play/Pause button constraints
            playPauseButton.topAnchor.constraint(equalTo: seekBar.bottomAnchor, constant: 20),
            playPauseButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            
            // Activity indicator constraints
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            toggleIcon.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            toggleIcon.centerXAnchor.constraint(equalTo: view.centerXAnchor),
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

        player = AVPlayer(url: url)
        playerLayer = AVPlayerLayer(player: player)
        playerLayer?.frame = view.frame
        playerLayer?.videoGravity = .resizeAspect
        view.layer.addSublayer(self.playerLayer!)
        
        view.bringSubviewToFront(seekBar)
        view.bringSubviewToFront(toggleIcon)

    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "playbackLikelyToKeepUp" {
            activityIndicator.stopAnimating()
        }
    }
    
    @objc func playPauseTapped() {
        if player?.rate == 0 {
            player?.play()
            playPauseButton.setTitle("Pause", for: .normal)
        } else {
            player?.pause()
            playPauseButton.setTitle("Play", for: .normal)
        }
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
        playPauseButton.setTitle("Pause", for: .normal)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        player?.pause()
        playerObserver = nil
    }
}
