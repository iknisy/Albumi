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
        imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: contentMode, options: options, resultHandler: {(resultImage, info) in
            guard let resultImage = resultImage else {return}
            handler(resultImage)
        })
    }
    
    func assetInfo (_ asset: PHAsset) -> String {
//        回傳Asset相關資訊
        var infoString = ""
//        print(asset)
        if asset.representsBurst {
            infoString += "This photos is in burst mode.\n"
        }
//        print(asset.burstSelectionTypes)
//        print(asset.burstIdentifier)
        if let createData = asset.creationDate {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "YYYY / MM / dd, HH:mm:ss"
            infoString += "Create Date: \(dateFormat.string(from: createData))\n"
        }
        if let modifyDate = asset.modificationDate {
            let dateFormat = DateFormatter()
            dateFormat.dateFormat = "YYYY / MM / dd, HH:mm:ss"
            infoString += "Modify Date: \(dateFormat.string(from: modifyDate))\n"
        }
        infoString += "PhotoSize: \(asset.pixelHeight) Ｘ \(asset.pixelWidth) \n"
        switch asset.sourceType {
        case .typeUserLibrary:
            infoString += "From: Local\n"
        case .typeCloudShared:
            infoString += "From: iCloud\n"
        case .typeiTunesSynced:
            infoString += "From: iTunes\n"
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
                if let error = error {
                    print(error)
                }
                if let placemarks = placemarks {
                    let city = placemarks[0].locality ?? "Unknown City"
                    let country = placemarks[0].country ?? "Unknown Country"
                    let localString = "Location: \(city), \(country)"
                    handler(localString)
                }
            })
        }
    }
    
}
