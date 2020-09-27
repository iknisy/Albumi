//
//  EditTextViewController.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/3/29.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit
import FlexColorPicker
import Photos

class EditTextViewController: UIViewController{

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var textView: UITextView!{
        didSet{
            textView.delegate = self
        }
    }
    @IBOutlet var buttonStack: UIStackView!
    @IBOutlet var fontSize: UITextField!{
        didSet{
//            設定鍵盤
            fontSize.keyboardType = .numberPad
            fontSize.delegate = self
        }
    }
    
    @IBAction func clearText(){
//        若正在編輯文字則不會起作用
        if textView.isEditable || fontSize.isEditing {return}
//        清除文字，恢復預設值
        textView.text = ""
        textView.textColor = UIColor.white
        textView.frame = imageView.contentClippingRect
        textView.font = textView.font?.withSize(20)
        fontSize.text = "20"
    }
    @IBOutlet var lockSwitch: UISwitch!
    @IBAction func lock(_ sender: UISwitch){
//        鎖定文字位置
        if sender.isOn {
            lockFlag = true
        }else{
            lockFlag = false
        }
    }
    @IBAction func lockButton(){
//        手動調整lockswitch
        if lockSwitch.isOn {
            lockFlag = false
            lockSwitch.setOn(false, animated: true)
        }else{
            lockFlag = true
            lockSwitch.setOn(true, animated: true)
        }
    }
    @IBAction func colorPicker(){
//        呼叫調色盤選文字顏色
        let controller = DefaultColorPickerViewController()
        controller.delegate = self
        controller.selectedColor = textView.textColor!
        if #available(iOS 13.0, *) {
            present(controller, animated: true, completion: nil)
        }else{
            show(controller, sender: nil)
        }
    }
    
//    儲存DetailTableViewVC傳來的asset及ＤＢ物件
    var asset: PHAsset?
    var textData: PictureRemark?
//    鎖定文字位置
    var lockFlag = false
//    為了確認要使用update還是insert
    var updateFlag = false
//    顯示第二張說明圖片的flag
    var helpActFlag: Bool?
//    暫存跳出app時的edit狀態
    var editFlag: Bool?
//    儲存觸碰點
    var touchPoint = CGPoint.zero
//    儲存view移動前的中心點
    var originalCenter = CGPoint.zero
//    儲存鍵盤大小
    var keyboardSize = CGSize()
//    完成文字編輯的按鈕及func
    let textbar = UIBarButtonItem(title: NSLocalizedString("Done", comment: ""), style: .done, target: self, action: #selector(doneEditText))
    @objc func doneEditText(){
//        確認是完成編輯的是textView還是textField
        if textView.isEditable{
//            關閉編輯功能
            textView.resignFirstResponder()
            textView.isEditable = false
//            關閉textView的使用者互動功能
            textView.isUserInteractionEnabled = false
//            移除此按鈕
            _ = navigationItem.rightBarButtonItems?.popLast()
//            恢復navigationbar原有功能
            for i in 0..<(navigationItem.rightBarButtonItems?.count ?? 0) {
                navigationItem.rightBarButtonItems?[i].isEnabled = true
            }
            navigationItem.hidesBackButton = false
            
        }else{
//            移除此按鈕
            _ = navigationItem.rightBarButtonItems?.popLast()
//            恢復navigationbar原有功能
            for i in 0..<(navigationItem.rightBarButtonItems?.count ?? 0) {
                navigationItem.rightBarButtonItems?[i].isEnabled = true
            }
            navigationItem.hidesBackButton = false
//            呼叫結束修改的func
            _ = textFieldShouldReturn(fontSize)
        }
    }
    
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
        })
//        先關閉textView的使用者互動功能
        textView.isUserInteractionEnabled = false
//        儲存view的中心點位置
        originalCenter = view.center
