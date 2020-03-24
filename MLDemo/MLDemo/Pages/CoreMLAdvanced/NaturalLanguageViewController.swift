//
//  NaturalLanguageViewController.swift
//  MLDemo
//
//  Created by KuanWei on 2020/3/15.
//  Copyright © 2020 Cracktheterm. All rights reserved.
//

import UIKit
import CoreML
import Vision
import NaturalLanguage

class NaturalLanguageViewController: UIViewController, UITextViewDelegate {
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
        let items = ["言語判定", "トークン化", "タグ付け", "レンマ化", "固用表現"]
        let segmentedControl = UISegmentedControl(items: items)
        segmentedControl.selectedSegmentIndex = 0
        return segmentedControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()

        textView.text = "With Core ML, you can integrate trained machine learning models into your app."

        //自然言語処理の実行
        analyze()
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
        //自然言語処理の実行
        analyze()
    }

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            self.textView.resignFirstResponder()

            //自然言語処理の実行
            analyze()
            return false;
        }
        return true;
    }

    //自然言語処理の実行
    func analyze() {
        if self.textView.text == nil || self.textView.text!.isEmpty {return}
        if self.segmentedControl.selectedSegmentIndex == 0 {
            self.language(self.textView.text!)
        } else if self.segmentedControl.selectedSegmentIndex == 1 {
            self.tokenize(self.textView.text!)
        } else if self.segmentedControl.selectedSegmentIndex == 2 {
            self.tagging(self.textView.text!)
        } else if self.segmentedControl.selectedSegmentIndex == 3 {
            self.lemmaization(self.textView.text!)
        } else if self.segmentedControl.selectedSegmentIndex == 4 {
            self.namedEntry(self.textView.text!)
        }
    }

    //(2)言語判定
    func language(_ text: String) {
        //言語判定の実行
        let tagger = NLTagger(tagSchemes: [.language])
        tagger.string = text
        let language = tagger.dominantLanguage!.rawValue

        //対応しているタグスキームの取得
        let schemes = NLTagger.availableTagSchemes(
            for: .word, language: NLLanguage(rawValue: language))
        var schemesText = "Schemes :\n"
        for scheme in schemes {
            schemesText += "    \(scheme.rawValue)\n"
        }

        //UIの更新
        self.resultLabel.text = "Language : \(language)\n\n\(schemesText)"
    }

    //(3)トークン化
    func tokenize(_ text: String) {
        self.resultLabel.text = ""

        //トークン化の準備
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text

        //トークン化の実行
        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) {
            tokenRange, _ in
            self.resultLabel.text = self.resultLabel.text!+text[tokenRange]+"\n"
            return true
        }
    }

    //(4)品詞タグ付け
    func tagging(_ text: String) {
        self.resultLabel.text = ""

        //品詞タグ付けの準備
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        tagger.string = text

        //品詞タグ付けの実行
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word, scheme: .lexicalClass, options: options) {
                                tag, tokenRange in
                                self.resultLabel.text =
                                    self.resultLabel.text!+text[tokenRange]+" : "+tag!.rawValue+"\n"
                                return true
        }
    }

    //(5)レンマ化
    func lemmaization(_ text: String) {
        self.resultLabel.text = ""

        //レンマ化の準備
        let tagger = NLTagger(tagSchemes: [.lemma])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace]

        //レンマ化の実行
        tagger.enumerateTags(in: text.startIndex..<text.endIndex,
                             unit: .word, scheme: .lemma, options: options) {
                                tag, tokenRange in
                                if tag != nil {
                                    self.resultLabel.text =
                                        self.resultLabel.text!+text[tokenRange]+" : "+tag!.rawValue+"\n"
                                }
                                return true
        }
    }

    //(6)固有表現抽出
    func namedEntry(_ text: String) {
        self.resultLabel.text = ""

        //固有表現抽出の準備
        let tagger = NLTagger(tagSchemes: [.nameType])
        tagger.string = text
        let options: NLTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]

        //固有表現抽出の実行
        tagger.enumerateTags(in: text.startIndex..<text.endIndex, unit: .word,
                             scheme: .nameType, options: options) {
                                tag, tokenRange in
                                let tags: [NLTag] = [.personalName, .placeName, .organizationName]
                                if let tag = tag, tags.contains(tag) {
                                    self.resultLabel.text =
                                        self.resultLabel.text!+text[tokenRange]+" : "+tag.rawValue+"\n"
                                }
                                return true
        }
    }
}
