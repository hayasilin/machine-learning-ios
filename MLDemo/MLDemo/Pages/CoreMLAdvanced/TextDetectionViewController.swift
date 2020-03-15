//
//  TextDetectionViewController.swift
//  MLDemo
//
//  Created by KuanWei on 2020/3/15.
//  Copyright © 2020 Cracktheterm. All rights reserved.
//

import UIKit
import AVFoundation
import Vision

class TextDetectionViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    lazy var drawView: TextDetectionDrawView = {
        let view = TextDetectionDrawView()
        return view
    }()
    
    var previewLayer: AVCaptureVideoPreviewLayer!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        startCapture()
    }

    func configureViews() {
        drawView.frame = view.bounds
        drawView.backgroundColor = .clear
        drawView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(drawView)
    }

    func showAlert(_ text: String!) {
        let alert = UIAlertController(title: text, message: nil,
            preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK",
            style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

//====================
//カメラキャプチャ
//====================
    //カメラキャプチャの開始
    func startCapture() {
        //セッションの初期化
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSession.Preset.photo

        //入力の指定
        let captureDevice: AVCaptureDevice! = self.device(false)
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}
        guard captureSession.canAddInput(input) else {return}
        captureSession.addInput(input)

        //出力の指定
        let output: AVCaptureVideoDataOutput = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "VideoQueue"))
        guard captureSession.canAddOutput(output) else {return}
        captureSession.addOutput(output)
        let videoConnection = output.connection(with: AVMediaType.video)
        videoConnection!.videoOrientation = .portrait

        //プレビューの指定
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewLayer.frame = self.drawView.frame
        self.view.layer.insertSublayer(previewLayer, at: 0)

        //カメラキャプチャの開始
        captureSession.startRunning()
    }

    //デバイスの取得
    func device(_ frontCamera: Bool) -> AVCaptureDevice! {
        let position: AVCaptureDevice.Position = frontCamera ? .front : .back
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera],
            mediaType: AVMediaType.video,
            position: AVCaptureDevice.Position.unspecified)
        let devices = deviceDiscoverySession.devices
        for device in devices {
            if device.position == position {
                return device
            }
        }
        return nil
    }

    //カメラキャプチャの取得時に呼ばれる
    func captureOutput(_ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection) {
        predict(sampleBuffer)
    }


//====================
//テキスト検出
//====================
    //(1)予測
    func predict(_ sampleBuffer: CMSampleBuffer) {
        //リクエストの生成
        let request = VNDetectTextRectanglesRequest {
            request, error in
            //エラー処理
            if error != nil {
                self.showAlert(error!.localizedDescription)
                return
            }

            DispatchQueue.main.async {
                //検出結果の取得
                let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
                self.drawView.setImageSize(CGSize(
                    width: CGFloat(CVPixelBufferGetWidth(imageBuffer!)),
                    height: CGFloat(CVPixelBufferGetHeight(imageBuffer!))))
                self.drawView.texts = (request.results as! [VNTextObservation])

                //UIの更新
                self.drawView.setNeedsDisplay()
            }
        }

        //文字ごとの領域を検出するかどうか
        request.reportCharacterBoxes = true

        //CMSampleBufferをCVPixelBufferに変換
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!

        //ハンドラの生成と実行
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer)
        guard (try? handler.perform([request])) != nil else {return}
    }
}
