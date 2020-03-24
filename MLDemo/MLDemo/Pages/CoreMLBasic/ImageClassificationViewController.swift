//
//  ImageClassificationViewController.swift
//  MLDemo
//
//  Created by KuanWei on 2019/12/8.
//  Copyright © 2019 Cracktheterm. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ImageClassificationViewController: UIViewController {
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

    var model = try! VNCoreMLModel(for: ImageClassification().model)

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

    func openPicker(sourceType: UIImagePickerController.SourceType) {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }

    func predict(_ image: UIImage) {
        DispatchQueue.global(qos: .default).async {
            let request = VNCoreMLRequest(model: self.model) {
                request, error in
                if error != nil {
                    self.showAlert(error!.localizedDescription)
                    return
                }

                //検出結果の取得
                let observations = request.results as! [VNClassificationObservation]
                var text: String = "\n"
                for i in 0..<min(3, observations.count) { //上位3件
                    let probabillity = Int(observations[i].confidence*100) //信頼度
                    let label = observations[i].identifier //ラベル
                    text += "\(label) : \(probabillity)%\n"
                }

                //UIの更新
                DispatchQueue.main.async {
                    self.resultLabel.text = text
                }
            }

            //入力画像のリサイズ指定
            request.imageCropAndScaleOption = .centerCrop

            //UIImageをCIImageに変換
            let ciImage = CIImage(image: image)!

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

extension ImageClassificationViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIGestureRecognizerDelegate {

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

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
        picker.presentingViewController!.dismiss(animated:true, completion:nil);

        //予測
        predict(image);
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.presentingViewController!.dismiss(animated:true, completion:nil)
    }
}
