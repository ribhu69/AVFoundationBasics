//
//  CaptureController.swift
//  AVFoundationBasics
//
//  Created by Arkaprava Ghosh on 23/08/24.
//

import UIKit
import AVFoundation

protocol CaptureControllerDelegate: AnyObject {
    func capturedPhoto(image: UIImage?)
}

class CaptureController: UIViewController, AVCapturePhotoCaptureDelegate {
    
    
    weak var delegate: CaptureControllerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoOutput: AVCapturePhotoOutput!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "cancel")?.withRenderingMode(.alwaysTemplate).withTintColor(.lightGray),
            style: .plain,
            target: self,
            action: #selector(dismissView)
        )
        // Initialize capture session
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        // Set up the camera as the input device
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No camera available")
            return
        }
        
        do {
            let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
            
            if captureSession.canAddInput(videoInput) {
                captureSession.addInput(videoInput)
            } else {
                print("Couldn't add video input")
                return
            }
        } catch {
            print("Error setting up video input: \(error)")
            return
        }
        
        // Set up the photo output
        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            print("Couldn't add photo output")
            return
        }
        
        // Set up the preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        
        // Add a capture button
        let captureButton = UIButton()
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = .lightGray
        captureButton.layer.borderWidth = 0.8
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(didTapCaptureButton), for: .touchUpInside)
        view.addSubview(captureButton)
        
        NSLayoutConstraint.activate([
            
            captureButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
        ])
        // Start the capture session
        captureSession.startRunning()
    }
    
    @objc func dismissView() {
        dismiss(animated: true)
    }
    @objc func didTapCaptureButton() {
        // Capture photo settings
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
    
    // AVCapturePhotoCaptureDelegate method
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = UIImage(data: imageData)
        delegate?.capturedPhoto(image: image)
        dismiss(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Adjust the preview layer frame to match the view bounds
        previewLayer.frame = view.bounds
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession.stopRunning()
    }
}

