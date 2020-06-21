//
//  MainNaviViewController.swift
//  Albumi
//
//  Created by 陳昱宏 on 2020/6/9.
//  Copyright © 2020 Mike. All rights reserved.
//

import UIKit

class MainNaviViewController: UINavigationController {

    override var shouldAutorotate: Bool {
        get{
            return visibleViewController?.shouldAutorotate ?? true
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        get{
            return visibleViewController?.supportedInterfaceOrientations ?? .all
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
