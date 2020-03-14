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
import NVActivityIndicatorView

class MainCollectionViewController: UICollectionViewController {

    @IBOutlet weak var sequenceButton: UIButton!
    @IBAction func sequenceAction(){
        switch sequenceButton.titleLabel?.text {
        case "Clear":
//            排序Button若為Clear，清除所有分析結果，畫面恢復為顯示photo library
            self.assetList = []
            self.isAsset = nil
            sequenceButton.setTitle("排序", for: .normal)
            self.loadPhotos()
            self.collectionView.reloadData()
        default:
            break
        }
    }
//    用來儲存所有圖片
    var assetList: [PHAsset] = []
//    用來儲存指定要分析相似圖片的Asset
    var isAsset: PHAsset?
//    設定預設的Layout
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
//    宣告讀取中的顯示動畫
    let nvActiveView = NVActivityIndicatorView(frame: CGRect(x: (UIScreen.main.bounds.width/2-50), y: (UIScreen.main.bounds.height/2-50), width: 100, height: 100), type: .lineScalePulseOutRapid, color: UIColor.gray, padding: 20)
//    宣告進度說明的label
    let processLabel = UILabel(frame: CGRect(x: 0, y: (UIScreen.main.bounds.height/2-100), width: UIScreen.main.bounds.width, height: 30))
    
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
        loadPhotos()
    }
    func loadPhotos(){
//        將動畫加入view
        self.view.addSubview(nvActiveView)
        if let isAsset = isAsset {
//            若有指定asset，並且asset庫沒有物件則進行相似圖片分析工作
            if assetList.count != 0 {return}
//            讀取中，動畫開始運作
            nvActiveView.startAnimating()
//            註冊Notification讓分析Model回傳進度
            NotificationCenter.default.addObserver(self, selector: #selector(getProcess(noti:)), name: Notification.Name(rawValue: "MLprocess"), object: nil)
//            開始分析
            let SI = SimilarImages()
            SI.findSimilarImages(asset: isAsset){assets in
                self.assetList = assets
//                向NotificationCenter回傳進度100％
                NotificationCenter.default.post(name: Notification.Name("MLprocess"), object: nil, userInfo: ["persent": 100])
//                重讀畫面
                self.collectionView.reloadData()
//                設定排序Button
                self.sequenceButton.setTitle("Clear", for: .normal)
//                停止動畫並移除
                self.nvActiveView.stopAnimating()
                self.nvActiveView.removeFromSuperview()
//                移除Notification
                NotificationCenter.default.removeObserver(self, name: Notification.Name("MLprocess"), object: nil)
            }
        }else if assetList.count == 0{
//            讀取中，動畫開始運作
            nvActiveView.startAnimating()
//            讀取設備內的圖片資料，並以creationDate降冪排列，然後存入allAssets
            let phoptions = PHFetchOptions()
            phoptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(with: .image, options: phoptions)
            for i in 0..<assets.count {
                assetList.append(assets.object(at: i))
            }
//            停止動畫並移除
            self.nvActiveView.stopAnimating()
            self.nvActiveView.removeFromSuperview()
        }
    }
    @objc func getProcess(noti: Notification) {
//        接收到Notification傳來進度，顯示給user
        guard let persent = noti.userInfo?["persent"] as? Int else {return}
        switch persent {
        case 0:
//            進度為0％時，設定進度說明的label並加入
            processLabel.textAlignment = .center
            processLabel.font = UIFont.systemFont(ofSize: 15)
            processLabel.textColor = sequenceButton.titleLabel?.textColor
            processLabel.text = "Analyzing Photos... \(persent)%"
            self.view.addSubview(processLabel)
        case 100:
//            進度為100%時，移除進度說明的label
            processLabel.text = "Analyzing Photos... \(persent)%"
            processLabel.removeFromSuperview()
        default:
            processLabel.text = "Analyzing Photos... \(persent)%"
        }
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
        return assetList.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GridCell", for: indexPath) as! GridCollectionViewCell
        // Configure the cell
//        從allAssets中讀取圖片，在cell裡顯示
        let assetWork = AssetWorks()
        assetWork.assetToUIImage(assetList[indexPath.row], targetSize: CGSize(width: 90, height: 90), contentMode: .aspectFit){image in
            cell.gridImageView.image = image
        }
    
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showDetail" {
            let destinationViewController = segue.destination as! DetailTableViewController
            guard let indexPaths = collectionView.indexPathsForSelectedItems else{return}
            destinationViewController.assetIndex = indexPaths[0].row
            destinationViewController.assetList = assetList
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPhotos()
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
