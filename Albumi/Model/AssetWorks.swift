//
//  AssetWorks.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/2/27.
//  Copyright © 2020 Mike. All rights reserved.
//

import Photos
import UIKit

class AssetWorks {
//    Asset相關工作
    
    func assetToUIImage (_ asset: PHAsset, targetSize: CGSize, contentMode: PHImageContentMode, options: PHImageRequestOptions? = nil, handler: @escaping (UIImage) -> Void) {
//        Asset轉換成UIImage
        let imageManager = PHImageManager.default()
        let option = PHImageRequestOptions()
        option.isNetworkAccessAllowed = true
        option.resizeMode = .none
        option.deliveryMode = .highQualityFormat
//        option.progressHandler = {(process, error, isStop, info) in
//            if error != nil {
//                print(error.debugDescription)
//                return
//            }
//            if process == 1 {
//                imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options ?? option, resultHandler: {(resultImage, info) in
//                    guard let resultImage = resultImage else {return}
//                    handler(resultImage)
//                })
//            }
//        }
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options ?? option, resultHandler: {(resultImage, info) in
            guard let resultImage = resultImage else {return}
            handler(resultImage)
        })
    }
    
    func assetInfo (_ asset: PHAsset) -> String {
//        回傳Asset相關資訊
        var infoString = ""
//        print(asset)
        if asset.representsBurst {
            infoString += NSLocalizedString("This photos is in burst mode.\n", comment: "")
        }
//        print(asset.burstSelectionTypes)
//        print(asset.burstIdentifier)
        if let createData = asset.creationDate {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "YYYY / MM / dd, HH:mm:ss"
            infoString += NSLocalizedString("Create Date", comment: "") + ": \(dateFormat.string(from: createData))\n"
        }
        if let modifyDate = asset.modificationDate {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "YYYY / MM / dd, HH:mm:ss"
            infoString += NSLocalizedString("Modify Date", comment: "") + ": \(dateFormat.string(from: modifyDate))\n"
        }
        infoString += NSLocalizedString("PhotoSize", comment: "") + ": \(asset.pixelHeight) Ｘ \(asset.pixelWidth) \n"
        switch asset.sourceType {
        case .typeUserLibrary:
            infoString += NSLocalizedString("From: Local\n", comment: "")
        case .typeCloudShared:
            infoString += NSLocalizedString("From: iCloud\n", comment: "")
        case .typeiTunesSynced:
            infoString += NSLocalizedString("From: iTunes\n", comment: "")
        default:
            break
        }
//        print(allAssets[assetIndex].mediaSubtypes)
//        print(allAssets[assetIndex].playbackStyle)
//        print(allAssets[assetIndex].duration)
        return infoString
    }
    
    func assetLocation(_ asset: PHAsset, handler: @escaping (String) -> Void) {
//        回傳Asset的拍攝地點
        if let location = asset.location {
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location, preferredLocale: nil, completionHandler: {(placemarks, error) in
//                if let error = error {
//                    print(error)
//                }
                if let placemarks = placemarks {
                    let city = placemarks[0].locality ?? NSLocalizedString("Unknown City", comment: "")
                    let country = placemarks[0].country ?? NSLocalizedString("Unknown Country", comment: "")
                    let localString = NSLocalizedString("Location", comment: "") + ": \(city), \(country)"
                    handler(localString)
                }
            })
        }
    }
    
}
