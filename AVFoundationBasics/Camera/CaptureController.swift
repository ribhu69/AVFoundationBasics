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
    
    
    var currentCameraPosition: AVCaptureDevice.Position = .back
    weak var delegate: CaptureControllerDelegate?
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    var photoOutput: AVCapturePhotoOutput!
    var activityIndicator : UIActivityIndicatorView!
    var containerView = UIView()
    var cameraFlipImage = UIImageView(image: UIImage(named: "cameraSwitch"))
    
    /// This method sets up the captureSession, input and output layer, along with the preview layer which takes a captureSession as the parameter. Finally we add this as a layer to the view.
    func setupIO() {
        
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
            print("No camera available")
            return
        }
        
        /// setting up the input capturing device, and then if possible adding it to the captureSession
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
        
        /// setting up the output rendering component, and then if possible adding it to the captureSession

        photoOutput = AVCapturePhotoOutput()
        if captureSession.canAddOutput(photoOutput) {
            captureSession.addOutput(photoOutput)
        } else {
            print("Couldn't add photo output")
            return
        }
        
        /// Set up the preview layer that shows the preview. We load it with our session.
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    /// This method adds other elements to the UI Which we need.
    func setupOtherUIElements() {
        activityIndicator = UIActivityIndicatorView(style: .medium)
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.backgroundColor = .black.withAlphaComponent(0.4)
        view.addSubview(containerView)
        
        view.addSubview(activityIndicator)
        
        let captureButton = UIButton()
        captureButton.layer.cornerRadius = 35
        captureButton.backgroundColor = .lightGray
        captureButton.layer.borderWidth = 0.8
        captureButton.layer.borderColor = UIColor.white.cgColor
        captureButton.translatesAutoresizingMaskIntoConstraints = false
        captureButton.addTarget(self, action: #selector(didTapCaptureButton), for: .touchUpInside)
        containerView.addSubview(captureButton)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        

        
        cameraFlipImage.translatesAutoresizingMaskIntoConstraints = false
        cameraFlipImage.contentMode = .scaleAspectFit
        cameraFlipImage.isUserInteractionEnabled = true
        
        let tapgesture = UITapGestureRecognizer(target: self, action: #selector(flipCamera))
        cameraFlipImage.addGestureRecognizer(tapgesture)
        containerView.addSubview(cameraFlipImage)
    
        
        NSLayoutConstraint.activate([
            
            containerView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            activityIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            activityIndicator.widthAnchor.constraint(equalToConstant: 25),
            activityIndicator.heightAnchor.constraint(equalToConstant: 25),
            captureButton.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
            captureButton.bottomAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            captureButton.topAnchor.constraint(equalTo: containerView.topAnchor,constant: 16),
        
            captureButton.widthAnchor.constraint(equalToConstant: 70),
            captureButton.heightAnchor.constraint(equalToConstant: 70),
            
            cameraFlipImage.trailingAnchor.constraint(equalTo: containerView.safeAreaLayoutGuide.trailingAnchor, constant: -32),
            cameraFlipImage.widthAnchor.constraint(equalToConstant: 50),
            cameraFlipImage.centerYAnchor.constraint(equalTo: captureButton.centerYAnchor)
            
        ])
        
        activityIndicator.isHidden = true
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(named: "cancel")?.withRenderingMode(.alwaysTemplate).withTintColor(.lightGray),
            style: .plain,
            target: self,
            action: #selector(dismissView)
        )
        
        setupIO()
        setupOtherUIElements()
    }
    
    @objc func flipCamera(sender: UIImageView) {
        guard let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput else { return }
        captureSession.beginConfiguration()
        
        // Remove the current input
        captureSession.removeInput(currentInput)
        
        // Toggle the camera position
        currentCameraPosition = (currentCameraPosition == .back) ? .front : .back
        
        // Get the new camera
        let newCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCameraPosition)
        
        do {
            let newInput = try AVCaptureDeviceInput(device: newCamera!)
            
            // Add the new input
            if captureSession.canAddInput(newInput) {
                captureSession.addInput(newInput)
            }
        } catch {
            print("Error switching cameras: \(error)")
        }
        
        captureSession.commitConfiguration()
    }

    
    @objc func dismissView() {
        dismiss(animated: true)
    }
    @objc func didTapCaptureButton() {
        // Capture photo settings
        let settings = AVCapturePhotoSettings()
        settings.flashMode = .auto
        photoOutput.capturePhoto(with: settings, delegate: self)
        
        
        activityIndicator.startAnimating()
        activityIndicator.isHidden = false
    }
    
    // AVCapturePhotoCaptureDelegate method
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let imageData = photo.fileDataRepresentation() else { return }
        let image = UIImage(data: imageData)
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
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

