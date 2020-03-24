//
//  HorizonDetectionViewController.swift
//  MLDemo
//
//  Created by KuanWei on 2020/3/15.
//  Copyright © 2020 Cracktheterm. All rights reserved.
//

import UIKit
import CoreML
import Vision

class HorizonDetectionViewController: UIViewController, UINavigationControllerDelegate,
UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {

    lazy var imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var resultLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()

        if self.imageView.image == nil {
            showActionSheet()
        }
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        showActionSheet()
    }

    func configureViews() {
        let cameraBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(showActionSheet))
        navigationItem.rightBarButtonItem = cameraBarButtonItem

        imageView.frame = view.bounds
        imageView.backgroundColor = .groupTableViewBackground
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(imageView)

        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.numberOfLines = 0
        resultLabel.backgroundColor = .gray
        resultLabel.textColor = .white
        view.addSubview(resultLabel)

        NSLayoutConstraint.activate([
            resultLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            resultLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    @objc func showActionSheet() {
        let actionSheet = UIAlertController(title: nil, message: nil,
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "カメラ", style: .default) {
            action in
            self.openPicker(sourceType: .camera)
        })
        actionSheet.addAction(UIAlertAction(title: "フォトライブラリ", style: .default) {
            action in
            self.openPicker(sourceType: .photoLibrary)
        })
        actionSheet.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        self.present(actionSheet, animated: true, completion: nil)
    }

    func showAlert(_ text: String!) {
        let alert = UIAlertController(title: text, message: nil,
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    //イメージピッカーのオープン
    func openPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }

    //イメージピッカーのイメージ取得時に呼ばれる
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        //イメージの取得
        var image = info[UIImagePickerController.InfoKey.originalImage] as! UIImage

        //画像向きの補正
        let size = image.size
        UIGraphicsBeginImageContext(size)
        image.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()

        //イメージの指定
        self.imageView.image = image

        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)

        //予測
        predict(image)
    }

    //イメージピッカーのキャンセル時に呼ばれる
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        //クローズ
        picker.presentingViewController!.dismiss(animated:true, completion:nil)
    }

    func predict(_ image: UIImage) {
        DispatchQueue.global(qos: .default).async {
            //リクエストの生成
            let request = VNDetectHorizonRequest {
                request, error in
                //エラー処理
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }

                DispatchQueue.main.async {
                    //検出結果の取得
                    let horizons = request.results as! [VNHorizonObservation]

                    //UIの更新
                    if horizons.first == nil {
                        self.imageView.transform = CGAffineTransform(rotationAngle: 0)
                        self.resultLabel.text = "検出失敗"
                    } else {
                        let angle = horizons.first!.angle
                        self.imageView.transform = CGAffineTransform(rotationAngle: -angle)
                        self.resultLabel.text = String(format:"\nAngle : %.2f度\n",
                                                       -angle*180/CGFloat(Double.pi))
                    }
                }
            }

            //UIImageをCIImageに変換
            guard let ciImage = CIImage(image: image) else {return}

            //画像の向きの取得
            let orientation = CGImagePropertyOrientation(
                rawValue: UInt32(image.imageOrientation.rawValue))!

            //ハンドラの生成と実行
            let handler = VNImageRequestHandler(
                ciImage: ciImage, orientation: orientation)
            guard (try? handler.perform([request])) != nil else {return}
        }
    }
}
