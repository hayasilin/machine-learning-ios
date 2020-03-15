//
//  TextClassificationViewController.swift
//  MLDemo
//
//  Created by KuanWei on 2019/12/8.
//  Copyright © 2019 Cracktheterm. All rights reserved.
//

import UIKit
import CoreML
import Vision
import NaturalLanguage

class TextClassificationViewController: UIViewController {

    lazy var textView: UITextView = {
        let textView = UITextView(frame: .zero)
        textView.delegate = self
        return textView
    }()

    lazy var resultLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.textAlignment = .center
        return label
    }()

    lazy var segmentedControl: UISegmentedControl = {
        let items = ["スポーツ", "ITライフハック"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()

    let model = TextClassification()

    override func viewDidLoad() {
        super.viewDidLoad()

        configureViews()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }

    func configureViews() {
        view.backgroundColor = .white

        segmentedControl.addTarget(self, action: #selector(didChangeSegmentedControl), for: .valueChanged)
        view.addSubview(segmentedControl)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
        segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
        segmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
        segmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
        ])

        textView.layer.borderColor = UIColor.black.cgColor
        textView.layer.borderWidth = 1.0
        textView.layer.cornerRadius = 8.0
        textView.layer.masksToBounds = true
        textView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(textView)

        NSLayoutConstraint.activate([
            textView.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor, constant: 8),
            textView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8),
            textView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8),
            textView.heightAnchor.constraint(equalToConstant: 200),
        ])

        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        resultLabel.numberOfLines = 0
        resultLabel.backgroundColor = .gray
        resultLabel.textColor = .white
        view.addSubview(resultLabel)

        NSLayoutConstraint.activate([
            resultLabel.topAnchor.constraint(equalTo: textView.bottomAnchor, constant: 8),
            resultLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            resultLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            resultLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
        ])
    }

    @objc
    func didChangeSegmentedControl(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            textView.text = "大谷翔平は3月27日の楽天戦（札幌ドーム）で自身初の開幕投手を務め、5回2/3を被安打3、失点1、6奪三振に抑え勝利投手になった"
        case 1:
            textView.text = "オーイズミ・アミュージオは、農場シミュレーション『ファーミングシミュレーター 20』のNintendo Switch版を2020年5月28日（木）に発売すると発表した。"
        default:
            break
        }
    }


    func showAlert(_ text: String!) {
        let alert = UIAlertController(title: text, message: nil,
                                      preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "OK",
                                      style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }

    //====================
    //テキスト分類
    //====================
    //(2)予測
    func predict(_ text: String) {
        DispatchQueue.global(qos: .default).async {
            //テキストをBag-of-wordsに変換
            let bagOfWords: [String: Double] = self.bagOfWords(text)

            //予測
            let prediction = try? self.model.prediction(text: bagOfWords)

            //UIの更新
            DispatchQueue.main.async {
                if prediction != nil {
                    self.resultLabel.text =
                        (prediction!.label == 0) ? "\nITライフハック\n" : "\nスポーツ\n"
                }
            }
        }
    }

    //(3)テキストをBag-of-wordsに変換
    func bagOfWords(_ text: String) -> [String: Double] {
        //結果変数の準備
        var bagOfWords = [String: Double]()

        //トークン化の準備
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        //トークン化の実行
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) {
            tokenRange, _ in

            //トークン化した単語
            let word = String(text[tokenRange])
            if (word.count == 1) {
            } else if bagOfWords[word] != nil {
                bagOfWords[word]! += 1
            } else {
                bagOfWords[word] = 1
            }
            return true
        }
        return bagOfWords
    }

}

extension TextClassificationViewController: UITextViewDelegate {
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        if text == "\n" {
            self.textView.resignFirstResponder()

            //テキスト分類
            if self.textView.text != nil && !self.textView.text!.isEmpty {
                predict(textView.text!)
            }
            view.resignFirstResponder()
            return false;
        }
        view.resignFirstResponder()
        return true;
    }
}
