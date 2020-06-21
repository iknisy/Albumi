//
//  FullScreenViewController.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/2/6.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit
import Photos

class FullScreenViewController: UIViewController, CAAnimationDelegate {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    
//    儲存DetailTableViewVC傳入的asset及ＤＢ資料
    var assetList: [PHAsset] = []
    var assetIndex = 0
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        讀取圖片
        let requestImage = AssetWorks()
        requestImage.assetToUIImage(assetList[assetIndex], targetSize: CGSize(width: assetList[assetIndex].pixelWidth, height: assetList[assetIndex].pixelHeight), contentMode: .aspectFit, handler: {(image) in
            self.imageView.image = image
//            設定textView
            self.setText()
        })
//        設定單擊手勢
        let tap = UITapGestureRecognizer(target: self, action: #selector(oneClick(gesture:)))
        tap.numberOfTapsRequired = 1
        tap.numberOfTouchesRequired = 1
        view.addGestureRecognizer(tap)
//        設定左右滑跳到前(下)一張的手勢
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(viewSwipe(gesture:)))
        swipeLeft.direction = .left
        view.addGestureRecognizer(swipeLeft)
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(viewSwipe(gesture:)))
        swipeRight.direction = .right
        view.addGestureRecognizer(swipeRight)
    }
    
    func setText() {
        if let textData = PictureRemarkIO.shared.queryData(with: assetList[assetIndex].localIdentifier) {
//            找出縮放比例
            let scale = (imageView.bounds.width / imageView.image!.size.width) < (imageView.bounds.height / imageView.image!.size.height) ? (imageView.bounds.width / imageView.image!.size.width) : (imageView.bounds.height / imageView.image!.size.height)
//            找出縮放後的textView原點
            let positionX = imageView.frame.midX + CGFloat(textData.locationX) * scale
            let positionY = imageView.frame.midY + CGFloat(textData.locationY) * scale
//            textView細項設定
            textView.frame = CGRect(x: positionX, y: positionY, width: imageView.contentClippingRect.width, height: imageView.contentClippingRect.height)
            textView.font = UIFont.systemFont(ofSize: CGFloat(textData.size) * scale)
            textView.textColor = PictureRemarkIO.shared.hexToUIColor(hexString: textData.colorString)
            textView.text = textData.text
        }else{
            textView.text = ""
        }
    }
    @objc func oneClick(gesture: UITapGestureRecognizer){
//        單擊螢幕動作
        if textView.isDescendant(of: view) && textView.text != ""{
//            若有TextView則隱藏(移除)TextView
            textView.removeFromSuperview()
        }else{
//            若無TextView則回上個View
            close()
        }
    }
    func close(){
//        關閉此View
        if let naviController = presentingViewController as? UINavigationController, let detailController = naviController.topViewController as? DetailTableViewController{
//            關閉前先檢查前一個View與此View的index是否一致
            if detailController.assetIndex != assetIndex{
                detailController.assetIndex = assetIndex
                detailController.reloadFlag = true
            }
        }
        dismiss(animated: false, completion: nil)
    }
    
    @objc func viewSwipe(gesture: UISwipeGestureRecognizer){
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
            self.view.layer.add(animation, forKey: "leftToRightTransition")
            requestImage.assetToUIImage(assetList[assetIndex], targetSize: CGSize(width: assetList[assetIndex].pixelWidth, height: assetList[assetIndex].pixelHeight), contentMode: .aspectFit, handler: {(image) in
                self.imageView.image = image
//                設定textView
                if self.textView.isDescendant(of: self.view) {
                    self.setText()
                }
            })
        case .right:
            if assetIndex <= 0 {
                assetIndex = assetList.count-1
            }else{
                assetIndex -= 1
            }
            animation.subtype = .fromLeft
            self.view.layer.add(animation, forKey: "leftToLeftTransition")
            requestImage.assetToUIImage(assetList[assetIndex], targetSize: CGSize(width: assetList[assetIndex].pixelWidth, height: assetList[assetIndex].pixelHeight), contentMode: .aspectFit, handler: {(image) in
                self.imageView.image = image
//                設定textView
                if self.textView.isDescendant(of: self.view) {
                    self.setText()
                }
            })
        default:
            break
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

