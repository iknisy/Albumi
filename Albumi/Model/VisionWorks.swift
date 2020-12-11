//
//  VisionWorks.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/12/5.
//  Copyright © 2020 Mike. All rights reserved.
//

import Foundation
import Photos
import Vision
import UIKit

@available(iOS 13.0, *)
class VisionWorks {
    
    func findSimilarImages(asset: PHAsset, findHandler: @escaping ([PHAsset]) -> Void) {
//        從photo library分析相似圖片
//        讀取photo library
        var allAssets: [PHAsset] = []
        let phoptions = PHFetchOptions()
        phoptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchAssets = PHAsset.fetchAssets(with: .image, options: phoptions)
        for i in 0..<fetchAssets.count {
            allAssets.append(fetchAssets.object(at: i))
        }
        guard allAssets.count > 0 else{return}
//        分析圖片
        var targetObservation, sourceObsevation: VNFeaturePrintObservation?
        let assetWorks = AssetWorks()
        var distanceArray = [Double]()
        let semaphore = DispatchSemaphore(value: 0)
        let queueGroup = DispatchGroup()
//        另開線程group
        DispatchQueue.global().async(group: queueGroup) {
//            獲得來源圖片的Image
            assetWorks.assetToUIImage(asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit, handler: { image in
//                獲得來源圖片的FeaturePrintObservation
                if let obsevation = self.featureprintObservation(from: image) {
                    sourceObsevation = obsevation
                }
//                獲得photo library所有圖片的Image
                let allImage = allAssets.enumerated().map { (i,m) -> UIImage in
                    let imageSemaphore = DispatchSemaphore(value: 0)
                    var result = UIImage()
                    assetWorks.assetToUIImage(m, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit) { image in
                        result = image
//                        發送線程信號
                        imageSemaphore.signal()
                    }
//                    等待線程信號
                    imageSemaphore.wait()
                    return result
                }
//                計算所有圖片與來源圖片的歐幾里得距離
                distanceArray = allImage.enumerated().map { (i,m) -> Double in
                    var result = 0.0
//                    獲得圖片的FeaturePrintObservation
                    if let obsevation = self.featureprintObservation(from: m) {
                        targetObservation = obsevation
                    }
//                    從FeaturePrintObservation計算歐幾里得距離
                    do {
                        var distance: Float = 0
                        try targetObservation?.computeDistance(&distance, to: sourceObsevation!)
                        result = Double(distance)
                    }catch{
                        dPrint("computeDistanceError: \(error)")
                    }
//                    將進度回傳給NotificationCenter
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: Notification.Name("MLprocess"), object: nil, userInfo: ["persent": Int(i * 100 / allAssets.count)])
                    }
                    return result
                }
//                發送線程信號
                semaphore.signal()
            })
//            等待線程信號
            semaphore.wait()
        }

        DispatchQueue.global().async{
//            等待線程group中的工作都已完成
            queueGroup.wait()
//            以歐氏距離由小到大對所有圖片排序
            let sorted = distanceArray.enumerated().sorted(by: {$0.element < $1.element})
            dPrint(sorted)
            var similarAssets = [PHAsset]()
            for i in sorted {
                similarAssets.append(allAssets[i.offset])
            }
//            切換至主線程執行closure
            DispatchQueue.main.async {
                findHandler(similarAssets)
            }
        }
    }
    
    private func featureprintObservation(from image: UIImage) -> VNFeaturePrintObservation? {
//        回傳圖片的FeaturePrintObservation
        guard let cgimage = image.cgImage else {return nil}
        let requestHandler = VNImageRequestHandler(cgImage: cgimage, options: [:])
        let fpRequest = VNGenerateImageFeaturePrintRequest()
        do {
            try requestHandler.perform([fpRequest])
            return fpRequest.results?.first as? VNFeaturePrintObservation
        }catch{
            dPrint("Vision error: \(error)")
        }
        return nil
    }
    
}
