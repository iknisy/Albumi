//
//  DetailTableViewController.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/2/5.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit
import Photos
import CoreLocation
import GoogleMobileAds

class DetailTableViewController: UITableViewController, CAAnimationDelegate {
    // MARK: - IB
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var detailView: UIView!
    @IBOutlet var infoLabel: UILabel!{
        didSet{
//            預設info欄位大小並隱藏
            infoLabel.isHidden = true
            infoLabel.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.width/4, y: -20), size: CGSize(width: UIScreen.main.bounds.width*3/4, height: (infoLabel.superview?.frame.height)!))
            infoLabel.numberOfLines = 0
        }
    }
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var fullButton: UIButton!
    @IBOutlet var editButton: UIButton!
    @IBOutlet var siButton: UIButton!
    @IBOutlet var saveButton: UIButton!
    @IBAction func info(){
        if infoFlag {
//            若有顯示infolabel就轉成隱藏，並enable其他button
            infoLabel.isHidden = true
            fullButton.isEnabled = true
            editButton.isEnabled = true
            siButton.isEnabled = true
            saveButton.isEnabled = true
            infoButton.tintColor = self.view.tintColor
            infoFlag = false
        }else{
//            若infoLabel隱藏則讀取圖片資訊然後顯示，並disable其他button
            let assetWork = AssetWorks()
            var photoText = assetWork.assetInfo(assetList[assetIndex])
            assetWork.assetLocation(assetList[assetIndex], handler: {location in
                photoText += location
                self.infoLabel.text = photoText
            })
            infoLabel.text = photoText
            infoLabel.isHidden = false
            fullButton.isEnabled = false
            editButton.isEnabled = false
            siButton.isEnabled = false
            saveButton.isEnabled = false
            infoButton.tintColor = UIColor.darkGray
            infoFlag = true
        }
    }
    @IBAction func fullScreenView(){
//        全螢幕顯示圖片
        if let controller = storyboard?.instantiateViewController(withIdentifier: "FullScreenViewController") as? FullScreenViewController{
            controller.assetList = assetList
            controller.assetIndex = assetIndex
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: false, completion: nil)
        }
    }
    @IBAction func editText(){
//        編輯文字的view
        if let controller = storyboard?.instantiateViewController(withIdentifier: "EditTextViewController") as? EditTextViewController{
            controller.asset = assetList[assetIndex]
            controller.textData = remark
            show(controller, sender: nil)
        }
    }
    @IBAction func similaryImage(){
//        相似圖片分析，asset回傳給Main並清空assetlist
        let mainController = self.navigationController?.viewControllers[0] as? MainCollectionViewController
        mainController?.isAsset = assetList[assetIndex]
        mainController?.assetList.removeAll()
//        mainController?.assetThumbnail.removeAll()
        mainController?.collectionView.reloadData()
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func saveImage(){
//        結合圖片與文字敘述，另存新檔
        guard let image = imageView.image else {
            return
        }
//        新建一張畫布，大小與image一樣大
        UIGraphicsBeginImageContextWithOptions(image.size, false, 1)
//        將圖繪在畫布裡
        image.draw(in: CGRect(origin: CGPoint.zero, size: image.size))
//        將textView畫進畫布
        if let textView = textView, let remark = remark {
//            宣告跟原圖一樣大小的textView再繪圖
            let scale = CGFloat(remark.size) / textView.font!.pointSize
            let tempView = UITextView(frame: CGRect(x: image.size.width / 2 + CGFloat(remark.locationX), y: image.size.height / 2 + CGFloat(remark.locationY), width: imageView.contentClippingRect.width * scale, height: imageView.contentClippingRect.height * scale))
//            將此view文字設定成跟textView一樣
            tempView.text = remark.text
            tempView.font = textView.font?.withSize(CGFloat(remark.size))
            tempView.textColor = PictureRemarkIO.shared.hexToUIColor(hexString: remark.colorString)
            tempView.backgroundColor = nil
//            大概是一個版本issue，iOS13版與12版需使用不同func才能完整繪出整個textView
            if #available(iOS 13, *){
                guard let ctx = UIGraphicsGetCurrentContext() else {return}
//                ctx.saveGState()
                ctx.translateBy(x: tempView.frame.origin.x, y: tempView.frame.origin.y)
                tempView.layer.render(in: ctx)
//                ctx.restoreGState()
            }else{
                tempView.drawHierarchy(in: tempView.frame, afterScreenUpdates: true)
            }
        }
//        儲存畫布
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
//        關閉畫布
        UIGraphicsEndImageContext()
        if let image = newImage {
//            將圖存在設備裡
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
//            設定popover提示使用者
            if let controller = storyboard?.instantiateViewController(withIdentifier: "PopoverViewController") as? PopoverViewController {
                controller.modalPresentationStyle = .popover
                controller.popoverPresentationController?.delegate = self
                controller.popoverPresentationController?.sourceView = saveButton
                controller.popoverPresentationController?.sourceRect = CGRect(origin: .zero, size: saveButton.frame.size)
                controller.labelString = "  " + NSLocalizedString("Image saved", comment: "")
                present(controller, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - var declear
//    顯示圖片文字的TextView
    var textView: UITextView?
//    儲存從ＤＢ讀取到的資料，以便傳給其他controller
    var remark: PictureRemark?
//    讀取MainCollectionVC傳入的assets及index
    var assetList: [PHAsset] = []
    var assetIndex = 0
//    以flag判斷infoLabel是否顯示
    var infoFlag = false
//    以flag判斷是否需reload
    var reloadFlag = false
//    顯示第二張說明圖片的flag
    var helpActFlag = false
//    宣告廣告橫幅
    lazy var adBannerView: GADBannerView = {
        let adBannerView = GADBannerView(adSize: kGADAdSizeSmartBannerPortrait)
//        adBannerView.adUnitID = "ca-app-pub-3920585268111253/9671922101"
//        以下官方提供的測試用ID
        adBannerView.adUnitID = "ca-app-pub-3940256099942544/2934735716"
        adBannerView.delegate = self
        adBannerView.rootViewController = self
        return adBannerView
    }()
    
    // MARK: - view function
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
//        從asset讀取圖片
        let requestImage = AssetWorks()
        requestImage.assetToUIImage(assetList[assetIndex], targetSize: CGSize(width: assetList[assetIndex].pixelWidth, height: assetList[assetIndex].pixelHeight), contentMode: .aspectFit, handler: {(image) in
            self.imageView.image = image
//            設定textView
            self.setRemark()
        })
//        設定左右滑跳到前(下)一張的手勢
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(viewSwipe(gesture:)))
        swipeLeft.direction = .left
        detailView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(viewSwipe(gesture:)))
        swipeRight.direction = .right
        detailView.addGestureRecognizer(swipeRight)
//        加入說明button
        let helpButton = UIBarButtonItem(image: UIImage(named: "hexhelp"), style: .plain, target: self, action: #selector(helpAct))
        navigationItem.rightBarButtonItem = helpButton
        
//        設定GoogleMobileAds測試設備
        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = (["a8ffedffeb5de5cf11194edd45471902429e1ecd", "77326fb9e37ca20ddb6fd34175ee42416a7a1933"])
//        向google請求廣告內容
        adBannerView.load(GADRequest())
    }
    @objc func helpAct(){
//        popover說明
        if let controller = storyboard?.instantiateViewController(withIdentifier: "PopImageViewController") as? PopImageViewController {
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.delegate = self
            var image: UIImage?
            if helpActFlag {
                controller.popoverPresentationController?.sourceView = imageView
                controller.popoverPresentationController?.sourceRect = imageView.bounds
                image = UIImage(named: NSLocalizedString("Detail2", comment: ""))
                helpActFlag = false
            }else{
                controller.popoverPresentationController?.sourceView = editButton
                controller.popoverPresentationController?.sourceRect = editButton.bounds
                image = UIImage(named: NSLocalizedString("Detail1", comment: ""))
                helpActFlag = true
            }
            controller.image = image?.resizeByWidth(UIScreen.main.bounds.width * 2/3)
            present(controller, animated: true, completion: nil)
        }
    }
    @objc func viewSwipe(gesture: UISwipeGestureRecognizer){
//        滑動後恢復infoLabel的狀態
        infoFlag = true
        info()
//        設定左右滑的動畫並切換圖片
        let requestImage = AssetWorks()
        let animation = CATransition()
        animation.type = .push
        animation.duration = 0.5
        animation.delegate = self
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        switch gesture.direction {
        case .left:
            if assetIndex >= assetList.count-1 {
                assetIndex = 0
            }else{
                assetIndex += 1
            }
            animation.subtype = .fromRight
            self.detailView.layer.add(animation, forKey: "leftToRightTransition")
            requestImage.assetToUIImage(assetList[assetIndex], targetSize: CGSize(width: assetList[assetIndex].pixelWidth, height: assetList[assetIndex].pixelHeight), contentMode: .aspectFit, handler: {(image) in
                self.imageView.image = image
//                清空textView
                if self.textView != nil {
                    self.textView!.removeFromSuperview()
                    self.textView = nil
                }
//                設定textView
                self.setRemark()
            })
        case .right:
            if assetIndex <= 0 {
                assetIndex = assetList.count-1
            }else{
                assetIndex -= 1
            }
            animation.subtype = .fromLeft
            self.detailView.layer.add(animation, forKey: "leftToLeftTransition")
            requestImage.assetToUIImage(assetList[assetIndex], targetSize: CGSize(width: assetList[assetIndex].pixelWidth, height: assetList[assetIndex].pixelHeight), contentMode: .aspectFit, handler: {(image) in
                self.imageView.image = image
//                清空textView
                if self.textView != nil {
                    self.textView!.removeFromSuperview()
                    self.textView = nil
                }
//                設定textView
                self.setRemark()
            })
        default:
            break
        }
    }
    func setRemark(){
        if let remark = PictureRemarkIO.shared.queryData(with: assetList[assetIndex].localIdentifier) {
//            找出縮放比例
            let scale = (imageView.bounds.width / imageView.image!.size.width) < (imageView.bounds.height / imageView.image!.size.height) ? (imageView.bounds.width / imageView.image!.size.width) : (imageView.bounds.height / imageView.image!.size.height)
//            找出縮放後的textView原點
            let positionX = imageView.frame.midX + CGFloat(remark.locationX) * scale
            let positionY = imageView.frame.midY + CGFloat(remark.locationY) * scale
//            textView細項設定
            textView = UITextView(frame: CGRect(x: positionX, y: positionY, width: imageView.contentClippingRect.width, height: imageView.contentClippingRect.height))
            textView!.text = remark.text
            textView!.font = UIFont.systemFont(ofSize: CGFloat(remark.size) * scale)
            textView!.textColor = PictureRemarkIO.shared.hexToUIColor(hexString: remark.colorString)
            textView!.backgroundColor = nil
            textView!.isEditable = false
            textView!.isUserInteractionEnabled = false
//            將textView加入tableview
            self.tableView.cellForRow(at: IndexPath(row: 0, section: 0))?.addSubview(textView!)
//            儲存ＤＢ讀到的資料
            self.remark = remark
        }else{
//            ＤＢ沒有資料，清空儲存資料的變數
            remark = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if reloadFlag {
//            flag為true代表FullScreen mode有切換圖片
//            重新從asset讀取圖片
            let requestImage = AssetWorks()
            requestImage.assetToUIImage(assetList[assetIndex], targetSize: CGSize(width: assetList[assetIndex].pixelWidth, height: assetList[assetIndex].pixelHeight), contentMode: .aspectFit, handler: {(image) in
                self.imageView.image = image
                if self.textView != nil {
                    self.textView!.removeFromSuperview()
                    self.textView = nil
                }
                self.setRemark()
                self.tableView.reloadData()
            })
//            flag切回false
            reloadFlag = false
        }else{
//            flag為false代表沒切換圖片，僅需重讀textView
//            清空textView
            if self.textView != nil {
                self.textView!.removeFromSuperview()
                self.textView = nil
            }
            if imageView.image != nil {
                setRemark()
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        設定各欄位的高度
        switch indexPath.row{
        case 0:
            return UIScreen.main.bounds.height * 0.65
        case 1:
            return UIScreen.main.bounds.height * 0.15
        default:
            return UITableView.automaticDimension
        }
    }
    
    override func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
//        設定不能選到欄位
        return false
    }

    // MARK: - Table view data source

//    override func numberOfSections(in tableView: UITableView) -> Int {
//        // #warning Incomplete implementation, return the number of sections
//        return 0
//    }
//
//    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        // #warning Incomplete implementation, return the number of rows
//        return 0
//    }

    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        // Get the new view controller using segue.destination.
//        // Pass the selected object to the new view controller.
//        if segue.identifier == "showFullScreen"{
//            let destinationViewController = segue.destination as! FullScreenViewController
//            destinationViewController.asset = allAssets[assetIndex]
//        }
//    }
    

}
    // MARK: - Delegate
extension DetailTableViewController: GADBannerViewDelegate {
//    橫幅廣告的delegate
    func adViewDidReceiveAd(_ bannerView: GADBannerView) {
//        成功讀取廣告時呼叫此func，加入view
        adBannerView.frame.origin = CGPoint(x: UIScreen.main.bounds.width - adBannerView.frame.size.width, y: UIScreen.main.bounds.height - adBannerView.frame.size.height - (navigationController?.navigationBar.frame.maxY ?? 0))
        self.view.addSubview(adBannerView)
    }
    
    func adView(_ bannerView: GADBannerView, didFailToReceiveAdWithError error: GADRequestError) {
//        讀取廣告失敗時呼叫此func
        dPrint("Receive ads error:")
        dPrint(error)
    }
}

extension DetailTableViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return .none
    }
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
//        popover的View消失後執行此func(after iOS13
        if helpActFlag {
//            以flag確認是否顯示第二張說明
            helpAct()
        }
    }
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
//        popover的View消失後執行此func(before iOS13
        if helpActFlag {
//            以flag確認是否顯示第二張說明
            helpAct()
        }
    }
}

extension UIImageView {
//    回傳View裡面的圖片的實際frame
    var contentClippingRect: CGRect {
        guard let image = image else { return bounds }
        guard contentMode == .scaleAspectFit else { return bounds }
        guard image.size.width > 0 && image.size.height > 0 else { return bounds }

        let scale: CGFloat
        if image.size.width > image.size.height {
            scale = bounds.width / image.size.width
        } else {
            scale = bounds.height / image.size.height
        }

        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let x = (bounds.width - size.width) / 2.0 + frame.origin.x
        let y = (bounds.height - size.height) / 2.0 + frame.origin.y

        return CGRect(x: x, y: y, width: size.width, height: size.height)
    }
}

extension UIImage {
    func resizeByWidth(_ width: CGFloat) -> UIImage {
//        以寬度為基準調整圖片大小
//        若寬度大於圖片本身就不調整
        if width > self.size.width {return self}
        let size = CGSize(width: width, height: self.size.height * width / self.size.width)
        let renderer = UIGraphicsImageRenderer(size: size)
        let newImage = renderer.image(actions: {(context) in
            self.draw(in: renderer.format.bounds)
        })
        return newImage
    }
}
