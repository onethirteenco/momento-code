//
//  CameraModel.swift
//  Momento
//
//  Created by Nicholas Dapolito on 8/19/24.
//

import SwiftUI
import AVFoundation

class CameraModel: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var isTaken = false
    @Published var session = AVCaptureSession()
    @Published var alert = false
    @Published var output = AVCapturePhotoOutput()
    @Published var postProcessing: Bool = UserDefaults.standard.bool(forKey: "postProcessing")
    private var photoProcessor = PhotoProcessor()
    @Published var cameraState: CameraState = .setup
    private let hapticService = HapticService()
    
    enum FlashMode {
        case on, off, auto
    }
    
    @Published var flashMode: FlashMode = .auto
    
    override init() {
        super.init()
        self.checkPermissions()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.setUp()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { status in
                if status {
                    self.setUp()
                } else {
                    DispatchQueue.main.async {
                        self.alert = true
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.alert = true
            }
        default:
            break
        }
    }
    
    func setUp() {
        do {
            self.session.beginConfiguration()
            
            guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                cameraState = .error("Unable to access back camera!")
                return
            }
            
            let input = try AVCaptureDeviceInput(device: device)
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            output.isHighResolutionCaptureEnabled = true
            output.maxPhotoQualityPrioritization = .quality
            
            if self.session.canAddOutput(self.output) {
                self.session.addOutput(self.output)
            }
            
            self.session.commitConfiguration()
            configureCamera() // Add the new camera configuration
            self.session.startRunning()
            cameraState = .ready
        } catch {
            cameraState = .error(error.localizedDescription)
        }
    }
    
    func takePhoto() {
        guard cameraState == .ready else { return }
        cameraState = .capturing
        
        
        let settings = AVCapturePhotoSettings(format: [AVVideoCodecKey: AVVideoCodecType.hevc])
        settings.isHighResolutionPhotoEnabled = true
        settings.photoQualityPrioritization = .quality
        
        switch flashMode {
        case .on: settings.flashMode = .on
        case .off: settings.flashMode = .off
        case .auto: settings.flashMode = .auto
        }
        
        output.capturePhoto(with: settings, delegate: self)
    }
    
    func toggleFlashMode() {
        switch flashMode {
        case .on:
            flashMode = .off
        case .off:
            flashMode = .auto
        case .auto:
            flashMode = .on
        }
    }
    
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            cameraState = .error(error.localizedDescription)
            return
        }
        
        guard let imageData = photo.fileDataRepresentation() else {
            cameraState = .error("Failed to get image data")
            return
        }
        
        cameraState = .processing
        
        if postProcessing {
            if let processedData = PhotoProcessor.processImage(imageData) {
                savePhoto(processedData)
            } else {
                savePhoto(imageData)
            }
        } else {
            savePhoto(imageData)
        }
    }
    private func configureCamera() {
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        
        do {
            try device.lockForConfiguration()
            
            // Enable auto-focus
            if device.isFocusModeSupported(.continuousAutoFocus) {
                device.focusMode = .continuousAutoFocus
            }
            
            // Enable auto-exposure
            if device.isExposureModeSupported(.continuousAutoExposure) {
                device.exposureMode = .continuousAutoExposure
            }
            
            // Enable auto white balance
            if device.isWhiteBalanceModeSupported(.continuousAutoWhiteBalance) {
                device.whiteBalanceMode = .continuousAutoWhiteBalance
            }
            
            // Configure video stabilization if available
            for connection in self.output.connections {
                if connection.isVideoStabilizationSupported {
                    connection.preferredVideoStabilizationMode = .auto
                }
            }
            
            // Set highest quality prioritization
            if #available(iOS 15.0, *) {
                self.output.maxPhotoQualityPrioritization = .quality
            }
            
            device.unlockForConfiguration()
        } catch {
            print("Error configuring device: \(error.localizedDescription)")
        }
    }
    // Function to strip metadata from image data
    private func stripMetadata(from imageData: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let uti = CGImageSourceGetType(source),
              let mutableData = CFDataCreateMutable(nil, 0),
              let destination = CGImageDestinationCreateWithData(mutableData, uti, 1, nil) else {
            return nil
        }
        
        CGImageDestinationAddImageFromSource(destination, source, 0, nil)
        guard CGImageDestinationFinalize(destination) else { return nil }
        
        return mutableData as Data
    }
    
    // Function to save the stripped image data
    private func savePhoto(_ imageData: Data) {
        let fileManager = FileManager.default
        
        do {
            // Get documents directory
            guard let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
                print("Could not access documents directory")
                return
            }
            
            // Create and get MomentoPhotos directory
            let photoDirectoryURL = documentsURL.appendingPathComponent("MomentoPhotos", isDirectory: true)
            
            // Create directory if it doesn't exist
            if !fileManager.fileExists(atPath: photoDirectoryURL.path) {
                try fileManager.createDirectory(at: photoDirectoryURL, withIntermediateDirectories: true, attributes: nil)
            }
            
            // Generate unique filename with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            let filename = "Momento_\(timestamp)_\(UUID().uuidString).heic"
            
            let photoURL = photoDirectoryURL.appendingPathComponent(filename)
            
            // Save the photo
            try imageData.write(to: photoURL)
            print("Photo saved successfully to: \(photoURL.path)")
            
            // Trigger haptic feedback
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
            
        } catch {
            print("Error saving photo: \(error.localizedDescription)")
            DispatchQueue.main.async {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.error)
            }
        }
    }
}


struct CameraViewController: UIViewControllerRepresentable {
    @ObservedObject var camera: CameraModel
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        controller.view.backgroundColor = .black

        let previewLayer = AVCaptureVideoPreviewLayer(session: camera.session)
        previewLayer.frame = controller.view.bounds
        previewLayer.videoGravity = .resizeAspectFill

        controller.view.layer.addSublayer(previewLayer)
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
