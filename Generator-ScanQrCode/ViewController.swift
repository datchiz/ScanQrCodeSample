//
//  ViewController.swift
//  Generator-ScanQrCode
//
//  Created by Bùi Minh Tiến on 12/28/17.
//  Copyright © 2017 TienBM. All rights reserved.
//

import UIKit
import AVFoundation
import AudioToolbox

class ViewController: UIViewController {

    @IBOutlet weak var imageFocus: UIImageView!
    @IBOutlet weak var cameraView: UIView!
    
    var captureSession: AVCaptureSession?
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVideoPreviewLayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // NotificationCenter
        NotificationCenter.default.addObserver(self, selector:#selector(self.didChangeCaptureInputPortFormatDescription(notification:)), name: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange, object: nil)
        self.startScanQRcode()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // remove notificationCenter
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureInputPortFormatDescriptionDidChange, object: nil)
    }
    
    func setupVideoPreviewLayer() {
        self.view.layoutIfNeeded()
        let captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice!)
            
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            let captureMetadataOutput = AVCaptureMetadataOutput()
            captureSession?.addOutput(captureMetadataOutput)
            
            captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
            
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession!)
            videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
            self.cameraView.layer.addSublayer(videoPreviewLayer!)
            
            // layer
            let layerRect = self.cameraView.layer.bounds
            self.videoPreviewLayer?.frame = layerRect
            self.videoPreviewLayer?.position = CGPoint(x: layerRect.midX, y: layerRect.midY)
            // Start video capture.
            if self.captureSession?.isRunning == false {
                self.captureSession?.startRunning()
            }
            view.bringSubview(toFront: self.imageFocus)
            
        } catch {
            return
        }
    }
    
    func startScanQRcode() {
        if self.captureSession?.isRunning == false {
            self.captureSession?.startRunning()
        }
    }
    
    func stopScanQRcode() {
        if self.captureSession?.isRunning == true {
            self.captureSession?.stopRunning()
            AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        }
    }
    
    @objc func didChangeCaptureInputPortFormatDescription(notification: NSNotification) {
        if let metadataOutput = self.captureSession?.outputs.last as? AVCaptureMetadataOutput,
            let rect = self.videoPreviewLayer?.metadataOutputRectConverted(fromLayerRect: self.imageFocus.frame) {
            metadataOutput.rectOfInterest = rect
        }
    }
    
    func showAlertWith(content: String) {
        let alertController = UIAlertController(title: "Content Qr Code", message: content, preferredStyle: .alert)
        let actionOk = UIAlertAction(title: "Ok", style: .default) { (alert) in
            self.startScanQRcode()
        }
        alertController.addAction(actionOk)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

extension ViewController: AVCaptureMetadataOutputObjectsDelegate {
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        
        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject
        
        if let value = metadataObj.stringValue, metadataObj.type == AVMetadataObject.ObjectType.qr {
            self.stopScanQRcode()
            self.showAlertWith(content: value)
        }
    }
    
}

