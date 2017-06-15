//
//  ViewController.swift
//  iOS-CoreML-Inceptionv3
//
//  Created by Sri Raghu Malireddi on 15/06/17.
//  Copyright © 2017 Sri Raghu Malireddi. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML

class ViewController: UIViewController {

    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var predictLabel: UILabel!
    
    // Session - Initialization
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil)
    private var permissionGranted = false
    
    // Model
    let model = Inceptionv3()
    let modelInputSize = CGSize(width: 299, height: 299)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set some features for PreviewView
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        previewView.session = session
        
        // Check for permissions
        checkPermission()
        
        // Configure Session in session queue
        sessionQueue.async { [unowned self] in
            self.configureSession()
        }
    }
    
    // Check for camera permissions
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    // Request permission if not given
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    // Start session
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        sessionQueue.async {
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    // Stop session
    override func viewWillDisappear(_ animated: Bool) {
        sessionQueue.async { [unowned self] in
            if self.permissionGranted {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
        super.viewWillDisappear(animated)
    }
    
    // Configure session properties
    private func configureSession() {
        guard permissionGranted else { return }
        
        session.beginConfiguration()
        session.sessionPreset = AVCaptureSessionPreset1280x720
        
        guard let captureDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) else { return }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard session.canAddInput(captureDeviceInput) else { return }
        session.addInput(captureDeviceInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        guard session.canAddOutput(videoOutput) else { return }
        session.addOutput(videoOutput)
        
        session.commitConfiguration()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput!, didOutputSampleBuffer sampleBuffer: CMSampleBuffer!, from connection: AVCaptureConnection!) {
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvImageBuffer: imageBuffer)
        guard let uiImage = UIImage(ciImage: ciImage).resize(modelInputSize),
            let cgImage = uiImage.cgImage,
            let pixelBuffer = ImageConverter.pixelBuffer(from: cgImage)?.takeRetainedValue(),
            let output = try? model.prediction(image: pixelBuffer) else {
                return
        }
        DispatchQueue.main.async {
            self.predictLabel.text = output.classLabel
        }
    }
}

extension UIImage {
    func resize(_ size: CGSize)-> UIImage? {
        UIGraphicsBeginImageContext(size)
        draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}



