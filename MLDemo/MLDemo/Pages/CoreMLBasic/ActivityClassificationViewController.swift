//
//  ActivityClassificationViewController.swift
//  MLDemo
//
//  Created by KuanWei on 2020/3/15.
//  Copyright © 2020 Cracktheterm. All rights reserved.
//

import UIKit
import CoreML
import Vision
import CoreMotion

class ActivityClassificationViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    static let predictionWindowSize = 50 // Prediction Windowのサイズ
    static let numOfFeatures = 6 //特徴数
    static let sensorsUpdateInterval = 1.0 / 50.0 //センサーのインターバル
    static let hiddenInLength = 200 //hiddenInの長さ
    static let cellInLength = 200 //cellInの長さ

    lazy var resultLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        return label
    }()

    //モーションマネージャ
    var motionManager: CMMotionManager!

    //(1)モデルの生成
    let model = ActivityClassification()

    //(2)Prediction Windowのデータとインデックス
    let predictionWindowData = try! MLMultiArray(
        shape: [1, predictionWindowSize, numOfFeatures] as [NSNumber],
        dataType: MLMultiArrayDataType.double)
    var predictionWindowIndex = 0

    //(3)hiddenOutとcellOutの保持変数
    var hiddenOut = try! MLMultiArray(
        shape:[hiddenInLength as NSNumber],
        dataType: MLMultiArrayDataType.double)
    var cellOut = try! MLMultiArray(
        shape:[cellInLength as NSNumber],
        dataType: MLMultiArrayDataType.double)

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()

        //(4)加速度センサーとジャイロスコープの有効化
        self.motionManager = CMMotionManager()
        guard let motionManager = self.motionManager,
            motionManager.isAccelerometerAvailable &&
                motionManager.isGyroAvailable else {return}
        motionManager.deviceMotionUpdateInterval = ActivityClassificationViewController.sensorsUpdateInterval
        motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler:{
            deviceManager, error in
            self.onUpdateSensorInfo(deviceManager!)
        })
    }

    func configureViews() {
        view.backgroundColor = .white
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.numberOfLines = 0
        resultLabel.backgroundColor = .gray
        resultLabel.textColor = .white
        view.addSubview(resultLabel)

        NSLayoutConstraint.activate([
            resultLabel.heightAnchor.constraint(equalToConstant: 100),
            resultLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            resultLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    //(5)センサー情報の更新時に呼ばれる
    func onUpdateSensorInfo(_ deviceManager: CMDeviceMotion!) {
        //センサー情報の取得
        let accel = deviceManager!.userAcceleration
        let gyro = deviceManager!.rotationRate

        ///センサー情報をデータ配列に追加
        predictionWindowData[[0, predictionWindowIndex, 0] as [NSNumber]] = accel.x as NSNumber
        predictionWindowData[[0, predictionWindowIndex, 1] as [NSNumber]] = accel.y as NSNumber
        predictionWindowData[[0, predictionWindowIndex, 2] as [NSNumber]] = accel.z as NSNumber
        predictionWindowData[[0, predictionWindowIndex, 3] as [NSNumber]] = gyro.x as NSNumber
        predictionWindowData[[0, predictionWindowIndex, 4] as [NSNumber]] = gyro.y as NSNumber
        predictionWindowData[[0, predictionWindowIndex, 5] as [NSNumber]] = gyro.z as NSNumber

        //Prediction Windowのインデックスに1加算
        predictionWindowIndex += 1

        //Prediction Windowのデータが埋まった時は予測を実行
        if predictionWindowIndex == ActivityClassificationViewController.predictionWindowSize {
            //予測
            predict()

            //Prediction Windowのインデックスに0指定
            predictionWindowIndex = 0
        }
    }

    //アラートの表示
    func showAlert(_ text: String!) {
        let alert = UIAlertController(title: text, message: nil,
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    //予測
    func predict() {
        //予測
        let results = try? self.model.prediction(
            features: self.predictionWindowData,
            hiddenIn: self.hiddenOut,
            cellIn: self.cellOut)
        let text = results!.activity
        print(text)

        //hiddenOutとcellOutの保持
        self.hiddenOut = results!.hiddenOut
        self.cellOut = results!.cellOut

        //UIの更新
        DispatchQueue.main.async {
            self.resultLabel.text = "\n\(text)\n"
        }
    }
}
