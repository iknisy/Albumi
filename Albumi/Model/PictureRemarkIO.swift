//
//  PictureRemarkIO.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/3/13.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit
import FMDB

class PictureRemarkIO: NSObject {
    
    static let shared = PictureRemarkIO()
    
    var fileName = "PictureRemark_DATA.sqlite"
    var filePath = ""
    var database: FMDatabase!
    let sql_LocalID = "localID"
    let sql_Text = "text"
    let sql_ColorString = "colorString"
    let sql_Size = "size"
    let sql_LocationX = "locationX"
    let sql_LocationY = "locationY"
    
    private override init() {
        super.init()
        
        filePath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0] + "/" + fileName
//        print("filePath: \(filePath)")
    }
    deinit {
//        print("deinit \(self)")
    }
    
    func createTable() -> Bool{
        var created = false
        
        if !FileManager.default.fileExists(atPath: filePath){
            database = FMDatabase(path: filePath)
            if database != nil{
                if database.open() {
                    let createTableSQL = "create table PictureRemark " +
                    "(\(sql_LocalID) varchar(50) primary key not null, " +
                    "\(sql_Text) varchar(500) not null default \'\', " +
                    "\(sql_ColorString) char(8) not null, " +
                    "\(sql_Size) integer not null, " +
                    "\(sql_LocationX) float(24) not null, " +
                    "\(sql_LocationY) float(24) not null)"
                    do{
                        try database.executeUpdate(createTableSQL, values: nil)
                        print("Table Create at: \(filePath)")
                        created = true
                    }catch{
                        print("Can not create the table.")
                        print(error.localizedDescription)
                    }
                    database.close()
                }else{
                    print("Can not open the database.")
                }
            }
        }
        return created
    }
    
    func openConnection() -> Bool{
        if database == nil {
            if FileManager.default.fileExists(atPath: filePath) {
                database = FMDatabase(path: filePath)
            }
        }
        if database != nil {
            if database.open() {
                return true
            }
        }
        print("Can not connect the database.")
        return false
    }
    
    func insertData(locolIdentifier: String, text: String, colorString: String, size: Int, X: Double, Y: Double) -> Bool{
        var result = false
        if openConnection(){
            let insertSQL = "insert into PictureRemark (\(sql_LocalID), \(sql_Text), \(sql_ColorString), \(sql_Size), \(sql_LocationX), \(sql_LocationY)) values (\'\(locolIdentifier)\', \'\(text)\', \'\(colorString)\', \(size), \(X), \(Y))"
            do{
                try database.executeUpdate(insertSQL, values: nil)
                result = true
            }catch{
                print("insertERROR")
                print(error.localizedDescription)
            }
            database.close()
        }
        return result
    }
    func updateDate(locolIdentifier: String, text: String? = nil, colorString: String? = nil, size: Int? = nil, X: Double? = nil, Y: Double? = nil) -> Bool{
        var result = false
        var updateFlag = false
        var updateSQL = "update PictureRemark set "
        if let text = text {
            updateSQL += "\(sql_Text)=\'\(text)\'"
            updateFlag = true
        }
        if let colorString = colorString {
            if updateFlag {
                updateSQL += ", "
            }
            updateSQL += "\(sql_ColorString)=\'\(colorString)\'"
            updateFlag = true
        }
        if let size = size {
            if updateFlag {
                updateSQL += ", "
            }
            updateSQL += "\(sql_Size)=\(size)"
            updateFlag = true
        }
        if let locationX = X, let locationY = Y {
            if updateFlag {
                updateSQL += ", "
            }
            updateSQL += "\(sql_LocationX)=\(locationX), \(sql_LocationY)=\(locationY)"
            updateFlag = true
        }
        guard updateFlag else{
            return false
        }
        if openConnection(){
            updateSQL += " where \(sql_LocalID)=\'\(locolIdentifier)\'"
            do {
                try database.executeUpdate(updateSQL, values: nil)
                result = true
            }catch{
                print("updateERROR")
                print(error.localizedDescription)
            }
            database.close()
        }
        return result
    }
    func queryData() -> [PictureRemark] {
        var pictureRemarks: [PictureRemark] = []
        if openConnection() {
            let querySQL = "select * from PictureRemark"
            do{
                let queryResult = try database.executeQuery(querySQL, values: nil)
                while queryResult.next() {
                    let pictureRemark = PictureRemark(locolIdentifier: queryResult.string(forColumn: sql_LocalID)!,
                                                      text: queryResult.string(forColumn: sql_Text)!,
                                                      colorString: queryResult.string(forColumn: sql_ColorString)!,
                                                      size: Int(queryResult.int(forColumn: sql_Size)),
                                                      X: queryResult.double(forColumn: sql_LocationX),
                                                      Y: queryResult.double(forColumn: sql_LocationY))
                    pictureRemarks.append(pictureRemark)
                }
            }catch{
                print("queryERROR")
                print(error.localizedDescription)
            }
            database.close()
        }
        return pictureRemarks
    }
    func queryData(with locolIdentifier: String) -> PictureRemark?{
        var fetchResult: PictureRemark?
        if openConnection() {
            let querySQL = "select * from PictureRemark where \(sql_LocalID)=\'\(locolIdentifier)\'"
            do{
                let queryResult = try database.executeQuery(querySQL, values: nil)
                if queryResult.next(){
                    fetchResult = PictureRemark(locolIdentifier: queryResult.string(forColumn: sql_LocalID)!,
                    text: queryResult.string(forColumn: sql_Text)!,
                    colorString: queryResult.string(forColumn: sql_ColorString)!,
                    size: Int(queryResult.int(forColumn: sql_Size)),
                    X: queryResult.double(forColumn: sql_LocationX),
                    Y: queryResult.double(forColumn: sql_LocationY))
                }else{
                    print(database.lastError())
                }
            }catch{
                print("queryERROR")
                print(error.localizedDescription)
            }
            database.close()
        }
        return fetchResult
    }
    func deleteData(where locolIdentifier: String) -> Bool{
        var result = false
        if openConnection() {
            let deleteSQL = "delete from PictureRemark where \(sql_LocalID)=\'\(locolIdentifier)\'"
            do{
                try database.executeUpdate(deleteSQL, values: nil)
                result = true
            }catch{
                print("deleteERROR")
                print(error.localizedDescription)
            }
            database.close()
        }
        return result
    }
    
    func hexToUIColor(hexString: String) -> UIColor{
//        將RGBA_String轉換成UIColor
        if hexString.count == 8 {
            let scanner = Scanner(string: hexString)
            var hexNumber: UInt64 = 0
            if scanner.scanHexInt64(&hexNumber) {
                let r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                let g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                let b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                let a = CGFloat(hexNumber & 0x000000ff) / 255
                return UIColor(red: r, green: g, blue: b, alpha: a)
            }
        }
        return UIColor.white
    }
    func hexFromUIColor(_ color: UIColor) -> String {
//        將UIColor轉換成RGBA_String
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        if color.getRed(&r, green: &g, blue: &b, alpha: &a) {
            var result = ""
            result += String(format: "%02x", Int(r * 255))
            result += String(format: "%02x", Int(g * 255))
            result += String(format: "%02x", Int(b * 255))
            result += String(format: "%02x", Int(a * 255))
            return result
        }
        return "FFFFFFFF"
    }
    
}

