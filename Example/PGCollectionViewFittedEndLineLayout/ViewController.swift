//
//  ViewController.swift
//  PGCollectionViewFittedEndLineLayout
//
//  Created by ipagong on 02/24/2021.
//  Copyright (c) 2021 ipagong. All rights reserved.
//

import UIKit
import PGCollectionViewFittedEndLineLayout

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, FittedEndLineLayoutDelegate {
    var items: [String] = [
        "hello", "world", "bitcoin", "my house", "where is my house?", "hello world",
        "new world", "counter-strike", "valorant", "do something", "fps", "iOS", "swift", "Objcetive-C",
        "javascript", "send", "bird", "amazon", "github",
    ]
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            if let layout = self.collectionView.collectionViewLayout as? FittedEndLineLayout {
                layout.delegate = self
            }
            
            self.collectionView.dataSource = self
            self.collectionView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { self.items.count }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as? ColorCell else { return UICollectionViewCell() }
        cell.label.text = self.items[indexPath.row]
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat { return 0.0 }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat { return 0.0 }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets { return .zero }
    
    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, numberOfRowInSection: Int) -> Int { 3 }

    func collectionView(_ collectionView: UICollectionView, layout: FittedEndLineLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let value = self.items[indexPath.row]
        let size = (value as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 17)])
        return CGSize.init(width: size.width + 20, height: size.height + 10)
    }
}

class ColorCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    override func prepareForReuse() {
        super.prepareForReuse()
        self.label.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.label.layer.cornerRadius = 10
        self.label.clipsToBounds = true
    }
}
