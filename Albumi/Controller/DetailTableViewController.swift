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

class DetailTableViewController: UITableViewController, CAAnimationDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var detailView: UIView!
    @IBOutlet var infoLabel: UILabel!{
        didSet{
//            預設info欄位大小並隱藏
            infoLabel.isHidden = true
            infoLabel.frame = CGRect(origin: CGPoint(x: UIScreen.main.bounds.width/4, y: 0), size: CGSize(width: UIScreen.main.bounds.width*3/4, height: (infoLabel.superview?.frame.height)!))
            infoLabel.numberOfLines = 0
        }
    }
    @IBOutlet var infoButton: UIButton! {
        didSet{
//            設定成可完整顯示"Hide Info"
            infoButton.titleLabel?.numberOfLines = 0
        }
    }
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
            infoButton.setTitle("Info", for: .normal)
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
            infoButton.setTitle("Hide\nInfo", for: .normal)
            infoFlag = true
        }
    }
    @IBAction func fullScreenView(){
//        全螢幕顯示圖片
        if let controller = storyboard?.instantiateViewController(withIdentifier: "FullScreenViewController") as? FullScreenViewController{
            controller.asset = assetList[assetIndex]
            controller.modalPresentationStyle = .fullScreen
            if remark != nil {
                controller.textData = remark
            }
            present(controller, animated: true, completion: nil)
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
        mainController?.collectionView.reloadData()
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func saveImage(){
        
    }
//    顯示圖片文字的TextView
    var textView: UITextView?
//    儲存從ＤＢ讀取到的資料，以便傳給其他controller
    var remark: PictureRemark?
//    讀取MainCollectionVC傳入的assets及index
    var assetList: [PHAsset] = []
    var assetIndex = 0
//        以infoFlag判斷infoLabel是否顯示
    var infoFlag = false
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
            textView = UITextView(frame: CGRect(x: positionX, y: positionY, width: imageView.bounds.width, height: imageView.bounds.height))
            textView!.text = remark.text
            textView!.font = UIFont.systemFont(ofSize: CGFloat(remark.size) * scale)
            textView!.textColor = PictureRemarkIO.shared.hexToUIColor(hexString: remark.colorString)
            textView!.backgroundColor = nil
            textView!.isEditable = false
            textView!.isUserInteractionEnabled = false
//            將textView加入view
            self.view.addSubview(textView!)
//            儲存ＤＢ讀到的資料
            self.remark = remark
        }else{
//            ＤＢ沒有資料，清空儲存資料的變數
            remark = nil
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        清空textView
        if self.textView != nil {
            self.textView!.removeFromSuperview()
            self.textView = nil
        }
        if imageView.image != nil {
            setRemark()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        設定各欄位的高度
        switch indexPath.row{
        case 0:
            return UIScreen.main.bounds.height * 0.70
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
