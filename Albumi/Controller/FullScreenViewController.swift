//
//  FullScreenViewController.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/2/6.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit
import Photos

class FullScreenViewController: UIViewController {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!
    @IBOutlet var closeButton: UIButton!
    @IBAction func close(){
        dismiss(animated: true, completion: nil)
    }
    
//    儲存DetailTableViewVC傳入的asset及ＤＢ資料
    var asset: PHAsset?
    var textData: PictureRemark?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        讀取圖片
        guard  let asset = asset else {
            return
        }
        let requestImage = AssetWorks()
        requestImage.assetToUIImage(asset, targetSize: CGSize(width: asset.pixelWidth, height: asset.pixelHeight), contentMode: .aspectFit, handler: {(image) in
            self.imageView.image = image
//            設定textView
            self.setText()
        })
    }
    
    func setText() {
        if let textData = textData {
//            找出縮放比例
            let scale = (imageView.bounds.width / imageView.image!.size.width) < (imageView.bounds.height / imageView.image!.size.height) ? (imageView.bounds.width / imageView.image!.size.width) : (imageView.bounds.height / imageView.image!.size.height)
//            找出縮放後的textView原點
            let positionX = imageView.frame.midX + CGFloat(textData.locationX) * scale
            let positionY = imageView.frame.midY + CGFloat(textData.locationY) * scale
//            textView細項設定
            textView.frame = CGRect(x: positionX, y: positionY, width: imageView.bounds.width, height: imageView.bounds.height)
            textView.font = UIFont.systemFont(ofSize: CGFloat(textData.size) * scale)
            textView.textColor = PictureRemarkIO.shared.hexToUIColor(hexString: textData.colorString)
            textView.text = textData.text
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

