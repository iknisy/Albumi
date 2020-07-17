//
//  SimilarImages.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/2/25.
//  Copyright © 2020 Mike. All rights reserved.
//

import Photos
import CoreML
import UIKit
import Vision

class SimilarImages: NSObject {
    
    func findSimilarImages(asset: PHAsset, findHandler: @escaping ([PHAsset]) -> Void){
//        從photo library分析相似圖片
//        讀取photo library
        var allAssets: [PHAsset] = []
        let phoptions = PHFetchOptions()
        phoptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let fetchAssets = PHAsset.fetchAssets(with: .image, options: phoptions)
        for i in 0..<fetchAssets.count {
            allAssets.append(fetchAssets.object(at: i))
        }
        
        requestSimilarImage(asset){assetRank, _ in
//原本是一次將全photo library的圖丟requestSimilarImage，但是在ipod上run會crash，以下是當時的錯誤訊息
//Fatal error: 'try!' expression unexpectedly raised an error: Error Domain=com.apple.CoreML Code=0 "Error in declaring network." UserInfo={NSLocalizedDescription=Error in declaring network.}
//猜測是無法一次處理多張圖片，因此改用遞迴的workaround
            self.requestSIRecursive(allAssets) { allRanks in
//                存放加權數
                var similarList: [Int] = []
//                將所有圖片的前20個相似參考圖都跟指定的圖比較，有一樣的圖形就加權數+1
                for j in allRanks {
                    var t = 0
                    j.forEach({ element in
                        if assetRank.contains(element) {t += 1}
                    })
                    similarList.append(t)
                }
//                依照加權數做遞減排序，加權0就捨棄
                let sorted = similarList.enumerated().sorted(by: {$0.element > $1.element })
//                加權數排序後的offset代表圖片在allAssets的順位，依照這個順位將asset記錄在similarAssets
                var similarAssets: [PHAsset] = []
                for j in sorted {
                    if j.element == 0 {break}
                    similarAssets.append(allAssets[j.offset])
                }
//                回傳分析後的相似圖片list
                findHandler(similarAssets)
            }
        }
    }
    
//    以遞迴的方式分批處理全photo library的圖
    func requestSIRecursive(_ allAssets: [PHAsset], index: Int = 0, allAssetsRank: [[Int]] = [], reHandler: @escaping ([[Int]]) -> Void){
//        儲存分析結果
        var allAssetsRanks = (allAssetsRank.count == 0) ? Array(repeating: [], count: allAssets.count) : allAssetsRank
//        index是上次處理進度，max是這次處理進度，一次處理1張圖片
        let max = (allAssets.count < index + 1) ? allAssets.count : index + 1
//        將進度回傳給NotificationCenter
        NotificationCenter.default.post(name: Notification.Name("MLprocess"), object: nil, userInfo: ["persent": Int(index * 100 / allAssets.count)])
        for i in index..<max {
//            一次分析超過8張圖會crash
            requestSimilarImage(allAssets[i], index: i) {allRank, rankIndex in
                allAssetsRanks[rankIndex] = allRank
//                檢查是否已處理完此次進度
                for j in index..<max {
                    if allAssetsRanks[j] == [] {return}
                }
//                若已處理完全部進度，回傳分析結果，否則進入下次遞迴
                if max == allAssets.count {
                    reHandler(allAssetsRanks)
                }else{
                    self.requestSIRecursive(allAssets, index: max, allAssetsRank: allAssetsRanks, reHandler: reHandler)
                }
            }
        }
    }
    
