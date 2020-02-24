//
//  MainCollectionViewController.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/1/5.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit
import Photos
import IBPCollectionViewCompositionalLayout


class MainCollectionViewController: UICollectionViewController {

//    用來儲存所有圖片
    var allAssets : [PHAsset] = []
//    預設的Layout
    var initCollectionViewLayout: UICollectionViewLayout = {
//        item設定成：寬與高皆為group寬的0.22倍
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.22), heightDimension: .fractionalWidth(0.22))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
//        group設定成：寬為section寬的1倍，長為section寬的0.25倍，內部間隔最小10
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1), heightDimension: .fractionalWidth(0.25))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])
//        ipod與模擬器版面issue的workaround，需要其他設備確認真正的問題點
        if #available(iOS 13, *) {
            group.interItemSpacing = .flexible(10)
        }else{
            group.interItemSpacing = .fixed(10)
        }
//        group.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .fixed(1), top: nil, trailing: .fixed(1), bottom: nil)
//        section設定成：邊際大小節皆為10
        let section = NSCollectionLayoutSection(group: group)
        section.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        let layout = UICollectionViewCompositionalLayout(section: section)
        return layout
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
//        已在storyboard中register
        // Do any additional setup after loading the view.
//        設定成自定的Layout  （下兩行應該是一樣的作用）
        self.collectionView.collectionViewLayout = initCollectionViewLayout
//        self.collectionView.setCollectionViewLayout(initCollectionViewLayout, animated: false)
//        讀取設備內的圖片資料，並以creationDate降冪排列，然後存入allAssets
        let phoptions = PHFetchOptions()
        phoptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let assets = PHAsset.fetchAssets(with: .image, options: phoptions)
        assets.enumerateObjects({ (asset, _, _) in
            self.allAssets.append(asset)
        })
        
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // return the number of items
        return allAssets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCell", for: indexPath) as! GridCollectionViewCell
        // Configure the cell
//        從allAssets中讀取圖片，在cell裡顯示
        let imageManager = PHImageManager.default()
        imageManager.requestImage(for: allAssets[indexPath.row], targetSize:  CGSize(width: 90, height: 90), contentMode: .aspectFit, options: nil, resultHandler: {(image, info) in
            cell.gridImageView.image = image
        })
    
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let destinationViewController = segue.destination as! DetailTableViewController
            guard let indexPaths = collectionView.indexPathsForSelectedItems else{return}
            destinationViewController.assetIndex = indexPaths[0].row
            destinationViewController.allAssets = allAssets
        }
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
