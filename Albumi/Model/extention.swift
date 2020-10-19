//
//  extention.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/10/6.
//  Copyright © 2020 Mike. All rights reserved.
//

import Foundation

func dPrint(_ item: Any..., function: String = #function) {
    #if DEBUG
    print("\(function): \(item)")
    #endif
}
