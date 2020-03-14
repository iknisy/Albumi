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
    @IBOutlet var textLable: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var closeButton: UIButton!
    @IBAction func close(){
        dismiss(animated: true, completion: nil)
    }
    
    
    var asset: PHAsset?
    var showMode: FullScreenViewMode?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
//        讀取圖片
        guard  let asset = asset else {
            return
        }
        let requestImage = AssetWorks()
        requestImage.assetToUIImage(asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, handler: {(image) in
            self.imageView.image = image
        })
//        依照模式設定隱藏物件
        switch showMode {
        case .fullScreen:
            self.textView.isHidden = true
        case .editText:
            self.textLable.isHidden = true
            self.closeButton.isHidden = true
        default:
            self.textView.isHidden = true
            self.textLable.isHidden = true
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

enum FullScreenViewMode {
    case fullScreen
    case editText
}