//        加入說明button
        let helpButton = UIBarButtonItem(image: UIImage(named: "hexhelp"), style: .plain, target: self, action: #selector(helpAct))
        navigationItem.rightBarButtonItem = helpButton
//        建立儲存按鈕
        let saveBar = UIBarButtonItem(image: UIImage(named: "save-2"), style: .plain, target: self, action: #selector(saveText))
        navigationItem.rightBarButtonItems?.append(saveBar)
    }
    @objc func helpAct(){
//        popover說明
        if let controller = storyboard?.instantiateViewController(withIdentifier: "PopImageViewController") as? PopImageViewController {
            controller.modalPresentationStyle = .popover
            controller.popoverPresentationController?.delegate = self
            var image: UIImage?
            switch helpActFlag {
//                以flag決定要顯示第幾張說明圖片
            case nil:
//                第一張說明
                controller.popoverPresentationController?.sourceView = buttonStack
                controller.popoverPresentationController?.sourceRect = buttonStack.bounds
                image = UIImage(named: NSLocalizedString("Edit1", comment: ""))
                helpActFlag = true
            case true:
//                第二張說明
                controller.popoverPresentationController?.sourceView = imageView
                controller.popoverPresentationController?.sourceRect = CGRect(origin: .zero, size: CGSize(width: imageView.bounds.size.width, height: imageView.bounds.midY))
                image = UIImage(named: NSLocalizedString("Edit2", comment: ""))
                helpActFlag = false
            case false:
//                第三張說明
                controller.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItems?[1]
                image = UIImage(named: NSLocalizedString("Edit3", comment: ""))
                helpActFlag = nil
            default:
                break
            }
            controller.image = image?.resizeByWidth(UIScreen.main.bounds.width * 2/3)
            present(controller, animated: true, completion: nil)
        }
    }
    @objc func saveText(){
        if textView.text == "" {
//            若textView沒有內容則從ＤＢ刪除原有資料
            _ = PictureRemarkIO.shared.deleteData(where: asset!.localIdentifier)
            return
        }
//        找出縮放比例
        let scale = (imageView.bounds.width / imageView.image!.size.width) < (imageView.bounds.height / imageView.image!.size.height) ? (imageView.bounds.width / imageView.image!.size.width) : (imageView.bounds.height / imageView.image!.size.height)
//        找出縮放後的textView原點
        let positionX = (textView.frame.minX - imageView.frame.midX) / scale
        let positionY = (textView.frame.minY - imageView.frame.midY) / scale
        let font = textView.font!.pointSize / scale
        if updateFlag {
//            若ＤＢ已有資料則進行update
            _ = PictureRemarkIO.shared.updateDate(locolIdentifier: asset!.localIdentifier, text: textView.text, colorString: PictureRemarkIO.shared.hexFromUIColor(textView.textColor!), size: Int(font), X: Double(positionX), Y: Double(positionY))
        }else{
//            若ＤＢ未有資料則進行insert，並將flag設定為true
            _ = PictureRemarkIO.shared.insertData(locolIdentifier: asset!.localIdentifier, text: textView.text, colorString: PictureRemarkIO.shared.hexFromUIColor(textView.textColor!), size: Int(font), X: Double(positionX), Y: Double(positionX))
            updateFlag = true
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let asset = asset, updateFlag == false, textView.text == "" {
//            在所有autolayout調整完後再設定textview
            setText(asset)
        }
    }
    func setText(_ asset: PHAsset){
        if let textData = textData, let image = imageView.image {
//            找出縮放比例
            let scale = (imageView.bounds.width / image.size.width) < (imageView.bounds.height / image.size.height) ? (imageView.bounds.width / image.size.width) : (imageView.bounds.height / image.size.height)
//            找出縮放後的text原點
            let positionX = imageView.frame.midX + CGFloat(textData.locationX) * scale
            let positionY = imageView.frame.midY + CGFloat(textData.locationY) * scale
//            textView細項設定
            textView.frame = CGRect(x: positionX, y: positionY, width: imageView.contentClippingRect.width, height: imageView.contentClippingRect.height)
            fontSize.text = Int(CGFloat(textData.size) * scale).description
            textView.text = textData.text
            textView.font = UIFont.systemFont(ofSize: CGFloat(textData.size) * scale)
            textView.textColor = PictureRemarkIO.shared.hexToUIColor(hexString: textData.colorString)
            updateFlag = true
        }else{
//            若ＤＢ沒有資料，則預設textView的frame跟圖片一樣
            textView.frame = imageView.contentClippingRect
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        註冊notification，以便在編輯文字跳出鍵盤時調整view
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(textViewChanged), name: UITextView.textDidChangeNotification, object: nil)
    }
    @objc func keyboardWillShow(_ note: NSNotification){
//        鍵盤出現以後呼叫此func
//        找出鍵盤高度
        keyboardSize = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        if textView.isEditable {
//            編輯textView
//            找出游標所在座標
            guard let select = textView.selectedTextRange else {return}
            let tempPosition = textView.caretRect(for: select.start)
//            找出游標在view上的座標
            let position = textView.convert(tempPosition, to: view)
//            先算出游標被鍵盤擋住多少再調整
            if position.maxY >= self.view.bounds.size.height - keyboardSize.height {
                view.center.y -= position.maxY + keyboardSize.height - self.view.bounds.size.height
            }
        }else{
//            編輯textField時將view上移
            view.center.y -= keyboardSize.height
        }
    }
    @objc func keyboardWillHide(_ note: NSNotification){
//        鍵盤關閉後呼叫此func
//        將view調整回原位置
        view.center = originalCenter
    }
//    @objc func textViewChanged(){
////        每次文字改變時都會呼叫此func
////        找出游標所在位置
//        guard let select = textView.selectedTextRange else {return}
//        let tempPosition = textView.caretRect(for: select.start)
////        找出游標在view上的座標
//        let position = textView.convert(tempPosition, to: view)
//        if position.minY - originalCenter.y + view.center.y <= 100 {
////            若游標的位置高於navigationbar時將view往下調整
//            view.center.y += position.height
//        }else if position.maxY - originalCenter.y + view.center.y >= self.view.bounds.size.height - keyboardSize.height {
////            若游標位置低於鍵盤時將view往上調整
//            view.center.y -= position.height
//        }
//    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
//        註冊Notification，在app從背景恢復時回復編輯游標
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(checkEditState),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(restoreEditState),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
//        移除Notification註冊
        NotificationCenter.default.removeObserver(self)
    }
    @objc func checkEditState(){
//        確認是否正在編輯文字，以flag暫存
        if textView.isEditable {
            editFlag = true
        }
        if fontSize.isEditing {
            editFlag = false
        }
    }
    @objc func restoreEditState(){
//        確認flag以回復編輯狀態
        guard let flag = editFlag else {return}
        if flag {
            textView.resignFirstResponder()
            textView.becomeFirstResponder()
            editFlag = nil
        }else{
            fontSize.resignFirstResponder()
            fontSize.becomeFirstResponder()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        使用者進行觸碰時呼叫此func
//        只對單點觸碰有反應
        if event?.allTouches?.count != 1 {return}
        if let touch = touches.first {
//            儲存此次觸碰座標
            touchPoint = touch.location(in: textView)
        }
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
//        使用者進行觸碰並移動時呼叫此func
//        確認是單點事件，text沒有鎖定，textView跟textField沒有在編輯
        if event?.allTouches?.count != 1 || lockFlag || textView.isEditable || fontSize.isEditing {return}
        guard let touch = touches.first else {return}
//        以移動前觸碰位置算出移動距離，然後移動textView的位置
        let currentPoint = touch.location(in: textView)
//        textView.frame = textView.frame.offsetBy(dx: currentPoint.x - touchPoint.x, dy: currentPoint.y - touchPoint.y)
        textView.center = CGPoint(x: textView.center.x + currentPoint.x - touchPoint.x, y: textView.center.y + currentPoint.y - touchPoint.y)
//        紀錄移動後觸碰位置
        touchPoint = currentPoint
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        使用者結束觸碰時呼叫此func
//        確認是單點事件，textView跟textField沒有在編輯
        if event?.allTouches?.count != 1 || textView.isEditable || fontSize.isEditing {return}
        guard let touch = touches.first else {return}
        if touch.location(in: textView) == touchPoint {
//            如果此次觸碰沒有移動則進入編輯文字動作
            textView.isEditable = true
            textView.becomeFirstResponder()
            textView.isUserInteractionEnabled = true
//            暫時關閉navigationbar上現有的所有功能
            for i in 0..<(navigationItem.rightBarButtonItems?.count ?? 0) {
                navigationItem.rightBarButtonItems?[i].isEnabled = false
            }
            navigationItem.hidesBackButton = true
//            加入完成修改按鈕
            navigationItem.rightBarButtonItems?.append(textbar)
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
extension EditTextViewController: UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
//        設定popover
        return .none
    }
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
//        popover的View消失後執行此func(after iOS13
        if helpActFlag != nil {
//            以flag確認是否顯示第二張說明
            helpAct()
        }
    }
    func popoverPresentationControllerDidDismissPopover(_ popoverPresentationController: UIPopoverPresentationController) {
//        popover的View消失後執行此func(before iOS13
        if helpActFlag != nil {
//            以flag確認是否顯示第二張說明
            helpAct()
        }
    }
}
extension EditTextViewController: ColorPickerDelegate {
    func colorPicker(_ colorPicker: ColorPickerController, selectedColor: UIColor, usingControl: ColorControl) {
        textView.textColor = selectedColor
    }
    func colorPicker(_ colorPicker: ColorPickerController, confirmedColor: UIColor, usingControl: ColorControl) {
        dismiss(animated: true, completion: nil)
    }
}
extension EditTextViewController: UITextViewDelegate{
    func textViewDidChangeSelection(_ textView: UITextView) {
//        每次游標改變時都會呼叫此func
//        找出游標所在位置
        guard let select = textView.selectedTextRange else {return}
        let tempPosition = textView.caretRect(for: select.end)
//        找出游標在view上的座標
        let position = textView.convert(tempPosition, to: view)
        if position.minY - originalCenter.y + view.center.y <= 100 {
//            若游標的位置高於navigationbar時將view往下調整
            view.center.y += position.height
        }else if position.maxY - originalCenter.y + view.center.y >= self.view.bounds.size.height - keyboardSize.height {
//            若游標位置低於鍵盤時將view往上調整
            view.center.y -= position.height
        }
    }
}
extension EditTextViewController: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
//        開始修改文字大小，UItextField的delegate會call這個func
//        若有暫存editflag則跳過這個func
        if editFlag == false {
            editFlag = nil
            return true
        }
//        暫時關閉navigationbar上現有的所有功能
        for i in 0..<(navigationItem.rightBarButtonItems?.count ?? 0) {
            navigationItem.rightBarButtonItems?[i].isEnabled = false
        }
        navigationItem.hidesBackButton = true
//        加入修改完成按鈕
        navigationItem.rightBarButtonItems?.append(textbar)
        return true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
//        結束修改文字大小，UItextField的delegate會call這個func
//        結束編輯
        textField.resignFirstResponder()
//        檢查內容是否合理，然後修改文字大小，若不合理則將textField恢復成修改前狀態
        guard let size = Double(textField.text!) else{
            fontSize.text = textView.font?.pointSize.description
            return true
        }
        if size > 0 {
            textView.font = textView.font?.withSize(CGFloat(size))
        }else{
            fontSize.text = textView.font?.pointSize.description
        }
        return true
    }
}