    func requestSimilarImage(_ asset: PHAsset, index: Int? = nil, handler: @escaping ([Int], Int) -> Void){
////        以下為直接使用Model的語法，測試時發現效能較差
//        let model = ImageSimilarity()
//        let assetWork = AssetWorks()
//        assetWork.assetToUIImage(asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit){requestImage in
////            將UIImage轉成CVPixelBuffer
//            guard let image = self.pixelImage(requestImage) else{return}
////            CVPixelBuffer轉成CoreMLModel所需的Input
//            let modelInput = ImageSimilarityInput.init(image: image)
////            Model分析的option
//            let options = MLPredictionOptions.init()
//            options.usesCPUOnly = true
////            Model分析
//            guard let predictionOutput = try? model.prediction(input: modelInput, options: options) else {return}
////            將分析結果存放在Array
//            let referenceImageNum = predictionOutput.distance.shape[0].intValue
//            var distanceArray: [Double] = []
//            for i in 0..<referenceImageNum {
//                distanceArray.append(Double(truncating: predictionOutput.distance[i]))
//            }
////            以加權值遞減排序分析結果，取前20個
//            let sorted = distanceArray.enumerated().sorted(by: {$0.element < $1.element})
//            let knn = sorted[..<min(20, referenceImageNum)]
//            var rank: [Int] = []
//            for i in 0..<knn.count {
//                rank.append(knn[i].offset)
//            }
////            回傳分析結果及index值
//            if let index = index {
//                handler(rank, index)
//            }else{
//                handler(rank, -1)
//            }
//        }
        
//        以下是使用Vision框架的語法
        guard let model = try? VNCoreMLModel(for: ImageSimilarity().model) else{
            fatalError("Can't load CoreML model")
        }
        let mlRequest = VNCoreMLRequest(model: model, completionHandler: {request, error in
            DispatchQueue.main.async {
                guard let results = request.results as? [VNCoreMLFeatureValueObservation], let firstResult = results.first, let distances = firstResult.featureValue.multiArrayValue else {
                    fatalError("result type ERROR")
                }
//                將分析結果存放在Array
                let referenceImageNum = distances.shape[0].intValue
                var distanceArray: [Double] = []
                for i in 0..<referenceImageNum {
                    distanceArray.append(Double(truncating: distances[i]))
                }
//                以加權值遞減排序分析結果，取前20個
                let sorted = distanceArray.enumerated().sorted(by: {$0.element < $1.element})
                let knn = sorted[..<min(20, referenceImageNum)]
                var rank: [Int] = []
                for i in 0..<knn.count {
                    rank.append(knn[i].offset)
                }
//                回傳分析結果及index值
                if let index = index {
                    handler(rank, index)
                }else{
                    handler(rank, -1)
                }
            }
        })
        mlRequest.imageCropAndScaleOption = .centerCrop
        let assetWork = AssetWorks()
        assetWork.assetToUIImage(asset, targetSize: PHImageManagerMaximumSize, contentMode: .aspectFit){requestimage in
            guard let cgimage = requestimage.cgImage else{return}
            let handler = VNImageRequestHandler(cgImage: cgimage)
            do{
                try handler.perform([mlRequest])
            }catch{
//                print(error)
            }
        }
    }
    
//    func pixelImage(_ image: UIImage) -> CVPixelBuffer? {
////        將UIImage轉為CVPixelBuffer
//        UIGraphicsBeginImageContextWithOptions(CGSize(width: 224, height: 224), true, 2)
//        image.draw(in: CGRect(x: 0, y: 0, width: 224, height: 224))
//        guard let newImage = UIGraphicsGetImageFromCurrentImageContext() else {return nil}
//        UIGraphicsEndImageContext()
//
//        var pixelBuffer: CVPixelBuffer?
//        let attrs = [kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue, kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue] as CFDictionary
//        let stutas = CVPixelBufferCreate(kCFAllocatorDefault, 224, 224, kCVPixelFormatType_32ARGB, attrs, &pixelBuffer)
//        if stutas != kCVReturnSuccess {return nil}
//
//        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
//        let pixeldata = CVPixelBufferGetBaseAddress(pixelBuffer!)
//        let context = CGContext(data: pixeldata, width: 224, height: 224, bitsPerComponent: 8, bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer!), space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue)
//        context?.translateBy(x: 0, y: 224)
//        context?.scaleBy(x: 1, y: -1)
//
//        UIGraphicsPushContext(context!)
//        newImage.draw(in: CGRect(x: 0, y: 0, width: 224, height: 224))
//        UIGraphicsPopContext()
//        CVPixelBufferLockBaseAddress(pixelBuffer!, CVPixelBufferLockFlags(rawValue: 0))
//
//        return pixelBuffer
//    }
}
