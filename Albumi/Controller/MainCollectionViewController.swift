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

class MainCollectionViewController: UICollectionViewController, PHPhotoLibraryChangeObserver, UIPopoverPresentationControllerDelegate {

    @IBOutlet weak var sequenceButton: UIButton!
    @IBAction func sequenceAction(){
        switch sequenceButton.titleLabel?.text {
        case "Clear":
//            排序Button若為Clear，清除所有分析結果，畫面恢復為顯示photo library
            self.assetList = []
            self.isAsset = nil
            sequenceButton.setTitle(" ", for: .normal)
            self.loadPhotos()
            self.collectionView.reloadData()
        default:
            break
        }
    }
    @IBOutlet weak var deletePhotoButton: UIButton!
    @IBAction func deletePhotoAction(){
        if deleteFlag {
//            若是delete mode就切換成normal mode
            deletePhotoButton.tintColor = UIColor.black
            deleteFlag = false
//            使用popover提示使用者
            if let controller = storyboard?.instantiateViewController(withIdentifier: "PopoverViewController") as? PopoverViewController {
                controller.modalPresentationStyle = .popover
                controller.popoverPresentationController?.delegate = self
                controller.popoverPresentationController?.sourceView = deletePhotoButton
                controller.popoverPresentationController?.sourceRect = CGRect(origin: .zero, size: deletePhotoButton.frame.size)
                controller.labelString = "  Normal Mode"
                controller.labelColor = UIColor.black
                present(controller, animated: true, completion: nil)
            }
        }else{
//            若是normal mode就切換成delete mode
            deletePhotoButton.tintColor = UIColor.red
            deleteFlag = true
//            使用popover提示使用者
            if let controller = storyboard?.instantiateViewController(withIdentifier: "PopoverViewController") as? PopoverViewController {
                controller.modalPresentationStyle = .popover
                controller.popoverPresentationController?.delegate = self
                controller.popoverPresentationController?.sourceView = deletePhotoButton
                controller.popoverPresentationController?.sourceRect = CGRect(origin: .zero, size: deletePhotoButton.frame.size)
                controller.labelString = "  Delete Mode"
                controller.labelColor = UIColor.red
                present(controller, animated: true, completion: nil)
            }
        }
    }
    
//    用來儲存所有圖片
    var assetList: [PHAsset] = []
//    儲存從設備fetch圖片的結果
    var assetFetchResult: PHFetchResult<PHAsset> = PHFetchResult.init()
//    儲存設備上的圖片增減狀態
    var changes: [PHFetchResultChangeDetails<PHAsset>] = []
//    delete mode的flag
    var deleteFlag = false
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
//        註冊設備相簿的改變通知
        PHPhotoLibrary.shared().register(self)
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
//            若asset庫沒有物件，則讀取設備內的圖片
//            讀取中，動畫開始運作
            nvActiveView.startAnimating()
//            讀取設備內的圖片資料，並以creationDate降冪排列，然後存入allAssets
            let phoptions = PHFetchOptions()
            phoptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            assetFetchResult = PHAsset.fetchAssets(with: .image, options: phoptions)
            for i in 0..<assetFetchResult.count {
                assetList.append(assetFetchResult.object(at: i))
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
    
    func photoLibraryDidChange(_ changeInstance: PHChange) {
//        偵測到設備內的圖片有增減以後會call這個func
        if let change = changeInstance.changeDetails(for: assetFetchResult) {
//            先將圖片增減改變儲存後待處理
            changes.append(change)
        }
//        若是delete mode則直接處理圖片的增減
        if deleteFlag {
            assetChanged()
        }
    }
    
    func assetChanged(){
//        處理圖片的增減（動畫更新View
        guard changes.count > 0 else {return}
//        分別儲存新增或移除的圖片index
        var removed: IndexSet?
        var inserted: IndexSet?
        var changed: IndexSet?
//        是否需reload整個view的flag
        var reloadFlag = false
//        for迴圈處理每次改變
        for changes in self.changes {
//            紀錄改變後的fetch結果
            assetFetchResult = changes.fetchResultAfterChanges
//            更新asset庫的物件
            self.assetList.removeAll()
            for i in 0..<self.assetFetchResult.count {
                self.assetList.append(self.assetFetchResult.object(at: i))
            }
//            若增減的變動不大，會使用動畫更新view
            if changes.hasIncrementalChanges {
//                分開儲存圖片增減改變的index
                removed = changes.removedIndexes
                inserted = changes.insertedIndexes
                changed = changes.changedIndexes
//                刪除改變順序以後刪除的圖片
                if changed != nil, let removed = changes.removedIndexes {
                    changed!.subtract(removed)
                }
            }else{
//                若增減的變動過大，則設定flag直接reload整個view
                reloadFlag = true
            }
        }
//        根據以上紀錄的增減執行動作
        if reloadFlag {
//            若flag有設定，直接reload整個view
            self.collectionView.reloadData()
        }else{
//            call collectionView的增減更新動畫，此動作需在main queue執行
            DispatchQueue.main.async{
                self.collectionView.performBatchUpdates({
                    if let removed = removed, removed.count > 0 {
                        self.collectionView.deleteItems(at: removed.map({IndexPath(item: $0, section: 0)}) )
                    }
                    if let inserted = inserted, inserted.count > 0 {
                        self.collectionView.insertItems(at: inserted.map({IndexPath(item: $0, section: 0)}) )
                    }
                    if let changed = changed, changed.count > 0 {
                        self.collectionView.reloadItems(at: changed.map({IndexPath(item: $0, section: 0)}) )
                    }
//                    changes.enumerateMoves({(fromIndex, toIndex) in
//                        self.collectionView.moveItem(at: IndexPath(item: fromIndex, section: 0), to: IndexPath(item: toIndex, section: 0))
//                    })
                }, completion: nil)
            }
        }
//        動作完成，清除所有改變紀錄
        self.changes.removeAll()
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadPhotos()
        assetChanged()
    }

    // MARK: UICollectionViewDelegate
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if deleteFlag {
//            若是delete mode，則刪除圖片
//            刪除圖片的alert，message的地方增加空行放圖片
            let delActController = UIAlertController(title: "Delete Confirm", message: "Do you want to delelte this Photo?\n\n\n\n\n\n\n\n\n\n", preferredStyle: .alert)
//            將圖片預覽圖放入alert提示使用者
            let imageView = UIImageView(frame: CGRect(x: 60, y: 65, width: 150, height: 150))
            guard let cell = self.collectionView.cellForItem(at: indexPath) as? GridCollectionViewCell else {return}
            imageView.image = cell.gridImageView.image
            delActController.view.addSubview(imageView)
//            使用者確認刪除圖片的動作
            let okAct = UIAlertAction(title: "OK", style: .destructive, handler: {_ in
//                先從ＤＢ上刪除相關資料
                _ = PictureRemarkIO.shared.deleteData(where: self.assetList[indexPath.row].localIdentifier)
//                呼叫系統刪除圖片
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.deleteAssets(NSArray(object: self.assetList[indexPath.row]))
                }, completionHandler: {(result, error) in
                    if !result {
                        print(error)
                    }
                })
            })
            delActController.addAction(okAct)
            let cancelAct = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            delActController.addAction(cancelAct)
            self.present(delActController, animated: true, completion: nil)
        }else if let destinationViewController = storyboard?.instantiateViewController(withIdentifier:  "DetailTableViewController") as? DetailTableViewController{
//            若是normal mode，則跳出DetailView
            guard let indexPaths = collectionView.indexPathsForSelectedItems else{return}
            destinationViewController.assetIndex = indexPaths[0].row
            destinationViewController.assetList = assetList
            show(destinationViewController, sender: nil)
        }
    }

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
