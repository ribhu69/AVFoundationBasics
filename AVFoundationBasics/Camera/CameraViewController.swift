//
//  CameraViewController.swift
//  AVFoundationBasics
//
//  Created by Arkaprava Ghosh on 23/08/24.
//

import UIKit
import AVFoundation

class CameraViewController : UIViewController {
    
    
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    
    var discardImageButton : UIButton!
    private var capturedImage : UIImage?
    
    private var imageView : UIImageView!
    private var openCameraButton : UIButton!
    override func viewDidLoad() {
        view.backgroundColor = .systemBackground
        super.viewDidLoad()
        
        setupImageView()
        setupCaptureButton()
    }
    
    
    func setupImageView() {
        imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
        
        discardImageButton = UIButton()
        discardImageButton.setTitle("Discard", for: .normal)
        discardImageButton.backgroundColor = .systemRed
        discardImageButton.translatesAutoresizingMaskIntoConstraints = false
        discardImageButton.addTarget(self, action: #selector(discardImage), for: .touchUpInside)
        view.addSubview(discardImageButton)
        NSLayoutConstraint.activate([
            
            discardImageButton.bottomAnchor.constraint(equalTo: imageView.bottomAnchor, constant: -24),
            discardImageButton.widthAnchor.constraint(equalToConstant: 100),
            discardImageButton.heightAnchor.constraint(equalToConstant: 50),
            discardImageButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        
        discardImageButton.isHidden = true
        imageView.isHidden = true
    }
    func setupCaptureButton() {
        openCameraButton = UIButton()
        openCameraButton.setTitle("Open Camera", for: .normal)
        openCameraButton.translatesAutoresizingMaskIntoConstraints = false
        openCameraButton.addTarget(self, action: #selector(openCaptureMachine), for: .touchUpInside)
        openCameraButton.backgroundColor = .systemGreen
        view.addSubview(openCameraButton)
        openCameraButton.layer.cornerRadius = 20
        
        NSLayoutConstraint.activate([
            openCameraButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            openCameraButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            openCameraButton.widthAnchor.constraint(equalToConstant: view.frame.size.width / 2),
            openCameraButton.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
    
    @objc func openCaptureMachine(sender: UIButton) {
      
        let vc = CaptureController()
        vc.delegate = self
        let controller = UINavigationController(rootViewController: vc)
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true)
        
    }
    
    @objc func discardImage(sender: UIImage) {
        imageView.isHidden = true
        capturedImage = nil
        discardImageButton.isHidden = true
        openCameraButton.isHidden = false
        
    }
}

extension CameraViewController : CaptureControllerDelegate  {
    func capturedPhoto(image: UIImage?) {
        capturedImage = image
        discardImageButton.isHidden = false
        imageView.image = capturedImage
        imageView.isHidden = false
        openCameraButton.isHidden = true
    }
}
