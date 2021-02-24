//
//  ViewController.swift
//  PGCollectionViewFittedEndLineLayout
//
//  Created by damon.p on 02/24/2021.
//  Copyright (c) 2021 damon.p. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    var items: [String] = [
        "hello", "world", "bitcoin", "my house", "where is my house?", "hello world",
        "new world", "counter-strike", "valorant", "do something", "fps", "iOS", "swift", "Objcetive-C",
        "javascript", "send", "bird", "amazon", "github",
        "hello", "world", "bitcoin", "my house", "where is my house?", "hello world",
        "new world", "counter-strike", "valorant", "do something", "fps", "iOS", "swift", "Objcetive-C",
        "javascript", "send", "bird", "amazon", "github",
        
    ]
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
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
    
}

class ColorCell: UICollectionViewCell {
    @IBOutlet weak var label: UILabel!
    override func prepareForReuse() {
        super.prepareForReuse()
        self.label.text = nil
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.layer.cornerRadius = 10
    }
}
