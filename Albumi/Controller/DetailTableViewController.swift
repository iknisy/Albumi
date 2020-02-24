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
//            設定成可完整顯示Hide Info
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
            infoFlag = !infoFlag
        }else{
//            若infoLabel隱藏則讀取圖片資訊然後顯示，並disable其他button
            var photoText = ""
//            print(allAssets[assetIndex])
            if allAssets[assetIndex].representsBurst {
                photoText += "This photos is in burst mode.\n"
            }
//            print(allAssets[assetIndex].burstSelectionTypes)
//            print(allAssets[assetIndex].burstIdentifier)
            if let createData = allAssets[assetIndex].creationDate {
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "YYYY / MM / dd, HH:mm:ss"
                photoText += "Create Date: \(dateFormat.string(from: createData))\n"
            }
            if let location = allAssets[assetIndex].location {
                let geocoder = CLGeocoder()
                geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: {(placemarks, error) in
                    if let error = error {
                        print(error)
                    }
                    if let placemarks = placemarks {
                        let city = placemarks[0].locality ?? "Unknown City"
                        let country = placemarks[0].country ?? "Unknown Country"
                        photoText += "Location: \(city), \(country)"
                        self.infoLabel.text = photoText
                    }
                })
            }
            if let modifyDate = allAssets[assetIndex].modificationDate {
                let dateFormat = DateFormatter()
                dateFormat.dateFormat = "YYYY / MM / dd, HH:mm:ss"
                photoText += "Modify Date: \(dateFormat.string(from: modifyDate))\n"
            }
            photoText += "Size: \(allAssets[assetIndex].pixelHeight) Ｘ \(allAssets[assetIndex].pixelWidth) \n"
            switch allAssets[assetIndex].sourceType {
            case .typeUserLibrary:
                photoText += "From: Local\n"
            case .typeCloudShared:
                photoText += "From: iCloud\n"
            case .typeiTunesSynced:
                photoText += "From: iTunes\n"
            default:
                break
            }
//            print(allAssets[assetIndex].mediaSubtypes)
//            print(allAssets[assetIndex].playbackStyle)
//            print(allAssets[assetIndex].duration)
            infoLabel.text = photoText
            infoLabel.isHidden = false
            fullButton.isEnabled = false
            editButton.isEnabled = false
            siButton.isEnabled = false
            saveButton.isEnabled = false
            infoButton.setTitle("Hide\nInfo", for: .normal)
            infoFlag = !infoFlag
        }
    }
    @IBAction func fullScreenView(){
//        點擊full則推送出FullScreenVC，顯示模式設定為fullScreen
        if let controller = storyboard?.instantiateViewController(withIdentifier: "FullScreenViewController") as? FullScreenViewController{
            controller.asset = allAssets[assetIndex]
            controller.modalPresentationStyle = .fullScreen
            controller.showMode = .fullScreen
            present(controller, animated: true, completion: nil)
        }
    }
    @IBAction func editText(){
//        點擊edit則推送出FullScreenVC，顯示模式設定為editText
        if let controller = storyboard?.instantiateViewController(withIdentifier: "FullScreenViewController") as? FullScreenViewController{
            controller.asset = allAssets[assetIndex]
//            controller.modalPresentationStyle = .pageSheet
            controller.showMode = .editText
//            若是iOS13以後則使用present新的modalPresentationStyle
//            若是iOS12以前則使用show
            if #available(iOS 13, *){
                present(controller, animated: true, completion: nil)
            }else{
                show(controller, sender: nil)
            }
        }
    }
    @IBAction func similaryImage(){
        
    }
    @IBAction func saveImage(){
        
    }
//    讀取MainCollectionVC傳入的assets及index
    var allAssets: [PHAsset] = []
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
        let imageManager = PHImageManager()
        imageManager.requestImage(for: allAssets[assetIndex], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil, resultHandler: {(image, info) in
            if let image = image {
                self.imageView.image = image
            }
        })
//        設定左右滑跳到前(下)一張
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(viewSwipe(gesture:)))
        swipeLeft.direction = .left
        detailView.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(viewSwipe(gesture:)))
        swipeRight.direction = .right
        detailView.addGestureRecognizer(swipeRight)
        detailView.isUserInteractionEnabled = true
    }
    @objc func viewSwipe(gesture: UISwipeGestureRecognizer){
//        滑動後恢復infoLabel的狀態
        infoFlag = true
        info()
//        設定左右滑的動畫並切換圖片
        switch gesture.direction {
        case .left:
            if assetIndex >= allAssets.count-1 {
                assetIndex = 0
            }else{
                assetIndex += 1
            }
            let animation = CATransition()
            animation.type = .push
            animation.subtype = .fromRight
            animation.duration = 0.5
            animation.delegate = self
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.detailView.layer.add(animation, forKey: "leftToRightTransition")
            let imageManager = PHImageManager()
            imageManager.requestImage(for: allAssets[assetIndex], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil, resultHandler: {(image, info) in
                guard let image = image else {return}
                self.imageView.image = image
            })
        case .right:
            if assetIndex <= 0 {
                assetIndex = allAssets.count-1
            }else{
                assetIndex -= 1
            }
            let animation = CATransition()
            animation.type = .push
            animation.subtype = .fromLeft
            animation.duration = 0.5
            animation.delegate = self
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.detailView.layer.add(animation, forKey: "leftToLeftTransition")
            let imageManager = PHImageManager()
            imageManager.requestImage(for: allAssets[assetIndex], targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, options: nil, resultHandler: {(image, info) in
                guard let image = image else {return}
                self.imageView.image = image
            })
        default:
            break
        }
        
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
//        設定欄位的高度
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
