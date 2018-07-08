//
//  ViewController.swift
//  ImageRecognition
//
//  Created by Sri Raghu Malireddi on 19/06/18.
//  Copyright © 2018 Sri Raghu Malireddi. All rights reserved.
//

import UIKit
import AVFoundation
import CoreML
import Vision

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var previewView: PreviewView!
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var confidenceLabel: UILabel!
    
    // Session - Initialization
    private let session = AVCaptureSession()
    private var isSessionRunning = false
    private let sessionQueue = DispatchQueue(label: "Camera Session Queue", attributes: [], target: nil)
    private var permissionGranted = false
    
    // ML - Initialization
    var model: VNCoreMLModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set some features for PreviewView
        self.previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewView.session = session
        
        // Check for permissions
        self.checkPermission()
        
        // Configure Session in session queue
        self.sessionQueue.async { [unowned self] in
            self.configureSession()
        }
        
        // Load MLModel
        self.loadModel()
    }
    
    // Check for camera permissions
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
        case .authorized:
            self.permissionGranted = true
        case .notDetermined:
            self.requestPermission()
        default:
            self.permissionGranted = false
        }
    }
    
    // Request permission if not given
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    // Configure session properties
    private func configureSession() {
        guard permissionGranted else { return }
        
        self.session.beginConfiguration()
        self.session.sessionPreset = .hd1280x720
        
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .back) else { return }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard self.session.canAddInput(captureDeviceInput) else { return }
        self.session.addInput(captureDeviceInput)
        
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer"))
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_32BGRA]
        videoOutput.alwaysDiscardsLateVideoFrames = true
        guard self.session.canAddOutput(videoOutput) else { return }
        self.session.addOutput(videoOutput)
        
        self.session.commitConfiguration()
        videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
    }
    
    private func loadModel() {
        model = try? VNCoreMLModel(for: Inceptionv3().model)
    }
    
    // Start session
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.sessionQueue.async {
            self.session.startRunning()
            self.isSessionRunning = self.session.isRunning
        }
    }
    
    // Stop session
    override func viewWillDisappear(_ animated: Bool) {
        self.sessionQueue.async { [unowned self] in
            if self.permissionGranted {
                self.session.stopRunning()
                self.isSessionRunning = self.session.isRunning
            }
        }
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // Do per-image-frame executions here!!!
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // TODO: Do ML Here
        guard let pixelBuffer : CVPixelBuffer = sampleBuffer.imageBuffer else { return }
        let request = VNCoreMLRequest(model: model!) {
            (finishedReq, err) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            
            DispatchQueue.main.async {
                self.classLabel.text = firstObservation.identifier
                self.confidenceLabel.text = NSString(format: "%.4f", firstObservation.confidence) as String
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }
    
}

